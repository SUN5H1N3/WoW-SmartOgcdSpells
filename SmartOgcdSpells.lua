-- SmartOgcdSpells.lua

local addonName = "SmartOgcdSpells"

-- Slash command: /sos generate <OgcdName> <MacrosesPage>
SLASH_SOS1 = "/sos"
SlashCmdList.SOS = function(msg)
    local cmd, ogcdNameInput, page, asGlobalMacro = msg:match("^(%S+)%s+(%S+)%s*(%d+)%s*(%d*)%s*$")
    asGlobalMacro = tonumber(asGlobalMacro) == 1
    if cmd == "generate" and ogcdNameInput and tonumber(page) then
        local ogcdNames = StrSplit(string.gsub(ogcdNameInput, "_", " "), ",")
        GenerateMacroses(ogcdNames, tonumber(page), asGlobalMacro)
        print(addonName..": Done generating macroses for ogcd '".. ogcdNameInput .."' on page ".. page)
    else
        print(addonName.." usage: /sos generate <OgcdName> <MacrosesPage>")
    end
end

-- Generate per-character macros for each spell on action bar slots 1-10
function GenerateMacroses(ogcdNames, macrosesPage, asGlobalMacro)
    local spellsPage = GetActionBarPage() or 1
    local spells = SnapshotSpells(spellsPage)

    if ChangeActionBarPage then
        print(addonName..": switching to page ".. macrosesPage)
        ChangeActionBarPage(macrosesPage)
    end

    CreateMacroses(spells, ogcdNames, spellsPage, macrosesPage, asGlobalMacro)
end

function SnapshotSpells(page)
    local spells = {}
    for i = 1, 12 do
        local actionType, id, _ = GetActionInfo(GetAbsoluteActionIndex(page, i))

        if actionType == "spell" then
            local name = GetSpellInfo(id, BOOKTYPE_SPELL)
            spells[i] = {
                id=id,
                name=name,
            }
            print(string.format("%s: slot %d -> %s", addonName, i, name or "(none)"))
        end
    end
    return spells;
end

function CreateMacroses(spells, ogcdNames, spellsPage, macrosesPage, asGlobalMacro)
    CreateToggleBarMacro(ogcdNames, macrosesPage, spellsPage)
    for i = 1, 12 do
        local spell = spells[i]
        if spell then
            local macroBody = "#showtooltip " .. spell.name
            for _, ogcdName in ipairs(ogcdNames) do
                macroBody = macroBody .. "\n/cast " .. ogcdName
            end
            macroBody = macroBody .. "\n/cast " .. spell.name
            macroBody = macroBody .. "\n/changeactionbar " .. spellsPage

            local macroName = GenerateMacroNamePrefix(ogcdNames) .. spell.id
            UpsertMacro(macroName, macroBody, asGlobalMacro)
            -- place macro on slot i of forPage
            local actionIndex = GetAbsoluteActionIndex(macrosesPage, i)
            PickupMacro(macroName)
            PlaceAction(actionIndex)
            ClearCursor()
            print(string.format("%s: placed '%s' at slot %d", addonName, macroName, actionIndex))
        end
    end
end

function CreateToggleBarMacro(ogcdNames, macrosesPage, spellsPage)
    
    if #ogcdNames == 0 then
        return
    end
    local macroBody = string.format(
        "#showtooltip %s\n/changeactionbar [nomod] %s\n/changeactionbar [mod:ctrl] %s",
        ogcdNames[#ogcdNames],
        macrosesPage,
        spellsPage
    )
    UpsertMacro("Toggle_" .. spellsPage .. "->" .. macrosesPage, macroBody, 0)
end

function UpsertMacro(macroName, macroBody, asGlobalMacro)
    local idx = GetMacroIndexByName(macroName)
    if idx == 0 then
        idx = CreateMacro(macroName, 1, macroBody, ~asGlobalMacro)
        print(addonName..": Created macro "..macroName)
    else
        EditMacro(idx, nil, 1, macroBody, ~asGlobalMacro)
        print(addonName..": Updated macro "..macroName)
    end
end

function GetAbsoluteActionIndex(pageIndex, actionIndexOnPage)
    return (pageIndex - 1) * 12 + actionIndexOnPage
end

function GenerateMacroNamePrefix(ogcdNames)
    local prefix = ""
    for _, ogcdName in ipairs(ogcdNames) do
        prefix = prefix .. ogcdName .. "+"
    end
    return prefix
end

function StrSplit(inputstr, sep)
    if sep == nil then sep = "," end
    local t = {}
    for field in inputstr:gmatch("([^" .. sep .. "]+)") do
        table.insert(t, field)
    end
    return t
end