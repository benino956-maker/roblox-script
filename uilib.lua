-- Matcha LuaVM Script
-- Fully compatible with documented APIs only
-- macOS Styled UI Library for Matcha LuaVM

local Library = {}
Library.__index = Library

-- Services (Emulated via Matcha)
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Configuration
local Config = {
    AccentColor = Color3.fromRGB(0, 122, 255), -- macOS Blue
    WindowBG = Color3.fromRGB(30, 30, 30),
    SidebarBG = Color3.fromRGB(35, 35, 35),
    TitleBarColor = Color3.fromRGB(45, 45, 45),
    TextColor = Color3.fromRGB(255, 255, 255),
    CornerRadius = 8
}

function Library:SetAccentColor(color)
    Config.AccentColor = color
end

-- Registry for cleanup
local Registry = {
    Drawings = {},
    Windows = {}
}

-- Utility: Is mouse over a region?
local function IsMouseOver(pos, size)
    local mouseLoc = UserInputService:GetMouseLocation()
    return mouseLoc.X >= pos.X and mouseLoc.X <= pos.X + size.X and
           mouseLoc.Y >= pos.Y and mouseLoc.Y <= pos.Y + size.Y
end

-- Render and Input Manager
local function StartRenderLoop()
    task.spawn(function()
        while true do
            local mouseLoc = UserInputService:GetMouseLocation()
            local mouse1Down = ismouse1pressed()
            
            for _, window in ipairs(Registry.Windows) do
                window:Update(mouseLoc, mouse1Down)
            end
            
            task.wait()
        end
    end)
end

