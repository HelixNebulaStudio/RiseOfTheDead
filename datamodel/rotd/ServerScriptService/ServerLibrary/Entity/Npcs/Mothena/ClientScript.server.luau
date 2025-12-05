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

local localplayer = game.Players.LocalPlayer;
local modData = shared.require(localplayer:WaitForChild("DataModule") :: ModuleScript);
local modCharacter = modData:GetModCharacter();
local playerClass: PlayerClass = shared.modPlayers.get(localplayer);

local playerRootPart = playerClass.RootPart;
--==
local humanoid = character:WaitForChild("Zombie");
local animator: Animator = humanoid:WaitForChild("Animator") :: Animator;
local rootPart = character:WaitForChild("HumanoidRootPart");

local wingsAnimation = animator:LoadAnimation(script:WaitForChild("Fly"));
wingsAnimation:Play();

modAudio.Preload("WingsCore", 5);
local wingsCoreSound = modAudio.Play("WingsCore", rootPart);

humanoid:GetAttributeChangedSignal("IsDead"):Connect(function()
	if not humanoid:GetAttribute("IsDead") then return end;
	wingsAnimation:Stop();

	if wingsCoreSound then
		wingsCoreSound:Destroy();
	end
end)