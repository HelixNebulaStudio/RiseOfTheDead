local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== 
local Skill = {Library=nil;};
Skill.__index = Skill;
--==
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

--== Script;

function Skill:Trigger(profile, triggerType, points)
	local player = profile.Player;
	local classPlayer = modPlayers.GetByName(player.Name);
	if classPlayer.Properties[Skill.Library.Id] then return end;
	
	local level, stats = Skill:CalStats(Skill.Library, points);
	if classPlayer.Health > 0 and classPlayer.Health <= classPlayer.MaxHealth*0.15 then
		local healPool = classPlayer.MaxHealth*(stats.Percent.Value/100);
		local targetHealth = healPool;
		
		local duration = 120;
		classPlayer:SetProperties(Skill.Library.Id, {
			Expires=modSyncTime.GetTime()+duration;
			Duration=duration;
			Percent=stats.Percent.Value;
		});
		
		repeat
			classPlayer.Humanoid.Health = classPlayer.Humanoid.Health + 2;
			healPool = healPool -2;
			task.wait(0.5);
			if classPlayer.Humanoid.Health <= 0 then
				break;
			end
		until not classPlayer.IsAlive or classPlayer.Health >= targetHealth or classPlayer.Health >= classPlayer.MaxHealth or healPool <= 0;
	end
end

function Skill.init(skillTree, lib)
	Skill.Library = lib;
	setmetatable(Skill, skillTree);
	return Skill;
end

return Skill;
