local PA_UI_ITEM_HEIGHT = 24
local PA_UI_MAX_VISIBLE = 15
local PA_DROPDOWN_MAX = 8
local PA_DROPDOWN_HEIGHT = 22
local selectedItemIndex = nil
local itemButtonsCreated = false
local dropdownCreated = false
local knownItems = {}
local knownItemsBuilt = false

function PoweredAuction_SetButtonFont(buttonName, text)
    local button = getglobal(buttonName)
    if not button then return end
    local fs = button:CreateFontString(buttonName .. "Text", "ARTWORK", "GameFontHighlight")
    fs:SetPoint("CENTER", button, "CENTER", 0, 0)
    fs:SetText(text)
    button.fontText = fs
end

function PoweredAuction_SetButtonText(buttonName, text)
    local button = getglobal(buttonName)
    if button and button.fontText then
        button.fontText:SetText(text)
    end
end

function PoweredAuction_OnEvent(event)
    if event == "VARIABLES_LOADED" then
        PoweredAuction_InitDB()
        PoweredAuction_CreateItemButtons()
        PoweredAuction_CreateDropdown()
        PoweredAuction_SetButtonFont("PoweredAuctionFrameAddButton", "Add")
        PoweredAuction_SetButtonFont("PoweredAuctionFrameScanButton", "Scan")
        PoweredAuction_SetButtonFont("PoweredAuctionFrameRemoveButton", "Remove")
        PoweredAuction_Print("Loaded v" .. PoweredAuction.version .. ". Type /pa for help.")
    elseif event == "AUCTION_HOUSE_SHOW" then
        PoweredAuction_AHOpened()
    elseif event == "AUCTION_HOUSE_CLOSED" then
        PoweredAuction_AHClosed()
    elseif event == "AUCTION_ITEM_LIST_UPDATE" then
        PoweredAuction_OnAuctionItemListUpdate()
    end
end

function PoweredAuction_ToggleUI(show)
    if show == nil then
        show = not PoweredAuctionFrame:IsVisible()
    end
    if show then
        PoweredAuctionFrame:Show()
    else
        PoweredAuctionFrame:Hide()
    end
end

function PoweredAuction_RebuildKnownItems()
    knownItems = {}
    local seen = {}
    if PoweredAuctionDB.scanHistory then
        for key, data in pairs(PoweredAuctionDB.scanHistory) do
            if data.name and not seen[string.lower(data.name)] then
                table.insert(knownItems, data.name)
                seen[string.lower(data.name)] = true
            end
        end
    end
    knownItemsBuilt = true
end

function PoweredAuction_OnInputTextChanged()
    local input = getglobal("PoweredAuctionFrameItemInput")
    if not input then return end
    local text = PoweredAuction_Trim(input:GetText() or "")
    if text == "" or string.len(text) < 2 then
        PoweredAuction_HideDropdown()
        return
    end
    if not knownItemsBuilt then
        PoweredAuction_RebuildKnownItems()
    end
    local lowerText = string.lower(text)
    local matches = {}
    for _, name in ipairs(knownItems) do
        if string.find(string.lower(name), lowerText, 1, true) then
            table.insert(matches, name)
            if table.getn(matches) >= PA_DROPDOWN_MAX then
                break
            end
        end
    end
    if table.getn(matches) == 0 then
        PoweredAuction_HideDropdown()
        return
    end
    PoweredAuction_ShowDropdown(matches)
end

