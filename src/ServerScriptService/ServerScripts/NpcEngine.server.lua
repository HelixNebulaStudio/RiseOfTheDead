while shared.ReviveEngineLoaded ~= true do task.wait() end;
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
while shared.MasterScriptInit  ~= true do task.wait() end;
--==
local modNpc = Debugger:Require(game.ServerScriptService.ServerLibrary.Entity.Npc);

local bindFunction = script:WaitForChild("Function");

--==
bindFunction.OnInvoke = function(name, cframe, preloadCallback, customNpcModule)
	debug.profilebegin(name);
	local prefab = modNpc.DoSpawn(name, cframe, preloadCallback, customNpcModule);
	debug.profileend()
	return prefab;
end;