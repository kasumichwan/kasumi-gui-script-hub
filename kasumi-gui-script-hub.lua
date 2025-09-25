--[[ 
  Script Library (ToS-friendly)
  - Minimal, draggable, minimizable UI
  - Search by title and game name (+ numeric IDs)
  - Category dropdown (auto-built from entries)
  - Responsive layout for phone/tablet/PC (no overlapping)
  - Details popup (no code) with "Open Link" (fallback to copy link)
  - Hover/tap description preview still supported

  Note: Intended for your own legitimate snippets/resources. Does not provide or run cheats.
]]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Studio-only clipboard convenience
local StudioService = nil
pcall(function() StudioService = game:GetService("StudioService") end)

-- CONFIG --------------------------------------------------------------

local Config = {
    Title = "Kasumi GUI Script Hub",
    Theme = {
        Bg = Color3.fromRGB(18, 18, 20),
        Panel = Color3.fromRGB(26, 26, 29),
        Stroke = Color3.fromRGB(60, 60, 65),
        Text = Color3.fromRGB(235, 235, 240),
        SubtleText = Color3.fromRGB(200, 200, 210),
        Accent = Color3.fromRGB(0, 170, 255),
        Button = Color3.fromRGB(40, 40, 45),
        ButtonHover = Color3.fromRGB(55, 55, 60),
        Tooltip = Color3.fromRGB(35, 35, 40),
    },
    Window = {
        StartPosition = UDim2.fromOffset(24, 120),
        BaseSize = Vector2.new(420, 380), -- baseline; actual size is responsive
        TitleBarHeight = 32,
        Padding = 8,
        ItemHeight = 48, -- wide mode
        ItemHeightCompact = 74, -- narrow mode (buttons wrap to new line)
    },
}

-- SAMPLE ENTRIES ------------------------------------------------------
-- Add/replace items. Fields: title, description, url?, category, gameName, placeIds, universeIds.
local Entries = {
    {
        title = "Instant Case Opening + Auto Clicker",
        gameName = "Case Rolling RNG",
        category = "Keyless",
        description = "- Set the animation speed to 1000 or higher for instant open\n- Drag the red dot to the reroll button\n- Adjust the click interval if needed\n- On the auto clicker and enjoy grinding!!\n\nCreated by Kasumi.",
        url = "https://workink.net/24Rm/caseopeningsimulatorscript",
    },
    {
        title = "KEYLESS BEST SCRIPT VOIDWARE",
        gameName = "99 Nights In The Forest",
        category = "Keyless",
        description = [[The best script I used for now with all the features all you need including kill auro, auto eat, player speed and more to reach 100 days
+Reveal Map 🗺️
+ Teleport All Trees 🌳
+ Teleport All BIG Trees 🌲
+ Teleport All Chests 🎁
+ Teleport Entities (Wolves, Bears, Aliens, etc.) 🐺
+ Freeze/Unfreeze Entities ❄️
+ Auto Pickup Flowers & Gold Stacks 💐💰
+ Plant Saplings in Circle 🌱
+ Build Log Walls in Circle 🏯
+ Cleanup Logs 🪵
+ Unload Script 🗑️
+ Walk Speed Adjustment 🚶
+ Speed Toggle (with Keybind) ⚡
+ Noclip (with Keybind) 🚫
+ Infinite Jump 🦘
+ FOV Adjustment 👁️
+ Anti AFK 🕒
+ Player ESP ❤️
+ ESP Highlight Toggle 🌟
+ Show Distance on ESP 📏
+ ESP Fill Transparency Slider 🌫️
+ ESP Outline Transparency Slider 🖼️
+ ESP Text Size Slider 🔠
+ Fullbright Toggle ☀️
+ Remove Fog 🌫️
+ Remove Sky 🌌
+ Low GFX Mode ⚙️
+ Show Coordinates 📍
+ Instant Interact 🚀
+ Open Keybind Menu 🎹
+ Custom Cursor Toggle 🖱️
+ Menu Keybind Customization 🔧
+ Theme Management 🎨
+ Save Configuration 💾
Features:

bring all logs
fuel esp
reveal map
teleport all trees
teleport all entities]],
        url = "https://workink.net/24Rm/rpeff9hw",
    },
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScriptLibraryUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local function tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function contains(t, value)
    for _, v in ipairs(t) do
        if v == value then return true end
    end
    return false
end

local function anyContains(t, predicate)
    if not t then return false end
    for _, v in ipairs(t) do
        if predicate(v) then return true end
    end
    return false
end

-- Active filters
local State = {
    Search = "",
    Category = "All",
    IsNarrow = false, -- responsive flag
}

-- THEME HELPERS -------------------------------------------------------

local function create(className, props, children)
    local inst = Instance.new(className)
    if props then
        for k, v in pairs(props) do inst[k] = v end
    end
    if children then
        for _, child in ipairs(children) do child.Parent = inst end
    end
    return inst
end

local function hookHover(btn)
    if not btn:IsA("GuiButton") then return end
    btn.MouseEnter:Connect(function()
        tween(btn, TweenInfo.new(0.08), {BackgroundColor3 = Config.Theme.ButtonHover})
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, TweenInfo.new(0.12), {BackgroundColor3 = Config.Theme.Button})
    end)
