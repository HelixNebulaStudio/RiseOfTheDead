local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

--== Script;
local Component = {};
Component.__index = Component;

function Component.new(Npc)
	local self = {};
	
	setmetatable(self, Component);
	return function(npcName)
		local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
		
		modNpc.Spawn(npcName, nil, function(npc, npcModule)
			npcModule:AddComponent("AutoRespawn");
		end);
	end;
end

return Component;