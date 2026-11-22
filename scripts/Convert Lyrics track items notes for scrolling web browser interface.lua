--[[
 * ReaScript Name: Convert Lyrics track items notes for scrolling web browser interface
 * About: Use with the Scrolling Chords ChordPro.html web interface.
 *        Runs in the background: publishes the item notes of the track named "Lyrics"
 *        (case-insensitive) of the active project tab, and publishes again whenever the
 *        tab changes or the project is edited. Run it again to stop it.
 *        To start it with REAPER, use the __startup.lua that comes with it.
 * Based on: X-Raym_Convert first selected track items notes for scrolling web browser interface.lua (v1.0.1)
 * Original Author: X-Raym
 * Original Repository URI: https://github.com/X-Raym/REAPER-ReaScripts
 * Licence: GPL v3
 * REAPER: 5.0
 * Version: 1.9
--]]

--[[
 * Changelog:
 * v1.9
  # Fade: the volume went back before the audio had really stopped. Now: fade, silence (volume 0),
    stop, wait for REAPER to stop and its buffers to empty, then put the volume back
 * v1.8
  + Fade out and stop, asked by the web page (ExtState XR_Lyrics/fade_stop = seconds):
    fades the master volume, stops, then puts the volume back
  + ExtState XR_Lyrics/running, so the page knows the fade is available
 * v1.7
  + Background script: follows the active project tab and republishes when the project changes
  + Toggle action: running it again stops it (toolbar button state)
  + JSON includes the project, so the page resets the transposition when the song changes
  - No alert anymore: without a "Lyrics" track the page shows it in its own language
 * v1.6
  + Alert message in English, Portuguese or Spanish (REAPER language pack, then system language)
 * v1.5
  + Publish the computer's LAN IPs (ExtState XR_Lyrics/host_ips) for the page's share QR code
 * v1.4
  # Join JSON entries safely (texts containing ",]" were altered)
 * v1.3
  # Escape backslashes, tabs and other control characters in JSON
 * v1.2
  # Trim spaces/tabs before line breaks and at the end of the text
 * v1.1
  + Use the track named "Lyrics" (any case) with item notes instead of the first selected track
 * v1.0.1 (2023-06-29) - X-Raym
  # encode quotes
 * v1.0 (2022-06-20) - X-Raym
  + Initial Release
--]]

TRACK_NAME = "lyrics" -- compared in lowercase, ignoring leading/trailing spaces
CHECK_EVERY = 1     -- seconds: full re-read, for edits that don't change the project state count
IPS_EVERY = 60      -- seconds: re-detect the network IPs (Wi-Fi changed...)
FADE_FLOOR_DB = -60 -- the fade goes from the master volume down to this, then to silence
FADE_SILENCE = 0.3  -- seconds at volume 0 before stopping: audio already processed ahead plays silent
FADE_RESTORE = 0.5  -- seconds after REAPER has stopped before the volume goes back (audio buffers)
FADE_STOP_TIMEOUT = 3 -- seconds: if REAPER never reports stopped, the volume goes back anyway
FADE_MAX = 30       -- seconds, longest fade accepted from the page

------------------------------------------------------------------
-- Host IP: the web page can't know the computer's LAN IP when it is opened
-- through localhost, so the script finds it and publishes it in
-- ExtState XR_Lyrics/host_ips ("192.168.0.10,172.17.0.1": best first).
------------------------------------------------------------------

local IPV4_PATTERN = "(%d+%.%d+%.%d+%.%d+)"

-- Valid IPv4, excluding loopback (127.x), link-local (169.254.x), 0.0.0.0 and masks (255.x)
function IsUsableIPv4( ip )
  local a, b, c, d = ip:match( "^(%d+)%.(%d+)%.(%d+)%.(%d+)$" )
  if not a then return false end
  a, b, c, d = tonumber( a ), tonumber( b ), tonumber( c ), tonumber( d )
  if a > 255 or b > 255 or c > 255 or d > 255 then return false end
  if a == 0 or a == 127 or a >= 224 or ( a == 169 and b == 254 ) then return false end
  return true
end

