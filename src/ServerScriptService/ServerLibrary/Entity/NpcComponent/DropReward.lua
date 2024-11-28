local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modItemDrops = require(game.ServerScriptService.ServerLibrary.ItemDrops);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);

--== Script;
local Component = {};

function Component.new(Npc)
	function Npc.UpdateDropReward(self, resourceDrop)
		self.Configuration.ResourceDrop = resourceDrop;
	end
	
	return function(self, cframe)
		local offset = self.DropRewardOffset or Vector3.zero;
		local resourceTable = self.Configuration and self.Configuration.ResourceDrop or nil;
		
		if resourceTable then
			local itemDrop = modItemDrops.ChooseDrop(resourceTable);
			if itemDrop then
				local despawnTime = 30;
				modItemDrops.Spawn(
					itemDrop,
					cframe + offset, --+ Vector3.new(math.random(-50, 50)/100 , -1.5, math.random(-50, 50)/100)
					nil,
					despawnTime,
					{
						ApplyForce = 1;
					}
				);
			end
		end
		
		local spawnLayerName = self.MapLayerName;
		if spawnLayerName then
			local regionDropRewardLib = modRewardsLibrary:Find("RegionDrop:"..spawnLayerName);
			
			if regionDropRewardLib then
				local itemDrop = modItemDrops.ChooseDrop(regionDropRewardLib);
				if itemDrop then
					modItemDrops.Spawn(itemDrop, cframe + offset + Vector3.new(math.random(-50, 50)/100, -1.5, math.random(-50, 50)/100));
				end
			end
		end
		
		modOnGameEvents:Fire("OnDropReward", self, cframe);
	end;
end

return Component;