-- SmartOgcdSpells.lua

local addonName = "SmartOgcdSpells"

-- Default configuration
SmartOgcdSpells_Config = SmartOgcdSpells_Config or {
    bursts = {"Милость", "Стылая кровь"},
    spells = {56, 48, 79, 55, 6, 13, 11, 81, 42},  -- IDs of your GCD spells
}

-- Create or update burst macros on login or via /sos recreate
local function CreateBurstMacros()
    for _, b in ipairs(SmartOgcdSpells_Config.bursts) do
        for _, spellId in ipairs(SmartOgcdSpells_Config.spells) do
            local spellName = GetSpellInfo(spellId)
            if spellName then
                local macroName = b.."-"..spellName
                local macroBody = string.format("/cast %s\n/cast %s", b, spellName)
                local idx = GetMacroIndexByName(macroName)
                if idx == 0 then
                    CreateMacro(macroName, "INV_MISC_QUESTIONMARK", macroBody)
                else
                    EditMacro(idx, nil, nil, macroBody)
                end
            end
        end
    end
    print(addonName..": Burst macros created/updated. Place them on your action bars.")
end

-- Slash command handler
SLASH_SOS1 = "/sos"
SlashCmdList.SOS = function(msg)
    if msg == "list" then
        print(addonName..": Bursts: "..table.concat(SmartOgcdSpells_Config.bursts, ", "))
    elseif msg == "recreate" then
        CreateBurstMacros()
    else
        print(addonName.." usage:")
        print("/sos list - list available bursts")
        print("/sos recreate - recreate burst macros")
    end
end

-- Event frame
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event)
    CreateBurstMacros()
end)
