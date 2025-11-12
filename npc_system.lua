return function()
    local rs = (game and typeof(game) == "Instance" and game.GetService and game:GetService("ReplicatedStorage")) or nil
    assert(rs, "ReplicatedStorage not found—make sure you are running this in Roblox.")

    local severeModule = rs:FindFirstChild("VSevere") or rs:WaitForChild("VSevere", 5)
    assert(severeModule, "VSevere module not found—did you install Severe correctly?")
    local severe = require(severeModule)

    -- Error/endurance checking for debugging
    local env = getfenv(2) or getfenv()
    local debugging = rawget(env, "debugging") or (getgenv and getgenv().debugging) or false

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

        if path == nil then
            if debugging then print("Config entry #" .. i .. " is nil!") end
            goto continue
        end
        if type(path.IsA) ~= "function" then
            if debugging then print("Config entry #" .. i .. " does not support IsA!") end
            goto continue
        end

        if debugging then
            print("\nChecking models for: " .. label)
        end

        if path:IsA("Folder") then
            for _, obj in ipairs(path:GetDescendants()) do
                if debugging then
                    print(obj.Name .. " is a " .. obj.ClassName)
                end
                if obj:IsA("Model") then
                    handleModel(obj, obj.Name)
                end
            end
        elseif path:IsA("Model") then
            if debugging then
                print(label .. " is a " .. path.ClassName)
            end
            handleModel(path, label)
        else
            if debugging then
                print(label .. " is a " .. path.ClassName .. " (not Model/Folder)")
            end
        end
        ::continue::
    end
end
