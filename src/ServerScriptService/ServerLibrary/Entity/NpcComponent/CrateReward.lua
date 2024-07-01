local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local modProfile = shared.modProfile;
local modCrates = require(game.ServerScriptService.ServerLibrary.Crates);
local modCrateLibrary = require(game.ReplicatedStorage.Library.CrateLibrary);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);

--== Script;
local Component = {};

function Component.new(Npc)
	return function(self, cframe, winners)
		local id = self.Configuration and self.Configuration.CrateId;
		
		local crateLib = modCrateLibrary.Get(id);
		if crateLib == nil then Debugger:Warn("Missing crate library for id:",id); end;
		
		local rewards = modCrates.GenerateRewards(id, nil, {HardMode=self.HardMode;});
		if #rewards <= 0 then return end;
			
		local rewardsLib = modRewardsLibrary:Find(id);
		local rewardRecipient = {};
		for a=1, #winners do
			local profile = modProfile:Get(winners[a]);
			local playerSave = profile and profile:GetActiveSave();
			local playerLevel = playerSave and playerSave:GetStat("Level") or 0;

			if rewardsLib.Level == nil or playerLevel >= rewardsLib.Level then
				table.insert(rewardRecipient, winners[a]);
			end
		end
		
		return modCrates.Spawn(id, cframe, rewardRecipient, rewards);
	
	end;
end

return Component;