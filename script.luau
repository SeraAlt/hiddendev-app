--Discord User: serataken
--Roblox User: Seraphynxx

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player:Player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local HRP = character:WaitForChild("HumanoidRootPart")
local humanoid:Humanoid = character.Humanoid 
local animator:Animator  = humanoid.Animator

local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

local mainGui = player.PlayerGui.MainGui
local anims = ReplicatedStorage.Default --Animation Folder
local VFX = ReplicatedStorage.VFX --vfx folder
local trailVFX = ReplicatedStorage.VFX.Default --Flight trails

local tweenInfo = TweenInfo.new(0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,0,false,0)

local canBoost = true --check for whether ur boosting or not

local alignAttachment = Instance.new("Attachment") --attachment for both alignPosition and alignOrientation
alignAttachment.Parent = HRP

local alignPosition = Instance.new("AlignPosition") -- re-usable align position for flying

alignPosition.Enabled = false --setting it to false as we arent using it right away
alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment -- setting it to 1 attachment as two are unecessary
alignPosition.MaxForce = math.huge --makes sure the force cap doesnt get in the way
alignPosition.Responsiveness = 50

alignPosition.Attachment0 = alignAttachment
alignPosition.Parent = HRP 

local alignOrientation = Instance.new("AlignOrientation") --re-usasble align orientation thats only enabled when ur flying

alignOrientation.Enabled = false -- setting it to false as we arent using it right away
alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment --  setting it to 1 attachment as two are unecessary
alignOrientation.MaxTorque = math.huge  --makes sure the torque cap doesnt get in the way
alignOrientation.Responsiveness = 50

alignOrientation.Attachment0 = alignAttachment
alignOrientation.Parent = HRP


local actionTable = { -- table used to know what direction to fly and animation to play based off the key ur holding, with idle being no key held
	["W"] = {"LookVector", 2, animator:LoadAnimation(anims.WFly),},
	["A"] = {"RightVector", -2, animator:LoadAnimation(anims.AFly),},
	["S"] = {"LookVector", -2, animator:LoadAnimation(anims.SFly),},
	["D"] = {"RightVector", 2, animator:LoadAnimation(anims.DFly),},
	["Idle"] = {"RightVector", 0, animator:LoadAnimation(anims.FlightIdle),},
} 
for i, v in pairs(actionTable) do --preloads all anims, doing this method since content provider only works on instances
	v[3]:Play()

	v[3]:Stop()
end

local currentDirection = "Idle" -- changes depending on what key ur holding, used to determine what index to use in actionTable

local LoopTable = { --used to know where to parent clones of trailVFX for when ur flying

	character:WaitForChild("LeftHand").LeftGripAttachment,
	character:WaitForChild("RightHand").RightGripAttachment,
	character:WaitForChild("LeftFoot").LeftFootAttachment,
	character:WaitForChild("RightFoot").RightFootAttachment,
} 

local itemTable = { --stores consumable's names, descriptions, and a function
	["Soder"] = {
		["Description"] = "gain +15 flight speed for 5 secs",

		["Activate"] = function()

			character:SetAttribute("Speed", character:GetAttribute("Speed" ) + 15)
			task.delay(5,function()
				character:SetAttribute("Speed", character:GetAttribute("Speed" ) - 15)

			end)
		end,

	},

	["Rotten Food"] = {
		["Description"] = "forces you to stop flying",

		["Activate"] = function()

			character:SetAttribute("Flying", nil)

		end,

	},


	["Witches Brew"] = {
		["Description"] = "permanent +1 to flying speed",

		["Activate"] = function()

			character:SetAttribute("Speed", character:GetAttribute("Speed" ) + 1)

		end,

	},

	["Cat Food"] = {
		["Description"] = "WHY??? (permanent -1 to flying speed)",

		["Activate"] = function()

			character:SetAttribute("Speed", character:GetAttribute("Speed" ) - 1)

		end,

	},

}

character:SetAttribute("Speed", 1) --used for speed multipliers, better than changing alignPosition's responsiveness directly to avoid multiplicative modifiers


local function PlaySound(Sound:Sound, Parent, Speed) --vfx function, simply clones a vfx, parents it and plays it 
	Sound = game.SoundService:WaitForChild(Sound):Clone()

	Sound.Parent = Parent
	Sound:Play()
	Sound.PlaybackSpeed = Speed or Sound.PlaybackSpeed

	Debris:AddItem(Sound, Sound.TimeLength + 2)
end

