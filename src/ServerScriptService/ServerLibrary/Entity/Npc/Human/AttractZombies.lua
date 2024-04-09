local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local random = Random.new();

local Component = {};
Component.__index = Component;

function Component.new(Npc)
	local self = {
		AttractRange = 32;
		IsActive = true;
	};
	
	spawn(function()
		repeat
			if not Npc.IsDead and self.IsActive then
				local enemies = Npc.NpcService.AttractEnemies(Npc.Prefab, self.AttractRange, function(modNpcModule)
					return modNpcModule.Humanoid and modNpcModule.Humanoid.Name == "Zombie";
				end);
				if Npc.OnTarget then
					Npc.OnTarget(enemies); -- Alert self enemies approaching.
				end
			end
		until Npc.IsDead or Npc.Humanoid.RootPart == nil or not task.wait(1);
	end)
	setmetatable(self, Component);
	return self;
end

return Component;