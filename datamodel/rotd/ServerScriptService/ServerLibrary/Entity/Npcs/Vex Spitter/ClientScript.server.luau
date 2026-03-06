local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local characterTag = script:WaitForChild("Character");
repeat task.wait(0.1) until characterTag.Value ~= nil;

local character = characterTag.Value;
if not workspace:IsAncestorOf(character) then return end;

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