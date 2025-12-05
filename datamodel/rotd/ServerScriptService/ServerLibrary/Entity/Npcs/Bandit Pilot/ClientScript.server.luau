local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local characterTag = script:WaitForChild("Character");
repeat task.wait(0.1) until characterTag.Value ~= nil;

local character = characterTag.Value;
if not workspace:IsAncestorOf(character) then return end;

local helicopterTag = character:WaitForChild("Helicopter");
repeat task.wait(0.1) until characterTag.Value ~= nil;

local heliModel = helicopterTag.Value;
if not workspace:IsAncestorOf(heliModel) then return end;

local animationController = heliModel:WaitForChild("AnimationController");

local localplayer = game.Players.LocalPlayer;
local modData = shared.require(localplayer:WaitForChild("DataModule") :: ModuleScript);
local modCharacter = modData:GetModCharacter();

--==
local humanoid = character:WaitForChild("Bandit");
local rootPart = character:WaitForChild("HumanoidRootPart");

local animationsFolder = heliModel:WaitForChild("Animations");
local heliRoot = heliModel:WaitForChild("Root");

local topRotorAnimation = animationController:LoadAnimation(animationsFolder:WaitForChild("TopRotor"));
topRotorAnimation:Play();
modAudio.Preload("HelicopterCore", 5);
modAudio.Play("HelicopterCore", heliRoot);

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

for _, spotTargetTag in pairs(heliRoot:GetDescendants()) do
	if spotTargetTag.Name ~= "SpotTarget" then continue end;

	local pointAtt = spotTargetTag.Parent;
	local defaultCf = pointAtt.CFrame;
	RunService.Heartbeat:Connect(function()
		local targetPart = spotTargetTag.Value;
		if targetPart == nil then
			pointAtt.CFrame = defaultCf;
			return;
		end;

		local targetCf = targetPart.CFrame;
		local newCf = CFrame.lookAt(pointAtt.WorldPosition, targetCf.Position);
		local localCf = heliRoot.CFrame:ToObjectSpace(newCf);

		pointAtt.CFrame = localCf;
	end)
end

while true do
	updateCollision(heliModel);
	wait(3);
end