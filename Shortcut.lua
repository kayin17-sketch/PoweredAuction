local orig_UseContainerItem = UseContainerItem
local orig_SetItemRef = SetItemRef
local orig_ChatEdit_InsertLink = ChatEdit_InsertLink
local orig_PickupContainerItem = PickupContainerItem

local lastDraggedItemName = nil

UseContainerItem = function(bag, slot)
    if PoweredAuctionFrame and PoweredAuctionFrame:IsVisible() then
        if not IsShiftKeyDown() and not IsControlKeyDown() and not IsAltKeyDown() then
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local itemName = PoweredAuction_ExtractItemName(itemLink)
                if itemName then
                    PoweredAuction_AddToWatchList(itemName)
                    return
                end
            end
        end
    end
    if orig_UseContainerItem then
        return orig_UseContainerItem(bag, slot)
    end
end

SetItemRef = function(link, text, button)
    if button == "RightButton" and PoweredAuctionFrame and PoweredAuctionFrame:IsVisible() then
        local _, _, itemID = string.find(link, "^item:(%d+)")
        if itemID then
            local itemName = GetItemInfo(tonumber(itemID))
            if itemName then
                PoweredAuction_AddToWatchList(itemName)
                return
            end
        end
    end
    if orig_SetItemRef then
        return orig_SetItemRef(link, text, button)
    end
end

ChatEdit_InsertLink = function(link)
    if link and PoweredAuctionFrame and PoweredAuctionFrame:IsVisible() then
        local input = getglobal("PoweredAuctionFrameItemInput")
        if input and input:HasFocus() then
            local name = PoweredAuction_ExtractItemName(link)
            if name then
                input:SetText(name)
                return 1
            end
        end
    end
    if orig_ChatEdit_InsertLink then
        return orig_ChatEdit_InsertLink(link)
    end
end

PickupContainerItem = function(bag, slot)
    lastDraggedItemName = nil
    local itemLink = nil
    if PoweredAuctionFrame and PoweredAuctionFrame:IsVisible() then
        itemLink = GetContainerItemLink(bag, slot)
    end
    local result
    if orig_PickupContainerItem then
        result = orig_PickupContainerItem(bag, slot)
    end
    if itemLink and CursorHasItem() then
        lastDraggedItemName = PoweredAuction_ExtractItemName(itemLink)
    end
    return result
end

function PoweredAuction_GetLastDraggedItem()
    local name = lastDraggedItemName
    lastDraggedItemName = nil
    return name
end
