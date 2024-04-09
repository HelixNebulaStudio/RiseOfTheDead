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
	if classPlayer.Health <= classPlayer.MaxHealth*0.35 then
		
		local modSquadService = require(game.ServerScriptService.ServerLibrary.SquadService);
		local squad = modSquadService.GetSquadByPlayer(player);
		if squad then
			local memberHealth = 0;
			local memberPlayer = nil;
			squad:LoopPlayers(function(name)
				local mPlayer = modPlayers.GetByName(name);
				if mPlayer and mPlayer.Health and memberHealth < mPlayer.Health then
					memberHealth = mPlayer.Health;
					memberPlayer = mPlayer;
				end
			end);
			
			if memberPlayer then
				local duration = 60;
				classPlayer:SetProperties(Skill.Library.Id, {
					Expires=modSyncTime.GetTime()+duration;
					Duration=duration;
					Percent=stats.Percent.Value;
				});
				
				local healPool = memberHealth*(stats.Percent.Value/100);
				repeat
					classPlayer.Humanoid.Health = classPlayer.Humanoid.Health + 1;
					healPool = healPool -1;
					task.wait(0.2);
				until not classPlayer.IsAlive or classPlayer.Health >= classPlayer.MaxHealth or healPool <= 0;
			end
		end
	end
end

function Skill.init(skillTree, lib)
	Skill.Library = lib;
	setmetatable(Skill, skillTree);
	return Skill;
end

return Skill;
