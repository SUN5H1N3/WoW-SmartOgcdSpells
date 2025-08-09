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
    keys = {
        "ACTIONBUTTON1", "ACTIONBUTTON2", "ACTIONBUTTON3", "ACTIONBUTTON4", "ACTIONBUTTON5",
        "ACTIONBUTTON6", "ACTIONBUTTON7", "ACTIONBUTTON8", "ACTIONBUTTON9", "ACTIONBUTTON10",
    },
}

-- Aggregate override frame
local holder = UIParent

-- Create hidden secure buttons and set PostClick handlers
local secureButtons = {}
for i = 1, #SmartOgcdSpells_Config.keys do
    local btn = CreateFrame("Button", addonName.."Btn"..i, holder, "SecureActionButtonTemplate")
    btn:SetAttribute("type", "macro")
    -- compatibility: init both macrotext attributes for WoW 3.3.5
    btn:SetAttribute("macrotext", "")
    btn:SetAttribute("macrotext1", "")
    btn:Hide()
    secureButtons[i] = btn
    btn:SetScript("PostClick", function(self)
        print("SmartOgcdSpells: Hidden button clicked, clearing overrides...")
        ClearOverrideBindings(holder)
    end)
end

-- Activate burst or combo
local function ActivateBurst(name)
    local keysList = {}
    if SmartOgcdSpells_Config.bursts[name] then
        keysList = { SmartOgcdSpells_Config.bursts[name] }
    else
        for _, combo in ipairs(SmartOgcdSpells_Config.combos) do
            if table.concat(combo, "+") == name then keysList = combo; break end
        end
    end
    if #keysList == 0 then
        print(addonName..": Unknown burst/combo: "..name)
        return
    end

    -- Iterate hidden buttons corresponding to action slots
    for i, btn in ipairs(secureButtons) do
        local actionButtonName = "ACTIONBUTTON"..i
        local bindingKey = GetBindingKey(actionButtonName)
        if not bindingKey then
            print(string.format("SmartOgcdSpells: No key bound to %s, skipping.", actionButtonName))
        else
            local action = ActionButton_GetPagedID(_G["ActionButton"..i])
            local _, spell = GetActionInfo(action)
            if spell then
                -- Build macro text
                local macroText = ""
                for _, b in ipairs(keysList) do
                    macroText = macroText .. "/cast "..b.."\n"
                end
                macroText = macroText .. "/cast "..spell
                -- Apply override
                btn:SetAttribute("macrotext", macroText)
                -- compatibility: also set macrotext1 on older clients
                btn:SetAttribute("macrotext1", macroText)
                SetOverrideBindingClick(holder, false, bindingKey, btn:GetName())
                print(string.format("SmartOgcdSpells: Bound %s -> %s (burst: %s, spell: %s)", bindingKey, btn:GetName(), table.concat(keysList, "+"), spell))
            else
                print(string.format("SmartOgcdSpells: No spell on ActionButton%d, skipping.", i))
            end
        end
    end
    print(addonName..": Activated burst "..name..". Next GCD-click will include burst.")
end

-- Build list of available bursts/combos
local function BuildList()
    local list = {}
    for name in pairs(SmartOgcdSpells_Config.bursts) do list[#list+1] = name end
    for _, combo in ipairs(SmartOgcdSpells_Config.combos) do
        list[#list+1] = table.concat(combo, "+")
    end
    return table.concat(list, ", ")
end

-- Slash command handler
SLASH_SOS1 = "/sos"
SlashCmdList.SOS = function(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    if cmd == "burst" and arg ~= "" then
        ActivateBurst(arg)
    elseif cmd == "list" then
        print(addonName..": Available bursts/combo: "..BuildList())
    else
        print(addonName.." usage:")
        print("/sos list - show bursts/combo names")
        print("/sos burst <name> - activate burst for next click")
    end
end
