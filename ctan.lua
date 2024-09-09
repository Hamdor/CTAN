local f = CreateFrame("Frame", nil, UIParent)
local events = {}

-- Callback will be called all 40sec.
local interval = 40

local role = "none"

local in_group = false

-- Dungeon IDs
local dungeon_ids = {
  -- Dungeons
  2086, -- Shadowlands (NHC)
  2087, -- Shadowlands (HC)
  2350, -- Dragonflight (NHC)
  2351, -- Dragonflight (HC)
  2516, -- The War Within (NHC)
  2517, -- The War Within (HC)
  -- Timewalk
  744,  -- Burning Crusade (Timewalking)
  995,  -- Wrath of the Lich King (Timewalking)
  1146, -- Cataclysm (Timewalking)
  1453, -- Mists of Pandaria (Timewalking)
  1971, -- Warlords of Draenor (Timewalking)
  2274, -- Legion (Timewalking)
  -- LFR
  2337, -- The Leeching Vaults (LFR)
  2338, -- Reliquary of Opulence (LFR)
  2339, -- Blood from Stone (LFR)
  2340, -- An Audience with Arrogance (LFR)
  2341, -- The Jailer's Vanguard (LFR)
  2342, -- The Dark Bastille (LFR)
  2343, -- Shackles of Fate (LFR)
  2344, -- The Reckoning (LFR)
  2345, -- Cornerstone of Creation (LFR)
  2346, -- Ephemeral Plains (LFR)
  2347, -- Domination's Grasp (LFR)
  2348, -- The Grand Design (LFR)
  2370, -- The Primal Bulwark (LFR)
  2371, -- Caverns of Infusion (LFR)
  2372, -- Fury of the Storm (LFR)
  2399, -- Discarded Works (LFR)
  2400, -- Fury of Giants (LFR)
  2401, -- Neltharion's Shadow (LFR)
  2402, -- Edge of the Void (LFR)
  2411, -- The Leeching Vaults (LFR)
  2412, -- Reliquary of Opulence (LFR)
  2413, -- Blood from Stone (LFR)
  2414, -- An Audience with Arrogance (LFR)
  2415, -- The Jailer's Vanguard (LFR)
  2416, -- The Dark Bastille (LFR)
  2417, -- Shackles of Fate (LFR)
  2418, -- The Reckoning (LFR)
  2419, -- Cornerstone of Creation (LFR)
  2420, -- Ephemeral Plains (LFR)
  2421, -- Domination's Grasp (LFR)
  2422, -- The Grand Design (LFR)
}

local dungeon_infos = {}

local function load_dungeon_info(id)
  name, typeid, _, _, _, _, _, _, _, _, _, _,
  _, _, _, _, _, timewalk, _, _, _, _ = GetLFGDungeonInfo(id)
  dungeon_info = {name = name, typeid = typeid, timewalk = timewalk}
  return dungeon_info
end

local earnable_dungeons = {}
local seen_dungeons = {}

-- Checks if two tables are equal
local function table_equal(a, b)
  return table.concat(a) == table.concat(b)
end

-- Timer callback function, checks whether there is a bonus or not.
local function tick()
  local enable_glow = false
  local current_dungeons = {}
  earnable_dungeons = {}
  for i = 1, #dungeon_ids do
    eligible, forTank, forHealer,
    forDamage, _, _, _ = GetLFGRoleShortageRewards(dungeon_ids[i],
                                                   LFG_ROLE_SHORTAGE_RARE)
    if (role == "TANK" and forTank)      or
       (role == "HEALER" and forHealer)  or
       (role == "DAMAGER" and forDamage) then
      enable_glow = true
      table.insert(current_dungeons, i)
    end
  end

  if not in_group then
    if not table_equal(current_dungeons, seen_dungeons) and enable_glow then
      ActionButton_ShowOverlayGlow(LFDMicroButton)
    else
      ActionButton_HideOverlayGlow(LFDMicroButton)
    end
    earnable_dungeons = current_dungeons
  end
  C_Timer.After(interval, tick)
end

-- Handler for PLAYER_SPECIALIZATION_CHANGED event.
function events:PLAYER_SPECIALIZATION_CHANGED(...)
  local spec = GetSpecialization()
  local _, _, _, _, r, _ = GetSpecializationInfo(spec)
  role = r
end

-- Handler for PLAYER_ENTERING_WORLD event.
function events:PLAYER_ENTERING_WORLD(...)
  -- Call PLAYER_SPECIALIZATION_CHANGED to get current spec.
  events:PLAYER_SPECIALIZATION_CHANGED()
end

-- Handler for group changes (e.g. joining, leaving, ...)
function events:GROUP_ROSTER_UPDATE(...)
  local auto_group = GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE) > 0
  local currently_in_group = GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) > 0
  if not in_group and currently_in_group then
    print("ctan disabled, you joined a (manual) group.")
    in_group = true
  elseif not currently_in_group then
    if not auto_group then
      print("ctan enabled, you leaved a (manual) group.")
    end
      in_group = false
  end
end

--- Handler for ADDON_LOADED event (on login or UI reload).
function events:ADDON_LOADED(name)
  if name ~= "ctan" then return end

  -- Load dungeon information
  dungeon_infos = {}
  for i = 1, #dungeon_ids do
    table.insert(dungeon_infos, i, load_dungeon_info(dungeon_ids[i]))
  end

  in_group = GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) > 0
  if in_group then
    print("ctan disabled, you are in a (manual) group.")
  end

  -- Register function for tooltip show
  LFDMicroButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(LFDMicroButton, "ANCHOR_BOTTOM")
    for i = 1, #earnable_dungeons do
      GameTooltip:AddLine(dungeon_infos[earnable_dungeons[i]].name)
    end
    GameTooltip:Show()
  end)

  -- Register function for tooltip hide
  LFDMicroButton:SetScript("OnLeave", function()
    seen_dungeons = earnable_dungeons
    ActionButton_HideOverlayGlow(LFDMicroButton)
    GameTooltip:Hide()
  end)

  -- Start the timer.
  C_Timer.After(5, tick)
end

f:SetScript("OnEvent", function(self, event, ...)
  events[event](self, ...)
end);

for k, v in pairs(events) do
  f:RegisterEvent(k)
end

--- Handle console commands.
local function CommandHandler(msg, editbox)
  local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
  if cmd == "status" then
    if not in_group and role ~= "none" then
      print("ctan is listening to lfg tool ("..role..").")
    else
      print("ctan is not listening to lfg tool.")
    end
  else
    print("Syntax: /ctan status");
  end
end
SLASH_CTAN1 = '/ctan'
SlashCmdList["CTAN"] = CommandHandler

f:Show()
