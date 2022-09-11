local f = CreateFrame("Frame", nil, UIParent)
local events = {}

-- Callback will be called all 40sec.
local interval = 40
-- Default role.
local role = "none"

-- Dungeon IDs
local dungeon_ids = {
  2086, -- Shadowlands (NHC)
  2087, -- Shadowlands (HC)
  744,  -- Burning Crusade (Timewalking)
  995,  -- Wrath of the Lich King (Timewalking)
  1146, -- Cataclysm (Timewalking)
  1453, -- Mists of Pandaria (Timewalking)
  1971, -- Warlords of Draenor (Timewalking)
  2274, -- Legion (Timewalking)
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
  2348  -- The Grand Design (LFR)
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
  earnable_dungeons = {}
  for _, id in pairs(dungeon_ids) do
    eligible, forTank, forHealer,
    forDamage, _, _, _ = GetLFGRoleShortageRewards(id,
                                                   LFG_ROLE_SHORTAGE_RARE)
    if role == "TANK" and forTank then
      enable_glow = true
      table.insert(earnable_dungeons, id)
    elseif role == "HEALER" and forHealer then
      enable_glow = true
      table.insert(earnable_dungeons, id)
    elseif role == "DAMAGER" and forDamage then
      enable_glow = true
      table.insert(earnable_dungeons, id)
    end
  end

  if not table_equal(earnable_dungeons, seen_dungeons) and enable_glow then
    ActionButton_ShowOverlayGlow(LFDMicroButton)
  else
    ActionButton_HideOverlayGlow(LFDMicroButton)
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

--- Handler for ADDON_LOADED event (on login or UI reload).
function events:ADDON_LOADED(name)
  if name ~= "ctan" then return end

  -- Load dungeon information
  dungeon_infos = {}
  for _, id in pairs(dungeon_ids) do
    table.insert(dungeon_infos, id, load_dungeon_info(id))
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
    if role ~= "none" then
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
