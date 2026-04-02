function PoweredAuction_InitDB()
    if not PoweredAuctionDB then
        PoweredAuctionDB = {
            watchList = {},
            scanHistory = {},
        }
    end

    if not PoweredAuctionDB.watchList then
        PoweredAuctionDB.watchList = {}
    end

    if not PoweredAuctionDB.scanHistory then
        PoweredAuctionDB.scanHistory = {}
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

    itemName = strtrim(itemName)

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
    if index < 1 or index > table.getn(PoweredAuctionDB.watchList) then return end

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

function PoweredAuction_AddScanResult(itemID, itemName, buyout, quantity)
    if not itemID or not buyout or not quantity then return end

    if not PoweredAuctionDB.scanHistory[itemID] then
        PoweredAuctionDB.scanHistory[itemID] = {
            name = itemName,
            scans = {},
        }
    end

    local timestamp = time()

    for _, scan in ipairs(PoweredAuctionDB.scanHistory[itemID].scans) do
        if scan.timestamp == timestamp and scan.buyout == buyout then
            return
        end
    end

    table.insert(PoweredAuctionDB.scanHistory[itemID].scans, {
        timestamp = timestamp,
        buyout = buyout,
        quantity = quantity,
    })

    PoweredAuctionDB.scanHistory[itemID].name = itemName
end

function PoweredAuction_ClearHistory()
    PoweredAuctionDB.scanHistory = {}
    PoweredAuction_Print("Scan history cleared.")
end

function PoweredAuction_GetScanCount(itemID)
    if not PoweredAuctionDB.scanHistory[itemID] then return 0 end
    return table.getn(PoweredAuctionDB.scanHistory[itemID].scans)
end
