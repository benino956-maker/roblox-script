--// Matcha UI Core - NIL FIX GUARANTEED

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local Matcha = {}
Matcha.__index = Matcha

local function Create(class, props)
    local obj = Instance.new(class)
    for k,v in pairs(props) do
        obj[k] = v
    end
    return obj
end

function Matcha:CreateWindow(title, toggleKey)
    local UI = {}

    local ScreenGui = Create("ScreenGui", {
        Parent = game:GetService("CoreGui"),
        ResetOnSpawn = false,
        Name = "MatchaUI"
    })

    local Main = Create("Frame", {
        Parent = ScreenGui,
        Size = UDim2.fromOffset(500, 350),
        Position = UDim2.fromScale(0.5,0.5) - UDim2.fromOffset(250,175),
        BackgroundColor3 = Color3.fromRGB(20,20,20),
        BorderSizePixel = 0
    })
    Create("UICorner",{Parent=Main,CornerRadius=UDim.new(0,10)})

    local Top = Create("Frame",{
        Parent = Main,
        Size = UDim2.new(1,0,0,36),
        BackgroundColor3 = Color3.fromRGB(25,25,25),
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

    local Body = Create("Frame",{
        Parent = Main,
        Position = UDim2.fromOffset(0,36),
        Size = UDim2.new(1,0,1,-36),
        BackgroundTransparency = 1
    })

    if toggleKey then
        UIS.InputBegan:Connect(function(i,gp)
            if not gp and i.KeyCode == toggleKey then
                ScreenGui.Enabled = not ScreenGui.Enabled
            end
        end)
    end

    function UI:AddButton(text, callback)
        local B = Create("TextButton",{
            Parent = Body,
            Size = UDim2.fromOffset(460,36),
            Position = UDim2.fromOffset(20,20),
            BackgroundColor3 = Color3.fromRGB(30,30,30),
            Text = text,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = Color3.new(1,1,1)
        })
        Create("UICorner",{Parent=B,CornerRadius=UDim.new(0,8)})
        B.MouseButton1Click:Connect(callback)
    end

    return UI
end

-- 🔥 THIS IS WHAT FIXES YOUR ERROR 🔥
return Matcha
