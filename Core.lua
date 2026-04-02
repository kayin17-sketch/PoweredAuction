PoweredAuction = {}
PoweredAuction.version = "1.0.0"

local ADDON_NAME = "PoweredAuction"
local PRINT_PREFIX = "|cFF00FF00[PoweredAuction]|r "

function PoweredAuction_Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(PRINT_PREFIX .. msg)
end

function PoweredAuction_PrintError(msg)
    DEFAULT_CHAT_FRAME:AddMessage(PRINT_PREFIX .. "|cFFFF0000" .. msg .. "|r")
end

function PoweredAuction_OnLoad()
    SLASH_POWEREDAUCTION1 = "/pa"
    SLASH_POWEREDAUCTION2 = "/poweredauction"
    SlashCmdList["POWEREDAUCTION"] = function(msg)
        PoweredAuction_SlashCommand(msg)
    end

    this:RegisterEvent("VARIABLES_LOADED")
    this:RegisterEvent("ADDON_LOADED")

    PoweredAuction_Print("Loaded v" .. PoweredAuction.version .. ". Type /pa for help.")
end

function PoweredAuction_SlashCommand(msg)
    msg = string.lower(msg or "")

    if msg == "" or msg == "help" then
        PoweredAuction_PrintHelp()
    elseif msg == "scan" then
        PoweredAuction_StartScan()
    elseif string.sub(msg, 1, 3) == "add" then
        local itemName = string.sub(msg, 5)
        if itemName and itemName ~= "" then
            PoweredAuction_AddToWatchList(itemName)
        else
            PoweredAuction_PrintError("Usage: /pa add <item name>")
        end
    elseif string.sub(msg, 1, 6) == "remove" then
        local itemName = string.sub(msg, 8)
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
    PoweredAuction_Print("/pa clear - Clear all scan history")
    PoweredAuction_Print("/pa help - Show this help")
end

function PoweredAuction_OnEvent(event)
    if event == "VARIABLES_LOADED" then
        PoweredAuction_InitDB()
        PoweredAuction_InitUI()
    end
end