-- Lower is better, used only between addresses without a default route
function IPRank( ip )
  local a, b = ip:match( "^(%d+)%.(%d+)%." )
  a, b = tonumber( a ), tonumber( b )
  if ip:match( "^172%.17%.0%.1$" ) then return 5 end              -- Docker bridge
  if a == 192 and b == 168 then return 1 end
  if a == 10 then return 2 end
  if a == 172 and b >= 16 and b <= 31 then return 2 end
  if a == 100 and b >= 64 and b <= 127 then return 6 end          -- CGNAT / Tailscale VPN
  return 4
end

-- Preferred IPs first (the ones with a default route = connected to the router),
-- then the others by IPRank. No duplicates.
function SortIPs( preferred, all )
  local list, seen = {}, {}
  local function add( ip )
    if ip and IsUsableIPv4( ip ) and not seen[ip] then
      seen[ip] = true
      table.insert( list, ip )
    end
  end
  for _, ip in ipairs( preferred ) do add( ip ) end
  local others = {}
  for _, ip in ipairs( all ) do
    if IsUsableIPv4( ip ) and not seen[ip] then table.insert( others, ip ) end
  end
  table.sort( others, function( x, y )
    if IPRank( x ) ~= IPRank( y ) then return IPRank( x ) < IPRank( y ) end
    return x < y
  end )
  for _, ip in ipairs( others ) do add( ip ) end
  return list
end

function AllIPv4( text )
  local t = {}
  for ip in ( text or "" ):gmatch( IPV4_PATTERN ) do table.insert( t, ip ) end
  return t
end

-- Linux: "ip route get 1.1.1.1" (no internet needed, only a default route) + "hostname -I"
function ParseLinux( route_out, hostname_out )
  local preferred = {}
  local src = ( route_out or "" ):match( "src " .. IPV4_PATTERN )
  if src then table.insert( preferred, src ) end
  return SortIPs( preferred, AllIPv4( hostname_out ) )
end

-- macOS: "ipconfig getifaddr <default interface>" + "ifconfig"
function ParseMac( default_if_ip_out, ifconfig_out )
  local preferred = {}
  local ip = ( default_if_ip_out or "" ):match( IPV4_PATTERN )
  if ip then table.insert( preferred, ip ) end
  local all = {}
  for inet in ( ifconfig_out or "" ):gmatch( "inet " .. IPV4_PATTERN ) do table.insert( all, inet ) end
  return SortIPs( preferred, all )
end

-- Windows: "ipconfig". Works in any language: per adapter, the IPv4 is on the line with "IPv4",
-- and any other address that isn't a mask (255.x) is the default gateway.
function ParseWindows( ipconfig_out )
  local preferred, all = {}, {}
  local function close_section( section )
    if not section or #section.ips == 0 then return end
    for _, ip in ipairs( section.ips ) do
      table.insert( section.has_gateway and preferred or all, ip )
    end
  end
  local section
  for line in ( ( ipconfig_out or "" ) .. "\n" ):gmatch( "([^\r\n]*)\r?\n" ) do
    if line:match( "^%S" ) then -- adapter header, e.g. "Wireless LAN adapter Wi-Fi:"
      close_section( section )
      section = { ips = {}, has_gateway = false }
    elseif section then
      local ip = line:match( IPV4_PATTERN )
      if ip and line:find( "IPv4" ) then
        table.insert( section.ips, ip )
      elseif ip and not ip:match( "^255%." ) and not ip:match( "^0%." ) then
        section.has_gateway = true
      end
    end
  end
  close_section( section )
  return SortIPs( preferred, all )
end

-- Runs a command and returns its output ("" on failure)
function Run( cmd )
  if reaper.GetOS():match( "^Win" ) then
    local out = reaper.ExecProcess( cmd, 3000 ) -- no console window flashing, unlike io.popen
    if not out then return "" end
    return ( out:gsub( "^[^\n]*\n", "", 1 ) ) -- first line is the exit code
  end
  local p = io.popen( cmd .. " 2>/dev/null" )
  if not p then return "" end
  local out = p:read( "*a" ) or ""
  p:close()
  return out
end

