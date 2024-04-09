local RunService = game:GetService("RunService");
local targetDummy = workspace:WaitForChild("Environment"):WaitForChild("TargetDummy");
local destructible = game.ServerScriptService:WaitForChild("ServerLibrary", 10):WaitForChild("Destructibles", 10);

repeat until game.Players:FindFirstChildWhichIsA("Player") or not RunService.Heartbeat:Wait();
local mod = require(targetDummy:WaitForChild("Destructible"));
print("TargetDummy>> Activated.");