end

-- WINDOW --------------------------------------------------------------

local window = create("Frame", {
    Name = "Window",
    BackgroundColor3 = Config.Theme.Bg,
    BorderSizePixel = 0,
    Active = true,
    Position = Config.Window.StartPosition,
}, {
    create("UICorner", { CornerRadius = UDim.new(0, 8) }),
    create("UIStroke", { Color = Config.Theme.Stroke, Thickness = 1 }),
})
window.Parent = screenGui

local titleBar = create("Frame", {
    Name = "TitleBar",
    Size = UDim2.new(1, 0, 0, Config.Window.TitleBarHeight),
    BackgroundColor3 = Config.Theme.Panel,
    BorderSizePixel = 0,
}, {
    create("UICorner", { CornerRadius = UDim.new(0, 8) }),
})
titleBar.Parent = window

local titleLabel = create("TextLabel", {
    Name = "Title",
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -110, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    Font = Enum.Font.GothamMedium,
    Text = Config.Title,
    TextSize = 14,
    TextColor3 = Config.Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
})
titleLabel.Parent = titleBar

local btnClose = create("TextButton", {
    Name = "Close",
    Size = UDim2.fromOffset(28, 24),
    Position = UDim2.new(1, -30, 0, 4),
    BackgroundColor3 = Config.Theme.Button,
    Text = "×",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Config.Theme.Text,
    AutoButtonColor = false,
})
btnClose.Parent = titleBar
hookHover(btnClose)

local btnMin = create("TextButton", {
    Name = "Minimize",
    Size = UDim2.fromOffset(28, 24),
    Position = UDim2.new(1, -62, 0, 4),
    BackgroundColor3 = Config.Theme.Button,
    Text = "–",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Config.Theme.Text,
    AutoButtonColor = false,
})
btnMin.Parent = titleBar
hookHover(btnMin)

-- HELP BUTTON (NEW)
local btnHelp = create("TextButton", {
    Name = "Help",
    Size = UDim2.fromOffset(28, 24),
    Position = UDim2.new(1, -94, 0, 4),
    BackgroundColor3 = Config.Theme.Button,
    Text = "?",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Config.Theme.Text,
    AutoButtonColor = false,
})
btnHelp.Parent = titleBar
hookHover(btnHelp)

-- CONTENT AREA (toolbar + list) --------------------------------------

local content = create("Frame", {
    Name = "Content",
    BackgroundTransparency = 1,
})
content.Parent = window

-- Toolbar (2 rows)
local toolbar = create("Frame", {
    Name = "Toolbar",
    BackgroundTransparency = 1,
})
toolbar.Parent = content

local toolbarRow1 = create("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 36),
})
toolbarRow1.Parent = toolbar

local searchBox = create("TextBox", {
    PlaceholderText = "Search title or game…",
    ClearTextOnFocus = false,
    BackgroundColor3 = Config.Theme.Panel,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 1, 0),
    Font = Enum.Font.Gotham,
    Text = "",
    TextSize = 14,
    TextColor3 = Config.Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
}, {
    create("UICorner", { CornerRadius = UDim.new(0, 6) }),
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    }),
    create("UIStroke", { Color = Config.Theme.Stroke, Thickness = 1 }),
})
searchBox.Parent = toolbarRow1

local toolbarRow2 = create("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 36),
})
toolbarRow2.Parent = toolbar

local categoryBtn = create("TextButton", {
    Name = "CategoryButton",
    BackgroundColor3 = Config.Theme.Panel,
    BorderSizePixel = 0,
    Size = UDim2.fromOffset(160, 32),
    Text = "Category: All ▾",
    Font = Enum.Font.Gotham,
    TextSize = 13,
    TextColor3 = Config.Theme.Text,
    AutoButtonColor = false,
}, {
    create("UICorner", { CornerRadius = UDim.new(0, 6) }),
    create("UIStroke", { Color = Config.Theme.Stroke, Thickness = 1 }),
})
categoryBtn.Parent = toolbarRow2
hookHover(categoryBtn)

-- Position category button
categoryBtn.Position = UDim2.new(0, 0, 0, 2)

-- Category dropdown menu (overlay)
local categoryMenu = create("Frame", {
    Name = "CategoryMenu",
    BackgroundColor3 = Config.Theme.Panel,
    BorderSizePixel = 0,
    Size = UDim2.fromOffset(200, 10), -- auto height
    Visible = false,
    ZIndex = 12,
}, {
    create("UICorner", { CornerRadius = UDim.new(0, 8) }),
    create("UIStroke", { Color = Config.Theme.Stroke, Thickness = 1 }),
})
categoryMenu.Parent = screenGui

