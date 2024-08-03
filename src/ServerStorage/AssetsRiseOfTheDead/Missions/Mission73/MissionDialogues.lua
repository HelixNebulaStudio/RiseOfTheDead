local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

--=
local Dialogues = {
	Patrick={};
};

local missionId = 73;
--==

-- MARK: Patrick Dialogues
Dialogues.Patrick.DialogueStrings = {
	["dps_init"]={
		Face="Frustrated"; 
		Reply="Hurry, I think it's around here somewhere. Get your weapons ready..";
	};
	["dps_start"]={
		Face="Skeptical"; 
		Say="What is here?";
		Reply="A zenith boss is here, be careful.";
	};
	["dps_retry"]={
		Face="Frustrated"; 
		Reply="It's still around, let's try this again.";
	};
	["dps_restart"]={
		Face="Skeptical"; 
		Say="Let's do this again..";
		Reply="That's the spirit, take it down.";
	};
	["dps_cheer"]={
		Face="Frustrated"; 
		Reply="Watch your backs!";
	};
	["dps_goToHq"]={
		Face="Happy"; 
		Say="I got a mission from my faction, can you bring me to HQ?";
		Reply="Sure, let's go..";
	};
};

if RunService:IsServer() then

	-- MARK: Patrick Handler
	if modBranchConfigs.IsWorld("Safehome") then 
		Dialogues.Patrick.DialogueHandler = function(player, dialog, data, mission)
			local modCoopMission = require(game.ServerScriptService.ServerLibrary.CoopMission);
			local modFactions = require(game.ServerScriptService.ServerLibrary.Factions);
			
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
		
			end
		end
	end;

end


return Dialogues;