local BossSpawn = {};

local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);

function BossSpawn.new(entityObject, ...)
	local self = {};
	self.OnBossDefeated = modEventSignal.new("OnBossDefeated");
	
	local spawnCframe = entityObject.Script.Parent.CFrame + Vector3.new(0, 2.5, 0);
	
	local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	function self:SpawnBoss(spawnType, customNpcModuleName, preloadFunc)
		local customNpcModule = customNpcModuleName and modNpc.NpcBaseModules[customNpcModuleName];
		
		local rNpcModule = nil;
		modNpc.Spawn(spawnType, spawnCframe, function(npc, npcModule)
			rNpcModule = npcModule;
			npcModule.OnTarget(game.Players:GetPlayers());
			
			if preloadFunc then
				preloadFunc(npcModule);
			end
			
			npcModule.Humanoid.Died:Connect(function()
				self.OnBossDefeated:Fire(npcModule);
			end);
			
		end, customNpcModule);
		
		return rNpcModule;
	end
	
	setmetatable(self, BossSpawn);
	return self;
end

return BossSpawn;