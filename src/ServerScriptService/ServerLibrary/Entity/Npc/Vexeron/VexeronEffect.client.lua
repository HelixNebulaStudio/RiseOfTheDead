local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local localplayer = game.Players.LocalPlayer;

local RunService = game:GetService("RunService");
local modData = require(localplayer:WaitForChild("DataModule"));
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modCharacter = modData:GetModCharacter();

local bossModel = script:WaitForChild("Prefab").Value; 
local humanoid = bossModel:WaitForChild("Zombie");
local rootPart = bossModel:WaitForChild("HumanoidRootPart");

local remoteVexeron = bossModel:WaitForChild("VexeronRemote", 5);

local Tracks = {};

local random = Random.new();
--== Script;
local parentChangeSignal, runLoop;
parentChangeSignal = bossModel:GetPropertyChangedSignal("Parent"):Connect(function()
	if bossModel.Parent ~= nil then return end
	parentChangeSignal:Disconnect();
	runLoop:Disconnect();
	script:Destroy();
end)

local function screenShake()
	local distance = localplayer:DistanceFromCharacter(rootPart.Position);
	modCharacter.CameraShakeAndZoom(math.clamp((128-distance)/128, 0, 1)*8, 0, 3, nil, false);
end

local lastTouchWater = tick()-5;
local lastGrowl = tick()-5;
local nextGrowl = 5;
runLoop = RunService.Heartbeat:Connect(function()
	if tick()-lastTouchWater > 5 then
		if rootPart.Position.Y <= -4.35 then
			lastTouchWater = tick();
			modAudio.Play("HeavySplash", rootPart).PlaybackSpeed = random:NextNumber(0.55, 1);
			screenShake();
		end
	end
	if tick()-lastGrowl > nextGrowl then
		lastGrowl = tick();
		nextGrowl = random:NextNumber(5, 15);
		modAudio.Play("VexeronGrowl", rootPart).PlaybackSpeed = random:NextNumber(0.55, 1);
	end
end)

wait(0.5)
for _, obj in pairs(bossModel:GetDescendants()) do
	if obj.Name == "BallSocketConstraint" 
	or obj.Name == "Weight" then
		obj:Destroy();
	end
	if obj:IsA("BasePart") then
		obj.CollisionGroup = "Default";
		obj.CanCollide = true;
	end
end

local touchDebounce = tick();
modCharacter.Character:WaitForChild("Humanoid").Touched:Connect(function(part)
	if part:IsDescendantOf(bossModel) and tick()-touchDebounce >= 4 then
		touchDebounce = tick();
		remoteVexeron:FireServer(part);
		modAudio.Play("HardSlice", rootPart);
		modCharacter.CameraShakeAndZoom(10, 0, 0.4, nil, false);
	end
end)