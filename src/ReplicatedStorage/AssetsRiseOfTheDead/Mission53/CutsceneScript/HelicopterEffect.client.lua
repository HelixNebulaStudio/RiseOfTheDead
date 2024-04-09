local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local localplayer = game.Players.LocalPlayer;

local RunService = game:GetService("RunService");
local modData = require(localplayer:WaitForChild("DataModule"));
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modCharacter = modData:GetModCharacter();

local helicopterModel = script:WaitForChild("Prefab").Value; 
local animationController = helicopterModel:WaitForChild("AnimationController");
local rootPart = helicopterModel:WaitForChild("Root");

local random = Random.new();
--== Script;
local parentChangeSignal, runLoop;
parentChangeSignal = helicopterModel:GetPropertyChangedSignal("Parent"):Connect(function()
	if helicopterModel.Parent ~= nil then return end
	parentChangeSignal:Disconnect();
	script:Destroy();
end)


local topRotorAnimation = animationController:LoadAnimation(script:WaitForChild("TopRotor"));
topRotorAnimation:Play();
modAudio.Play("HelicopterCore", rootPart);

--wait(0.5)
--for _, obj in pairs(helicopterModel:GetDescendants()) do
--	if obj.Name == "BodyPosition" 
--	or obj.Name == "BodyGyro" then
--		obj:Destroy();
--	end
--end