local f = CreateFrame("Frame", nil, UIParent)
local events = {}

-- Callback will be called all 40sec.
local interval = 40
-- Default role.
local role = "none"
-- ID for Random Heroic (Shadowlands)
local dungeon_id = 2087

-- Timer callback function, checks whether there is a bonus or not.
local function tick()
  eligible, forTank, forHealer,
  forDamage, _, _, _ = GetLFGRoleShortageRewards(dungeon_id,
                                                 LFG_ROLE_SHORTAGE_RARE)
  if role == "TANK" and forTank then
    ActionButton_ShowOverlayGlow(LFDMicroButton)
  elseif role == "HEALER" and forHealer then
    ActionButton_ShowOverlayGlow(LFDMicroButton)
  elseif role == "DAMAGER" and forDamage then
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