local catScroll = create("ScrollingFrame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -12, 1, -12),
    Position = UDim2.fromOffset(6, 6),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 6,
})
catScroll.Parent = categoryMenu

local catLayout = create("UIListLayout", {
    SortOrder = Enum.SortOrder.Name,
    Padding = UDim.new(0, 6),
})
catLayout.Parent = catScroll

-- List container
local list = create("ScrollingFrame", {
    Name = "List",
    BackgroundColor3 = Config.Theme.Panel,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 6,
}, {
    create("UICorner", { CornerRadius = UDim.new(0, 8) }),
    create("UIStroke", { Color = Config.Theme.Stroke, Thickness = 1 }),
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
    }),
})
list.Parent = content

local layout = create("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
})
layout.Parent = list

-- Tooltip (kept for quick preview on hover)


-- Copy panel (fallback for links)
local copyPanel = create("Frame", {
    Name = "CopyPanel",
    BackgroundColor3 = Config.Theme.Panel,
    BorderSizePixel = 0,
    Size = UDim2.fromOffset(420, 160),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Visible = false,
    ZIndex = 14,
}, {
    create("UICorner", { CornerRadius = UDim.new(0, 10) }),
    create("UIStroke", { Color = Config.Theme.Stroke, Thickness = 1 }),
})
copyPanel.Parent = screenGui

local copyTitle = create("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -16, 0, 22),
    Position = UDim2.new(0, 8, 0, 8),
    Text = "Copy",
    Font = Enum.Font.GothamMedium,
    TextSize = 14,
    TextColor3 = Config.Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
})
copyTitle.Parent = copyPanel

local copyBox = create("TextBox", {
    BackgroundColor3 = Config.Theme.Bg,
    BorderSizePixel = 0,
    Size = UDim2.new(1, -16, 1, -70),
    Position = UDim2.new(0, 8, 0, 36),
    ClearTextOnFocus = false,
    Text = "",
    MultiLine = true,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    Font = Enum.Font.Code,
    TextSize = 13,
    TextColor3 = Config.Theme.Text,
}, {
    create("UICorner", { CornerRadius = UDim.new(0, 6) }),
    create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 6) }),
    create("UIStroke", { Color = Config.Theme.Stroke, Thickness = 1 }),
})
copyBox.Parent = copyPanel

local copyHint = create("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -16, 0, 18),
    Position = UDim2.new(0, 8, 1, -28),
    Text = "Tip: Press Ctrl+C (PC) or long-press to copy (mobile).",
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextColor3 = Config.Theme.SubtleText,
    TextXAlignment = Enum.TextXAlignment.Left,
})
copyHint.Parent = copyPanel

local copyBtnBar = create("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -16, 0, 28),
    Position = UDim2.new(0, 8, 1, -56),
})
copyBtnBar.Parent = copyPanel

local btnSelectAll = create("TextButton", {
    Size = UDim2.fromOffset(100, 28),
    BackgroundColor3 = Config.Theme.Button,
    Text = "Select All",
    Font = Enum.Font.Gotham,
    TextSize = 13,
    TextColor3 = Config.Theme.Text,
    AutoButtonColor = false,
})
btnSelectAll.Parent = copyBtnBar
hookHover(btnSelectAll)

local btnClosePanel = create("TextButton", {
    Size = UDim2.fromOffset(100, 28),
    Position = UDim2.new(1, -100, 0, 0),
    BackgroundColor3 = Config.Theme.Button,
    Text = "Close",
    Font = Enum.Font.Gotham,
    TextSize = 13,
    TextColor3 = Config.Theme.Text,
    AutoButtonColor = false,
})
btnClosePanel.Parent = copyBtnBar
hookHover(btnClosePanel)

-- Toast
local toast = create("TextLabel", {
    BackgroundColor3 = Config.Theme.Tooltip,
    BorderSizePixel = 0,
    Size = UDim2.fromOffset(360, 26),
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -12),
    Text = "",
    Font = Enum.Font.Gotham,
    TextSize = 13,
    TextColor3 = Config.Theme.Text,
    Visible = false,
    ZIndex = 16,
})
toast.Parent = screenGui

local function showToast(msg, dur)
    toast.Text = msg
    toast.Visible = true
    toast.BackgroundTransparency = 1
    toast.TextTransparency = 1
    tween(toast, TweenInfo.new(0.18), {BackgroundTransparency = 0})
    tween(toast, TweenInfo.new(0.18), {TextTransparency = 0})
    task.delay(dur or 2.0, function()
        tween(toast, TweenInfo.new(0.2), {BackgroundTransparency = 1, TextTransparency = 1})
        task.wait(0.22)
        toast.Visible = false
    end)
end

-- DETAILS POPUP (no code; link-only) ---------------------------------

