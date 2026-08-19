--Discord User: serataken
--Roblox User: Seraphynxx

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid:Humanoid = Character.Humanoid 
local Animator:Animator = Humanoid.Animator
local Camera = workspace.CurrentCamera
local MainGui = Player.PlayerGui.MainGui
local Mouse = Player:GetMouse()

local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Anims = ReplicatedStorage.Default --Animation Folder
local VFX = ReplicatedStorage.VFX
local TrailVFX = ReplicatedStorage.VFX.Default --Flight trails

local TweeInfo = TweenInfo.new(0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,0,false,0)

local CanBoost = true --check thats off whenever ur boosting so you cant stack boost with itself, nor ''fast fly''

local Att = Instance.new("Attachment")
Att.Parent = HRP

local AlignPos = Instance.new("AlignPosition") -- align position that will be used and reused for flight

AlignPos.Enabled = false --setting it to false as we arent using it right away
AlignPos.Mode = Enum.PositionAlignmentMode.OneAttachment -- setting it to 1 attachment as two are unecessary
AlignPos.MaxForce = math.huge --removes the speed cap
AlignPos.Responsiveness = 50

AlignPos.Attachment0 = Att
AlignPos.Parent = HRP 

local AlignOrientation = Instance.new("AlignOrientation")

AlignOrientation.Enabled = false
AlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment --  setting it to 1 attachment as two are unecessary
AlignOrientation.MaxTorque = math.huge  --removes the torque cap
AlignOrientation.Responsiveness = 50

AlignOrientation.Attachment0 = Att
AlignOrientation.Parent = HRP



local ActionTable = { -- a key, the direction associated with that key and the multiplier, followed by which anim to play
	["W"] = {"LookVector", 2, Animator:LoadAnimation(Anims.WFly),},
	["A"] = {"RightVector", -2, Animator:LoadAnimation(Anims.AFly),},
	["S"] = {"LookVector", -2, Animator:LoadAnimation(Anims.SFly),},
	["D"] = {"RightVector", 2, Animator:LoadAnimation(Anims.DFly),},
	["Idle"] = {"RightVector", 0, Animator:LoadAnimation(Anims.FlightIdle),},
} 
for i, v in pairs(ActionTable) do --preloads all anims, doing this method since content provider only works on instances
	v[3]:Play()

	v[3]:Stop()
end

local CurrentDirection = "Idle" -- used across the script to know what anim and direction to use from the actionTable Dictionary

local LoopTable = {

	Character:WaitForChild("LeftHand").LeftGripAttachment,
	Character:WaitForChild("RightHand").RightGripAttachment,
	Character:WaitForChild("LeftFoot").LeftFootAttachment,
	Character:WaitForChild("RightFoot").RightFootAttachment,
} -- table used to disable/enable trails inside the 4 attachments

local ItemTable = { --table for all the consumables in the game with hover descriptions and effects
	["Soder"] = {
		["Description"] = "gain +15 flight speed for 5 secs",

		["Activate"] = function()

			Character:SetAttribute("Speed", Character:GetAttribute("Speed" ) + 15)
			task.delay(5,function()
				Character:SetAttribute("Speed", Character:GetAttribute("Speed" ) - 15)

			end)
		end,

	},

	["Rotten Food"] = {
		["Description"] = "forces you to stop flying",

		["Activate"] = function()

			Character:SetAttribute("Flying", nil)

		end,

	},


	["Witches Brew"] = {
		["Description"] = "permanent +1 to flying speed",

		["Activate"] = function()

			Character:SetAttribute("Speed", Character:GetAttribute("Speed" ) + 1)

		end,

	},

	["Cat Food"] = {
		["Description"] = "WHY??? (permanent -1 to flying speed)",

		["Activate"] = function()

			Character:SetAttribute("Speed", Character:GetAttribute("Speed" ) - 1)

		end,

	},

}

Character:SetAttribute("Speed", 1) --used for speed multipliers, such as items


local function PlaySound(Sound:Sound, Parent, Speed) --used for playing SFX 
	Sound = game.SoundService:WaitForChild(Sound):Clone()

	Sound.Parent = Parent
	Sound:Play()
	Sound.PlaybackSpeed = Speed or Sound.PlaybackSpeed

	Debris:AddItem(Sound, Sound.TimeLength + 2)
end

