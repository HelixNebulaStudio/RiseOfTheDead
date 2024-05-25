local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local DropRateCalculator = {};
--==
local RunService = game:GetService("RunService");

local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modPseudoRandom = require(game.ReplicatedStorage.Library.PseudoRandom);

if RunService:IsServer() then
	modGlobalRandom = require(game.ServerScriptService.ServerLibrary.GlobalRandom);
end

local randoms = {};
--==
function DropRateCalculator.Calculate(rewardLib, criteria)
	local rewards = rewardLib.Rewards;
	if rewards == nil then 
		Debugger:Warn("Unknown rewards library for ",rewardLib.Id);
		return {};
	end;
	local indexGroups = {};
	for a=1, #rewards do
		local rewardInfo = rewards[a];
		if rewardInfo then
			local index = rewardInfo.Index or 1;
			local indexGroupMeta;
			if indexGroups[index] == nil then
				indexGroupMeta = {};
				indexGroupMeta.__index = indexGroupMeta;
				indexGroupMeta.TopChance = 0;
				indexGroupMeta.TotalChance = 0;
				
				indexGroups[index] = {};
				setmetatable(indexGroups[index], indexGroupMeta);
			end
			indexGroupMeta = indexGroupMeta or getmetatable(indexGroups[index]);
			
			local addChance = rewardInfo.Chance;
			if rewardInfo.Chance > indexGroupMeta.TopChance then
				indexGroupMeta.TopChance = rewardInfo.Chance;
			end
			
			if rewardInfo.Weekday then
				addChance = rewardInfo.Weekday == modSyncTime.GetWeekDay() and 1 or 0;
			end
			
			if rewardInfo.HardMode and (criteria == nil or criteria.HardMode ~= true) then
				addChance = 0;
			end
			
			local min, max = indexGroupMeta.TotalChance, indexGroupMeta.TotalChance + addChance;
			rewardInfo.Min = min;
			rewardInfo.Max = max;
			table.insert(indexGroups[index], rewardInfo);
			indexGroupMeta.TotalChance = max;
		end
	end
	for a=1, #indexGroups do
		local indexGroupMeta = getmetatable(indexGroups[a]);
		if indexGroupMeta.TopChance < 1 then
			local emptyOdds = 1-indexGroupMeta.TopChance;
			indexGroupMeta.TotalChance = indexGroupMeta.TotalChance + emptyOdds;
		end
	end
	return indexGroups;
end

function DropRateCalculator.RollDrop(rewardLib, player, criteria)
	local groups = DropRateCalculator.Calculate(rewardLib, criteria);
	
	local rolls = 0;
	
	if typeof(player) == "Instance" then
		rolls = modPseudoRandom:NextNumber(player, rewardLib.Id, 0, 1);
		
	elseif player == "Global" then
		rolls = modGlobalRandom:NextNumber(rewardLib.Id, 0, 1);
		
	else
		if randoms[rewardLib.Id] == nil then
			randoms[rewardLib.Id] = Random.new();
		end
		
		rolls = randoms[rewardLib.Id]:NextNumber();
		
	end
	
	local drops = {};
	for a=1, #groups do
		local aRoll = groups[a].TotalChance * rolls;
		
		for b=1, #groups[a] do
			local rewardInfo = groups[a][b];
			if rewardInfo.Min < aRoll and aRoll <= rewardInfo.Max then

				if typeof(rewardInfo.Quantity) == "table" then
					rewardInfo.DropQuantity = Random.new(rolls*10000):NextInteger(rewardInfo.Quantity.Min, rewardInfo.Quantity.Max);
				else
					rewardInfo.DropQuantity = rewardInfo.Quantity or 1;
				end

				table.insert(drops, rewardInfo);
				break;
			end
		end
	end
	return drops;
end

return DropRateCalculator;