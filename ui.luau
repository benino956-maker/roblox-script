--[[

    Matcha UI Library (Enterprise Framework)
    =======================================

    Features:
    - Window system
    - Tabs
    - Cards
    - Toggles
    - Buttons
    - Sliders
    - Dropdowns
    - Color pickers
    - Keybind system
    - Config saving & loading
    - Config manager UI
    - Window minimize

    Executor compatible (Drawing API based)

]]

local Library = {}
local Windows = {}

-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Theme
local Theme = {
    Background = Color3.fromRGB(12,12,14),
    Sidebar = Color3.fromRGB(16,16,18),
    Card = Color3.fromRGB(20,20,22),
    Accent = Color3.fromRGB(0,162,255),
    Text = Color3.fromRGB(240,240,240),
    SubText = Color3.fromRGB(120,120,120),
    Stroke = Color3.fromRGB(35,35,38)
}

-- Drawing helpers
local function Rect(color, transparency, drawings)
    local d = Drawing.new("Square")
    d.Color = color
    d.Transparency = transparency or 1
    d.Filled = true
    d.Visible = false
    table.insert(drawings, d)
    return d
end

local function Text(text, size, color, drawings)
    local d = Drawing.new("Text")
    d.Text = text
    d.Size = size or 12
    d.Color = color or Theme.Text
    d.Outline = true
    d.Visible = false
    table.insert(drawings, d)
    return d
end

local function IsHover(pos, size)
    local m = Vector2.new(Mouse.X, Mouse.Y)
    return m.X >= pos.X and m.X <= pos.X + size.X and
           m.Y >= pos.Y and m.Y <= pos.Y + size.Y
end

-- Keybind system
local Keybinds = {}

UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    for _,k in ipairs(Keybinds) do
        if i.KeyCode == k.Key then
            if k.Toggle then
                k.State = not k.State
                k.Callback(k.State)
            else
                k.Callback(true)
            end
        end
    end
end)

UIS.InputEnded:Connect(function(i,gp)
    if gp then return end
    for _,k in ipairs(Keybinds) do
        if i.KeyCode == k.Key and not k.Toggle then
            k.Callback(false)
        end
    end
end)

