local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local characterTag = script:WaitForChild("Character");
repeat task.wait(0.1) until characterTag.Value ~= nil;

local character = characterTag.Value;
if not workspace:IsAncestorOf(character) then return end;

local localplayer = game.Players.LocalPlayer;
local modData = shared.require(localplayer:WaitForChild("DataModule") :: ModuleScript);
local modCharacter = modData:GetModCharacter();
--==

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local humanoid = character:WaitForChild("Zombie");
local rootPart = character:WaitForChild("HumanoidRootPart");


local function screenShake()
	local distance = localplayer:DistanceFromCharacter(rootPart.Position);
	modCharacter.CameraShakeAndZoom(math.clamp((128-distance)/128, 0, 1)*8, 0, 0.5, nil, false);
end

local lastTouchWater = tick()-5;
local lastGrowl = tick()-5;
local nextGrowl = 5;
runLoop = RunService.Heartbeat:Connect(function()
	if tick()-lastTouchWater > 5 then
		if rootPart.Position.Y <= -4.35 then
			lastTouchWater = tick();
			modAudio.Play("HeavySplash", rootPart).PlaybackSpeed = math.random(55, 100)/100;
			screenShake();
		end
	end
	if tick()-lastGrowl > nextGrowl then
		lastGrowl = tick();
		nextGrowl = math.random(5, 15);
		modAudio.Preload("VexeronGrowl", 5);
		modAudio.Play("VexeronGrowl", rootPart).PlaybackSpeed = math.random(55, 100)/100;
	end
end)


task.wait(0.5);

for _, obj in pairs(character:GetDescendants()) do
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
local remoteVexeron = character:WaitForChild("VexeronRemote", 5);
game.Players.LocalPlayer.Character:WaitForChild("Humanoid").Touched:Connect(function(part)
	if not part:IsDescendantOf(character) then return end;
	if tick()-touchDebounce < 4 then return end;
	touchDebounce = tick();

	remoteVexeron:FireServer(part);
	modAudio.Play("HardSlice", rootPart);
	modCharacter.CameraShakeAndZoom(10, 0, 0.4, nil, false);
end)