local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== 
local Skill = {Library=nil;};
Skill.__index = Skill;
--==
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modWeaponsLibrary = require(game.ReplicatedStorage.Library.Weapons);

--== Script;

function Skill:Trigger(profile, triggerType, points, ...)
	local duration, set = ...;
	if duration == nil or set == nil then return end;
	local level, stats = Skill:CalStats(Skill.Library, points);
	set(duration * (100-stats.Percent.Value)/100);
	
	local classPlayer = modPlayers.GetByName(profile.Player.Name);
	
	if classPlayer.Properties[Skill.Library.Id] == nil then
		classPlayer:SetProperties(Skill.Library.Id, {Percent=stats.Percent.Value});
		delay(5, function()
			classPlayer:SetProperties(Skill.Library.Id);
		end)
	end
end

function Skill.init(skillTree, lib)
	Skill.Library = lib;
	setmetatable(Skill, skillTree);
	return Skill;
end

return Skill;
