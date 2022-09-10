local f = CreateFrame("Frame", nil, UIParent)
local events = {}

-- Callback will be called all 40sec.
local interval = 40
-- Default role.
local role = "none"

-- Dungeon IDs
local dungeon_ids = {}
dungeon_ids["Shadowlands (NHC)"] = 2086
dungeon_ids["Shadowlands (HC)"] = 2087
dungeon_ids["Burning Crusade (Timewalking)"] = 744
dungeon_ids["Wrath of the Lich King (Timewalking)"] = 995
dungeon_ids["Cataclysm (Timewalking)"] = 1146
dungeon_ids["Mists of Pandaria (Timewalking)"] = 1453
dungeon_ids["Warlords of Draenor (Timewalking)"] = 1971
dungeon_ids["Legion (Timewalking)"] = 2274

-- Raid IDs
dungeon_ids["The Leeching Vaults (LFR)"] = 2337
dungeon_ids["Reliquary of Opulence (LFR)"] = 2338
dungeon_ids["Blood from Stone (LFR)"] = 2339
dungeon_ids["An Audience with Arrogance (LFR)"] = 2340
--
dungeon_ids["The Jailer's Vanguard (LFR)"] = 2341
dungeon_ids["The Dark Bastille (LFR)"] = 2342
dungeon_ids["Shackles of Fate (LFR)"] = 2343
dungeon_ids["The Reckoning (LFR)"] = 2344
--
dungeon_ids["Cornerstone of Creation (LFR)"] = 2345
dungeon_ids["Ephemeral Plains (LFR)"] = 2346
dungeon_ids["Domination's Grasp (LFR)"] = 2347
dungeon_ids["The Grand Design (LFR)"] = 2348

local earnable_dungeons = {}

-- Timer callback function, checks whether there is a bonus or not.
local function tick()
  local enable_glow = false
  earnable_dungeons = {}
  for key, id in pairs(dungeon_ids) do
    eligible, forTank, forHealer,
    forDamage, _, _, _ = GetLFGRoleShortageRewards(id,
                                                   LFG_ROLE_SHORTAGE_RARE)
    if role == "TANK" and forTank then
      enable_glow = true
      table.insert(earnable_dungeons, key)
    elseif role == "HEALER" and forHealer then
      enable_glow = true
      table.insert(earnable_dungeons, key)
    elseif role == "DAMAGER" and forDamage then
      enable_glow = true
      table.insert(earnable_dungeons, key)
    end
  end
  if enable_glow then
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

  -- Register function for tooltip show
  LFDMicroButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(LFDMicroButton, "ANCHOR_BOTTOM")
    for idx, dungeon_str in pairs(earnable_dungeons) do
      GameTooltip:AddLine(dungeon_str)
    end
    GameTooltip:Show()
  end)

  -- Register function for tooltip hide
  LFDMicroButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  -- Start the timer.
  C_Timer.After(interval, tick)
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
