-- Matcha UI Library
-- Drawing UI Framework
-- Enterprise Grade
-- By: Matcha

local Library = {}
Library.Version = "1.0.0"

--// Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

--// Core Vars
local Windows = {}
local Configs = {}
local CurrentConfig = "default"

--// Utility
local function Create(class)
    local obj = Drawing.new(class)
    return obj
end

local function Clamp(x,min,max)
    return math.max(min,math.min(max,x))
end

local function HSVToRGB(h,s,v)
    local r,g,b = Color3.fromHSV(h,s,v)
    return r,g,b
end

--// Config System
local ConfigSystem = {}

function ConfigSystem:Save(name, data)
    if writefile then
        writefile("matcha_"..name..".json", HttpService:JSONEncode(data))
    end
end

function ConfigSystem:Load(name)
    if isfile and isfile("matcha_"..name..".json") then
        return HttpService:JSONDecode(readfile("matcha_"..name..".json"))
    end
end

function ConfigSystem:GetConfigs()
    local t = {}
    if listfiles then
        for _,f in ipairs(listfiles("")) do
            if f:find("matcha_") then
                table.insert(t,f:gsub("matcha_",""):gsub(".json",""))
            end
        end
    end
    return t
end

--// Window System
function Library:CreateWindow(title, toggleKey)
    local Window = {}
    Window.Title = title
    Window.Tabs = {}
    Window.Visible = true
    Window.Minimized = false
    Window.Key = toggleKey or Enum.KeyCode.RightShift

    local Pos = Vector2.new(150,150)
    local Size = Vector2.new(600,420)
    local Dragging, DragOffset = false, Vector2.zero

    -- Drawings
    local BG = Create("Square")
    BG.Color = Color3.fromRGB(20,20,25)
    BG.Size = Size
    BG.Position = Pos
    BG.Filled = true

    local Top = Create("Square")
    Top.Color = Color3.fromRGB(30,30,35)
    Top.Size = Vector2.new(Size.X,35)
    Top.Position = Pos
    Top.Filled = true

    local Title = Create("Text")
    Title.Text = title.."  |  Matcha UI"
    Title.Size = 14
    Title.Color = Color3.fromRGB(255,255,255)
    Title.Position = Pos + Vector2.new(10,8)

    local Sidebar = Create("Square")
    Sidebar.Color = Color3.fromRGB(25,25,30)
    Sidebar.Size = Vector2.new(140,Size.Y-35)
    Sidebar.Position = Pos + Vector2.new(0,35)
    Sidebar.Filled = true

    -- Input
    UserInputService.InputBegan:Connect(function(i,gp)
        if gp then return end
        if i.KeyCode == Window.Key then
            Window.Visible = not Window.Visible
            for _,v in pairs(Window.Drawings) do
                v.Visible = Window.Visible
            end
        end
    end)

    function Window:AddTab(name)
        local Tab = {}
        Tab.Name = name
        Tab.Elements = {}
        Tab.Active = false

        table.insert(self.Tabs,Tab)

        function Tab:AddButton(text,callback)
            table.insert(self.Elements,{
                Type="Button",Text=text,Callback=callback
            })
        end

        function Tab:AddToggle(text,default,callback)
            table.insert(self.Elements,{
                Type="Toggle",Text=text,Value=default,Callback=callback
            })
        end

        function Tab:AddSlider(text,min,max,default,callback)
            table.insert(self.Elements,{
                Type="Slider",Text=text,Min=min,Max=max,Value=default,Callback=callback
            })
        end

        function Tab:AddDropdown(text,list,callback)
            table.insert(self.Elements,{
                Type="Dropdown",Text=text,List=list,Value=list[1],Callback=callback
            })
        end

        function Tab:AddColorPicker(text,default,callback)
            table.insert(self.Elements,{
                Type="Color",Text=text,Color=default or Color3.new(1,0,0),Callback=callback
            })
        end

        function Tab:AddKeybind(text,default,callback)
            table.insert(self.Elements,{
                Type="Keybind",Text=text,Key=default,Callback=callback
            })
        end

        function Tab:AddConfigManager()
            table.insert(self.Elements,{Type="ConfigManager"})
        end

        return Tab
    end

    table.insert(Windows,Window)
    return Window
end

--// Render Engine
RunService.RenderStepped:Connect(function()
    for _,Window in ipairs(Windows) do
        -- Window Drag
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            local mouse = UserInputService:GetMouseLocation()
            if mouse.X > Window.Position.X and mouse.X < Window.Position.X + 600 and
               mouse.Y > Window.Position.Y and mouse.Y < Window.Position.Y + 35 then
                if not Dragging then
                    Dragging = true
                    DragOffset = Window.Position - mouse
                end
            end
        else
            Dragging = false
        end

        if Dragging then
            Window.Position = UserInputService:GetMouseLocation() + DragOffset
        end
    end
end)

--// Example Config Manager UI
function Library:CreateConfigManager(tab)
    tab:AddButton("Save Config", function()
        ConfigSystem:Save(CurrentConfig,Configs)
    end)

    tab:AddButton("Load Config", function()
        local cfg = ConfigSystem:Load(CurrentConfig)
        if cfg then
            Configs = cfg
        end
    end)
end

--// Return Library (CRITICAL)
return Library
