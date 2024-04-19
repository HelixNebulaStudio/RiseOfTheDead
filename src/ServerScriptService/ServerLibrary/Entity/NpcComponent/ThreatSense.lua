local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local remoteThreatSenseSkill = modRemotesManager:Get("ThreatSenseSkill");

--== Script;
local Component = {};
Component.__index = Component;

function Component.new(Npc)
	return function()
		if Npc.Enemy == nil or Npc.Enemy.Character == nil then return end;
		if Npc.ThreatSenseHidden == true then return end;

		task.spawn(function()
			local player = game.Players:GetPlayerFromCharacter(Npc.Enemy.Character);
			if player == nil then return end;
			
			local profile = shared.modProfile:Find(player.Name);
			if profile == nil then return end

			local skill = profile.SkillTree:GetSkill(player, "thrsen");
			if skill.Points <= 0 then
				return;
			end

			local skillLvl, skillStat = profile.SkillTree:CalStats(skill.Library, skill.Points);
			local distance = skillStat.Amount.Value;
			
			if Npc.Enemy.Distance > distance then
				return;
			end
			
			remoteThreatSenseSkill:FireClient(player, Npc.Prefab);
		end)
	end;
end

return Component;