function PoweredAuction_CreateDropdown()
    if dropdownCreated then return end

    local dropdown = CreateFrame("Frame", "PoweredAuctionDropdown", PoweredAuctionFrame)
    dropdown:SetWidth(300)
    dropdown:SetHeight(PA_DROPDOWN_MAX * PA_DROPDOWN_HEIGHT + 4)
    dropdown:SetPoint("TOPLEFT", "PoweredAuctionFrameItemInput", "BOTTOMLEFT", 0, -2)
    dropdown:SetFrameStrata("TOOLTIP")
    dropdown:EnableMouse(true)
    dropdown:Hide()
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = true, tileSize = 32, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    dropdown:SetBackdropColor(0.09, 0.09, 0.09, 0.97)
    dropdown:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    for i = 1, PA_DROPDOWN_MAX do
        local btn = CreateFrame("Button", "PoweredAuctionDropdownButton" .. i, dropdown)
        btn:SetWidth(294)
        btn:SetHeight(PA_DROPDOWN_HEIGHT)
        btn:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 3, -2 - (i - 1) * PA_DROPDOWN_HEIGHT)

        local btnBg = btn:CreateTexture(nil, "BACKGROUND")
        btnBg:SetTexture("Interface\\Buttons\\WHITE8X8")
        btnBg:SetAllPoints(btn)
        btnBg:SetVertexColor(0.12, 0.12, 0.12, 1)
        btn.bg = btnBg

        local btnHighlight = btn:CreateTexture(nil, "HIGHLIGHT")
        btnHighlight:SetTexture("Interface\\Buttons\\WHITE8X8")
        btnHighlight:SetAllPoints(btn)
        btnHighlight:SetVertexColor(0.2, 0.35, 0.55, 0.6)

        local btnText = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        btnText:SetJustifyH("LEFT")
        btnText:SetPoint("LEFT", btn, "LEFT", 6, 0)
        btnText:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
        btnText:SetTextColor(0.84, 0.88, 0.83, 1)

        btn:SetScript("OnClick", function()
            local itemName = this.itemName
            if itemName then
                getglobal("PoweredAuctionFrameItemInput"):SetText("")
                PoweredAuction_HideDropdown()
                PoweredAuction_AddToWatchList(itemName)
            end
        end)

        btn:SetScript("OnEnter", function()
            this.bg:SetVertexColor(0.18, 0.28, 0.42, 1)
            for _, r in pairs({ this:GetRegions() }) do
                if r:IsObjectType("FontString") then
                    r:SetTextColor(1, 0.85, 0, 1)
                    break
                end
            end
        end)

        btn:SetScript("OnLeave", function()
            this.bg:SetVertexColor(0.12, 0.12, 0.12, 1)
            for _, r in pairs({ this:GetRegions() }) do
                if r:IsObjectType("FontString") then
                    r:SetTextColor(0.84, 0.88, 0.83, 1)
                    break
                end
            end
        end)
    end

    dropdownCreated = true
end

function PoweredAuction_ShowDropdown(matches)
    local dropdown = getglobal("PoweredAuctionDropdown")
    if not dropdown then return end
    local numMatches = table.getn(matches)
    dropdown:SetHeight(numMatches * PA_DROPDOWN_HEIGHT + 4)
    for i = 1, PA_DROPDOWN_MAX do
        local btn = getglobal("PoweredAuctionDropdownButton" .. i)
        if not btn then break end
        if i <= numMatches then
            btn.itemName = matches[i]
            for _, r in pairs({ btn:GetRegions() }) do
                if r:IsObjectType("FontString") then
                    r:SetText(matches[i])
                    r:SetTextColor(0.84, 0.88, 0.83, 1)
                    break
                end
            end
            btn:Show()
        else
            btn.itemName = nil
            btn:Hide()
        end
    end
    dropdown:Show()
end

function PoweredAuction_HideDropdown()
    local dropdown = getglobal("PoweredAuctionDropdown")
    if dropdown then
        dropdown:Hide()
    end
end

function PoweredAuction_UIAddItem()
    PoweredAuction_HideDropdown()
    local input = getglobal("PoweredAuctionFrameItemInput")
    local text = input:GetText()
    if text and text ~= "" then
        local extractedName = PoweredAuction_ExtractItemName(text)
        if extractedName then
            text = extractedName
        end
        PoweredAuction_AddToWatchList(text)
        input:SetText("")
        input:SetFocus()
    end
