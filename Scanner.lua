local PA_SCAN_DELAY = 1.0
local PA_PAGE_DELAY = 1.2

local scanState = {
    isScanning = false,
    currentIndex = 0,
    currentItemName = nil,
    currentPage = 0,
    totalPages = 0,
    totalScannedItems = 0,
    totalNewRecords = 0,
}

local scanFrame = CreateFrame("Frame", "PoweredAuctionScanFrame")
scanFrame:Hide()

local scanTimerFrame = CreateFrame("Frame", "PoweredAuctionScanTimerFrame")
scanTimerFrame:Hide()

local function PoweredAuction_IsAuctionHouseOpen()
    return AuctionFrame and AuctionFrame:IsVisible()
end

function PoweredAuction_StartScan()
    if not PoweredAuction_IsAuctionHouseOpen() then
        PoweredAuction_PrintError("Auction House must be open to scan.")
        return
    end

    if scanState.isScanning then
        PoweredAuction_PrintError("Scan already in progress.")
        return
    end

    if not PoweredAuctionDB.watchList or table.getn(PoweredAuctionDB.watchList) == 0 then
        PoweredAuction_PrintError("Watch list is empty. Add items first with /pa add <name>")
        return
    end

    scanState.isScanning = true
    scanState.currentIndex = 1
    scanState.currentPage = 0
    scanState.totalScannedItems = 0
    scanState.totalNewRecords = 0

    PoweredAuction_Print("Starting scan of " .. table.getn(PoweredAuctionDB.watchList) .. " items...")
    PoweredAuction_SetStatusText("Scanning...")
    PoweredAuction_UpdateScanUI()

    PoweredAuction_ScanNextItem()
end

function PoweredAuction_ScanNextItem()
    if not scanState.isScanning then return end

    if scanState.currentIndex > table.getn(PoweredAuctionDB.watchList) then
        PoweredAuction_FinishScan()
        return
    end

    if not PoweredAuction_IsAuctionHouseOpen() then
        PoweredAuction_CancelScan("Auction House closed. Scan cancelled.")
        return
    end

    scanState.currentItemName = PoweredAuctionDB.watchList[scanState.currentIndex]
    scanState.currentPage = 0

    PoweredAuction_SetStatusText("Scanning: " .. scanState.currentItemName ..
        " (" .. scanState.currentIndex .. "/" .. table.getn(PoweredAuctionDB.watchList) .. ")")
    PoweredAuction_UpdateScanUI()

    PoweredAuction_ScanAuctionPage(scanState.currentItemName, 0)
end

function PoweredAuction_ScanAuctionPage(itemName, page)
    if not scanState.isScanning then return end

    if not PoweredAuction_IsAuctionHouseOpen() then
        PoweredAuction_CancelScan("Auction House closed. Scan cancelled.")
        return
    end

    scanState.currentPage = page

    local canQuery, canQueryAll = CanSendAuctionQuery()
    if not canQuery then
        PoweredAuction_ScheduleRetry(function()
            PoweredAuction_ScanAuctionPage(itemName, page)
        end, 0.5)
        return
    end

    QueryAuctionItems(itemName, nil, nil, nil, nil, nil, page, nil, nil)

    scanFrame:RegisterEvent("CHAT_MSG_SYSTEM")
end

scanFrame:SetScript("OnEvent", function()
    if event == "CHAT_MSG_SYSTEM" then
        if arg1 and (string.find(arg1, "Auction") or string.find(arg1, "auction") or
            string.find(arg1, "browse") or string.find(arg1, "found")) then
            scanFrame:UnregisterEvent("CHAT_MSG_SYSTEM")
            PoweredAuction_ProcessScanResults()
        end
    end
end)

function PoweredAuction_ProcessScanResults()
    if not scanState.isScanning then return end

    local numBatchAuctions, totalAuctions = GetNumAuctionItems("list")

    if numBatchAuctions == 0 then
        PoweredAuction_AdvanceItem()
        return
    end

    local totalPages = math.ceil(totalAuctions / 50)

    for i = 1, numBatchAuctions do
        local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice,
            bidAmount, highBidder, owner = GetAuctionItemInfo("list", i)

        if name and buyoutPrice and buyoutPrice > 0 and count and count > 0 then
            local itemLink = GetAuctionItemLink("list", i)
            local itemID = nil

            if itemLink then
                local _, _, id = string.find(itemLink, "item:(%d+)")
                if id then
                    itemID = tonumber(id)
                end
            end

            local buyoutPerUnit = math.floor(buyoutPrice / count)

            PoweredAuction_AddScanResult(itemID or 0, name, buyoutPerUnit, count)
            scanState.totalScannedItems = scanState.totalScannedItems + 1
        end
    end

    if scanState.currentPage < totalPages - 1 then
        local nextPage = scanState.currentPage + 1
        PoweredAuction_ScheduleRetry(function()
            PoweredAuction_ScanAuctionPage(scanState.currentItemName, nextPage)
        end, PA_PAGE_DELAY)
    else
        PoweredAuction_AdvanceItem()
    end
end

function PoweredAuction_AdvanceItem()
    scanState.currentIndex = scanState.currentIndex + 1

    PoweredAuction_ScheduleRetry(function()
        PoweredAuction_ScanNextItem()
    end, PA_SCAN_DELAY)
end

function PoweredAuction_FinishScan()
    scanState.isScanning = false
    scanTimerFrame:Hide()

    PoweredAuction_Print("Scan complete! " .. scanState.totalScannedItems .. " records processed.")
    PoweredAuction_SetStatusText("Scan complete!")
    PoweredAuction_UpdateScanUI()
    PoweredAuction_RefreshItemList()
end

function PoweredAuction_CancelScan(reason)
    scanState.isScanning = false
    scanTimerFrame:Hide()
    scanFrame:UnregisterEvent("CHAT_MSG_SYSTEM")

    PoweredAuction_PrintError(reason or "Scan cancelled.")
    PoweredAuction_SetStatusText("Scan cancelled.")
    PoweredAuction_UpdateScanUI()
end

function PoweredAuction_ScheduleRetry(callback, delay)
    scanTimerFrame.callback = callback
    scanTimerFrame.delay = delay
    scanTimerFrame.elapsed = 0
    scanTimerFrame:Show()
end

scanTimerFrame:SetScript("OnUpdate", function()
    this.elapsed = this.elapsed + arg1
    if this.elapsed >= this.delay then
        this:Hide()
        if this.callback then
            this.callback()
            this.callback = nil
        end
    end
end)

function PoweredAuction_UpdateScanUI()
    local scanButton = getglobal("PoweredAuctionFrameScanButton")
    if scanButton then
        if scanState.isScanning then
            scanButton:SetText("Cancel")
            scanButton:SetScript("OnClick", function()
                PoweredAuction_CancelScan("Scan cancelled by user.")
            end)
        else
            scanButton:SetText("Scan AH")
            scanButton:SetScript("OnClick", function()
                PoweredAuction_StartScan()
            end)
        end
    end
end
