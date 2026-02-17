

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local Matcha = {}
Matcha.__index = Matcha

local ConfigFolder = "MatchaConfigs"

--// Utility

local function Create(instance, props)
    local obj = Instance.new(instance)
    for i,v in pairs(props) do
        obj[i] = v
    end
    return obj
end

local function Draggable(frame, dragBar)
    local dragging, dragInput, dragStart, startPos
    
    dragBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

--// Window

function Matcha:CreateWindow(title, keybind)
    local UI = {}

    local ScreenGui = Create("ScreenGui", {
        Name = "MatchaUI",
        Parent = game:GetService("CoreGui"),
        ResetOnSpawn = false
    })

    local Main = Create("Frame", {
        Parent = ScreenGui,
        Size = UDim2.fromOffset(540, 420),
        Position = UDim2.fromScale(0.5, 0.5) - UDim2.fromOffset(270, 210),
        BackgroundColor3 = Color3.fromRGB(20,20,20),
        BorderSizePixel = 0
    })

    Create("UICorner", {Parent = Main, CornerRadius = UDim.new(0,12)})

    local Top = Create("Frame", {
        Parent = Main,
        Size = UDim2.new(1,0,0,40),
        BackgroundColor3 = Color3.fromRGB(25,25,25),
        BorderSizePixel = 0
    })

    Create("UICorner", {Parent = Top, CornerRadius = UDim.new(0,12)})

    local Title = Create("TextLabel", {
        Parent = Top,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(255,255,255),
        BackgroundTransparency = 1,
        Size = UDim2.new(1,-90,1,0),
        Position = UDim2.fromOffset(12,0),
        TextXAlignment = Left
    })

    local Min = Create("TextButton", {
        Parent = Top,
        Text = "_",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(255,255,255),
        BackgroundColor3 = Color3.fromRGB(35,35,35),
        Size = UDim2.fromOffset(30,24),
        Position = UDim2.new(1,-70,0.5,-12)
    })

    Create("UICorner", {Parent = Min, CornerRadius = UDim.new(0,6)})

    local Close = Create("TextButton", {
        Parent = Top,
        Text = "X",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(255,80,80),
        BackgroundColor3 = Color3.fromRGB(35,35,35),
        Size = UDim2.fromOffset(30,24),
        Position = UDim2.new(1,-35,0.5,-12)
    })

    Create("UICorner", {Parent = Close, CornerRadius = UDim.new(0,6)})

    local Container = Create("Frame", {
        Parent = Main,
        Position = UDim2.fromOffset(0,42),
        Size = UDim2.new(1,0,1,-42),
        BackgroundTransparency = 1
    })

    local Layout = Create("UIListLayout", {
        Parent = Container,
        Padding = UDim.new(0,8),
        HorizontalAlignment = Center
    })

    Draggable(Main, Top)

    Close.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    local minimized = false
    Min.MouseButton1Click:Connect(function()
        minimized = not minimized
        Container.Visible = not minimized
        Main.Size = minimized and UDim2.fromOffset(540,42) or UDim2.fromOffset(540,420)
    end)

    if keybind then
        UIS.InputBegan:Connect(function(i,gp)
            if not gp and i.KeyCode == keybind then
                ScreenGui.Enabled = not ScreenGui.Enabled
            end
        end)
    end

    --// UI ELEMENTS

    function UI:AddButton(text, callback)
        local Btn = Create("TextButton", {
            Parent = Container,
            Size = UDim2.fromOffset(500,36),
            BackgroundColor3 = Color3.fromRGB(30,30,30),
            Text = text,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(255,255,255)
        })
        Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0,8)})
        Btn.MouseButton1Click:Connect(callback)
    end

    function UI:AddToggle(text, default, callback)
        local state = default

        local Btn = Create("TextButton", {
            Parent = Container,
            Size = UDim2.fromOffset(500,36),
            BackgroundColor3 = Color3.fromRGB(30,30,30),
            Text = text.." : "..(state and "ON" or "OFF"),
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(255,255,255)
        })
        Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0,8)})

        Btn.MouseButton1Click:Connect(function()
            state = not state
            Btn.Text = text.." : "..(state and "ON" or "OFF")
            callback(state)
        end)
    end

    function UI:AddSlider(text,min,max,default,callback)
        local val = default

        local Holder = Create("Frame", {
            Parent = Container,
            Size = UDim2.fromOffset(500,44),
            BackgroundColor3 = Color3.fromRGB(30,30,30)
        })
        Create("UICorner", {Parent = Holder, CornerRadius = UDim.new(0,8)})

        local Label = Create("TextLabel", {
            Parent = Holder,
            Size = UDim2.new(1,-12,0,20),
            Position = UDim2.fromOffset(6,2),
            Text = text.." : "..val,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = Color3.new(1,1,1),
            BackgroundTransparency = 1,
            TextXAlignment = Left
        })

        local Bar = Create("Frame", {
            Parent = Holder,
            Position = UDim2.fromOffset(6,26),
            Size = UDim2.new(1,-12,0,10),
            BackgroundColor3 = Color3.fromRGB(40,40,40)
        })
        Create("UICorner", {Parent = Bar, CornerRadius = UDim.new(1,0)})

        local Fill = Create("Frame", {
            Parent = Bar,
            Size = UDim2.new((val-min)/(max-min),0,1,0),
            BackgroundColor3 = Color3.fromRGB(90,140,255)
        })
        Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1,0)})

        Bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local conn
                conn = UIS.InputChanged:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseMovement then
                        local pct = math.clamp((Mouse.X - Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X,0,1)
                        val = math.floor(min + (max-min)*pct)
                        Fill.Size = UDim2.new(pct,0,1,0)
                        Label.Text = text.." : "..val
                        callback(val)
                    end
                end)
                UIS.InputEnded:Once(function()
                    conn:Disconnect()
                end)
            end
        end)
    end

    function UI:AddColorPicker(text, default, callback)
        local color = default

        local Btn = Create("TextButton", {
            Parent = Container,
            Size = UDim2.fromOffset(500,36),
            BackgroundColor3 = color,
            Text = text,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = Color3.new(1,1,1)
        })
        Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0,8)})

        Btn.MouseButton1Click:Connect(function()
            local h = math.random()
            color = Color3.fromHSV(h,1,1)
            Btn.BackgroundColor3 = color
            callback(color)
        end)
    end

    --// Config Manager

    function UI:CreateConfigManager()
        self:AddButton("Save Config", function()
            writefile(ConfigFolder.."/config.json", HttpService:JSONEncode(self))
        end)

        self:AddButton("Load Config", function()
            if isfile(ConfigFolder.."/config.json") then
                local data = HttpService:JSONDecode(readfile(ConfigFolder.."/config.json"))
                print("Loaded config:", data)
            end
        end)
    end

    return UI
end

return Matcha
