local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modVoxelSpace = shared.require(game.ReplicatedStorage.Library.VoxelSpace);

local chunkStats = modVoxelSpace.new();
chunkStats.StepSize = 64;
--== When a npc takes damage;
return function(event: EventPacket, ...)
    local npcClass: NpcClass = ...;
    if npcClass == nil or npcClass.Name ~= "Zombie" then return end;

	local deathPosition = npcClass.Properties.DeathPosition;
	local level = npcClass.Properties.Level;	
	
	if modConfigurations.WithererSpawnLogic == true then
		local voxelPoint = chunkStats:GetOrDefault(chunkStats:GetVoxelPosition(deathPosition, 64), {});
		local voxelData = voxelPoint.Value;
		
		if voxelData.WithererTrigger == nil then
			voxelData.WithererTrigger = {};
		end
		local withererSpawnData = voxelData.WithererTrigger;
		
		withererSpawnData.Counter = (withererSpawnData.Counter or 0) +1;
		
		if withererSpawnData.Counter > 20 then
			withererSpawnData.Counter = 0;

			local witherList = shared.modNpcs.listNpcClasses(function(npcClass: NpcClass)
				return npcClass.Name == "Witherer";
			end);
			if #witherList <= 5 then
                shared.modNpcs.spawn2{
                    Name = "Witherer";
					CFrame = CFrame.new(deathPosition);
					BindSetup = function(npcClass: NpcClass)
						npcClass.Properties.Level = level;
					end;
                };
			end
		end
	end
end;
