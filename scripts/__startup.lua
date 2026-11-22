--[[
 * REAPER runs Scripts/__startup.lua every time it starts.
 * This one starts the Scrolling Chords background script, so the web page always has
 * the lyrics of the active project tab.
 *
 * Install: put this file in the REAPER Scripts folder (Options > Show REAPER resource path).
 * If you already have a __startup.lua, paste this code at the end of it instead.
 * The background script must already be loaded in the action list
 * (Actions > Show action list > New action > Load ReaScript...).
--]]

do
  local SCRIPT_NAME = "Convert Lyrics track items notes for scrolling web browser interface.lua"

  -- The action list (reaper-kb.ini) has a line like:
  -- SCR 4 0 RSa9e8...f89f "Custom: <name>" "Custom/<name>"
  local function FindCommand()
    local kb = io.open( reaper.GetResourcePath() .. "/reaper-kb.ini", "r" )
    if not kb then return 0 end
    for line in kb:lines() do
      local id, path = line:match( '^SCR %d+ 0 (%S+) ".-" "(.-)"' )
      if id and ( path == SCRIPT_NAME or path:sub( -#SCRIPT_NAME - 1 ):match( "^[/\\]" ) and path:sub( -#SCRIPT_NAME ) == SCRIPT_NAME ) then
        kb:close()
        return reaper.NamedCommandLookup( "_" .. id )
      end
    end
    kb:close()
    return 0
  end

  local cmd = FindCommand()
  if cmd ~= 0 then
    reaper.Main_OnCommand( cmd, 0 )
  else
    reaper.ShowConsoleMsg( "__startup.lua: load \"" .. SCRIPT_NAME .. "\" in the action list first.\n" )
  end
end
