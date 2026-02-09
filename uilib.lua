-- custom_simple_ui.lua
-- Minimal UILib-like API using Drawing (Matcha friendly)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer and LocalPlayer:GetMouse()

local function getMousePos()
    if not Mouse then
        return Vector2.new()
    end
    return Vector2.new(Mouse.X, Mouse.Y)
end

local function rectContains(pos, size, p)
    return p.X >= pos.X and p.X <= pos.X + size.X
       and p.Y >= pos.Y and p.Y <= pos.Y + size.Y
end

----------------------------------------------------------------
-- Drawing helpers
----------------------------------------------------------------

local function newRect(z)
    local d = Drawing.new("Square")
    d.Visible = true
    d.Filled = true
    d.Color = Color3.fromRGB(25, 25, 25)
    d.ZIndex = z or 0
    d.Thickness = 1
    return d
end

local function newText(z)
    local d = Drawing.new("Text")
    d.Visible = true
    d.Font = Drawing.Fonts.UI
    d.Size = 13
    d.Color = Color3.fromRGB(230, 230, 230)
    d.ZIndex = z or 0
    d.Center = false
    return d
end

----------------------------------------------------------------
-- UI object
----------------------------------------------------------------

local Menu = {}
Menu.__index = Menu

function Menu.new()
    local self = setmetatable({}, Menu)

    self.title = "Menu"
    self.size = Vector2.new(400, 260)
    self.position = Vector2.new(200, 200)
    self.tabs = {}
    self.openTab = nil
    self.dragging = false
    self.dragOffset = Vector2.new()
    self.running = true
    self.watermarkEnabled = false

    self.bg = newRect(1)
    self.border = newRect(2); self.border.Filled = false
    self.titleBar = newRect(3)
    self.titleText = newText(4)

    self.drawings = { self.bg, self.border, self.titleBar, self.titleText }

    -- layout constants
    self.tabHeight = 26
    self.headerHeight = 24
    self.padding = 8

    coroutine.wrap(function()
        self:MainLoop()
    end)()

    return self
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function Menu:SetMenuTitle(newTitle)
    self.title = newTitle or self.title
end

function Menu:SetMenuSize(newSize)
    self.size = newSize or self.size
end

function Menu:SetMenuPosition(newPos)
    self.position = newPos or self.position
end

function Menu:SetWatermarkEnabled(value)
    self.watermarkEnabled = not not value
end

function Menu:GetMenuSize()
    return self.size
end

function Menu:CenterMenu()
    local cam = workspace.CurrentCamera
    local view = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    self.position = Vector2.new(
        math.floor(view.X/2 - self.size.X/2),
        math.floor(view.Y/2 - self.size.Y/2)
    )
end

function Menu:Notification(text, time)
    print("[UI Notification]", text)
end

