local minimapButton = nil
local contextMenu = nil
local PA_MINIMAP_RADIUS = 80

StaticPopupDialogs["POWEREDAUCTION_CLEAR"] = {
    text = "Are you sure you want to clear all scan history?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        PoweredAuction_ClearHistory()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local function GetMinimapAngle()
    if not PoweredAuctionDB then return 225 end
    if not PoweredAuctionDB.minimapAngle then PoweredAuctionDB.minimapAngle = 225 end
    return PoweredAuctionDB.minimapAngle
end

local function SetMinimapAngle(angle)
    if not PoweredAuctionDB then return end
    PoweredAuctionDB.minimapAngle = angle
end

local function UpdateMinimapPosition()
    if not minimapButton then return end

    local angle = math.rad(GetMinimapAngle())
    local x = math.cos(angle) * PA_MINIMAP_RADIUS
    local y = math.sin(angle) * PA_MINIMAP_RADIUS

    local cx, cy = Minimap:GetCenter()
    local px, py = UIParent:GetCenter()
    cx = cx - px
    cy = cy - py

    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function CreateContextMenu()
    if contextMenu then return contextMenu end

    local menu = CreateFrame("Frame", "PoweredAuctionContextMenu", UIParent)
    menu:SetWidth(160)
    menu:SetHeight(160)
    menu:SetFrameStrata("TOOLTIP")
    menu:EnableMouse(true)
    menu:SetMovable(false)

    menu:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })

    menu:SetPoint("CENTER", UIParent, "CENTER")

    local buttons = {}

    local function AddMenuButton(text, callback)
        local btn = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
        btn:SetWidth(140)
        btn:SetHeight(24)
        btn:SetText(text)

        if #buttons == 0 then
            btn:SetPoint("TOP", menu, "TOP", 0, -10)
        else
            btn:SetPoint("TOP", buttons[#buttons], "BOTTOM", 0, -4)
        end

        btn:SetScript("OnClick", function()
            menu:Hide()
            callback()
        end)

        table.insert(buttons, btn)
    end

    AddMenuButton("Toggle Panel", function()
        PoweredAuction_ToggleUI()
    end)

    AddMenuButton("Scan AH", function()
        PoweredAuction_StartScan()
    end)

    AddMenuButton("Watch List", function()
        PoweredAuction_ListWatchList()
    end)

    AddMenuButton("Clear History", function()
        StaticPopup_Show("POWEREDAUCTION_CLEAR")
    end)

    AddMenuButton("Close", function()
        menu:Hide()
    end)

    local totalHeight = 20 + (#buttons * 28)
    menu:SetHeight(totalHeight)

    contextMenu = menu

    return menu
end

local function CreateMinimapButton()
    if minimapButton then return end

    local btn = CreateFrame("Button", "PoweredAuctionMinimapButton", Minimap)
    btn:SetWidth(32)
    btn:SetHeight(32)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local overlay = btn:CreateTexture("PoweredAuctionMinimapButtonOverlay", "OVERLAY")
    overlay:SetWidth(53)
    overlay:SetHeight(53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)

    local icon = btn:CreateTexture("PoweredAuctionMinimapButtonIcon", "BACKGROUND")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_02")
    icon:SetPoint("CENTER", btn, "CENTER", 0, 0)

    btn:SetScript("OnClick", function()
        if arg1 == "LeftButton" then
            PoweredAuction_ToggleUI()
        elseif arg1 == "RightButton" then
            local menu = CreateContextMenu()
            if menu:IsVisible() then
                menu:Hide()
            else
                local mx, my = GetCursorPosition()
                local scale = UIParent:GetScale()
                mx = mx / scale
                my = my / scale
                menu:ClearAllPoints()
                menu:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", mx, my)
                menu:Show()
            end
        end
    end)

    btn:SetScript("OnDragStart", function()
        this:LockHighlight()
        this.isDragging = true
    end)

    btn:SetScript("OnDragStop", function()
        this:UnlockHighlight()
        this.isDragging = false

        local mx, my = GetCursorPosition()
        local scale = Minimap:GetScale()
        mx = mx / scale
        my = my / scale

        local cx, cy = Minimap:GetCenter()
        cx = cx * scale
        cy = cy * scale

        local angle = math.deg(math.atan2(my - cy, mx - cx))
        if angle < 0 then angle = angle + 360 end
        SetMinimapAngle(angle)
        UpdateMinimapPosition()
    end)

    btn:SetScript("OnUpdate", function()
        if this.isDragging then
            local mx, my = GetCursorPosition()
            local scale = Minimap:GetScale()
            mx = mx / scale
            my = my / scale

            local cx, cy = Minimap:GetCenter()
            local angle = math.deg(math.atan2(my - cy, mx - cx))
            if angle < 0 then angle = angle + 360 end
            SetMinimapAngle(angle)
            UpdateMinimapPosition()
        end
    end)

    btn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("PoweredAuction")
        GameTooltip:AddLine("Left-click: Toggle panel", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Context menu", 1, 1, 1)
        GameTooltip:AddLine("Drag: Move button", 1, 1, 1)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    minimapButton = btn
    UpdateMinimapPosition()
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("VARIABLES_LOADED")
initFrame:SetScript("OnEvent", function()
    CreateMinimapButton()
    this:UnregisterEvent("VARIABLES_LOADED")
end)

-- update SavedVariables declaration to include minimapAngle
local origInitDB = PoweredAuction_InitDB
PoweredAuction_InitDB = function()
    origInitDB()
    if not PoweredAuctionDB.minimapAngle then
        PoweredAuctionDB.minimapAngle = 225
    end
end
