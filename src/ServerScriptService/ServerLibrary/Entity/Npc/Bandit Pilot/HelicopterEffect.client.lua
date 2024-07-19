local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local localplayer = game.Players.LocalPlayer;

local RunService = game:GetService("RunService");
local modData = require(localplayer:WaitForChild("DataModule"));
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modCharacter = modData:GetModCharacter();

local prefabObjVal = script:WaitForChild("Prefab");
while prefabObjVal.Value == nil do task.wait() end;
local pilotPrefab = prefabObjVal.Value;

local helicopterModel = pilotPrefab:WaitForChild("Helicopter");
local animationController = helicopterModel:WaitForChild("AnimationController");
local rootPart = helicopterModel:WaitForChild("Root");

local random = Random.new();
--== Script;
local parentChangeSignal, runLoop;
parentChangeSignal = helicopterModel:GetPropertyChangedSignal("Parent"):Connect(function()
	if helicopterModel.Parent ~= nil then return end
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

local topRotorAnimation = animationController:LoadAnimation(script:WaitForChild("TopRotor"));
topRotorAnimation:Play();
modAudio.Play("HelicopterCore", rootPart);

wait(0.5)

local function updateCollision(model)
	if model:IsA("BasePart") then
		model.CollisionGroup = "Default";
		model.CanCollide = true;
	end
	for _, obj in pairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.CollisionGroup = "Default";
			obj.CanCollide = true;
		end
	end
end
while true do
	updateCollision(helicopterModel);
	wait(3);
end