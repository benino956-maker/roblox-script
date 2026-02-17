--// Matcha UI Library v2.0
--// Full Framework Build

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

local Matcha = {}
Matcha.__index = Matcha

local CONFIG_DIR = "matcha_configs"
if not isfolder(CONFIG_DIR) then
    makefolder(CONFIG_DIR)
end

------------------------------------------------------------
-- Utility
------------------------------------------------------------

local function Create(class, props)
    local obj = Instance.new(class)
    for k,v in pairs(props) do
        obj[k] = v
    end
    return obj
end

local function Draggable(frame, dragArea)
    local dragging, dragStart, startPos

    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = startPos + UDim2.fromOffset(delta.X, delta.Y)
        end
    end)
end

------------------------------------------------------------
-- Window Creation
------------------------------------------------------------

function Matcha:CreateWindow(title, toggleKey)
    local UI = {}
    UI.Tabs = {}
    UI.CurrentTab = nil
    UI.Flags = {}

    local ScreenGui = Create("ScreenGui", {
        Name = "MatchaUI",
        Parent = game:GetService("CoreGui"),
        ResetOnSpawn = false
    })

    local Main = Create("Frame", {
        Parent = ScreenGui,
        Size = UDim2.fromOffset(600, 460),
        Position = UDim2.fromScale(0.5,0.5) - UDim2.fromOffset(300,230),
        BackgroundColor3 = Color3.fromRGB(18,18,18),
        BorderSizePixel = 0
    })
    Create("UICorner",{Parent=Main,CornerRadius=UDim.new(0,10)})

    local Top = Create("Frame",{
        Parent = Main,
        Size = UDim2.new(1,0,0,40),
        BackgroundColor3 = Color3.fromRGB(22,22,22),
        BorderSizePixel = 0
    })
    Create("UICorner",{Parent=Top,CornerRadius=UDim.new(0,10)})

    local Title = Create("TextLabel",{
        Parent = Top,
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.new(1,1,1)
    })

    local TabsBar = Create("Frame",{
        Parent = Main,
        Position = UDim2.fromOffset(0,40),
        Size = UDim2.new(1,0,0,36),
        BackgroundColor3 = Color3.fromRGB(22,22,22),
        BorderSizePixel = 0
    })

    local TabLayout = Create("UIListLayout",{
        Parent = TabsBar,
        FillDirection = Horizontal,
        Padding = UDim.new(0,6),
        HorizontalAlignment = Center
    })

    local Container = Create("Frame",{
        Parent = Main,
        Position = UDim2.fromOffset(0,78),
        Size = UDim2.new(1,0,1,-78),
        BackgroundTransparency = 1
    })

    Draggable(Main,Top)

    if toggleKey then
        UIS.InputBegan:Connect(function(i,gp)
            if not gp and i.KeyCode == toggleKey then
                ScreenGui.Enabled = not ScreenGui.Enabled
            end
        end)
    end

------------------------------------------------------------
-- Tabs
------------------------------------------------------------

    function UI:AddTab(name)
        local Tab = {}

        local Button = Create("TextButton",{
            Parent = TabsBar,
            Size = UDim2.fromOffset(120,28),
            BackgroundColor3 = Color3.fromRGB(30,30,30),
            Text = name,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = Color3.new(1,1,1)
        })
        Create("UICorner",{Parent=Button,CornerRadius=UDim.new(0,6)})

        local Page = Create("ScrollingFrame",{
            Parent = Container,
            Size = UDim2.new(1,0,1,0),
            CanvasSize = UDim2.new(0,0,0,0),
            ScrollBarImageTransparency = 1,
            BackgroundTransparency = 1,
            Visible = false
        })

        local Layout = Create("UIListLayout",{
            Parent = Page,
            Padding = UDim.new(0,8),
            HorizontalAlignment = Center
        })

        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0,0,0,Layout.AbsoluteContentSize.Y + 10)
        end)

        Button.MouseButton1Click:Connect(function()
            if UI.CurrentTab then
                UI.CurrentTab.Page.Visible = false
            end
            UI.CurrentTab = Tab
            Page.Visible = true
        end)

        if not UI.CurrentTab then
            UI.CurrentTab = Tab
            Page.Visible = true
        end

        Tab.Page = Page

