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
end

function Skill.init(skillTree, lib)
	Skill.Library = lib;
	setmetatable(Skill, skillTree);
	return Skill;
end

return Skill;
