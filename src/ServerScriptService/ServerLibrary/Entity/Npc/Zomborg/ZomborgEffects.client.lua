local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local localplayer = game.Players.LocalPlayer;

local RunService = game:GetService("RunService");
local modData = require(localplayer:WaitForChild("DataModule"));
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modArcParticles = require(game.ReplicatedStorage.Particles.ArcParticles);
local modCharacter = modData:GetModCharacter();

local prefabObjVal = script:WaitForChild("Prefab");
while prefabObjVal.Value == nil do task.wait() end;
local bossModel = prefabObjVal.Value;

local humanoid = bossModel:WaitForChild("Zombie");
local rootPart = bossModel:WaitForChild("HumanoidRootPart");

local zomborgRemote = bossModel:WaitForChild("ZomborgRemote", 10);

local Arc = {
	Color = Color3.fromRGB(255, 0, 4);
	Color2 = Color3.fromRGB(8, 0, 255);
	Amount = 2;
	Thickness = 0.35;
};

--== Script;
zomborgRemote.OnClientEvent:Connect(function(effect, ...)
	if effect == "shock" then
		local part = ...;
		local att1 = Instance.new("Attachment");
		att1.Parent = bossModel.LeftHand;
		local att2 = Instance.new("Attachment");
		att2.Parent = part;

		local arc = modArcParticles.link(
			att1,
			att2,
			Arc.Color,
			Arc.Color2,
			5,
			0.5
		);
		delay(2, function()
			if arc then arc:Destroy(); end;
		end)

		local diff = bossModel.LeftHand.Position-part.Position;
		local dist = diff.Magnitude;

		local shock = Instance.new("Part");
		shock.Color = Color3.fromRGB(255, 0, 0);
		shock.CanCollide = false;
		shock.Shape = Enum.PartType.Cylinder;
		shock.Size = Vector3.new(dist, 1, 1);
		shock.Material = Enum.Material.ForceField;
		shock.Massless = true;
		shock.CFrame = CFrame.new(bossModel.LeftHand.Position-(diff)/2, bossModel.LeftHand.Position) * CFrame.Angles(0, math.rad(90), 0);
		shock.Anchored = true;
		shock.Parent = workspace.Debris;
		game.Debris:AddItem(shock, 0.5);
		while (shock.Parent ~= nil) do
			diff = bossModel.LeftHand.Position-part.Position;
			dist = diff.Magnitude;
			shock.Size = Vector3.new(dist, 1, 1);
			shock.CFrame = CFrame.new(bossModel.LeftHand.Position-(diff)/2, bossModel.LeftHand.Position) * CFrame.Angles(0, math.rad(90), 0);

			RunService.Heartbeat:Wait();
		end
		arc:Destroy();
		arc = nil;
	end
end)


--local Tracks = {};

--local random = Random.new();
--== Script;
--local parentChangeSignal, runLoop;
--parentChangeSignal = bossModel:GetPropertyChangedSignal("Parent"):Connect(function()
--	if bossModel.Parent ~= nil then return end
--	parentChangeSignal:Disconnect();
--	runLoop:Disconnect();
--	script:Destroy();
--end)

--local function screenShake()
--	local distance = localplayer:DistanceFromCharacter(rootPart.Position);
--	modCharacter.CameraShakeAndZoom(math.clamp((128-distance)/128, 0, 1)*8, 0, 3, nil, false);
--end

--local lastTouchWater = tick()-5;
--local lastGrowl = tick()-5;
--local nextGrowl = 5;
--runLoop = RunService.Heartbeat:Connect(function()
--	if tick()-lastTouchWater > 5 then
--		if rootPart.Position.Y <= -4.35 then
--			lastTouchWater = tick();
--			modAudio.Play("HeavySplash", rootPart).PlaybackSpeed = random:NextNumber(0.55, 1);
--			screenShake();
--		end
--	end
--	if tick()-lastGrowl > nextGrowl then
--		lastGrowl = tick();
--		nextGrowl = random:NextNumber(5, 15);
--		modAudio.Play("VexeronGrowl", rootPart).PlaybackSpeed = random:NextNumber(0.55, 1);
--	end
--end)

--wait(0.5)
--for _, obj in pairs(bossModel:GetDescendants()) do
--	if obj.Name == "BallSocketConstraint" 
--	or obj.Name == "Weight" then
--		obj:Destroy();
--	end
--	if obj:IsA("BasePart") then
--		obj.CollisionGroup = "Default";
--		obj.CanCollide = true;
--	end
--end

--local touchDebounce = tick();
--localplayer.Character:WaitForChild("Humanoid").Touched:Connect(function(part)
--	if part:IsDescendantOf(bossModel) and tick()-touchDebounce >= 4 then
--		touchDebounce = tick();
--		remoteVexeron:FireServer(part);
--		modAudio.Play("HardSlice", rootPart);
--		modCharacter.CameraShakeAndZoom(10, 0, 0.4, nil, false);
--	end
--end)