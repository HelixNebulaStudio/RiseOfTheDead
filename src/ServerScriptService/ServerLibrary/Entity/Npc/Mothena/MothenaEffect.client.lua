local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local localplayer = game.Players.LocalPlayer;

local RunService = game:GetService("RunService");
local modData = require(localplayer:WaitForChild("DataModule") :: ModuleScript);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modCharacter = modData:GetModCharacter();

local prefab = script:WaitForChild("Prefab").Value; 
local humanoid: Humanoid = prefab:WaitForChild("Zombie");
local animator: Animator = humanoid:WaitForChild("Animator") :: Animator;
local rootPart = prefab:WaitForChild("HumanoidRootPart");

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

local wingsAnimation = animator:LoadAnimation(script:WaitForChild("Fly"));
wingsAnimation:Play();

local wingsCoreSound = modAudio.Play("WingsCore", rootPart);

humanoid:GetAttributeChangedSignal("IsDead"):Connect(function()
	if not humanoid:GetAttribute("IsDead") then return end;
	wingsAnimation:Stop();
	wingsCoreSound:Destroy();
end)