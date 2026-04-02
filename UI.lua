local PA_UI_ITEM_HEIGHT = 20
local PA_UI_ITEM_OFFSET = 0
local PA_UI_MAX_VISIBLE = 15

local selectedItemIndex = nil

function PoweredAuction_InitUI()
    hooksecurefunc("ContainerFrameItemButton_OnClick", function(button, ignoreModifiers)
        if IsShiftKeyDown() and PoweredAuctionFrame:IsVisible() then
            local link = GetContainerItemLink(this:GetParent():GetID(), this:GetID())
            if link then
                local _, _, name = string.find(link, "%[(.-)%]")
                if name then
                    PoweredAuction_AddToWatchList(name)
                end
            end
        end
    end)

    hooksecurefunc("SetItemRef", function(link)
        if IsShiftKeyDown() and PoweredAuctionFrame:IsVisible() then
            local _, _, name = string.find(link or "", "%[(.-)%]")
            if name then
                PoweredAuction_AddToWatchList(name)
            end
        end
    end)
end

function PoweredAuction_ToggleUI(show)
    if show == nil then
        show = not PoweredAuctionFrame:IsVisible()
    end

    if show then
        PoweredAuctionFrame:Show()
        PoweredAuction_RefreshItemList()
    else
        PoweredAuctionFrame:Hide()
    end
end

function PoweredAuction_UIAddItem()
    local input = getglobal("PoweredAuctionFrameItemInput")
    local text = input:GetText()

    if text and text ~= "" then
        PoweredAuction_AddToWatchList(text)
        input:SetText("")
        input:SetFocus()
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

function PoweredAuction_RefreshItemList()
    local scrollFrame = getglobal("PoweredAuctionFrameItemListScrollFrame")
    local scrollChild = getglobal("PoweredAuctionFrameItemListScrollFrame" .. "ScrollBar")

    if not PoweredAuctionDB or not PoweredAuctionDB.watchList then return end

    local watchList = PoweredAuctionDB.watchList
    local numItems = table.getn(watchList)
    local maxScroll = math.max(0, (numItems - PA_UI_MAX_VISIBLE) * PA_UI_ITEM_HEIGHT)

    if scrollChild then
        scrollChild:SetValue(0)
        scrollChild:SetMinMaxValues(0, maxScroll)
    end

    PoweredAuction_UpdateItemList()
end

function PoweredAuction_UpdateItemList()
    local scrollFrame = getglobal("PoweredAuctionFrameItemListScrollFrame")
    local scrollBar = getglobal("PoweredAuctionFrameItemListScrollFrame" .. "ScrollBar")
    local itemFrame = getglobal("PoweredAuctionFrameItemList")

    if not PoweredAuctionDB or not PoweredAuctionDB.watchList then return end

    local watchList = PoweredAuctionDB.watchList
    local numItems = table.getn(watchList)

    local offset = FauxScrollFrame_GetOffset(scrollFrame)

    for i = 1, PA_UI_MAX_VISIBLE do
        local button = getglobal("PoweredAuctionItemButton" .. i)
        local text = getglobal("PoweredAuctionItemButtonText" .. i)
        local scanCount = getglobal("PoweredAuctionItemButtonScanCount" .. i)

        if not button then
            button = CreateFrame("Button", "PoweredAuctionItemButton" .. i, itemFrame,
                                 "PoweredAuctionItemButtonTemplate")
            button:SetID(i)
        end

        local dataIndex = offset + i

        if dataIndex <= numItems then
            text:SetText(watchList[dataIndex])

            local historyCount = 0
            for itemID, data in pairs(PoweredAuctionDB.scanHistory) do
                if data.name and string.lower(data.name) == string.lower(watchList[dataIndex]) then
                    historyCount = table.getn(data.scans)
                    break
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
            button:Hide()
        end
    end

    local maxScroll = math.max(0, (numItems - PA_UI_MAX_VISIBLE) * PA_UI_ITEM_HEIGHT)
    if scrollBar then
        scrollBar:SetMinMaxValues(0, maxScroll)
    end

    FauxScrollFrame_Update(scrollFrame, numItems, PA_UI_MAX_VISIBLE, PA_UI_ITEM_HEIGHT)
end

function PoweredAuction_SetStatusText(text)
    local label = getglobal("PoweredAuctionFrameStatusLabel")
    if label then
        label:SetText(text)
    end
end

-- Item button template (created dynamically on first load)
local function CreateItemButtonTemplates()
    local templateName = "PoweredAuctionItemButtonTemplate"

    local button = CreateFrame("Button", templateName .. "Hidden", UIParent)
    button:SetHeight(PA_UI_ITEM_HEIGHT)
    button:SetWidth(330)

    local buttonText = button:CreateFontString(templateName .. "HiddenText", "ARTWORK",
                                                "GameFontHighlight")
    buttonText:SetJustifyH("LEFT")
    buttonText:SetPoint("LEFT", button, "LEFT", 5, 0)

    local scanCountText = button:CreateFontString(templateName .. "HiddenScanCount", "ARTWORK",
                                                    "GameFontNormalSmall")
    scanCountText:SetJustifyH("RIGHT")
    scanCountText:SetPoint("RIGHT", button, "RIGHT", -5, 0)
end

CreateItemButtonTemplates()

-- Create actual item buttons
for i = 1, PA_UI_MAX_VISIBLE do
    local itemFrame = getglobal("PoweredAuctionFrameItemList")
    local button = CreateFrame("Button", "PoweredAuctionItemButton" .. i, itemFrame)
    button:SetHeight(PA_UI_ITEM_HEIGHT)
    button:SetWidth(330)
    button:SetPoint("TOPLEFT", itemFrame, "TOPLEFT", 0, -(i - 1) * PA_UI_ITEM_HEIGHT)

    local normalTexture = button:CreateTexture("PoweredAuctionItemButton" .. i .. "Normal")
    normalTexture:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    normalTexture:SetVertexColor(1, 1, 0, 0.3)
    normalTexture:SetAllPoints(button)
    button:SetNormalTexture(normalTexture)

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
        local dataIndex = this.dataIndex
        if dataIndex then
            if selectedItemIndex == dataIndex then
                selectedItemIndex = nil
            else
                selectedItemIndex = dataIndex
            end
            PoweredAuction_UpdateItemList()
        end
    end)
end
