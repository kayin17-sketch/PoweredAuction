PoweredAuction = {}
PoweredAuction.version = "1.0.0"

local PRINT_PREFIX = "|cFF00FF00[PoweredAuction]|r "

function PoweredAuction_Trim(s)
    if not s then return "" end
    return string.gsub(s, "^%s*(.-)%s*$", "%1")
end

function PoweredAuction_ExtractItemName(link)
    if not link then return nil end
    local _, _, name = string.find(link, "%[(.-)%]")
    if name then return name end
    return nil
end

function PoweredAuction_Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(PRINT_PREFIX .. tostring(msg))
end

function PoweredAuction_PrintError(msg)
    DEFAULT_CHAT_FRAME:AddMessage(PRINT_PREFIX .. "|cFFFF0000" .. tostring(msg) .. "|r")
end

SLASH_POWEREDAUCTION1 = "/pa"
SLASH_POWEREDAUCTION2 = "/poweredauction"
SlashCmdList["POWEREDAUCTION"] = function(msg)
    PoweredAuction_SlashCommand(msg)
end

function PoweredAuction_SlashCommand(msg)
    msg = string.lower(msg or "")

    if msg == "" or msg == "help" then
        PoweredAuction_PrintHelp()
    elseif msg == "scan" then
        PoweredAuction_StartScan()
    elseif msg == "fullscan" then
        PoweredAuction_StartFullScan()
    elseif string.sub(msg, 1, 3) == "add" then
        local itemName = PoweredAuction_Trim(string.sub(msg, 5))
        if itemName and itemName ~= "" then
            PoweredAuction_AddToWatchList(itemName)
        else
            PoweredAuction_PrintError("Usage: /pa add <item name>")
        end
    elseif string.sub(msg, 1, 6) == "remove" then
        local itemName = PoweredAuction_Trim(string.sub(msg, 8))
        if itemName and itemName ~= "" then
            PoweredAuction_RemoveFromWatchList(itemName)
        else
            PoweredAuction_PrintError("Usage: /pa remove <item name>")
        end
    elseif msg == "list" then
        PoweredAuction_ListWatchList()
    elseif msg == "clear" then
        PoweredAuction_ClearHistory()
    elseif msg == "show" then
        PoweredAuction_ToggleUI(true)
    elseif msg == "hide" then
        PoweredAuction_ToggleUI(false)
    else
        PoweredAuction_PrintError("Unknown command. Type /pa help for commands.")
    end
end

function PoweredAuction_PrintHelp()
    PoweredAuction_Print("--- PoweredAuction Commands ---")
    PoweredAuction_Print("/pa show - Show the panel")
    PoweredAuction_Print("/pa hide - Hide the panel")
    PoweredAuction_Print("/pa add <name> - Add item to watch list")
    PoweredAuction_Print("/pa remove <name> - Remove item from watch list")
    PoweredAuction_Print("/pa list - Show current watch list")
    PoweredAuction_Print("/pa scan - Start auction scan (AH must be open)")
    PoweredAuction_Print("/pa fullscan - Full auction house scan")
    PoweredAuction_Print("/pa clear - Clear all scan history")
    PoweredAuction_Print("/pa help - Show this help")
end