end

function PoweredAuction_OnReceiveDrag()
    local name = PoweredAuction_GetLastDraggedItem()
    if name then
        getglobal("PoweredAuctionFrameItemInput"):SetText(name)
    end
end

function PoweredAuction_UIRemoveSelected()
    if selectedItemIndex then
        PoweredAuction_RemoveFromWatchListByIndex(selectedItemIndex)
        selectedItemIndex = nil
    else
        PoweredAuction_PrintError("No item selected.")
    end
end

local function GetMoneyString(copper)
    if not copper or copper == 0 then return "|cFF93978B---|r" end
    local gold = math.floor(copper / 10000)
    local silver = math.floor(math.mod(copper, 10000) / 100)
    local remaining = math.mod(copper, 100)
    local result = ""
    if gold > 0 then
        result = result .. "|cFFFFFF00" .. gold .. "g|r "
    end
    if silver > 0 or gold > 0 then
        result = result .. "|cFFC0C0C0" .. silver .. "s|r "
    end
    result = result .. "|cFFEDA55F" .. remaining .. "c|r"
    return result
end

local function GetLastScanData(itemName)
    if not itemName then return nil, 0 end
    local key = string.lower(itemName)
    if not PoweredAuctionDB.scanHistory or not PoweredAuctionDB.scanHistory[key] then
        return nil, 0
    end
    local history = PoweredAuctionDB.scanHistory[key]
    local scanCount = table.getn(history.scans or {})
    if scanCount == 0 then return nil, 0 end
    local lastScan = history.scans[scanCount]
    return lastScan, scanCount
end

function PoweredAuction_CreateItemButtons()
    if itemButtonsCreated then return end
    local itemFrame = getglobal("PoweredAuctionFrameItemList")
    if not itemFrame then return end

    for i = 1, PA_UI_MAX_VISIBLE do
        local button = CreateFrame("Button", "PoweredAuctionItemButton" .. i, itemFrame)
        button:SetHeight(PA_UI_ITEM_HEIGHT)
        button:SetWidth(470)
        button:SetPoint("TOPLEFT", itemFrame, "TOPLEFT", 0, -(i - 1) * PA_UI_ITEM_HEIGHT)

        local bg = button:CreateTexture("PoweredAuctionItemButton" .. i .. "Bg", "BACKGROUND")
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetAllPoints(button)
        bg:SetVertexColor(0.16, 0.16, 0.16, 1)

        local highlightTexture = button:CreateTexture("PoweredAuctionItemButton" .. i .. "Highlight")
        highlightTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
        highlightTexture:SetAllPoints(button)
        highlightTexture:SetVertexColor(1, 0.85, 0, 0.12)
        button:SetHighlightTexture(highlightTexture)

        local selectedTexture = button:CreateTexture("PoweredAuctionItemButton" .. i .. "Selected", "ARTWORK")
        selectedTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
        selectedTexture:SetAllPoints(button)
        selectedTexture:SetVertexColor(1, 0.85, 0, 0.18)
        selectedTexture:Hide()

        local nameText = button:CreateFontString("PoweredAuctionItemButtonText" .. i, "ARTWORK",
                                                "GameFontHighlight")
        nameText:SetJustifyH("LEFT")
        nameText:SetPoint("LEFT", button, "LEFT", 8, 0)
        nameText:SetWidth(200)

        local priceText = button:CreateFontString("PoweredAuctionItemButtonPrice" .. i, "ARTWORK",
                                                   "GameFontNormalSmall")
        priceText:SetJustifyH("RIGHT")
        priceText:SetPoint("RIGHT", button, "RIGHT", -155, 0)
        priceText:SetWidth(120)

        local qtyText = button:CreateFontString("PoweredAuctionItemButtonQty" .. i, "ARTWORK",
                                                 "GameFontNormalSmall")
        qtyText:SetJustifyH("RIGHT")
        qtyText:SetPoint("RIGHT", button, "RIGHT", -85, 0)
        qtyText:SetWidth(60)

        local scanCountText = button:CreateFontString("PoweredAuctionItemButtonScanCount" .. i, "ARTWORK",
                                                       "GameFontNormalSmall")
        scanCountText:SetJustifyH("RIGHT")
        scanCountText:SetPoint("RIGHT", button, "RIGHT", -8, 0)
        scanCountText:SetWidth(65)

        button:SetScript("OnClick", function()
            local idx = this.dataIndex
            if idx then
                if selectedItemIndex == idx then
                    selectedItemIndex = nil
                else
                    selectedItemIndex = idx
                end
                PoweredAuction_UpdateItemList()
            end
        end)
    end

    itemButtonsCreated = true