function GetHostIPs()
  local os_name = reaper.GetOS()
  if os_name:match( "^Win" ) then
    return ParseWindows( Run( "ipconfig" ) )
  elseif os_name:match( "OSX" ) or os_name:match( "macOS" ) then
    local default_if = Run( "route -n get default" ):match( "interface:%s*(%S+)" )
    local default_ip = default_if and Run( "ipconfig getifaddr " .. default_if ) or ""
    return ParseMac( default_ip, Run( "ifconfig" ) )
  else
    local hostname_out = Run( "hostname -I" )
    if hostname_out == "" then hostname_out = Run( "ip -4 -o addr show" ) end
    return ParseLinux( Run( "ip route get 1.1.1.1" ), hostname_out )
  end
end

function HostIPsString()
  local ok, ips = pcall( GetHostIPs )
  return ok and table.concat( ips, "," ) or ""
end

-- Returns a table of {text, pos_start, pos_end} for every item with notes on the track
function GetItemsWithNotes( track )
  local t = {}
  for i = 0, reaper.CountTrackMediaItems( track ) - 1 do
    local item = reaper.GetTrackMediaItem( track, i )
    local retval, item_notes = reaper.GetSetMediaItemInfo_String( item, "P_NOTES", "", false )
    if retval and item_notes ~= "" then
      local item_pos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      local item_len = reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
      table.insert( t, {text = item_notes, pos_start = item_pos, pos_end = item_pos + item_len} )
    end
  end
  return t
end

-- Finds the first track named "Lyrics" (any case) that has at least one item with notes
function FindLyricsTrack( proj )
  for i = 0, reaper.CountTracks( proj ) - 1 do
    local track = reaper.GetTrack( proj, i )
    local _, name = reaper.GetTrackName( track )
    name = name:match( "^%s*(.-)%s*$" ):lower()
    if name == TRACK_NAME then
      local t = GetItemsWithNotes( track )
      if #t > 0 then return track, t end
    end
  end
end

-- JSON string content. \ instead of \\ for backslashes because the web page un-escapes
-- "\n" before "\\", which would break a lyric containing a backslash followed by "n".
function JsonEscape( str )
  return ( str:gsub( "\\", "\\u005c" ) -- must come before the other escapes
              :gsub( '"', '\\"' )
              :gsub( "\t", "\\t" )
              :gsub( "%c", function( c ) return string.format( "\\u%04x", c:byte() ) end ) )
end

-- JSON with the notes of the "Lyrics" track of the project. Without that track, "entry" is empty.
-- "project" identifies the song: its file, or the tab for a project that was never saved.
function BuildJSON( proj, proj_file )
  local _, t = FindLyricsTrack( proj )
  local entries = {}
  for _, v in ipairs( t or {} ) do
    local text = v.text:gsub( "\r", "" )        -- remove carriage returns
                       :gsub( "[ \t]+\n", "\n" ) -- remove spaces/tabs before each line break
                       :gsub( "[ \t]+$", "" )    -- remove spaces/tabs at the end of the text
                       :gsub( "\n", "<br>" )
    table.insert( entries, "\n{\n  \"pos_start\": " .. v.pos_start .. ",\n  \"pos_end\": " .. v.pos_end
      .. ",\n  \"text\": \"" .. JsonEscape( text ) .. "\"\n}" )
  end
  local project = proj_file ~= "" and proj_file or tostring( proj )
  return "{ \"project\": \"" .. JsonEscape( project ) .. "\",\n\"entry\": [" .. table.concat( entries, "," ) .. "]\n}"
end

------------------------------------------------------------------
-- Fade out and stop (asked by the page with ExtState XR_Lyrics/fade_stop = seconds)
-- The fade is even in dB: from the master volume down to FADE_FLOOR_DB.
------------------------------------------------------------------

-- fade.phase: "fade" (volume going down) -> "silence" (volume 0) -> "stopping" (stop asked,
-- volume 0, waiting) -> volume back. Playback stopped by someone else during the fade: "stopping".
local fade = nil

function StartFade( seconds, now )
  local proj = reaper.EnumProjects( -1 )
  if reaper.GetPlayStateEx( proj ) ~= 1 then return end -- only while playing (not paused or recording)
  local master = reaper.GetMasterTrack( proj )
  fade = { proj = proj, master = master, vol = reaper.GetMediaTrackInfo_Value( master, "D_VOL" ),
           phase = "fade", start = now, duration = seconds }
end

function SetMasterVolume( vol )
  reaper.SetMediaTrackInfo_Value( fade.master, "D_VOL", vol )
