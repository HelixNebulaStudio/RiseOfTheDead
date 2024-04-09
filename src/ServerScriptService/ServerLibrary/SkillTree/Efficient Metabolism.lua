local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== 
local Skill = {Library=nil;};
Skill.__index = Skill;
--==
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modWeaponsLibrary = require(game.ReplicatedStorage.Library.Weapons);
local modTools = require(game.ReplicatedStorage.Library.Tools);

--== Script;

function Skill:Trigger(profile, triggerType, points, storageItem)
	if storageItem == nil then return end;
	local toolLib = modTools[storageItem.ItemId];
	if toolLib and toolLib.Type == "FoodTool" then
		local classPlayer = modPlayers.GetByName(profile.Player.Name);
		if triggerType == "OnToolEquipped" then
			local level, stats = Skill:CalStats(Skill.Library, points);
			classPlayer:SetProperties(Skill.Library.Id, {Percent=stats.Percent.Value});
			
		elseif triggerType == "OnToolUnequipped" then
			classPlayer:SetProperties(Skill.Library.Id);
			
		end
	end
end

function Skill.init(skillTree, lib)
	Skill.Library = lib;
	setmetatable(Skill, skillTree);
	return Skill;
end

return Skill;