local detailsOverlay = create("Frame", {
    Name = "DetailsOverlay",
    BackgroundColor3 = Color3.new(0,0,0),
    BackgroundTransparency = 1,
    Size = UDim2.new(1,0,1,0),
    Visible = false,
    ZIndex = 19,
})
detailsOverlay.Parent = screenGui

local detailsWindow = create("Frame", {
    Name = "DetailsWindow",
    BackgroundColor3 = Config.Theme.Bg,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5,0.5),
    Position = UDim2.new(0.5,0,0.5,0),
    Size = UDim2.fromOffset(480, 320),
}, {
    create("UICorner", { CornerRadius = UDim.new(0, 10) }),
    create("UIStroke", { Color = Config.Theme.Stroke, Thickness = 1 }),
})
detailsWindow.Parent = detailsOverlay

local detailsTitle = create("TextLabel", {
    Name = "DetailsTitle",
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -50, 0, 40),
    Position = UDim2.fromOffset(16, 0),
    Font = Enum.Font.GothamBold,
    Text = "Script Details",
    TextSize = 16,
    TextColor3 = Config.Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
})
detailsTitle.Parent = detailsWindow

local detailsGame = create("TextLabel", {
    Name = "DetailsGame",
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -32, 0, 20),
    Position = UDim2.fromOffset(16, 40),
    Font = Enum.Font.Gotham,
    Text = "Game: Any",
    TextSize = 13,
    TextColor3 = Config.Theme.SubtleText,
    TextXAlignment = Enum.TextXAlignment.Left,
})
detailsGame.Parent = detailsWindow

local detailsBtnClose = create("TextButton", {
    Name = "DetailsClose",
    Size = UDim2.fromOffset(32, 28),
    Position = UDim2.new(1, -40, 0, 6),
    BackgroundColor3 = Config.Theme.Button,
    Text = "×",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Config.Theme.Text,
    AutoButtonColor = false,
}, {
    create("UICorner", { CornerRadius = UDim.new(0, 6) }),
})
detailsBtnClose.Parent = detailsWindow
hookHover(detailsBtnClose)

local detailsDescScroll = create("ScrollingFrame", {
    Name = "Description",
    BackgroundColor3 = Config.Theme.Panel,
    BorderSizePixel = 0,
    Size = UDim2.new(1,-32,1,-122),
    Position = UDim2.fromOffset(16,64),
    ScrollBarThickness = 6,
    AutomaticCanvasSize = Enum.AutomaticSize.Y, -- Let the frame manage its height
    ScrollingDirection = Enum.ScrollingDirection.Y, -- Only allow vertical scrolling
}, {
    create("UICorner", { CornerRadius = UDim.new(0, 8) }),
    create("UIStroke", { Color = Config.Theme.Stroke, Thickness = 1 }),
    create("UIPadding", { -- Add some space around the text
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
    })
})
detailsDescScroll.Parent = detailsWindow

local detailsDesc = create("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 0), -- Full width, auto height
    Position = UDim2.fromOffset(0,0),
    Font = Enum.Font.Gotham,
    Text = "",
    TextSize = 14,
    TextColor3 = Config.Theme.Text,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    AutomaticSize = Enum.AutomaticSize.Y,
})
detailsDesc.Parent = detailsDescScroll

local detailsBtnLink = create("TextButton", {
    Name = "DetailsLink",
    Visible = true,
    Size = UDim2.new(1, -32, 0, 36),
    Position = UDim2.new(0,16,1,-48),
    BackgroundColor3 = Config.Theme.Button,
    Text = "Open Link",
    Font = Enum.Font.GothamMedium,
    TextSize = 14,
    TextColor3 = Config.Theme.Text,
    AutoButtonColor = false,
}, {
    create("UICorner", { CornerRadius = UDim.new(0, 8) }),
})
detailsBtnLink.Parent = detailsWindow
hookHover(detailsBtnLink)

local currentDetailsURL = nil
local detailsLinkConn -- to avoid stacking connections

local function tryOpenURL(url)
    local ok = pcall(function() StarterGui:SetCore("OpenUrl", url) end)
    if ok then
        showToast("Opening link in your browser…", 1.5)
    else
        -- Fall back to copy panel with the URL
        copyTitle.Text = "Open Link (Copy)"
        copyBox.Text = url
        copyPanel.Visible = true
        copyPanel.ZIndex = 20 -- Topmost
        copyBox:CaptureFocus()
        copyBox.SelectionStart = 1
        copyBox.CursorPosition = #copyBox.Text + 1
        showToast("Opening blocked. URL ready to copy.", 2.0)
    end
end

local function updateDetailsSizeForViewport()
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local w = math.clamp(math.floor(vp.X * 0.9), 300, 560)
    local h = math.clamp(math.floor(vp.Y * 0.7), 240, 460)
    detailsWindow.Size = UDim2.fromOffset(w, h)
end

