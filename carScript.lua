-- Define the RemoteEvent and necessary services
local carSystem = game:GetService("ReplicatedStorage").CarSpawnSystem.RemoteEvents.CarSystem
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local localPlayer = players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()

-- Function to spawn the car and return the vehicle reference
local function spawnCar()
    local args = {
        [1] = "Spawn",
        [2] = "SUV",
        [3] = {
            [1] = false
        }
    }

    -- Invoke the server to spawn the car
    print("Invoking CarSystem to spawn SUV...")
    carSystem:InvokeServer(unpack(args))

    -- Wait for the vehicle to spawn
    local vehicle
    repeat
        wait(1)
        -- Look for the vehicle in workspace by checking if it has a VehicleSeat and BasePart
        for _, obj in pairs(workspace:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChildWhichIsA("VehicleSeat") then
                vehicle = obj
                print("Found vehicle: " .. vehicle.Name)
                break
            end
        end
    until vehicle

    return vehicle
end

-- Function to make the car fly and spin
local function makeCarFlyAndSpin(vehicle)
    print("Making the car fly and spin...")
    local bodyGyro = Instance.new("BodyGyro")
    local bodyVelocity = Instance.new("BodyVelocity")

    -- Parent them to the vehicle's primary part (usually the root part of the model)
    local primaryPart = vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")

    if primaryPart then
        -- Set up flying and spinning
        bodyGyro.Parent = primaryPart
        bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000) -- Adjust for spinning speed
        bodyGyro.CFrame = CFrame.Angles(0, 0, math.rad(360)) -- Spinning motion

        bodyVelocity.Parent = primaryPart
        bodyVelocity.MaxForce = Vector3.new(1, 1, 1) * math.huge -- Infinite force to lift the vehicle
        bodyVelocity.Velocity = Vector3.new(0, 100, 0) -- Fly upwards at 100 studs/second
    else
        print("Could not find the PrimaryPart for the vehicle!")
    end
end

-- Function to teleport the car to each player
local function teleportCarToPlayers(vehicle)
    local primaryPart = vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")
    
    if primaryPart then
        -- Teleport the vehicle to every player in the server
        for _, player in pairs(players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                -- Get the position of the player's character
                local targetPosition = player.Character.HumanoidRootPart.Position
                -- Move the car to the player's position
                primaryPart.CFrame = CFrame.new(targetPosition + Vector3.new(0, 10, 0)) -- Teleport slightly above the player
                print("Teleported car to " .. player.Name)
                wait(0.2) -- Adjust the delay between teleports
            end
        end
    else
        print("PrimaryPart not found; cannot teleport the vehicle!")
    end
end

-- Function to constantly check if the player is sitting in the vehicle
local function checkIfSitting(vehicle)
    local vehicleSeat = vehicle:FindFirstChildWhichIsA("VehicleSeat")

    if vehicleSeat then
        while true do
            wait(0.5) -- Check every half a second
            if vehicleSeat.Occupant ~= character.Humanoid then
                -- If the player is not sitting in the vehicle, respawn it
                print("Player not in vehicle. Respawning...")
                vehicle:Destroy()
                local newVehicle = spawnCar()
                makeCarFlyAndSpin(newVehicle)
                teleportCarToPlayers(newVehicle)
                return checkIfSitting(newVehicle) -- Recursively check again for the new vehicle
            end
        end
    else
        print("VehicleSeat not found!")
    end
end

-- Main script execution
local vehicle = spawnCar()
if vehicle then
    makeCarFlyAndSpin(vehicle)
    teleportCarToPlayers(vehicle)
    checkIfSitting(vehicle)
else
    print("Vehicle spawn failed.")
end