end

function PoweredAuction_RefreshItemList()
    if not PoweredAuctionDB or not PoweredAuctionDB.watchList then return end
    if not itemButtonsCreated then
        PoweredAuction_CreateItemButtons()
    end
    PoweredAuction_UpdateItemList()
end

function PoweredAuction_UpdateItemList()
    local scrollFrame = getglobal("PoweredAuctionFrameItemListScrollFrame")
    if not scrollFrame then return end
    if not PoweredAuctionDB or not PoweredAuctionDB.watchList then return end

    local watchList = PoweredAuctionDB.watchList
    local numItems = table.getn(watchList)
    local offset = FauxScrollFrame_GetOffset(scrollFrame)

    for i = 1, PA_UI_MAX_VISIBLE do
        local button = getglobal("PoweredAuctionItemButton" .. i)
        local nameText = getglobal("PoweredAuctionItemButtonText" .. i)
        local priceText = getglobal("PoweredAuctionItemButtonPrice" .. i)
        local qtyText = getglobal("PoweredAuctionItemButtonQty" .. i)
        local scanCountText = getglobal("PoweredAuctionItemButtonScanCount" .. i)
        local bg = getglobal("PoweredAuctionItemButton" .. i .. "Bg")
        local selectedTex = getglobal("PoweredAuctionItemButton" .. i .. "Selected")

        if not button then return end

        local dataIndex = offset + i

        if dataIndex <= numItems then
            local itemName = watchList[dataIndex]
            nameText:SetText(itemName or "Unknown")

            local lastScan, scanCount = GetLastScanData(itemName)

            if lastScan and lastScan.buyout and lastScan.buyout > 0 then
                priceText:SetText(GetMoneyString(lastScan.buyout))
            else
                priceText:SetText("|cFF93978B---|r")
            end

            if lastScan and lastScan.quantity then
                qtyText:SetText("|cFFD8E1D3x" .. lastScan.quantity .. "|r")
            else
                qtyText:SetText("")
            end

            scanCountText:SetText(scanCount > 0 and ("|cFF99FFFF" .. scanCount .. " scans|r") or "|cFF93978B0|r")

            button.dataIndex = dataIndex

            if math.mod(i, 2) == 0 then
                bg:SetVertexColor(0.18, 0.18, 0.18, 1)
            else
                bg:SetVertexColor(0.14, 0.14, 0.14, 1)
            end

            if selectedItemIndex == dataIndex then
                selectedTex:Show()
                nameText:SetTextColor(1, 0.85, 0)
            else
                selectedTex:Hide()
                nameText:SetTextColor(0.84, 0.88, 0.83)
            end

            button:Show()
        else
            button.dataIndex = nil
            button:Hide()
        end
    end

    FauxScrollFrame_Update(scrollFrame, numItems, PA_UI_MAX_VISIBLE, PA_UI_ITEM_HEIGHT)
end

function PoweredAuction_SetStatusText(statusText)
    local label = getglobal("PoweredAuctionFrameStatusLabel")
    if label then
        label:SetText(statusText)
    end
end
