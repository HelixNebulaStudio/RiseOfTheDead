local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Script;

local modCrates = shared.require(game.ReplicatedStorage.Library.Crates);
local modCrateLibrary = shared.require(game.ReplicatedStorage.Library.CrateLibrary);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);

local Component = {};
Component.ClassName = "NpcComponent";
Component.__index = Component;
--==

function Component.new(npcClass: NpcClass)
	local self = {
		NpcClass = npcClass;
	};
	
	setmetatable(self, Component);
	return self;
end

function Component:__call(cframe: CFrame, winners: {Player})
	local npcClass: NpcClass = self.NpcClass;
	local rawProperties = npcClass.Properties.Values;

	local crateId = rawProperties.CrateId;
	local crateLib = modCrateLibrary.Get(crateId);
	if crateLib == nil then Debugger:Warn("Missing crate library for id:",crateId); end;
	
	local rewards = modCrates.GenerateRewards(crateId, nil, {HardMode=rawProperties.HardMode;});
	if #rewards <= 0 then return end;
		
	local rewardsLib = modRewardsLibrary:Find(crateId);

	local rewardRecipient = {};
	for a=1, #winners do
		local profile = shared.modProfile:Get(winners[a]);
		local gameSave = profile and profile:GetActiveSave();
		local playerLevel = gameSave and gameSave:GetStat("Level") or 0;

		if rewardsLib.Level == nil or playerLevel >= rewardsLib.Level then
			table.insert(rewardRecipient, winners[a]);
		end
	end
	
	return modCrates.spawn(crateId, cframe, rewardRecipient, rewards);
end

return Component;