end

function RestoreVolume()
  SetMasterVolume( fade.vol )
  fade = nil
end

function Silence( now, phase )
  SetMasterVolume( 0 )
  fade.phase, fade.since = phase, now
end

function FadeStep( now )
  local playing = reaper.GetPlayStateEx( fade.proj ) & 1 == 1

  if fade.phase == "fade" or fade.phase == "silence" then
    if not playing then -- stopped meanwhile (Space again)
      Silence( now, "stopping" )
      fade.stopped_at = now
      return
    end
  end

  if fade.phase == "fade" then
    local progress = ( now - fade.start ) / fade.duration
    if progress < 1 then
      SetMasterVolume( fade.vol * 10 ^ ( FADE_FLOOR_DB * progress / 20 ) )
    else
      Silence( now, "silence" )
    end

  elseif fade.phase == "silence" then
    if now - fade.since >= FADE_SILENCE then
      reaper.OnStopButtonEx( fade.proj )
      fade.phase, fade.since = "stopping", now
    end

  elseif fade.phase == "stopping" then
    -- REAPER stops asynchronously: right after OnStopButtonEx it still reports "playing"
    if not playing then
      fade.stopped_at = fade.stopped_at or now
      if now - fade.stopped_at >= FADE_RESTORE then RestoreVolume() end
    elseif fade.stopped_at then
      RestoreVolume() -- it had stopped and is playing again: volume back now
    elseif now - fade.since >= FADE_STOP_TIMEOUT then
      RestoreVolume() -- never stopped: don't leave the master silent
    end
  end
end

function CheckFadeRequest( now )
  local request = reaper.GetExtState( "XR_Lyrics", "fade_stop" )
  if request == "" then return end
  reaper.DeleteExtState( "XR_Lyrics", "fade_stop", false )
  local seconds = tonumber( request )
  if seconds and not fade then StartFade( math.min( math.max( seconds, 0.1 ), FADE_MAX ), now ) end
end

------------------------------------------------------------------
-- Background loop
------------------------------------------------------------------

local last = { json = nil, ips = nil, proj = nil, file = nil, count = nil, check = -math.huge, ips_check = -math.huge }

function Loop()
  local now = reaper.time_precise()
  local changed = false

  CheckFadeRequest( now )
  if fade then FadeStep( now ) end

  if now - last.ips_check >= IPS_EVERY then
    last.ips_check = now
    local ips = HostIPsString()
    if ips ~= last.ips then
      last.ips = ips
      reaper.SetExtState( "XR_Lyrics", "host_ips", ips, false )
      changed = true
    end
  end

  -- Cheap checks on every cycle: active tab and its undo state count
  local proj, proj_file = reaper.EnumProjects( -1 )
  local count = reaper.GetProjectStateChangeCount( proj )
  if proj ~= last.proj or proj_file ~= last.file or count ~= last.count or now - last.check >= CHECK_EVERY then
    last.proj, last.file, last.count, last.check = proj, proj_file, count, now
    local json = BuildJSON( proj, proj_file )
    if json ~= last.json then
      last.json = json
      reaper.SetExtState( "XR_Lyrics", "json", json, false )
      changed = true
    end
  end

  if changed then reaper.SetExtState( "XR_Lyrics", "need_refresh", "true", false ) end
  reaper.defer( Loop )
end

-- Toggle state (toolbar button lit while running)
function SetToggle( state )
  local _, _, section, cmd = reaper.get_action_context()
  if cmd and cmd > 0 then
    reaper.SetToggleCommandState( section, cmd, state )
    reaper.RefreshToolbar2( section, cmd )
  end
end

-- REAPER 7.03+: running the action again stops the script, without asking
if reaper.set_action_options then reaper.set_action_options( 1 ) end
SetToggle( 1 )
reaper.SetExtState( "XR_Lyrics", "running", "1", false )
reaper.DeleteExtState( "XR_Lyrics", "fade_stop", false ) -- an old request must not fade now
reaper.atexit( function()
  if fade then RestoreVolume() end -- script stopped in the middle of a fade: volume back
  reaper.SetExtState( "XR_Lyrics", "running", "0", false )
  SetToggle( 0 )
end )
reaper.defer( Loop )