local function showDetails(item)
    detailsTitle.Text = item.title or "Details"
    detailsGame.Text = "Game: " .. (item.gameName or "Any")
    detailsDesc.Text = item.description or "No description available."
    detailsDescScroll.CanvasPosition = Vector2.new(0, 0) -- reset scroll to top

    currentDetailsURL = (item.url and item.url ~= "" and item.url) or nil
    if detailsLinkConn then detailsLinkConn:Disconnect() detailsLinkConn = nil end

    if currentDetailsURL then
        detailsBtnLink.Active = true
        detailsBtnLink.AutoButtonColor = true
        detailsBtnLink.Text = "Open Link"
        detailsLinkConn = detailsBtnLink.MouseButton1Click:Connect(function()
            tryOpenURL(currentDetailsURL)
        end)
    else
        -- No URL provided
        detailsBtnLink.Active = false
        detailsBtnLink.AutoButtonColor = false
        detailsBtnLink.Text = "No Link Provided"
    end

    updateDetailsSizeForViewport()
    detailsOverlay.Visible = true
    detailsOverlay.BackgroundTransparency = 1
    tween(detailsOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 0.4})
end

local function hideDetails()
    tween(detailsOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 1})
    task.delay(0.2, function()
        detailsOverlay.Visible = false
    end)
end

detailsBtnClose.MouseButton1Click:Connect(hideDetails)
detailsOverlay.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        -- close if click outside the detailsWindow
        local pos = Vector2.new(input.Position.X, input.Position.Y)
        local wpos, wsize = detailsWindow.AbsolutePosition, detailsWindow.AbsoluteSize
        local inside = pos.X >= wpos.X and pos.X <= wpos.X + wsize.X and pos.Y >= wpos.Y and pos.Y <= wpos.Y + wsize.Y
        if not inside then hideDetails() end
    end
end)

-- COPY HELPERS --------------------------------------------------------

local function openCopyPanel(title, text)
    copyTitle.Text = title or "Copy"
    copyBox.Text = text or ""
    copyPanel.Visible = true
    copyPanel.ZIndex = 20 -- Ensure topmost
    copyBox:CaptureFocus()
    copyBox.SelectionStart = 1
    copyBox.CursorPosition = #copyBox.Text + 1
end

btnSelectAll.MouseButton1Click:Connect(function()
    copyBox:CaptureFocus()
    copyBox.SelectionStart = 1
    copyBox.CursorPosition = #copyBox.Text + 1
end)

btnClosePanel.MouseButton1Click:Connect(function()
    copyPanel.Visible = false
end)

local function tryCopy(text, titleForPanel)
    if StudioService then
        local ok = pcall(function() StudioService:CopyToClipboard(text) end)
        if ok then
            showToast("Copied to clipboard (Studio).", 1.5)
            return
        end
    end
    openCopyPanel(titleForPanel or "Copy", text)
    showToast("Text selected. Use Ctrl+C (PC) or long-press to copy.", 2.2)
end

-- FILTERING / CATEGORIES ---------------------------------------------

local function isNumeric(str)
    return str:match("^%d+$") ~= nil
end

local function matchesCategory(item, category)
    if category == "All" then return true end
    if item.category and item.category == category then return true end
    return false
end

local function matchesSearch(item, query)
    query = query:lower()
    if query == "" then return true end
    local title = (item.title or ""):lower()
    local gameName = (item.gameName or ""):lower()
    if title:find(query, 1, true) or gameName:find(query, 1, true) then
        return true
    end
    if isNumeric(query) then
        local qnum = tonumber(query)
        if item.placeIds and contains(item.placeIds, qnum) then return true end
        if item.universeIds and contains(item.universeIds, qnum) then return true end
    end
    return false
end

local function collectCategories()
    local set = {}
    local order = {}
    set["All"] = true
    table.insert(order, "All")
    for _, item in ipairs(Entries) do
        if item.category and not set[item.category] then
            set[item.category] = true
            table.insert(order, item.category)
        end
    end
    return order
end

-- DYNAMIC CATEGORY MENU (rebuilds on open)
local function buildCategoryMenu()
    catScroll:ClearAllChildren()
    local layout2 = create("UIListLayout", {
        SortOrder = Enum.SortOrder.Name,
        Padding = UDim.new(0, 6),
    })
    layout2.Parent = catScroll

    local cats = collectCategories()
    for _, cat in ipairs(cats) do
        local capturedCat = cat -- Store category in a local variable to ensure it's captured correctly
        
        local b = create("TextButton", {
            Name = "Cat_" .. cat,
            BackgroundColor3 = Config.Theme.Button,
            Text = cat,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = Config.Theme.Text,
            AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, 28),
        }, {
            create("UICorner", { CornerRadius = UDim.new(0, 6) }),
        })
        hookHover(b)
        b:SetAttribute("category", capturedCat) -- Store category as an attribute
        b.Parent = catScroll
        
        b.MouseButton1Click:Connect(function()
            -- Use the captured category
            State.Category = capturedCat
            categoryBtn.Text = "Category: " .. capturedCat .. " ▾"
            categoryMenu.Visible = false
            -- Don't call rebuildList() here, it will be called by the second handler
        end)
    end

    task.wait()
    catScroll.CanvasSize = UDim2.fromOffset(0, layout2.AbsoluteContentSize.Y)
    categoryMenu.Size = UDim2.fromOffset(200, math.min(layout2.AbsoluteContentSize.Y + 12, 220))
