local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;

local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modCutscene = require(game.ReplicatedStorage.Library.Cutscene);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
local modCoopMission = require(game.ServerScriptService.ServerLibrary.CoopMission);
local modFactions = require(game.ServerScriptService.ServerLibrary.Factions);

--==
local missionId = 73;
return function(player, dialog, data, mission)
	if not modBranchConfigs.IsWorld("Safehome") and not RunService:IsStudio() then return end;
	
	local profile = shared.modProfile:Get(player);
	local factionTag = tostring(profile.Faction.Tag);
	
	if shared.modSafehomeService.FactionTag == nil then
		Debugger:Warn("Not faction headquarters");
		
		dialog:AddChoice("dps_goToHq", function(dialog)
			modFactions.InvokeHandler(player, "travelhq");
		end)
		
		return;
	end

	local coopMission = modCoopMission:Get(factionTag, missionId);
	
	if coopMission == nil then 
		Debugger:Warn("no coop mission yet")
		return
	end;
	
	Debugger:Warn("dialog coopMission", coopMission);
	
	local checkPoint = coopMission.CheckPoint;
	if coopMission.Type == 1 then
		if checkPoint == 1 then
			dialog:SetInitiateTag("dps_init");

			dialog:AddChoice("dps_start", function(dialog)
				coopMission:Progress(function()
					if coopMission.CheckPoint == 1 then
						modAudio.Play("HordeGrowl", workspace);
						coopMission.CheckPoint = 2;
					end
					
				end)
			end)
			
		elseif checkPoint == 2 then
			dialog:SetInitiateTag("dps_cheer");
			
		end

	elseif coopMission.Type == 3 then
		Debugger:Warn("Completed dps");
		
	elseif coopMission.Type == 4 then
		--dialog:SetInitiateTag("dps_retry");
		--dialog:AddChoice("dps_restart", function(dialog)
		--	coopMission:Progress(function()
		--		coopMission.Type = 1;
		--		modAudio.Play("HordeGrowl");
		--		coopMission.CheckPoint = 2;

		--	end)
		--end)
		
	end
	
end