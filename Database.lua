function PoweredAuction_InitDB()
    if not PoweredAuctionDB then
        PoweredAuctionDB = {
            watchList = {},
            scanHistory = {},
            minimapAngle = 225,
        }
    end

    if not PoweredAuctionDB.watchList then
        PoweredAuctionDB.watchList = {}
    end

    if not PoweredAuctionDB.scanHistory then
        PoweredAuctionDB.scanHistory = {}
    end

    if not PoweredAuctionDB.minimapAngle then
        PoweredAuctionDB.minimapAngle = 225
    end
end

function PoweredAuction_AddToWatchList(itemName)
    if not itemName or itemName == "" then return end

    itemName = strtrim(itemName)

    for _, name in ipairs(PoweredAuctionDB.watchList) do
        if string.lower(name) == string.lower(itemName) then
            PoweredAuction_PrintError("\"" .. itemName .. "\" is already in the watch list.")
            return
        end
    end

    table.insert(PoweredAuctionDB.watchList, itemName)
    PoweredAuction_Print("Added \"" .. itemName .. "\" to watch list.")
    PoweredAuction_RefreshItemList()
end

function PoweredAuction_RemoveFromWatchList(itemName)
    if not itemName or itemName == "" then return end

    for i, name in ipairs(PoweredAuctionDB.watchList) do
        if string.lower(name) == string.lower(itemName) then
            table.remove(PoweredAuctionDB.watchList, i)
            PoweredAuction_Print("Removed \"" .. itemName .. "\" from watch list.")
            PoweredAuction_RefreshItemList()
            return
        end
    end

    PoweredAuction_PrintError("\"" .. itemName .. "\" not found in watch list.")
end

function PoweredAuction_RemoveFromWatchListByIndex(index)
    if not index or index < 1 or index > table.getn(PoweredAuctionDB.watchList) then return end

    local name = PoweredAuctionDB.watchList[index]
    table.remove(PoweredAuctionDB.watchList, index)
    PoweredAuction_Print("Removed \"" .. name .. "\" from watch list.")
    PoweredAuction_RefreshItemList()
end

function PoweredAuction_ListWatchList()
    if table.getn(PoweredAuctionDB.watchList) == 0 then
        PoweredAuction_Print("Watch list is empty. Use /pa add <item name>")
        return
    end

    PoweredAuction_Print("--- Watch List ---")
    for i, name in ipairs(PoweredAuctionDB.watchList) do
        PoweredAuction_Print(i .. ". " .. name)
    end
end

function PoweredAuction_AddScanResult(itemName, buyout, quantity, itemID)
    if not itemName or not buyout or not quantity then return end

    local key = string.lower(itemName)

    if not PoweredAuctionDB.scanHistory[key] then
        PoweredAuctionDB.scanHistory[key] = {
            name = itemName,
            itemId = itemID or 0,
            scans = {},
        }
    end

    local history = PoweredAuctionDB.scanHistory[key]
    history.name = itemName
    if itemID and itemID > 0 then
        history.itemId = itemID
    end

    local timestamp = time()

    for _, scan in ipairs(history.scans) do
        if scan.timestamp == timestamp and scan.buyout == buyout then
            return
        end
    end

    table.insert(history.scans, {
        timestamp = timestamp,
        buyout = buyout,
        quantity = quantity,
    })
end

function PoweredAuction_ClearHistory()
    PoweredAuctionDB.scanHistory = {}
    PoweredAuction_Print("Scan history cleared.")
end
