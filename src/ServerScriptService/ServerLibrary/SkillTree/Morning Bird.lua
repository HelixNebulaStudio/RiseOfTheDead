local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== 
local Skill = {Library=nil; CalStats=nil;};
Skill.__index = Skill;
--==
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

--== Script;

function Skill:Trigger(profile, triggerType, points, ...)
	local classPlayer = modPlayers.GetByName(profile.Player.Name);
	if triggerType == "OnDayTimeStart" then
		local level, stats = Skill:CalStats(Skill.Library, points);
		local duration = math.ceil(stats.Time.Value*60);
		classPlayer:SetHealSource(Skill.Library.Id, {
			Amount=(stats.Heal.Value/10);
			Expires=modSyncTime.GetTime() + duration;
			Duration=duration;
		});
	end
end

function Skill.init(skillTree, lib)
	Skill.Library = lib;
	setmetatable(Skill, skillTree);
	return Skill;
end

return Skill;
