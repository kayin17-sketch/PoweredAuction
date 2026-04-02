local PA_UI_ITEM_HEIGHT = 20
local PA_UI_MAX_VISIBLE = 15
local selectedItemIndex = nil
local itemButtonsCreated = false

function PoweredAuction_OnEvent(event)
    if event == "VARIABLES_LOADED" then
        PoweredAuction_InitDB()
        PoweredAuction_CreateItemButtons()
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

function PoweredAuction_UIAddItem()
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

function PoweredAuction_CreateItemButtons()
    if itemButtonsCreated then return end

    local itemFrame = getglobal("PoweredAuctionFrameItemList")
    if not itemFrame then return end

    for i = 1, PA_UI_MAX_VISIBLE do
        local button = CreateFrame("Button", "PoweredAuctionItemButton" .. i, itemFrame)
        button:SetHeight(PA_UI_ITEM_HEIGHT)
        button:SetWidth(330)
        button:SetPoint("TOPLEFT", itemFrame, "TOPLEFT", 0, -(i - 1) * PA_UI_ITEM_HEIGHT)

        local highlightTexture = button:CreateTexture("PoweredAuctionItemButton" .. i .. "Highlight")
        highlightTexture:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        highlightTexture:SetAllPoints(button)
        button:SetHighlightTexture(highlightTexture)

        local text = button:CreateFontString("PoweredAuctionItemButtonText" .. i, "ARTWORK",
                                              "GameFontHighlight")
        text:SetJustifyH("LEFT")
        text:SetPoint("LEFT", button, "LEFT", 5, 0)

        local scanCount = button:CreateFontString("PoweredAuctionItemButtonScanCount" .. i, "ARTWORK",
                                                    "GameFontNormalSmall")
        scanCount:SetJustifyH("RIGHT")
        scanCount:SetPoint("RIGHT", button, "RIGHT", -5, 0)

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
        local text = getglobal("PoweredAuctionItemButtonText" .. i)
        local scanCount = getglobal("PoweredAuctionItemButtonScanCount" .. i)

        if not button then return end

        local dataIndex = offset + i

        if dataIndex <= numItems then
            local itemName = watchList[dataIndex]
            text:SetText(itemName or "Unknown")

            local historyCount = 0
            if itemName then
                local key = string.lower(itemName)
                if PoweredAuctionDB.scanHistory and PoweredAuctionDB.scanHistory[key] then
                    historyCount = table.getn(PoweredAuctionDB.scanHistory[key].scans or {})
                end
            end
            scanCount:SetText(historyCount > 0 and (historyCount .. " scans") or "")

            button.dataIndex = dataIndex

            if selectedItemIndex == dataIndex then
                button:LockHighlight()
            else
                button:UnlockHighlight()
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