end
-- LIST BUILDING -------------------------------------------------------

local function makeButton(text)
    local b = create("TextButton", {
        BackgroundColor3 = Config.Theme.Button,
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Config.Theme.Text,
        AutoButtonColor = false,
        Size = UDim2.fromOffset(80, 28),
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 6) }),
    })
    hookHover(b)
    return b
end

local function clearList()
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("Frame") and child.Name:match("^Item_") then
            child:Destroy()
        end
    end
end

local function addItem(item, index)
    local rowHeight = State.IsNarrow and Config.Window.ItemHeightCompact or Config.Window.ItemHeight
    local row = create("Frame", {
        Name = "Item_" .. index,
        BackgroundColor3 = Config.Theme.Bg,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, rowHeight),
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 6) }),
        create("UIStroke", { Color = Config.Theme.Stroke, Thickness = 1 }),
    })
    row.Parent = list

    local title = create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = (item.title or "Untitled") .. ((item.gameName and item.gameName ~= "") and ("  •  " .. item.gameName) or ""),
        TextSize = 14,
        TextColor3 = Config.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    title.Parent = row

    local buttons = {}

    -- Open Link (if URL exists)
    

    -- Details popup (always shown)
    local btnDetails = makeButton("Details")
    table.insert(buttons, btnDetails)
    btnDetails.MouseButton1Click:Connect(function()
        showDetails(item)
    end)

    -- Buttons bar
    local btnBar = create("Frame", { BackgroundTransparency = 1 })
    btnBar.Parent = row
    local hLayout = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
    })
    hLayout.Parent = btnBar

    for _, b in ipairs(buttons) do
        b.Parent = btnBar
    end

    -- Optional quick preview tooltip on hover (PC)
    if item.description and item.description ~= "" then
        row.MouseEnter:Connect(function()
            if UserInputService.TouchEnabled then return end
            local mousePos = UserInputService:GetMouseLocation()
            showTooltip(item.description, UDim2.fromOffset(mousePos.X + 12, mousePos.Y + 12))
        end)
        row.MouseLeave:Connect(hideTooltip)
    end

    -- Responsive layout
    if State.IsNarrow then
        -- Two-line layout: title on top, buttons on bottom
        title.Position = UDim2.fromOffset(10, 6)
        title.Size = UDim2.new(1, -20, 0, 28)

        btnBar.Position = UDim2.new(0, 10, 1, -34)
        btnBar.Size = UDim2.new(1, -20, 0, 28)
    else
        -- Single line: title left, buttons right
        btnBar.Position = UDim2.new(1, - ( (#buttons * 80) + 6 * (#buttons - 1) + 10 ), 0.5, -14)
        btnBar.Size = UDim2.fromOffset((#buttons * 80) + 6 * (#buttons - 1), 28)

        title.Position = UDim2.fromOffset(10, 0)
        local rightReserve = btnBar.Size.X.Offset + 20
        title.Size = UDim2.new(1, - (rightReserve + 10), 1, 0)
    end
end

local function rebuildList()
    clearList()
    local shown = 0
    for i, item in ipairs(Entries) do
        local catOK = matchesCategory(item, State.Category)
        local searchOK = matchesSearch(item, State.Search)
        if catOK and searchOK then
            addItem(item, i)
            shown += 1
        end
    end
    task.wait()
    list.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 16)
end

-- SEARCH / CATEGORY HANDLERS -----------------------------------------

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    State.Search = searchBox.Text
    rebuildList()
end)

-- Category button behaviour
local function positionCategoryMenu()
    local abs = categoryBtn.AbsolutePosition
    local size = categoryBtn.AbsoluteSize
    categoryMenu.Position = UDim2.fromOffset(abs.X, abs.Y + size.Y + 6)
end

categoryBtn.MouseButton1Click:Connect(function()
    if not categoryMenu.Visible then
        buildCategoryMenu()
        positionCategoryMenu()
        categoryMenu.Visible = true
    else
        categoryMenu.Visible = false
    end
end)

-- Close category menu when clicking elsewhere
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if categoryMenu.Visible then
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local pos = (input.Position and input.Position) or Vector3.new()
            local p2d = Vector2.new(pos.X, pos.Y)
            local menuPos = categoryMenu.AbsolutePosition
            local menuSize = categoryMenu.AbsoluteSize
            local inside = p2d.X >= menuPos.X and p2d.X <= menuPos.X + menuSize.X and p2d.Y >= menuPos.Y and p2d.Y <= menuPos.Y + menuSize.Y
            local btnPos = categoryBtn.AbsolutePosition
            local btnSize = categoryBtn.AbsoluteSize
            local onBtn = p2d.X >= btnPos.X and p2d.X <= btnPos.X + btnSize.X and p2d.Y >= btnPos.Y and p2d.Y <= btnPos.Y + btnSize.Y
            if not inside and not onBtn then
                categoryMenu.Visible = false
            end
        end
    end
end)

-- LAYOUT / RESPONSIVE -------------------------------------------------

local minimized = false
local fullSizeY = Config.Window.BaseSize.Y

local function layoutContent()
    local pad = Config.Window.Padding
    content.Position = UDim2.fromOffset(pad, Config.Window.TitleBarHeight + pad)
    content.Size = UDim2.new(1, -pad*2, 1, -(Config.Window.TitleBarHeight + pad*2))

    toolbar.Position = UDim2.fromOffset(0, 0)
    toolbar.Size = UDim2.new(1, 0, 0, 78) -- two rows (36 + 36 + margins)

    toolbarRow1.Size = UDim2.new(1, 0, 0, 36)
    toolbarRow1.Position = UDim2.fromOffset(0, 0)
    searchBox.Size = UDim2.new(1, 0, 1, 0)
    searchBox.Position = UDim2.fromOffset(0, 0)

    toolbarRow2.Size = UDim2.new(1, 0, 0, 36)
    toolbarRow2.Position = UDim2.fromOffset(0, 42)

    list.Position = UDim2.fromOffset(0, 78 + 8)
    list.Size = UDim2.new(1, 0, 1, -(78 + 8))
end

local function clampWindowOnScreen()
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local pos = window.Position
    local x = math.clamp(pos.X.Offset, 0, math.max(0, vp.X - window.Size.X.Offset))
    local y = math.clamp(pos.Y.Offset, 0, math.max(0, vp.Y - window.Size.Y.Offset))
    window.Position = UDim2.fromOffset(x, y)
end

local function updateWindowSizeForViewport()
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local targetW = math.clamp(math.floor(vp.X * 0.92), 320, 560)
    local targetH = math.clamp(math.floor(vp.Y * 0.72), 280, 580)
    window.Size = UDim2.fromOffset(targetW, targetH)
    fullSizeY = targetH
    State.IsNarrow = (targetW < 520)
    layoutContent()
    clampWindowOnScreen()
    updateDetailsSizeForViewport()
end

-- window drag
do
    local dragging = false
    local dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        window.Position = UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
    end

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = window.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then update(input) end
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

btnMin.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        tween(window, TweenInfo.new(0.2), {Size = UDim2.fromOffset(window.Size.X.Offset, Config.Window.TitleBarHeight + Config.Window.Padding)})
        content.Visible = false
    else
        tween(window, TweenInfo.new(0.2), {Size = UDim2.fromOffset(window.Size.X.Offset, fullSizeY)})
        content.Visible = true
    end
end)

btnClose.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

updateWindowSizeForViewport()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        local wasNarrow = State.IsNarrow
        updateWindowSizeForViewport()
        if State.IsNarrow ~= wasNarrow then
            rebuildList()
        end
        if categoryMenu.Visible then positionCategoryMenu() end
    end)