function Library:NewWindow(title)
    local Window = {
        Title = title or "Window",
        Position = Vector2.new(100, 100),
        Size = Vector2.new(500, 350),
        Dragging = false,
        DragOffset = Vector2.new(0, 0),
        Visible = true,
        Elements = {},
        Drawings = {}
    }
    setmetatable(Window, {__index = Window})

    -- Background
    local MainFrame = Drawing.new("Square")
    MainFrame.Color = Config.WindowBG
    MainFrame.Thickness = 0
    MainFrame.Filled = true
    MainFrame.Transparency = 0.95
    MainFrame.Visible = true

    -- Title Bar
    local TitleBar = Drawing.new("Square")
    TitleBar.Color = Config.TitleBarColor
    TitleBar.Thickness = 0
    TitleBar.Filled = true
    TitleBar.Visible = true

    -- Title Text
    local TitleText = Drawing.new("Text")
    TitleText.Text = Window.Title
    TitleText.Color = Config.TextColor
    TitleText.Size = 13
    TitleText.Center = true
    TitleText.Visible = true

    -- Traffic Lights (Decorative for now)
    local function CreateButton(color, offset)
        local btn = Drawing.new("Circle")
        btn.Color = color
        btn.Radius = 6
        btn.Filled = true
        btn.Thickness = 0
        btn.Visible = true
        return btn
    end

    local CloseBtn = CreateButton(Color3.fromRGB(255, 95, 87), 20)
    local MinBtn = CreateButton(Color3.fromRGB(255, 189, 46), 40)
    local MaxBtn = CreateButton(Color3.fromRGB(40, 201, 64), 60)

    -- Sidebar
    local Sidebar = Drawing.new("Square")
    Sidebar.Color = Config.SidebarBG
    Sidebar.Thickness = 0
    Sidebar.Filled = true
    Sidebar.Visible = true

    Window.Drawings = {
        MainFrame = MainFrame,
        TitleBar = TitleBar,
        Sidebar = Sidebar,
        TitleText = TitleText,
        CloseBtn = CloseBtn,
        MinBtn = MinBtn,
        MaxBtn = MaxBtn
    }

    function Window:AddToggle(text, default, callback)
        local Toggle = {
            Text = text,
            Enabled = default or false,
            Callback = callback or function() end
        }

        local ToggleFrame = Drawing.new("Square")
        ToggleFrame.Color = Color3.fromRGB(60, 60, 60)
        ToggleFrame.Thickness = 0
        ToggleFrame.Filled = true
        ToggleFrame.Size = Vector2.new(16, 16)
        ToggleFrame.Visible = true

        local ToggleCheck = Drawing.new("Square")
        ToggleCheck.Color = Config.AccentColor
        ToggleCheck.Thickness = 0
        ToggleCheck.Filled = true
        ToggleCheck.Size = Vector2.new(10, 10)
        ToggleCheck.Visible = Toggle.Enabled

        local ToggleText = Drawing.new("Text")
        ToggleText.Text = text
        ToggleText.Color = Config.TextColor
        ToggleText.Size = 13
        ToggleText.Visible = true

        local index = #self.Elements + 1
        table.insert(self.Elements, function(basePos)
            local absPos = basePos + Vector2.new(0, (index - 1) * 30)
            ToggleFrame.Position = absPos
            ToggleCheck.Position = absPos + Vector2.new(3, 3)
            ToggleCheck.Visible = Toggle.Enabled
            ToggleText.Position = absPos + Vector2.new(25, 1)

            if ismouse1pressed() and IsMouseOver(absPos, ToggleFrame.Size) then
                task.wait(0.1)
                Toggle.Enabled = not Toggle.Enabled
                Toggle.Callback(Toggle.Enabled)
            end
        end)

        table.insert(self.Drawings, ToggleFrame)
        table.insert(self.Drawings, ToggleCheck)
        table.insert(self.Drawings, ToggleText)
    end

    function Window:AddSlider(text, min, max, default, callback)
        local Slider = {
            Text = text,
            Min = min or 0,
            Max = max or 100,
            Value = default or min,
            Callback = callback or function() end,
            Dragging = false
        }

        local SliderBack = Drawing.new("Square")
        SliderBack.Color = Color3.fromRGB(60, 60, 60)
        SliderBack.Thickness = 0
        SliderBack.Filled = true
        SliderBack.Size = Vector2.new(150, 4)
        SliderBack.Visible = true

        local SliderMain = Drawing.new("Square")
        SliderMain.Color = Config.AccentColor
        SliderMain.Thickness = 0
        SliderMain.Filled = true
        SliderMain.Size = Vector2.new(0, 4)
        SliderMain.Visible = true

        local SliderDot = Drawing.new("Circle")
        SliderDot.Color = Color3.fromRGB(200, 200, 200)
        SliderDot.Radius = 6
        SliderDot.Filled = true
        SliderDot.Thickness = 0
        SliderDot.Visible = true

        local SliderText = Drawing.new("Text")
        SliderText.Text = text .. ": " .. Slider.Value
        SliderText.Color = Config.TextColor
        SliderText.Size = 13
        SliderText.Visible = true

        local index = #self.Elements + 1
        table.insert(self.Elements, function(basePos)
            local absPos = basePos + Vector2.new(0, (index - 1) * 40)
            SliderBack.Position = absPos + Vector2.new(0, 2)
            SliderMain.Position = absPos + Vector2.new(0, 2)
            SliderText.Position = absPos + Vector2.new(0, -15)

            local mouseLoc = UserInputService:GetMouseLocation()
            if ismouse1pressed() and IsMouseOver(absPos - Vector2.new(0, 5), Vector2.new(150, 15)) then
                Slider.Dragging = true
            elseif not ismouse1pressed() then
                Slider.Dragging = false
            end

            if Slider.Dragging then
                local pct = math.clamp((mouseLoc.X - absPos.X) / 150, 0, 1)
                local val = math.floor(Slider.Min + (Slider.Max - Slider.Min) * pct)
                if val ~= Slider.Value then
                    Slider.Value = val
                    Slider.Callback(val)
                    SliderText.Text = text .. ": " .. val
                end
            end

            local progress = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
            SliderMain.Size = Vector2.new(150 * progress, 4)
            SliderDot.Position = absPos + Vector2.new(150 * progress, 4)
        end)

        table.insert(self.Drawings, SliderBack)
        table.insert(self.Drawings, SliderMain)
        table.insert(self.Drawings, SliderDot)
        table.insert(self.Drawings, SliderText)
    end

    function Window:Update(mouseLoc, mouse1Down)
        if not self.Visible then return end

        if mouse1Down then
            if not self.Dragging and IsMouseOver(self.Position, Vector2.new(self.Size.X, 28)) then
                self.Dragging = true
                self.DragOffset = self.Position - mouseLoc
            end
        else
            self.Dragging = false
        end

        if self.Dragging then
            self.Position = mouseLoc + self.DragOffset
        end

        -- Update Visuals
        MainFrame.Position = self.Position
        MainFrame.Size = self.Size

        TitleBar.Position = self.Position
        TitleBar.Size = Vector2.new(self.Size.X, 28)

        Sidebar.Position = self.Position + Vector2.new(0, 28)
        Sidebar.Size = Vector2.new(120, self.Size.Y - 28)

        TitleText.Position = self.Position + Vector2.new(self.Size.X / 2, 6)
        
        CloseBtn.Position = self.Position + Vector2.new(20, 14)
        MinBtn.Position = self.Position + Vector2.new(40, 14)
        MaxBtn.Position = self.Position + Vector2.new(60, 14)

        -- Update Elements
        for _, update in ipairs(self.Elements) do
            local absPos = self.Position + Vector2.new(135, 50) -- Offset for sidebar
            update(absPos)
        end
    end

    function Window:AddButton(text, callback)
        local Button = {
            Text = text,
            Callback = callback or function() end,
            Position = Vector2.new(0, 0) -- Relative to window
        }

        local BtnFrame = Drawing.new("Square")
        BtnFrame.Color = Config.AccentColor
        BtnFrame.Thickness = 0
        BtnFrame.Filled = true
        BtnFrame.Size = Vector2.new(100, 24)
        BtnFrame.Visible = true

        local BtnText = Drawing.new("Text")
        BtnText.Text = text
        BtnText.Color = Config.TextColor
        BtnText.Size = 13
        BtnText.Center = true
        BtnText.Visible = true

        local index = #self.Elements + 1
        table.insert(self.Elements, function(basePos)
            local absPos = basePos + Vector2.new(0, (index - 1) * 30)
            BtnFrame.Position = absPos
            BtnText.Position = absPos + Vector2.new(50, 4)

            if ismouse1pressed() and IsMouseOver(absPos, BtnFrame.Size) then
                task.wait(0.1) -- Debounce
                Button.Callback()
            end
        end)

        table.insert(self.Drawings, BtnFrame)
        table.insert(self.Drawings, BtnText)
    end

    function Window:Destroy()
        self.Visible = false
        for _, drawing in pairs(self.Drawings) do
            drawing:Remove()
        end
    end

    table.insert(Registry.Windows, Window)
    return Window
end

-- Initialize Loop
StartRenderLoop()

return Library