UIS.InputBegan:Connect(function(input, GPE)

	if GPE then return end 

	if  ActionTable[input.KeyCode.Name] then CurrentDirection = input.KeyCode.Name  end  -- checks if the input is either W,A,S,D and sets the variable if it is

	if input.KeyCode == Enum.KeyCode.Space  and Humanoid:GetState() == Enum.HumanoidStateType.Freefall and CanBoost then --checks if character is airborne and pressing space

		Character:SetAttribute("Flying" , if Character:GetAttribute("Flying") then nil else true) -- sets flying to true if they arent flying, otherwise sets it to nil (setting to nil  instead of false so the attribute isnt shown and clutter/bloat the character attributes)

	end

	if input.KeyCode == Enum.KeyCode.LeftControl then

		if  not Character:GetAttribute("Flying")  or not CanBoost then return end 

		TweenService:Create(Camera,TweeInfo, {["FieldOfView"] = 90}):Play()

		Character:SetAttribute("Speed", Character:GetAttribute("Speed") + 1)
	end

	if input.KeyCode == Enum.KeyCode.E and CanBoost and Character:GetAttribute("Flying") then

		CanBoost = false

		Character:SetAttribute("Speed", Character:GetAttribute("Speed") + 10)

		TweenService:Create(Camera,TweeInfo, {["FieldOfView"] = 120}):Play()

		PlaySound("Boost", HRP)

		local Clone = VFX.Boost:Clone() --shockwave VFX
		Clone.Parent = workspace
		Clone.CFrame = HRP.CFrame

		for i, v in pairs(Clone:GetDescendants()) do
			if v:IsA("ParticleEmitter") then 
				v:Emit(1)
			end
		end

		task.delay(1, function()

			Character:SetAttribute("Speed", Character:GetAttribute("Speed") - 10)

			TweenService:Create(Camera,TweeInfo, {["FieldOfView"] = 70}):Play()

			CanBoost = true
		end)
	end
end)

UIS.InputEnded:Connect(function(input, GPE) --stops movement on release

	if  GPE then return end

	if input.KeyCode.Name == CurrentDirection then --makes sure u only stop when no other key is being held


		CurrentDirection = "Idle"

	end

	if input.KeyCode == Enum.KeyCode.LeftControl then

		if  not Character:GetAttribute("Flying")  or not CanBoost then return end

		TweenService:Create(Camera,TweeInfo, {["FieldOfView"] = 70}):Play()
		Character:SetAttribute("Speed", Character:GetAttribute("Speed") - 1)

	end
end)

Character:GetAttributeChangedSignal("Flying"):Connect(function() --enables align orientation and position whenever the flying attribute is true, disables otherwise, also disables auto rotation so turning around is handled by align orientation only

	if Character:GetAttribute("Flying") then

		AlignOrientation.Enabled = true
		AlignPos.Enabled = true

		Humanoid.AutoRotate = false --makes sure u cant rotate with shiftlock


		for i, v in pairs(LoopTable) do --enables trails
			local Clone = TrailVFX:Clone()

			Clone.Parent = v
		end


	else

		AlignOrientation.Enabled = false
		AlignPos.Enabled = false

		Humanoid.AutoRotate = true
		
		TweenService:Create(Camera,TweeInfo, {["FieldOfView"] = 70}):Play()-- makes sure the fov change from ''fast flying'' (aka holding control) isnt kept if u stop flying while doing it

		for i, v in pairs(LoopTable) do --disables trails

			if v:FindFirstChild("Default") then

				v.Default:Destroy()
			end
		end
	end
end)

RS.Heartbeat:Connect(function()--runs every frame after physics

	if Character:GetAttribute("Flying") then


		--moves the character using align pos, adds the CFrame of the HRP (HRP[LookVector or RightVector] * 1 or -1), look in ActionTable for reference
		AlignPos.Position = (HRP.Position + (Camera.CFrame[ActionTable[CurrentDirection][1]] * (ActionTable[CurrentDirection][2])  * Character:GetAttribute("Speed"))) 



		AlignOrientation.CFrame = Camera.CFrame  -- updates the align orientation to face the same direction as the camera

		for i, v in pairs(ActionTable) do --plays the anm for the current key, and stops the anims for all other keys to avoid overlapping

			if i == CurrentDirection then

				if  v[3].IsPlaying then continue end

				v[3]:Play()

			else

				v[3]:Stop()
			end
		end

	else

		for i, v in pairs(ActionTable) do
			v[3]:Stop()
		end --stops all anims if you arent flying

	end

	local Target = Mouse.Target --gets the mouse target, used for the items

	if Target then --updates the hover text with the item description and makes it visible, or makes it not visible if you arent hovering over anything
		if Target:FindFirstAncestor("items") then
			MainGui.HoverLabel.Visible = true
			MainGui.HoverLabel.Text = ItemTable[Target.Name].Description

			MainGui.HoverLabel.Position = UDim2.new(0, Mouse.X - 100 , 0, Mouse.Y - 50) --constantly updates the gui position to be ontop of ur mouse

		else
			MainGui.HoverLabel.Visible = false
		end
	end

end)

for i, v:Part in pairs(workspace.CheckPoints:GetChildren()) do 

	v.Touched:Connect(function(Part) -- makes the touched checkpoint green, makes a noise then makes it red again after 20 secs

		if not Part:FindFirstAncestor("Live") or v:GetAttribute("Touched") then return end --checks if what touched it is acctualy a player and if it already has been touched before

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

	TouchFunction = v.Touched:Connect(function(Part)-- activates the item using the function inside the ItemTable Dictionary and disconnects the function, also destroys the item

		TouchFunction:Disconnect() 
		v:Destroy()

		if ItemTable[v.Name] then
			ItemTable[v.Name].Activate()
		end
	end)
end