end

-- HELP POPUP (DRAGGABLE) ----------------------------------------------

-- HELP POPUP (DRAGGABLE) ----------------------------------------------

-- HELP POPUP (DRAGGABLE, RELIABLE SCROLL) -----------------------------

-- Overlay
local helpOverlay = create("Frame", {
    Name = "HelpOverlay",
    BackgroundColor3 = Color3.new(0,0,0),
    BackgroundTransparency = 1,
    Size = UDim2.new(1,0,1,0),
    Visible = false,
    ZIndex = 45,
})
helpOverlay.Parent = screenGui

-- Window
local helpWindow = create("Frame", {
    Name = "HelpWindow",
    BackgroundColor3 = Config.Theme.Bg,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5,0.5),
    Position = UDim2.new(0.5,0,0.5,0),
    Size = UDim2.fromOffset(460, 320),
}, {
    create("UICorner", { CornerRadius = UDim.new(0, 10) }),
    create("UIStroke", { Color = Config.Theme.Stroke, Thickness = 1 }),
})
helpWindow.Parent = helpOverlay

-- Title bar
local helpTitle = create("TextLabel", {
    Name = "HelpTitle",
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -50, 0, 40),
    Position = UDim2.fromOffset(16, 0),
    Font = Enum.Font.GothamBold,
    Text = "Kasumi GUI Script Hub",
    TextSize = 16,
    TextColor3 = Config.Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
})
helpTitle.Parent = helpWindow

-- Close button
local helpBtnClose = create("TextButton", {
    Name = "HelpClose",
    Size = UDim2.fromOffset(32, 28),
    Position = UDim2.new(1, -40, 0, 6),
    BackgroundColor3 = Config.Theme.Button,
    Text = "×",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Config.Theme.Text,
    AutoButtonColor = false,
}, {
    create("UICorner", { CornerRadius = UDim.new(0, 6) }),
})
helpBtnClose.Parent = helpWindow
hookHover(helpBtnClose)

