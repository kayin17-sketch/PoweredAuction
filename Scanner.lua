local PA_SCAN_DELAY = 1.0
local PA_QUERY_POLL_DELAY = 0.5
local PA_QUERY_MAX_RETRIES = 10

local ahIsOpen = false

local scanState = {
    isScanning = false,
    currentIndex = 0,
    currentItemName = nil,
    currentPage = 0,
    totalScannedItems = 0,
    queryRetries = 0,
}

local scanTimerFrame = CreateFrame("Frame", "PoweredAuctionScanTimerFrame")
scanTimerFrame:Hide()
scanTimerFrame.elapsed = 0
scanTimerFrame.delay = 0
scanTimerFrame.callback = nil

scanTimerFrame:SetScript("OnUpdate", function()
    this.elapsed = this.elapsed + arg1
    if this.elapsed >= this.delay then
        this:Hide()
        if this.callback then
            local cb = this.callback
            this.callback = nil
            cb()
        end
    end
end)

local function ScheduleCallback(callback, delay)
    scanTimerFrame.callback = callback
    scanTimerFrame.delay = delay
    scanTimerFrame.elapsed = 0
    scanTimerFrame:Show()
end

local function IsAuctionHouseOpen()
    if ahIsOpen then return true end
    if AuctionFrame and AuctionFrame:IsVisible() then return true end
    if CanSendAuctionQuery() then
        ahIsOpen = true
        return true
    end
    return false
end

function PoweredAuction_AHOpened()
    ahIsOpen = true
end

function PoweredAuction_AHClosed()
    ahIsOpen = false
end

function PoweredAuction_StartScan()
    if not IsAuctionHouseOpen() then
        PoweredAuction_PrintError("Auction House must be open to scan.")
        return
    end

    if scanState.isScanning then
        PoweredAuction_CancelScan("Scan cancelled by user.")
        return
    end

    if not PoweredAuctionDB.watchList or table.getn(PoweredAuctionDB.watchList) == 0 then
        PoweredAuction_PrintError("Watch list is empty. Add items first with /pa add <name>")
        return
    end

    scanState.isScanning = true
    scanState.currentIndex = 1
    scanState.totalScannedItems = 0

    PoweredAuction_Print("Starting scan of " .. table.getn(PoweredAuctionDB.watchList) .. " items...")
    PoweredAuction_SetStatusText("Scanning...")
    PoweredAuction_UpdateScanButton()

    PoweredAuction_ScanNextItem()
end

function PoweredAuction_ScanNextItem()
    if not scanState.isScanning then return end

    if scanState.currentIndex > table.getn(PoweredAuctionDB.watchList) then
        PoweredAuction_FinishScan()
        return
    end

    if not IsAuctionHouseOpen() then
        PoweredAuction_CancelScan("Auction House closed. Scan cancelled.")
        return
    end

    scanState.currentItemName = PoweredAuctionDB.watchList[scanState.currentIndex]
    scanState.currentPage = 0
    scanState.queryRetries = 0

    PoweredAuction_SetStatusText("Scanning: " .. scanState.currentItemName ..
        " (" .. scanState.currentIndex .. "/" .. table.getn(PoweredAuctionDB.watchList) .. ")")

    PoweredAuction_QueryAuctionPage(scanState.currentItemName, 0)
end

function PoweredAuction_QueryAuctionPage(itemName, page)
    if not scanState.isScanning then return end

    if not IsAuctionHouseOpen() then
        PoweredAuction_CancelScan("Auction House closed. Scan cancelled.")
        return
    end

    scanState.currentPage = page
    scanState.queryRetries = 0

    PoweredAuction_WaitAndQuery(itemName, page)
end

function PoweredAuction_WaitAndQuery(itemName, page)
    if not scanState.isScanning then return end

    local canQuery, canQueryAll = CanSendAuctionQuery()
    if not canQuery then
        scanState.queryRetries = scanState.queryRetries + 1
        if scanState.queryRetries > PA_QUERY_MAX_RETRIES then
            PoweredAuction_PrintError("Could not query AH for \"" .. itemName .. "\". Skipping.")
            PoweredAuction_AdvanceItem()
            return
        end
        ScheduleCallback(function()
            PoweredAuction_WaitAndQuery(itemName, page)
        end, 0.5)
        return
    end

    scanState.queryRetries = 0
    QueryAuctionItems(itemName, nil, nil, nil, nil, nil, page, nil, nil)

    ScheduleCallback(function()
        PoweredAuction_ProcessScanResults()
    end, PA_QUERY_POLL_DELAY)
end

function PoweredAuction_ProcessScanResults()
    if not scanState.isScanning then return end

    local numBatchAuctions, totalAuctions = GetNumAuctionItems("list")

    if numBatchAuctions == 0 then
        PoweredAuction_AdvanceItem()
        return
    end

    local totalPages = math.ceil(totalAuctions / 50)
    if totalPages == 0 then totalPages = 1 end

    for i = 1, numBatchAuctions do
        local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice,
            bidAmount, highBidder, owner, saleStatus = GetAuctionItemInfo("list", i)

        if name and buyoutPrice and buyoutPrice > 0 and count and count > 0 then
            local buyoutPerUnit = math.floor(buyoutPrice / count)

            local itemID = 0
            local cachedName, _, _, _, _, _, _, _, _, _, cachedItemID = GetItemInfo(name)
            if cachedItemID then
                itemID = cachedItemID
            end

            PoweredAuction_AddScanResult(name, buyoutPerUnit, count, itemID)
            scanState.totalScannedItems = scanState.totalScannedItems + 1
        end
    end

    if scanState.currentPage < totalPages - 1 then
        local nextPage = scanState.currentPage + 1
        ScheduleCallback(function()
            PoweredAuction_QueryAuctionPage(scanState.currentItemName, nextPage)
        end, PA_SCAN_DELAY)
    else
        PoweredAuction_AdvanceItem()
    end
end

function PoweredAuction_AdvanceItem()
    scanState.currentIndex = scanState.currentIndex + 1

    ScheduleCallback(function()
        PoweredAuction_ScanNextItem()
    end, PA_SCAN_DELAY)
end

function PoweredAuction_FinishScan()
    scanState.isScanning = false

    PoweredAuction_Print("Scan complete! " .. scanState.totalScannedItems .. " records processed.")
    PoweredAuction_SetStatusText("Scan complete!")
    PoweredAuction_UpdateScanButton()
    PoweredAuction_RefreshItemList()
end

function PoweredAuction_CancelScan(reason)
    scanState.isScanning = false

    PoweredAuction_PrintError(reason or "Scan cancelled.")
    PoweredAuction_SetStatusText("Scan cancelled.")
    PoweredAuction_UpdateScanButton()
end

function PoweredAuction_UpdateScanButton()
    local scanButton = getglobal("PoweredAuctionFrameScanButton")
    if not scanButton then return end

    if scanState.isScanning then
        scanButton:SetText("Cancel")
    else
        scanButton:SetText("Scan AH")
    end
end
