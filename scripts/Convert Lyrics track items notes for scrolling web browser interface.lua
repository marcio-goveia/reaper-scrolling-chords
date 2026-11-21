--[[
 * ReaScript Name: Convert Lyrics track items notes for scrolling web browser interface
 * About: Use with the X-Raym_Scrolling Lyrics.html web interface.
 *        Looks for a track named "Lyrics" (case-insensitive) that has items with notes,
 *        instead of using the first selected track.
 * Based on: X-Raym_Convert first selected track items notes for scrolling web browser interface.lua (v1.0.1)
 * Original Author: X-Raym
 * Original Repository URI: https://github.com/X-Raym/REAPER-ReaScripts
 * Licence: GPL v3
 * REAPER: 5.0
 * Version: 1.6
--]]

--[[
 * Changelog:
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

------------------------------------------------------------------
-- Messages in English, Portuguese and Spanish
------------------------------------------------------------------

MESSAGES = {
  en = { no_track = 'No track named "Lyrics" with items with notes was found.' },
  pt = { no_track = 'Nenhuma track chamada "Lyrics" com itens com notas foi encontrada.' },
  es = { no_track = 'No se encontró ninguna pista llamada "Lyrics" con ítems con notas.' },
}

-- "pt_BR.UTF-8", "Portuguese_Brazil.1252", "Español.ReaperLangPack"... -> "pt" / "es" / nil
function LangFromName( name )
  name = ( name or "" ):lower()
  if name:match( "^pt" ) or name:find( "portug" ) then return "pt" end
  if name:match( "^es" ) or name:find( "spanish" ) or name:find( "espa" ) then return "es" end
  if name:match( "^en" ) or name:find( "english" ) then return "en" end
  return nil
end

function DetectLang()
  -- 1. REAPER language pack (Options > Preferences > General > Language)
  local ini = io.open( reaper.get_ini_file(), "r" )
  if ini then
    local content = ini:read( "*a" ) or ""
    ini:close()
    local lang = LangFromName( content:match( "\nlangpack=([^\r\n]*)" ) )
    if lang then return lang end
  end
  -- 2. System language: environment (Linux, macOS)...
  for _, var in ipairs( { "LC_ALL", "LC_MESSAGES", "LANG" } ) do
    local lang = LangFromName( os.getenv( var ) )
    if lang then return lang end
  end
  -- ... or the system locale (Windows). The locale is restored right away: with a
  -- Portuguese/Spanish locale, numbers would be written as "1,5" and break the JSON.
  local current = os.setlocale( nil )
  local system = os.setlocale( "" )
  os.setlocale( current )
  return LangFromName( system ) or "en"
end

function Msg( key )
  local lang = DetectLang()
  return ( MESSAGES[lang] or MESSAGES.en )[key] or MESSAGES.en[key]
end

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

function PublishHostIPs()
  local ok, ips = pcall( GetHostIPs )
  reaper.SetExtState( "XR_Lyrics", "host_ips", ok and table.concat( ips, "," ) or "", false )
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
function FindLyricsTrack()
  for i = 0, reaper.CountTracks( 0 ) - 1 do
    local track = reaper.GetTrack( 0, i )
    local _, name = reaper.GetTrackName( track )
    name = name:match( "^%s*(.-)%s*$" ):lower()
    if name == TRACK_NAME then
      local t = GetItemsWithNotes( track )
      if #t > 0 then return track, t end
    end
  end
end

function Main()

    PublishHostIPs() -- even without lyrics, so the page can already be shared

    local track, t = FindLyricsTrack()
    if not track then
      reaper.MB( Msg( "no_track" ), "Scrolling Lyrics", 0 )
      return
    end

    entries = {}
    for i, v in ipairs( t ) do
      local text = v.text:gsub("\r", "")      -- remove carriage returns
                         :gsub("[ \t]+\n", "\n") -- remove spaces/tabs before each line break
                         :gsub("[ \t]+$", "")    -- remove spaces/tabs at the end of the text
                         -- escape backslashes (must come before the other escapes).
                         -- \u005c instead of \\ because the web page un-escapes "\n" before "\\",
                         -- which would break a lyric containing a backslash followed by "n".
                         :gsub("\\", "\\u005c")
                         :gsub('"', '\\"')       -- escape quotes
                         :gsub("\n", "<br>")
                         :gsub("\t", "\\t")      -- escape tabs
                         :gsub("%c", function( c ) -- escape any other control character
                           return string.format( "\\u%04x", c:byte() )
                         end)
      local line = "\n{\n  \"pos_start\": " .. v.pos_start .. ",\n  \"pos_end\": " .. v.pos_end  .. ",\n  \"text\": \"" .. text .. "\"\n}"
      table.insert( entries, line )
    end

    json = "{ \"entry\": [" .. table.concat( entries, "," ) .. "]\n}"
    reaper.ClearConsole()
    --reaper.ShowConsoleMsg( json )
    -- reaper.CF_SetClipboard( json )
    reaper.SetExtState( "XR_Lyrics", "json", json, false )
    reaper.SetExtState( "XR_Lyrics", "need_refresh", "true", false )
end

reaper.defer(Main)