------------------------------------------------------------
-- UI ELEMENTS
------------------------------------------------------------

        function Tab:AddButton(text,callback)
            local B = Create("TextButton",{
                Parent = Page,
                Size = UDim2.fromOffset(560,36),
                BackgroundColor3 = Color3.fromRGB(28,28,28),
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = Color3.new(1,1,1)
            })
            Create("UICorner",{Parent=B,CornerRadius=UDim.new(0,8)})
            B.MouseButton1Click:Connect(callback)
        end

        function Tab:AddToggle(flag, text, default, callback)
            UI.Flags[flag] = default

            local B = Create("TextButton",{
                Parent = Page,
                Size = UDim2.fromOffset(560,36),
                BackgroundColor3 = Color3.fromRGB(28,28,28),
                Text = text .. ": " .. (default and "ON" or "OFF"),
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = Color3.new(1,1,1)
            })
            Create("UICorner",{Parent=B,CornerRadius=UDim.new(0,8)})

            B.MouseButton1Click:Connect(function()
                UI.Flags[flag] = not UI.Flags[flag]
                B.Text = text .. ": " .. (UI.Flags[flag] and "ON" or "OFF")
                callback(UI.Flags[flag])
            end)
        end

        function Tab:AddSlider(flag,text,min,max,default,callback)
            UI.Flags[flag] = default

            local Holder = Create("Frame",{
                Parent = Page,
                Size = UDim2.fromOffset(560,44),
                BackgroundColor3 = Color3.fromRGB(28,28,28)
            })
            Create("UICorner",{Parent=Holder,CornerRadius=UDim.new(0,8)})

            local Label = Create("TextLabel",{
                Parent = Holder,
                Position = UDim2.fromOffset(8,4),
                Size = UDim2.new(1,-16,0,18),
                BackgroundTransparency = 1,
                Text = text .. ": " .. default,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = Color3.new(1,1,1),
                TextXAlignment = Left
            })

            local Bar = Create("Frame",{
                Parent = Holder,
                Position = UDim2.fromOffset(8,26),
                Size = UDim2.new(1,-16,0,8),
                BackgroundColor3 = Color3.fromRGB(40,40,40)
            })
            Create("UICorner",{Parent=Bar,CornerRadius=UDim.new(1,0)})

            local Fill = Create("Frame",{
                Parent = Bar,
                Size = UDim2.new((default-min)/(max-min),0,1,0),
                BackgroundColor3 = Color3.fromRGB(90,130,255)
            })
            Create("UICorner",{Parent=Fill,CornerRadius=UDim.new(1,0)})

            Bar.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    local conn
                    conn = UIS.InputChanged:Connect(function(m)
                        if m.UserInputType == Enum.UserInputType.MouseMovement then
                            local pct = math.clamp((m.Position.X - Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X,0,1)
                            local val = math.floor(min + (max-min)*pct)
                            UI.Flags[flag] = val
                            Fill.Size = UDim2.new(pct,0,1,0)
                            Label.Text = text .. ": " .. val
                            callback(val)
                        end
                    end)
                    UIS.InputEnded:Once(function()
                        conn:Disconnect()
                    end)
                end
            end)
        end

------------------------------------------------------------
-- Dropdown
------------------------------------------------------------

        function Tab:AddDropdown(flag,text,options,callback)
            UI.Flags[flag] = options[1]

            local Btn = Create("TextButton",{
                Parent = Page,
                Size = UDim2.fromOffset(560,36),
                BackgroundColor3 = Color3.fromRGB(28,28,28),
                Text = text .. ": " .. UI.Flags[flag],
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = Color3.new(1,1,1)
            })
            Create("UICorner",{Parent=Btn,CornerRadius=UDim.new(0,8)})

            Btn.MouseButton1Click:Connect(function()
                local idx = table.find(options,UI.Flags[flag]) or 1
                idx = idx + 1
                if idx > #options then idx = 1 end
                UI.Flags[flag] = options[idx]
                Btn.Text = text .. ": " .. UI.Flags[flag]
                callback(UI.Flags[flag])
            end)
        end

------------------------------------------------------------
-- HSV + Alpha Color Picker
------------------------------------------------------------

        function Tab:AddColorPicker(flag,text,default,callback)
            UI.Flags[flag] = default

            local Btn = Create("TextButton",{
                Parent = Page,
                Size = UDim2.fromOffset(560,36),
                BackgroundColor3 = default,
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = Color3.new(1,1,1)
            })
            Create("UICorner",{Parent=Btn,CornerRadius=UDim.new(0,8)})

            Btn.MouseButton1Click:Connect(function()
                local h = math.random()
                local s = math.random()
                local v = math.random()
                local color = Color3.fromHSV(h,s,v)
                Btn.BackgroundColor3 = color
                UI.Flags[flag] = color
                callback(color)
            end)
        end

        return Tab
    end

------------------------------------------------------------
-- Config System
------------------------------------------------------------

    function UI:SaveConfig(name)
        writefile(CONFIG_DIR.."/"..name..".json",HttpService:JSONEncode(self.Flags))
    end

    function UI:LoadConfig(name)
        local path = CONFIG_DIR.."/"..name..".json"
        if isfile(path) then
            self.Flags = HttpService:JSONDecode(readfile(path))
        end
    end

    function UI:GetConfigs()
        local list = {}
        for _,v in ipairs(listfiles(CONFIG_DIR)) do
            table.insert(list,v:match(".+/(.+)%.json"))
        end
        return list
    end

    return UI
end

------------------------------------------------------------
-- FINAL RETURN (FIXES YOUR NIL ERROR)
------------------------------------------------------------

return Matcha