-- Scroller
local helpScroll = create("ScrollingFrame", {
    Name = "HelpScroll",
    BackgroundColor3 = Config.Theme.Panel,
    BorderSizePixel = 0,
    Size = UDim2.new(1,-32,1,-80),
    Position = UDim2.fromOffset(16,50),
    ScrollBarThickness = 6,
    Active = true,                                   -- drag-to-scroll on touch
    AutomaticCanvasSize = Enum.AutomaticSize.Y,      -- let scroller compute height
    ScrollingDirection = Enum.ScrollingDirection.Y,  -- vertical scroll only
}, {
    create("UICorner", { CornerRadius = UDim.new(0, 8) }),
    create("UIStroke", { Color = Config.Theme.Stroke, Thickness = 1 }),
})
helpScroll.Parent = helpWindow

-- Inner content container (important for reliable autosize)
local helpContent = create("Frame", {
    Name = "HelpContent",
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
}, {
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
    }),
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    }),
})
helpContent.Parent = helpScroll

-- The help text
local helpText = create("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 0),    -- fill width; height grows automatically
    AutomaticSize = Enum.AutomaticSize.Y,
    Font = Enum.Font.Gotham,
    Text = [[
Since this is still new, I need your help to suggest games that you want me to add. 
Just comment on any of my uploads in rscripts.net and I will gladly find the best scripts for you!

How to get the script?
Step 1: Copy and paste the link to your browser.
Step 2: Click "go to destination" wait for 10 seconds and click "continue with ads".
Step 3: Click again "go to destination" and wait the loading time to finish.
Step 4: Click the proceed button and follow the instructions.
- You should be redirected to pastebin.com, copy the script, execute and enjoy!
- Some scripts are not mine, all credits go to their respective owners.
    ]],
    TextSize = 14,
    TextColor3 = Config.Theme.Text,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    LayoutOrder = 1,
})
helpText.Parent = helpContent

-- Spacer so last line never sits flush with the bottom edge
local spacer = create("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 10),
    LayoutOrder = 2,
})
spacer.Parent = helpContent

-- Dragging (grab the title to move the window)
do
    local dragging, dragStart, startPos = false, nil, nil
    local function update(input)
        local delta = input.Position - dragStart
        helpWindow.Position = UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
    end
    helpTitle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = helpWindow.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    helpTitle.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
            update(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

-- Open/close handlers (expects a btnHelp button in your title bar)
btnHelp.MouseButton1Click:Connect(function()
    helpOverlay.Visible = not helpOverlay.Visible
    if helpOverlay.Visible then
        helpOverlay.BackgroundTransparency = 1
        tween(helpOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 0.4})
        helpScroll.CanvasPosition = Vector2.new(0, 0) -- reset to top
    else
        tween(helpOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 1})
        task.delay(0.2, function() helpOverlay.Visible = false end)
    end
end)

helpBtnClose.MouseButton1Click:Connect(function()
    helpOverlay.Visible = false
end)

-- Click outside to close
helpOverlay.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local pos = Vector2.new(input.Position.X, input.Position.Y)
        local wpos, wsize = helpWindow.AbsolutePosition, helpWindow.AbsoluteSize
        local inside = pos.X >= wpos.X and pos.X <= wpos.X + wsize.X and pos.Y >= wpos.Y and pos.Y <= wpos.Y + wsize.Y
        if not inside then helpOverlay.Visible = false end
    end
end)
-- INITIAL BUILD -------------------------------------------------------

layoutContent()
rebuildList()
buildCategoryMenu() -- prepare initial category list

-- PRESS EFFECTS
local function pressEffect(btn)
if not btn:IsA("GuiButton") then return end
  btn.MouseButton1Down:Connect(function() btn.BackgroundColor3 = Config.Theme.Accent end)
 btn.MouseButton1Up:Connect(function() btn.BackgroundColor3 = Config.Theme.Button end)
end
pressEffect(btnMin); pressEffect(btnClose); pressEffect(btnSelectAll); pressEffect(btnClosePanel)
pressEffect(categoryBtn); pressEffect(detailsBtnClose); pressEffect(detailsBtnLink); pressEffect(btnHelp); pressEffect(helpBtnClose)

-- Hook category selection to refresh list after pick
catScroll.ChildAdded:Connect(function(obj)
    if obj:IsA("GuiButton") then
        obj.MouseButton1Click:Connect(function()
            -- Ensure we're using the correct category value
            local selectedCat = obj:GetAttribute("category") or obj.Text
            if selectedCat then
                -- Update state again to be extra safe
                State.Category = selectedCat
                categoryBtn.Text = "Category: " .. selectedCat .. " ▾"
            end
            
            -- Allow a tiny delay for state to settle
            task.defer(rebuildList)
        end)
    end
end)
