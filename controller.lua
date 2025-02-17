local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local Mouse = player:GetMouse()
-- Lock player in first-person mode
player.CameraMode = Enum.CameraMode.LockFirstPerson

-- Physics Parameters
local gravity = 256 -- Scaled gravity (higher than Roblox default, lower than Quake)
local groundFriction = 7 -- Balanced friction for sliding
local airControl = 0.15 -- Limited air control for strafing
local groundAcceleration = 40 -- Quake-like snappy acceleration
local airAcceleration = 20 -- Smooth air strafing
local maxGroundSpeed = 40 -- Ground speed (~studs per second)
local maxAirSpeed = 40 -- Air speed (~studs per second)
local jumpForce = 30 -- Jump force to reach ~45-50 studs height
local rocketJumpForce = 100 -- Force applied during rocket jumping
local rocketJumpRadius = 10 -- Radius of explosion effect
local bunnyHopMomentum = 1.025 -- Momentum multiplier for bunny hopping
-- disable mouse
Mouse.Icon = "rbxassetid://107034647208762"
-- State Variables
local velocity = Vector3.zero -- Player velocity
local isGrounded = false -- Whether the player is grounded
local lastGrounded = tick() -- Timestamp of the last time grounded (for jump buffering)

-- Get input direction from WASD
local function getInputDirection()
	local inputService = game:GetService("UserInputService")
	local direction = Vector3.zero

	if inputService:IsKeyDown(Enum.KeyCode.W) then
		direction += Vector3.new(0, 0, -1)
	end
	if inputService:IsKeyDown(Enum.KeyCode.S) then
		direction += Vector3.new(0, 0, 1)
	end
	if inputService:IsKeyDown(Enum.KeyCode.A) then
		direction += Vector3.new(-1, 0, 0)
	end
	if inputService:IsKeyDown(Enum.KeyCode.D) then
		direction += Vector3.new(1, 0, 0)
	end

	if direction.Magnitude > 1 then
		direction = direction.Unit
	end

	return direction
end

-- Check if the player is grounded using humanoid state
local function checkIfGrounded()
	local state = humanoid:GetState()
	isGrounded = state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.Climbing or state == Enum.HumanoidStateType.Landed
	if isGrounded then
		lastGrounded = tick()
	end
	return isGrounded
end

-- Calculate movement direction relative to the camera
local function getCameraRelativeDirection(inputDirection)
	local camera = workspace.CurrentCamera
	local forward = camera.CFrame.LookVector
	local right = camera.CFrame.RightVector

	-- Flatten vectors to XZ plane
	forward = Vector3.new(forward.X, 0, forward.Z).Unit
	right = Vector3.new(right.X, 0, right.Z).Unit

	-- Calculate movement direction relative to the camera
	local moveDirection = forward * -inputDirection.Z + right * inputDirection.X
	if moveDirection.Magnitude > 0 then
		moveDirection = moveDirection.Unit
	end
	return moveDirection
end

-- Rocket jumping logic
local function rocketJump(explosionPosition)
	local distance = (rootPart.Position - explosionPosition).Magnitude
	if distance <= rocketJumpRadius then
		local direction = (rootPart.Position - explosionPosition).Unit
		velocity += direction * rocketJumpForce
	end
end

-- Main movement function
local function handleMovement(dt)
	local inputDirection = getInputDirection()
	local moveDirection = getCameraRelativeDirection(inputDirection)
	checkIfGrounded()

	if isGrounded then
		-- Apply ground friction
		velocity = velocity * math.max(1 - groundFriction * dt, 0)

		-- Accelerate towards the desired direction
		local desiredVelocity = moveDirection * maxGroundSpeed
		local difference = desiredVelocity - velocity
		velocity += difference * groundAcceleration * dt
	else
		-- Air movement logic
		local currentSpeed = velocity:Dot(moveDirection)
		local addSpeed = maxAirSpeed - currentSpeed
		if addSpeed > 0 then
			local accelSpeed = math.min(airAcceleration * dt, addSpeed)
			velocity += moveDirection * accelSpeed
		end

		-- Apply air control for more Quake-like maneuverability
		velocity += moveDirection * airControl * dt
	end

	-- Apply gravity
	velocity += Vector3.new(0, -gravity * dt, 0)

	-- Jump logic with buffering
	local inputService = game:GetService("UserInputService")
	if inputService:IsKeyDown(Enum.KeyCode.Space) and (isGrounded or tick() - lastGrounded < 0.2) then
		velocity = Vector3.new(velocity.X, jumpForce, velocity.Z)

		-- Bunny hop momentum retention
		if not isGrounded then
			velocity = Vector3.new(velocity.X * bunnyHopMomentum, velocity.Y, velocity.Z * bunnyHopMomentum)
		end
	end

	-- Apply velocity to the player
	rootPart.AssemblyLinearVelocity = velocity
end

-- Physics loop
game:GetService("RunService").Heartbeat:Connect(function(dt)
	handleMovement(dt)
end)

-- Example rocket explosion logic (replace this with your own implementation)
game:GetService("Workspace").ChildAdded:Connect(function(child)
	if child.Name == "RocketExplosion" then
		rocketJump(child.Position)
	end
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

-- Reference the RemoteEvent
local remoteEvent = ReplicatedStorage:WaitForChild("CharacterActionEvent")

-- Function to perform the action
local function performAction()
	print("Mouse clicked!")
	-- Send the action to the server
	remoteEvent:FireServer("Click", mouse.Hit.p)
end

-- Detect mouse click
mouse.Button1Down:Connect(function()
	performAction()
end)