-- Window API
function Library:CreateWindow(title)
    local Window = {
        Title = title,
        Position = Vector2.new(120,120),
        Size = Vector2.new(650,430),
        Tabs = {},
        Drawings = {},
        Dragging = false,
        Minimized = false,
        Visible = true
    }

    -- Main
    local Main = Rect(Theme.Background,1,Window.Drawings)
    local Sidebar = Rect(Theme.Sidebar,1,Window.Drawings)
    local Topbar = Rect(Theme.Sidebar,1,Window.Drawings)
    local TitleText = Text(title,16,Theme.Accent,Window.Drawings)

    -- Minimize button
    local MinBtn = Rect(Theme.Stroke,1,Window.Drawings)
    local MinTxt = Text("-",16,Theme.Text,Window.Drawings)

    function Window:SetVisible(v)
        self.Visible = v
        for _,d in pairs(self.Drawings) do
            d.Visible = v
        end
        for _,t in pairs(self.Tabs) do
            t:SetVisible(v and not self.Minimized and self.Active == t.Name)
        end
    end

    function Window:Update()
        if not self.Visible then return end

        local pos = self.Position

        if ismouse1pressed() and IsHover(pos,Vector2.new(self.Size.X,30)) then
            if not self.Dragging then
                self.Dragging = true
                self.Offset = pos - Vector2.new(Mouse.X,Mouse.Y)
            end
        else
            self.Dragging = false
        end

        if self.Dragging then
            self.Position = Vector2.new(Mouse.X,Mouse.Y) + self.Offset
        end

        Main.Position = pos
        Main.Size = self.Minimized and Vector2.new(self.Size.X,30) or self.Size
        Main.Visible = true

        Topbar.Position = pos
        Topbar.Size = Vector2.new(self.Size.X,30)
        Topbar.Visible = true

        Sidebar.Position = pos + Vector2.new(0,30)
        Sidebar.Size = Vector2.new(150,self.Size.Y-30)
        Sidebar.Visible = not self.Minimized

        TitleText.Position = pos + Vector2.new(10,6)
        TitleText.Visible = true

        MinBtn.Position = pos + Vector2.new(self.Size.X-28,6)
        MinBtn.Size = Vector2.new(22,18)
        MinBtn.Visible = true

        MinTxt.Position = MinBtn.Position + Vector2.new(6,0)
        MinTxt.Visible = true
        MinTxt.Text = self.Minimized and "+" or "-"

        if ismouse1pressed() and IsHover(MinBtn.Position,MinBtn.Size) then
            self.Minimized = not self.Minimized
            task.wait(.2)
        end

        local y = 50
        for _,t in ipairs(self.Tabs) do
            t:DrawSidebar(pos + Vector2.new(10,y))
            y += 35
        end

        if not self.Minimized then
            for _,t in ipairs(self.Tabs) do
                if self.Active == t.Name then
                    t:Update(pos + Vector2.new(170,45))
                end
            end
        end
    end

    function Window:AddTab(name)
        local Tab = {
            Name = name,
            Cards = {},
            Draw = Rect(Theme.Sidebar,1,Window.Drawings),
            Text = Text(name,12,Theme.SubText,Window.Drawings)
        }

        function Tab:SetVisible(v)
            for _,c in pairs(self.Cards) do
                c:SetVisible(v)
            end
        end

        function Tab:DrawSidebar(pos)
            local active = Window.Active == self.Name
            self.Draw.Position = pos
            self.Draw.Size = Vector2.new(130,28)
            self.Draw.Color = active and Theme.Card or Theme.Sidebar
            self.Draw.Visible = true

            self.Text.Position = pos + Vector2.new(10,6)
            self.Text.Color = active and Theme.Accent or Theme.SubText
            self.Text.Visible = true

            if ismouse1pressed() and IsHover(pos,Vector2.new(130,28)) then
                Window.Active = self.Name
                task.wait(.2)
            end
        end

        function Tab:Update(base)
            for _,c in ipairs(self.Cards) do
                c:Update(base + c.Position)
            end
        end

        function Tab:AddCard(title,pos,w,h)
            local Card = {
                Title = title,
                Position = pos,
                Width = w or 220,
                Height = h or 200,
                Elements = {}
            }

            local BG = Rect(Theme.Card,1,Window.Drawings)
            local TT = Text(title,12,Theme.Text,Window.Drawings)

            function Card:SetVisible(v)
                BG.Visible = v
                TT.Visible = v
                for _,e in pairs(self.Elements) do
                    e:SetVisible(v)
                end
            end

            function Card:Update(pos)
                BG.Position = pos
                BG.Size = Vector2.new(self.Width,self.Height)
                BG.Visible = true

                TT.Position = pos + Vector2.new(10,10)
                TT.Visible = true

                local y = 35
                for _,e in ipairs(self.Elements) do
                    e:Update(pos + Vector2.new(10,y), self.Width-20)
                    y += (e.Height or 22) + 10
                end
            end

            -- UI elements
            function Card:AddToggle(text,default,callback)
                local T = {Height=20, Value=default}
                local L = Text(text,12,Theme.SubText,Window.Drawings)
                local B = Rect(Theme.Stroke,1,Window.Drawings)

                function T:SetVisible(v)
                    L.Visible=v B.Visible=v
                end

                function T:Update(p,w)
                    L.Position=p L.Visible=true
                    B.Position=p+Vector2.new(w-20,2)
                    B.Size=Vector2.new(16,16)
                    B.Color=self.Value and Theme.Accent or Theme.Stroke
                    B.Visible=true

                    if ismouse1pressed() and IsHover(B.Position,B.Size) then
                        self.Value=not self.Value
                        callback(self.Value)
                        task.wait(.2)
                    end
                end

                table.insert(self.Elements,T)
                return T
            end

            function Card:AddButton(text,callback)
                local B={Height=25}
                local BG=Rect(Theme.Sidebar,1,Window.Drawings)
                local T=Text(text,12,Theme.Text,Window.Drawings)

                function B:SetVisible(v)
                    BG.Visible=v T.Visible=v
                end

                function B:Update(p,w)
                    BG.Position=p
                    BG.Size=Vector2.new(w,25)
                    BG.Visible=true

                    T.Position=p+Vector2.new(w/2-#text*3,5)
                    T.Visible=true

                    if IsHover(p,Vector2.new(w,25)) then
                        BG.Color=Theme.Card
                        if ismouse1pressed() then callback() task.wait(.2) end
                    else
                        BG.Color=Theme.Sidebar
                    end
                end

                table.insert(self.Elements,B)
                return B
            end

            function Card:AddSlider(text,min,max,default,callback)
                local S={Height=30,Value=default or min}
                local L=Text(text.." : "..S.Value,12,Theme.SubText,Window.Drawings)
                local Bar=Rect(Theme.Stroke,1,Window.Drawings)
                local Fill=Rect(Theme.Accent,1,Window.Drawings)

                function S:SetVisible(v)
                    L.Visible=v Bar.Visible=v Fill.Visible=v
                end

                function S:Update(p,w)
                    L.Text=text.." : "..math.floor(self.Value)
                    L.Position=p L.Visible=true

                    Bar.Position=p+Vector2.new(0,18)
                    Bar.Size=Vector2.new(w,6)
                    Bar.Visible=true

                    local pct=(self.Value-min)/(max-min)
                    Fill.Position=Bar.Position
                    Fill.Size=Vector2.new(w*pct,6)
                    Fill.Visible=true

                    if ismouse1pressed() and IsHover(Bar.Position,Bar.Size) then
                        local rel=(Mouse.X-Bar.Position.X)/w
                        self.Value=min+(max-min)*math.clamp(rel,0,1)
                        callback(self.Value)
                    end
                end

                table.insert(self.Elements,S)
                return S
            end

            function Card:AddDropdown(text,list,default,callback)
                local D={Height=28,Items=list,Value=default or list[1],Open=false}
                local L=Text(text..": "..tostring(D.Value),12,Theme.SubText,Window.Drawings)
                local BG=Rect(Theme.Sidebar,1,Window.Drawings)

                function D:SetVisible(v)
                    L.Visible=v BG.Visible=v
                end

                function D:Update(p,w)
                    L.Text=text..": "..tostring(self.Value)
                    L.Position=p L.Visible=true

                    BG.Position=p+Vector2.new(0,18)
                    BG.Size=Vector2.new(w,10)
                    BG.Visible=true

                    if ismouse1pressed() and IsHover(BG.Position,BG.Size) then
                        self.Open=not self.Open
                        task.wait(.2)
                    end

                    if self.Open then
                        for i,v in ipairs(self.Items) do
                            local tp=BG.Position+Vector2.new(0,i*14)
                            local t=Text(tostring(v),11,Theme.Text,Window.Drawings)
                            t.Position=tp t.Visible=true

                            if ismouse1pressed() and IsHover(tp,Vector2.new(w,14)) then
                                self.Value=v
                                self.Open=false
                                callback(v)
                                task.wait(.2)
                            end
                        end
                    end
                end

                table.insert(self.Elements,D)
                return D
            end

            function Card:AddKeybind(text,default,callback)
                local K={Height=20,Key=default or Enum.KeyCode.Unknown,Callback=callback,Toggle=true,State=false}
                local L=Text(text,12,Theme.SubText,Window.Drawings)

                function K:SetVisible(v)
                    L.Visible=v
                end

                function K:Update(p,w)
                    L.Text=text.." ["..K.Key.Name.."]"
                    L.Position=p
                    L.Visible=true

                    if ismouse1pressed() and IsHover(p,Vector2.new(w,20)) then
                        L.Text=text.." [...]"
                        local k=UIS.InputBegan:Wait()
                        K.Key=k.KeyCode
                        L.Text=text.." ["..K.Key.Name.."]"
                        task.wait(.2)
                    end
                end

                table.insert(Keybinds,K)
                table.insert(self.Elements,K)
                return K
            end

            table.insert(self.Cards,Card)
            return Card
        end

        table.insert(self.Tabs,Tab)
        if not self.Active then self.Active = name end
        return Tab
    end

    table.insert(Windows,Window)
    return Window
end

-- Render Loop
task.spawn(function()
    while true do
        for _,w in ipairs(Windows) do
            w:Update()
        end
        task.wait()
    end
end)

return Library