-- Tab / Section structure
function Menu:Tab(name)
    local tab = {
        name = name,
        sections = {}
    }
    self.tabs[#self.tabs + 1] = tab
    if not self.openTab then
        self.openTab = tab
    end

    local Section = {}
    Section.__index = Section

    function Section:Toggle(label, value, callback, unsafe, tooltip)
        local item = {
            type = "toggle",
            label = label,
            value = value or false,
            callback = callback,
            unsafe = unsafe or false,
            tooltip = tooltip
        }
        table.insert(self.items, item)
        return {
            Set = function(_, v)
                item.value = v
                if item.callback then item.callback(v) end
            end
        }
    end

    function Section:Slider(label, value, step, min, max, suffix, callback)
        local item = {
            type = "slider",
            label = label,
            value = value or min or 0,
            step = step or 1,
            min = min or 0,
            max = max or 100,
            suffix = suffix or "",
            callback = callback
        }
        table.insert(self.items, item)
        return {
            Set = function(_, v)
                item.value = v
                if item.callback then item.callback(v) end
            end
        }
    end

    function Section:Dropdown(label, value, choices, multi, callback)
        local item = {
            type = "dropdown",
            label = label,
            value = value or {},
            choices = choices or {},
            multi = multi or false,
            callback = callback,
            open = false
        }
        table.insert(self.items, item)
        return {
            Set = function(_, v)
                item.value = v
                if item.callback then item.callback(v) end
            end,
            UpdateChoices = function(_, newChoices)
                item.choices = newChoices or {}
            end
        }
    end

    function Section:Button(label, callback)
        local item = {
            type = "button",
            label = label,
            callback = callback
        }
        table.insert(self.items, item)
        return {}
    end

    function Section:Textbox(label, value, callback)
        local item = {
            type = "textbox",
            label = label,
            value = value or "",
            callback = callback,
            active = false
        }
        table.insert(self.items, item)
        return {
            Set = function(_, v)
                item.value = v
                if item.callback then item.callback(v) end
            end
        }
    end

    function tab:Section(sectionName)
        local section = {
            name = sectionName,
            items = {}
        }
        table.insert(self.sections, section)
        return setmetatable(section, Section)
    end

    return tab
end

function Menu:CreateSettingsTab(customName)
    local tab = self:Tab(customName or "Settings")
    local sec = tab:Section("Info")
    sec:Button("Unload", function()
        self:Unload()
    end)
    return tab, sec, sec
end

function Menu:Unload()
    self.running = false
    for _, d in ipairs(self.drawings) do
        pcall(function() d:Remove() end)
    end
    self.drawings = {}
    setrobloxinput(true)
end

----------------------------------------------------------------
-- Internal drawing + input
----------------------------------------------------------------

function Menu:Draw()
    local pos = self.position
    local size = self.size

    -- main rects
    self.bg.Position = pos
    self.bg.Size = size
    self.bg.Color = Color3.fromRGB(20, 20, 20)

    self.border.Position = pos
    self.border.Size = size
    self.border.Color = Color3.fromRGB(60, 60, 60)

    self.titleBar.Position = pos
    self.titleBar.Size = Vector2.new(size.X, self.headerHeight)
    self.titleBar.Color = Color3.fromRGB(30, 30, 30)

    self.titleText.Text = self.title
    self.titleText.Position = pos + Vector2.new(self.padding, 4)

    -- tabs
    local tabY = pos.Y + self.headerHeight
    local tabX = pos.X + self.padding
    local tabW = 70
    local tabH = self.tabHeight

    for i, tab in ipairs(self.tabs) do
        local active = (tab == self.openTab)
        local tRect = newRect(3)
        tRect.Position = Vector2.new(tabX + (i-1)*(tabW+4), tabY)
        tRect.Size = Vector2.new(tabW, tabH)
        tRect.Color = active and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(35, 35, 35)
        table.insert(self.drawings, tRect)

        local tText = newText(4)
        tText.Text = tab.name
        tText.Position = tRect.Position + Vector2.new(8, 6)
        table.insert(self.drawings, tText)
    end

    -- sections/items
    if self.openTab then
        local contentX = pos.X + self.padding
        local contentY = pos.Y + self.headerHeight + self.tabHeight + self.padding

        for _, section in ipairs(self.openTab.sections) do
            local sTitle = newText(4)
            sTitle.Text = section.name
            sTitle.Position = Vector2.new(contentX, contentY)
            table.insert(self.drawings, sTitle)
            contentY = contentY + 18

            for _, item in ipairs(section.items) do
                local labelText = newText(4)
                labelText.Text = item.label
                labelText.Position = Vector2.new(contentX + 20, contentY)
                table.insert(self.drawings, labelText)

                if item.type == "toggle" then
                    local box = newRect(4)
                    box.Size = Vector2.new(14, 14)
                    box.Position = Vector2.new(contentX, contentY)
                    box.Color = item.value and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(40, 40, 40)
                    table.insert(self.drawings, box)

                elseif item.type == "button" then
                    local btn = newRect(4)
                    btn.Size = Vector2.new(80, 18)
                    btn.Position = Vector2.new(contentX, contentY)
                    btn.Color = Color3.fromRGB(45, 45, 45)
                    table.insert(self.drawings, btn)

                elseif item.type == "slider" then
                    local bar = newRect(4)
                    bar.Size = Vector2.new(120, 4)
                    bar.Position = Vector2.new(contentX, contentY + 8)
                    bar.Color = Color3.fromRGB(40, 40, 40)
                    table.insert(self.drawings, bar)

                elseif item.type == "dropdown" then
                    local dd = newRect(4)
                    dd.Size = Vector2.new(120, 18)
                    dd.Position = Vector2.new(contentX, contentY)
                    dd.Color = Color3.fromRGB(40, 40, 40)
                    table.insert(self.drawings, dd)

                elseif item.type == "textbox" then
                    local tb = newRect(4)
                    tb.Size = Vector2.new(120, 18)
                    tb.Position = Vector2.new(contentX, contentY)
                    tb.Color = Color3.fromRGB(40, 40, 40)
                    table.insert(self.drawings, tb)
                end

                contentY = contentY + 22
            end

            contentY = contentY + 6
        end
    end
end

function Menu:HandleInput()
    local mousePos = getMousePos()
    local mouseDown = iskeypressed(0x01)

    -- drag header
    local headerRect = {
        pos = self.position,
        size = Vector2.new(self.size.X, self.headerHeight)
    }

    if mouseDown and not self.dragging and rectContains(headerRect.pos, headerRect.size, mousePos) then
        self.dragging = true
        self.dragOffset = mousePos - self.position
    elseif not mouseDown then
        self.dragging = false
    end

    if self.dragging then
        self.position = mousePos - self.dragOffset
    end
end

function Menu:MainLoop()
    setrobloxinput(false) -- capture input [file:12]
    while self.running do
        -- clear per-frame drawings (tabs + children)
        for i = #self.drawings, 5, -1 do
            local d = self.drawings[i]
            pcall(function() d:Remove() end)
            table.remove(self.drawings, i)
        end

        self:HandleInput()
        self:Draw()
        wait()
    end
end

----------------------------------------------------------------
-- return Menu instance
----------------------------------------------------------------

return Menu.new()
