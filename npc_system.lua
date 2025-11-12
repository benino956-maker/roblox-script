return function()
    local rs
    if game and typeof(game) == "Instance" and game.GetService then
        rs = game:GetService("ReplicatedStorage")
    end
    assert(rs, "ReplicatedStorage not found—make sure you are running this in Roblox.")

    local severeModule = rs:FindFirstChild("VSevere") or rs:WaitForChild("VSevere", 5)
    assert(severeModule, "VSevere module not found—did you install Severe correctly?")

    local severe = require(severeModule)

    -- Read path/name pairs from caller (your config)
    local env = getfenv(2) or getfenv()
    local paths, names = {}, {}
    local i = 1
    while true do
        local p = rawget(env, "path", i)
        local n = rawget(env, "name", i)
        if not p or not n then break end
        table.insert(paths, p)
        table.insert(names, n)
        i = i + 1
    end

    local function handleModel(target, label)
        if severe.Aim and severe.Aim.SetTarget then
            severe.Aim:SetTarget(target)
        end
        if severe.Visuals and severe.Visuals.EnableESP then
            severe.Visuals:EnableESP(target, {Name = label})
        end
    end

    for i = 1, #paths do
        local path = paths[i]
        local label = names[i]

        if path:IsA("Folder") then
            for _, obj in ipairs(path:GetChildren()) do
                if obj:IsA("Model") then
                    handleModel(obj, obj.Name)
                end
            end
        elseif path:IsA("Model") then
            handleModel(path, label)
        end
    end
end
