local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local RunService = game:GetService("RunService");

local modItemDrops = require(game.ServerScriptService.ServerLibrary.ItemDrops);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);

--== Script;
local Component = {};

function Component.new(Npc)
	function Npc.UpdateDropReward(self, resourceDrop)
		self.Configuration.ResourceDrop = resourceDrop;
	end
	
	return function(self, cframe)
		local offset = self.DropRewardOffset or Vector3.zero;
		local resourceTable = self.Configuration and self.Configuration.ResourceDrop or nil;
		
		if RunService:IsStudio() then
			Debugger:Log(self.Name," dropped ",resourceTable and resourceTable.Id or nil);
		end
		
		if resourceTable then
			local itemDrop = modItemDrops.ChooseDrop(resourceTable);
			if itemDrop then
				modItemDrops.Spawn(itemDrop, cframe + offset + Vector3.new(random:NextNumber(-0.5, 0.5), 0, random:NextNumber(-0.5, 0.5)));
			end
		end
		
		local spawnLayerName = self.MapLayerName;
		if spawnLayerName then
			local regionDropRewardLib = modRewardsLibrary:Find("RegionDrop:"..spawnLayerName);
			
			if regionDropRewardLib then
				local itemDrop = modItemDrops.ChooseDrop(regionDropRewardLib);
				if itemDrop then
					modItemDrops.Spawn(itemDrop, cframe + offset + Vector3.new(random:NextNumber(-0.5, 0.5), 0, random:NextNumber(-0.5, 0.5)));
				end
			end
		end
		
	end;
end

return Component;