local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEngineCore = require(game.ReplicatedStorage.EngineCore);

for _, s in pairs(script:GetChildren()) do
	if s.ClassName ~= "ModuleScript" then continue end;
	task.spawn(function()
		require(s):Init();
		Debugger:Warn(`Initialized {s.Name}`);
	end)
end

local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetModule(`ModPlayerScripts`, game.ReplicatedStorage);
if moddedSelf then 
	moddedSelf:Init();
end