local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local CollectionService = game:GetService("CollectionService");

local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

local fireCooldown = tick();
return function(safehouseId, hitPart)
	if tick() <= fireCooldown+0.5 then return end;
	fireCooldown = tick();
	
	local model = hitPart.Parent;
	if not model:IsA("Model") then return end;
	
	local damagable = modDamagable.NewDamagable(model);
	if damagable then
		local npcStatus = damagable.Object;
		if npcStatus.ClassName == "NpcStatus" and npcStatus.NpcModule and npcStatus.NpcModule.Humanoid.Health > 0 then
			local humans = CollectionService:GetTagged("Humans");
			
			for a=1, #humans do
				local humanNpcModule = modNpc.GetNpcModule(humans[a]);
				if humanNpcModule.SafehouseId == safehouseId and humanNpcModule.Enemies and damagable:CanDamage(humanNpcModule) then
					local exist = false;
					for b=1, #humanNpcModule.Enemies do
						if humanNpcModule.Enemies[b] == model then
							exist = true;
							break;
						end
					end
					
					if not exist then
						table.insert(humanNpcModule.Enemies, model);
					end
				end
			end
		end
	end
end;
