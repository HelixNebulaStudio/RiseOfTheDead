local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local localplayer = game.Players.LocalPlayer;

local RunService = game:GetService("RunService");
local modData = require(localplayer:WaitForChild("DataModule"));
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modCharacter = modData:GetModCharacter();

local prefab = script:WaitForChild("Prefab").Value; 
local humanoid = prefab:WaitForChild("Zombie");
local rootPart = prefab:WaitForChild("HumanoidRootPart");

local random = Random.new();
--== Script;
local parentChangeSignal, runLoop;
parentChangeSignal = prefab:GetPropertyChangedSignal("Parent"):Connect(function()
	if prefab.Parent ~= nil then return end
	parentChangeSignal:Disconnect();
	runLoop:Disconnect();
	script:Destroy();
end)

local function screenShake()
	local distance = localplayer:DistanceFromCharacter(rootPart.Position);
	modCharacter.CameraShakeAndZoom(math.clamp((128-distance)/128, 0, 1)*8, 0, 1, nil, false);
end

runLoop = RunService.Heartbeat:Connect(function()
end)

local wingsAnimation = humanoid:LoadAnimation(script:WaitForChild("Fly"));
wingsAnimation:Play();

modAudio.Play("WingsCore", rootPart);

--wait(0.5)
--for _, obj in pairs(helicopterModel:GetDescendants()) do
--	if obj.Name == "BodyPosition" 
--	or obj.Name == "BodyGyro" then
--		obj:Destroy();
--	end
--end