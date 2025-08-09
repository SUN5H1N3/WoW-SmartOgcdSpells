-- SmartOgcdSpells.lua

local addonName = "SmartOgcdSpells"

-- Slash command: /sos generate <burstName> <forPage>
SLASH_SOS1 = "/sos"
SlashCmdList.SOS = function(msg)
    local cmd, burstName, page = msg:match("^(%S+)%s+(%S+)%s*(%d+)%s*$")
    if cmd == "generate" and burstName and tonumber(page) then
        GenerateMacroses(burstName, tonumber(page))
    else
        print(addonName.." usage: /sos generate <BurstName> <PageNumber>")
    end
end

-- Helper to locate action button (standard and ElvUI)
local function GetActionButton(i)
    return _G["ActionButton"..i] or _G["ElvUI_ActionButton"..i] or _G["ElvUI_Bar1Button"..i]
end

-- Generate per-character macros for each spell on action bar slots 1-10
function GenerateMacroses(burstName, forPage)
    print(addonName..": GenerateMacros called with burst='"..burstName.."', page="..forPage)

    -- remember current page
    local currentPage = GetActionBarPage() or 1

    -- gather spells from visible buttons 1-10
    local spells = {}
    -- 1. Получаем саму кнопку (например, первую на текущей странице)
    local btn = _G["ActionButton1"]

    -- 2. Вычисляем её глобальный номер слота
    --    (этот хелпер учитывает текущую страницу панели)
    local slot = ActionButton_GetPagedID(btn)

    -- 3. Спрашиваем API, что там стоит
    local actionType, id, subType = GetActionInfo(slot)
    -- actionType может быть: "spell", "item", "macro", "companion" и т.д.
    -- id — для типа "spell" это spellID, для "item" — itemID и т.п.
    print("slot: "..slot)
    print("actionType: "..actionType)
    print("id: "..id)
    print("subType: "..subType)
    --local info = GetSpellBookItemInfo(id, BOOKTYPE_SPELL)
    --print("spellID:", info.spellID)
    local spellName  = GetSpellBookItemName(id, BOOKTYPE_SPELL)
    print("spellName : ", spellName )
    -- 4. Если это заклинание, получаем его имя и другие данные
    if actionType == "spell" then
        local name, rank, icon, castTime, minRange, maxRange = GetSpellInfo(id)
        print("В слоте", slot, "способность:", name, "(ранг:", rank, ")")
    else
        print("В слоте", slot, "не заклинка, а:", actionType, id)
    end
    for i = 1, 10 do
        local btn = GetActionButton(i)
        local name = nil
        if btn and btn.GetAttribute then
            local actionId = btn:GetAttribute("action")
            if actionId then
                local actionType, id = GetActionInfo(actionId)
                if actionType == "spell" then
                    name = GetSpellInfo(id)
                end
            end
        end
        spells[i] = name
        print(string.format("%s: slot %d -> %s", addonName, i, name or "(none)"))
    end

    -- switch to target page for placement
    if ChangeActionBarPage then
        print(addonName..": switching to page "..forPage)
        ChangeActionBarPage(forPage)
    end

    -- create/update and place macros
    for i = 1, 10 do
        local spellName = spells[i]
        if spellName then
            local safeName = spellName:gsub("%s+", "")
            local macroName = string.format("%s_%s", burstName, safeName)
            local macroBody = string.format("/cast %s\n/cast %s", burstName, spellName)
            local idx = GetMacroIndexByName(macroName)
            if idx == 0 then
                idx = CreateMacro(macroName, 1, macroBody, true)
                print(addonName..": Created macro "..macroName)
            else
                EditMacro(idx, nil, 1, macroBody, true)
                print(addonName..": Updated macro "..macroName)
            end
            -- place macro on slot i of forPage
            local actionSlot = (forPage - 1) * 12 + i
            PickupMacro(macroName)
            PlaceAction(actionSlot)
            ClearCursor()
            print(string.format("%s: placed '%s' at slot %d", addonName, macroName, actionSlot))
        end
    end

    -- revert to original page
    if ChangeActionBarPage then
        print(addonName..": reverting to page "..currentPage)
        ChangeActionBarPage(currentPage)
    end
    print(addonName..": Done generating macros for burst '"..burstName.."' on page "..forPage)
end

-- Создаём (или переиспользуем) невидимый тултип
local scanTT = CreateFrame("GameTooltip", "MyActionScanTooltip", nil, "GameTooltipTemplate")
scanTT:SetOwner(UIParent, "ANCHOR_NONE")

-- Функция для сканирования action-бара
local function ScanActionBar()
    for i = 1, 12 do
        local btn = _G["ActionButton"..i]
        if not btn then break end
        -- 1) Узнаём глобальный слот с учётом текущей страницы
        local slot = ActionButton_GetPagedID(btn)
        -- 2) Очищаем тултип и ставим на слот
        scanTT:ClearLines()
        scanTT:SetAction(slot)
        -- 3) Сразу вызываем GetSpell: он вернёт name, rank, trueSpellID
        local name, rank, trueID = scanTT:GetSpell()
        if trueID then
            print(i, btn:GetName(), "slot", slot, "→", name, "(ID", trueID,")")
        else
            -- если не заклинание, можно проверить item или макрос через GetActionInfo
            local t, id = GetActionInfo(slot)
            print(i, btn:GetName(), "slot", slot, "→", t, id)
        end
    end
    scanTT:Hide()
end

-- Делаем из этого Slash-команду, чтобы вызывалось хоть из чата, хоть из макроса:
SLASH_SCANAB1 = "/scanab"
SlashCmdList["SCANAB"] = ScanActionBar

-- и автоматически вызываем после лога:
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", ScanActionBar)