local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

--=
local Dialogues = {
	Joseph={};
};

local MISSION_ID = 87;
--==

-- MARK: Joseph DialogueStrings
Dialogues.Joseph.DialogueStrings = {
	["buyre_init"]={
		Face="Frustrated";
		Reply="You know what, enough is enough..";
	};
	
	["buyre_prologue1"]={
		CheckMission=MISSION_ID;
		Face="Angry"; 
		Say="We are going to do something about the Rats?";
		Reply="Yes, we are.";
		FailResponses = {
			{Reply="Yes, but wait for the right time."};
		};
	};
	["buyre_prologue2"]={
		Face="Skeptical";
		Say="...";
		Reply="We are going to have a word with Revas Remington, the leader of the Rats.\nLet's go when you are ready.";
	};
};

if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	-- MARK: Joseph Handler
	Dialogues.Joseph.DialogueHandler = function(player, dialog, data, mission)
		if mission.Type == 2 then -- Available
			dialog:SetInitiateTag("buyre_init");

			dialog:AddChoice("buyre_prologue1", function(dialog)
				dialog:AddChoice("buyre_prologue2", function(dialog)
					modMission:StartMission(player, MISSION_ID);
				end)
			end)
		
		elseif mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 1 then
				local dialogPacket = {
					Face = "Confident";
					Say = "I'm ready to go.";
					Reply = "Alrighty, let's get going.";
					MissionId = MISSION_ID;
				};
				
				dialog:AddDialog(dialogPacket, function(dialog)
					modMission:Progress(player, MISSION_ID, function()
						if mission.ProgressionPoint <= 2 then
							mission.ProgressionPoint = 2;
						end
					end)

				end)

			elseif mission.ProgressionPoint == 2 then
				if modBranchConfigs.IsWorld("TheResidentials") then
					dialog:SetInitiate("What are we still doing here?");
				elseif modBranchConfigs.IsWorld("TheHarbor") then
					dialog:SetInitiate("Let's go, I want to get this over with.");
				elseif modBranchConfigs.IsWorld("TheMall") then
					dialog:SetInitiate("I think we went the wrong way...");
				elseif modBranchConfigs.IsWorld("TheUnderground") then
					dialog:SetInitiate("I don't like this place.. Are you lost?");
				elseif modBranchConfigs.IsWorld("SectorE") then
					dialog:SetInitiate("Err.. What in tarnation?!");
				elseif modBranchConfigs.IsWorld("TheWarehouse") then
					dialog:SetInitiate("We're almost there..");
				elseif modBranchConfigs.IsWorld("BioXResearch") then
					dialog:SetInitiate("How'd you even get here?!");
				elseif modBranchConfigs.IsWorld("MainMenu") then
					dialog:SetInitiate("Doesn't look like anything to me..");
				else
					dialog:SetInitiate("I like to explore too...");
				end

			end
		end
	end
end


return Dialogues;