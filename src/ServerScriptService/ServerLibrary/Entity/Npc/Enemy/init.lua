local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

--== Modules Warn: Don't require(Npc)
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

return function(npc, spawnPoint)
	local self = modNpcComponent{};
return self end