UserInputService.InputBegan:Connect(function(input, GPE)

	if GPE then return end --makes sure u dont fly around while typing

	if  actionTable[input.KeyCode.Name] then currentDirection = input.KeyCode.Name  end  -- checks if the input is a valid direction (W,A,S,D) to avoid errors

	if input.KeyCode == Enum.KeyCode.Space  and humanoid:GetState() == Enum.HumanoidStateType.Freefall and canBoost then --makes sure u can only start flight if you jump while being airborne

		character:SetAttribute("Flying" , if character:GetAttribute("Flying") then nil else true) -- sets flight, nil is used instead of false to avoid attribute cluttering under character

	end

	if input.KeyCode == Enum.KeyCode.LeftControl then --makes you fly faster and doesnt work while boosting, also changes fov to give the illusion of speed

		if  not character:GetAttribute("Flying")  or not canBoost then return end 

		TweenService:Create(camera,tweenInfo, {["FieldOfView"] = 90}):Play()

		character:SetAttribute("Speed", character:GetAttribute("Speed") + 1)
	end

	if input.KeyCode == Enum.KeyCode.E and canBoost and character:GetAttribute("Flying") then --givesd you a massive flight speed boost for 1 second, also changes fov,

		canBoost = false --makes sure you cant stack boosts

		character:SetAttribute("Speed", character:GetAttribute("Speed") + 10)

		TweenService:Create(camera,tweenInfo, {["FieldOfView"] = 120}):Play()

		PlaySound("Boost", HRP)

		local Clone = VFX.Boost:Clone() --shockwave VFX
		Clone.Parent = workspace
		Clone.CFrame = HRP.CFrame

		for i, v in pairs(Clone:GetDescendants()) do
			if v:IsA("ParticleEmitter") then 
				v:Emit(1)
			end
		end

		task.delay(1, function() --resets the speed boost and fov, and lets you boost again

			character:SetAttribute("Speed", character:GetAttribute("Speed") - 10)

			TweenService:Create(camera,tweenInfo, {["FieldOfView"] = 70}):Play()

			canBoost = true
		end)
	end
end)

UserInputService.InputEnded:Connect(function(input, GPE) --stops movement on release

	if  GPE then return end

	if input.KeyCode.Name == currentDirection then --makes sure you dont fully stop if ur holding a diff key (EX:. holding A then D, and then letting go of A would stop you even if your still holding D, this prevents that)


		currentDirection = "Idle"

	end

	if input.KeyCode == Enum.KeyCode.LeftControl then --slows down your flight, doesnt work while boosting.

		if  not character:GetAttribute("Flying")  or not canBoost then return end 

		TweenService:Create(camera,tweenInfo, {["FieldOfView"] = 70}):Play()
		character:SetAttribute("Speed", character:GetAttribute("Speed") - 1)

	end
end)

character:GetAttributeChangedSignal("Flying"):Connect(function() --enables alignPosition and alignOrientation, and disables autorotate so rotation is handled by alignOrientation instead, does the opposite if flying attribute is false

	if character:GetAttribute("Flying") then

		alignOrientation.Enabled = true
		alignPosition.Enabled = true

		humanoid.AutoRotate = false 


		for i, v in pairs(LoopTable) do --enables trails
			local Clone = trailVFX:Clone()

			Clone.Parent = v
		end


	else

		alignOrientation.Enabled = false
		alignPosition.Enabled = false

		humanoid.AutoRotate = true
		
		TweenService:Create(camera,tweenInfo, {["FieldOfView"] = 70}):Play()-- gives the illusion of speed

		for i, v in pairs(LoopTable) do --prevents trails from staying after you stop flying

			if v:FindFirstChild("Default") then

				v.Default:Destroy()
			end
		end
	end
end)

RunService.Heartbeat:Connect(function()

	if character:GetAttribute("Flying") then --calculates in what direction to send alignPosition depending on what key ur holding, and how fast you should go based on the speed attribute.


		alignPosition.Position = (HRP.Position + (camera.CFrame[actionTable[currentDirection][1]] * (actionTable[currentDirection][2])  * character:GetAttribute("Speed"))) 



		alignOrientation.CFrame = camera.CFrame  -- makes the character face the camera's direction

		for i, v in pairs(actionTable) do --prevents anims from overlapping

			if i == currentDirection then

				if  v[3].IsPlaying then continue end

				v[3]:Play()

			else

				v[3]:Stop()
			end
		end

	else

		for i, v in pairs(actionTable) do
			v[3]:Stop()
		end --stops all flying anims if you arent flying

	end

	local target = mouse.Target 

	if target then-- lets you read item description by hovering over it, also makes sure the gui is ontop of ur mouse
		
		if target:FindFirstAncestor("items") then
			mainGui.HoverLabel.Visible = true
			mainGui.HoverLabel.Text = itemTable[target.Name].Description

			mainGui.HoverLabel.Position = UDim2.new(0, mouse.X - 100 , 0, mouse.Y - 50) 

		else
			mainGui.HoverLabel.Visible = false
		end
	end

end)

for i, v:Part in pairs(workspace.CheckPoints:GetChildren()) do 

	v.Touched:Connect(function(Part) -- ''activates'' a checkpoint when you touch it, then ''deactivates'' it after 20 seconds, ''activated'' checkpoints are turned green and play sfx, ''deactivated'' ones are red instead

		if not Part:FindFirstAncestor("Live") or v:GetAttribute("Touched") then return end 

		v:SetAttribute("Touched", true)

		v.Color = Color3.fromRGB(81, 255, 0)

		PlaySound("CheckpointSound", HRP, Random.new():NextNumber(0.9, 1.1))

		task.wait(20)

		v.Color = Color3.fromRGB(255, 0, 0)

		v:SetAttribute("Touched", false)


	end)
end

for i, v:Part in pairs(workspace.items:GetChildren()) do

	local TouchFunction = nil

	TouchFunction = v.Touched:Connect(function(Part)-- activates the item using the function inside the itemTable Dictionary and disconnects the function, also destroys the item

		TouchFunction:Disconnect() 
		v:Destroy()

		if itemTable[v.Name] then
			itemTable[v.Name].Activate()
		end
	end)
end
