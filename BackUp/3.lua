-- SmartOgcdSpells.lua

local addonName = "SmartOgcdSpells"

-- Default configuration
SmartOgcdSpells_Config = SmartOgcdSpells_Config or {
    bursts = {
        ["Милость"] = "Милость",
        ["Стылая кровь"] = "Стылая кровь",
    },
    combos = {
        { "Милость", "Стылая кровь" },
    },
}

-- Create secure handler for attribute-driven binding
local handler = CreateFrame("Frame", addonName.."Handler", UIParent, "SecureHandlerStateTemplate")

-- Create hidden secure buttons and register with handler
for i = 1, 10 do
    local btn = CreateFrame("Button", addonName.."Btn"..i, handler, "SecureActionButtonTemplate")
    btn:SetAttribute("type", "macro")
    btn:SetAttribute("macrotext", "")
    btn:Hide()
    handler:SetFrameRef("btn"..i, btn)
end

-- Define secure script for handling attribute change 'burst'
handler:SetAttribute("_onattributechanged-burst", [[
  if name == "burst" then
    local burstVal = value
    for i = 1, 10 do
      local btn = self:GetFrameRef("btn"..i)
      if btn then
        local key = GetBindingKey("ACTIONBUTTON"..i)
        if key then
          local action = ActionButton_GetPagedID(_G["ActionButton"..i])
          local actionType, spellOrId = GetActionInfo(action)
          local spellName = (actionType == "spell") and GetSpellInfo(spellOrId) or spellOrId
          if spellName then
            local text = "/cast "..burstVal.."\n/cast "..spellName
            btn:SetAttribute("macrotext", text)
            SetOverrideBindingClick(self, false, key, btn:GetName())
          end
        end
      end
    end
  end
]])

-- Activation function triggers secure handler via attribute
local function ActivateBurst(name)
    local isValid = SmartOgcdSpells_Config.bursts[name] or false
    if not isValid then
        for _, combo in ipairs(SmartOgcdSpells_Config.combos) do
            if table.concat(combo, "+") == name then isValid = true; break end
        end
    end
    if not isValid then
        print(addonName..": Unknown burst/combo: "..name)
        return
    end
    handler:SetAttribute("burst", name)
    print(addonName..": Activated burst "..name..". Next click will include burst + spell.")
end

-- Slash command handler
SLASH_SOS1 = "/sos"
SlashCmdList.SOS = function(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    if cmd == "burst" and arg ~= "" then
        ActivateBurst(arg)
    elseif cmd == "list" then
        local list = {}
        for k in pairs(SmartOgcdSpells_Config.bursts) do table.insert(list, k) end
        for _, combo in ipairs(SmartOgcdSpells_Config.combos) do table.insert(list, table.concat(combo, "+")) end
        print(addonName..": Available bursts/combo: "..table.concat(list, ", "))
    else
        print(addonName.." usage:")
        print("/sos list - show bursts/combo names")
        print("/sos burst <name> - activate burst for next click")
    end
end
