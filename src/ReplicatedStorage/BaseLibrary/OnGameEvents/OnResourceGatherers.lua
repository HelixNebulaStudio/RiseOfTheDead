local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modInteractables = require(game.ReplicatedStorage.Library.Interactables);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local skillKey = "resgat";
return function(player, interactData)
	local interactObject = interactData.Object;
	local interactModule = interactData.Script;
	
	Debugger:Warn("event interactData", interactData.ItemId);
	
	local profile = shared.modProfile:Get(player);
	local classPlayer = shared.modPlayers.Get(player);
	
	local modSquadService = require(game.ServerScriptService.ServerLibrary.SquadService);
	local squad = modSquadService.GetSquadByPlayer(player);
	if squad == nil then return end;
	
	squad:LoopPlayers(function(name)
		if name == player.Name then return end;
		
		local squadmateProfile = shared.modProfile:Find(name);
		if squadmateProfile == nil then return end;

		local squadmatePlayer = squadmateProfile.Player;

		local skill = squadmateProfile.SkillTree:GetSkill(squadmatePlayer, skillKey);
		local level, skillStats = profile.SkillTree:CalStats(skill.Library, skill.Points);
		local duration = skillStats.Cooldown.Value;

		local classPlayer = shared.modPlayers.Get(squadmatePlayer);
		if classPlayer.Properties[skillKey] then return end;

		local profileSettings = squadmateProfile.Settings or {};
		if interactData.ForceTouchPickup ~= true then
			if profileSettings.AutoPickupMode == 2 then
				return;

			elseif profileSettings.AutoPickupMode == 1 then
				local pickUpEnabled = squadmateProfile.Cache.PickupCache[interactData.ItemId];
				if pickUpEnabled ~= true then
					return;
				end

			else
				if interactData.TouchPickUp == false then
					return;
				end

			end
		end

		local statusTable = {
			ExpiresOnDeath=true;
			Duration=duration;
		};
		statusTable.Expires=modSyncTime.GetTime() + duration;
		classPlayer:SetProperties(skillKey, statusTable);

		local successful = shared.modProfile.PickUpRequest(squadmatePlayer, interactObject, interactModule);
		if successful then
			local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
			modReplicationManager.UnreplicateFrom(player, interactObject.Parent);
		end
	end)
end;