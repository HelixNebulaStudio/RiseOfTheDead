local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== 
local Skill = {Library=nil;};
Skill.__index = Skill;
--==
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

--== Script;

function Skill:Trigger(profile, triggerType, points, ...)
	local classPlayer = modPlayers.GetByName(profile.Player.Name);
	if triggerType == "OnToolEquipped" then
		local level, stats = Skill:CalStats(Skill.Library, points);

	end
end

function Skill.init(skillTree, lib)
	Skill.Library = lib;
	setmetatable(Skill, skillTree);
	return Skill;
end

return Skill;
