local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Mason={};
};

local missionId = 54;
--==

-- !outline: Mason Dialogues
Dialogues.Mason.DialogueStrings = {
	["hsh_init"]={
		CheckMission=missionId;
		Say="Yeah, sure.";
		Face="Confident"; 
		Reply="There's this place, I don't think it's been scavenged before.. We should check it out. Let me know when you're ready to head out.";
		FailResponses = {
			{Reply="Come back later, I'm just preparing some stuff.."};
		};	
	};

	["hsh_letsgo"]={
		Say="Alright, I'm ready.";
		Face="Confident"; 
		Reply="Here we go..";
	};
	["hsh_quiet"]={
		Say="Hmmm, it's so quiet here.";
		Face="Skeptical"; 
		Reply="Yeah.. Now that you mention it.. \n\nAnyways, follow me.";
	};

	["hsh_safehouse"]={
		Say="This place seems pretty sturdy, it could work as another safehouse.";
		Face="Welp"; 
		Reply="It could, but this place might be a bit too far out.\n\nYou know what, you could make it your own!";
	};
	["hsh_mine"]={
		Say="My own?"; 
		Face="Happy"; 
		Reply="Yes, your very own safehouse. You have been surviving on your own for quite some time, I'm sure you can take care of yourself here!";
	};
	["hsh_work"]={
		Say="I guess I could make something work..";
		Face="Confident"; 
		Reply="Yeah! Maybe one day you could shelter survivors here and we could get more people to fight this apocalypse or something..";
	};

	["tpwarehouse"]={
		Say="Let's go back to the warehouse"; 
		Face="Confident";
		Reply="Alright.";
	};

	["tpsafehome"]={
		Say="Let's go to my safehome."; 
		Face="Confident";
		Reply="Alright.";
	};
};

if RunService:IsServer() then
	-- !outline: Mason Handler
	Dialogues.Mason.DialogueHandler = function(player, dialog, data, mission)
		local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
		local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
		--==
		
		if modBranchConfigs.IsWorld("Safehome") then
			local ownerPlayer = modServerManager.PrivateWorldCreator;
			local isOwner = ownerPlayer == player;

			if not isOwner then
				dialog:SetInitiate("Did "..ownerPlayer.Name.." rescue you from somewhere?");
				return;
			end
			
		end
		
		if mission.Type == 2 then -- Available;
			dialog:SetInitiate("Hey, $PlayerName. Are you free for a scavenge?");
			dialog:AddChoice("hsh_init", function(dialog)
				modMission:StartMission(player, missionId);
			end)
			
		elseif mission.Type == 1 then -- Active
			if modBranchConfigs.IsWorld("TheWarehouse") then
				dialog:SetInitiate("Let's go?");
				dialog:AddChoice("hsh_letsgo", function(dialog)
					modMission:Progress(player, missionId, function(mission)
						mission.ProgressionPoint = 2;
					end)
					modServerManager:Travel(player, "Safehome");
				end)
			else
				if mission.ProgressionPoint == 2 then
					dialog:SetInitiate("Here we are, hope we will find something good here..");
					dialog:AddChoice("hsh_quiet", function(dialog)
						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint == 2 then
								mission.ProgressionPoint = 3;
							end;
						end)
					end)


				elseif mission.ProgressionPoint == 3 then
					dialog:SetInitiate("Here they come..");

				elseif mission.ProgressionPoint == 4 then
					dialog:SetInitiate("Watching your back.");

				elseif mission.ProgressionPoint == 5 then
					dialog:SetInitiate("This is bull! There's nothing useful here..");
					dialog:AddChoice("hsh_safehouse", function(dialog)
						dialog:AddChoice("hsh_mine", function(dialog)
							dialog:AddChoice("hsh_work", function(dialog)
								modMission:CompleteMission(player, missionId);
							end)
						end)
					end)

				end
			end
			
		elseif mission.Type == 3 then -- Complete
			if modBranchConfigs.IsWorld("Safehome") then
				dialog:AddChoice("tpwarehouse", function(dialog)
					modServerManager:Travel(player, "TheWarehouse");
				end)

			elseif modBranchConfigs.IsWorld("TheWarehouse") then
				dialog:AddChoice("tpsafehome", function(dialog)
					modServerManager:Travel(player, "Safehome");
				end)

			end;
			
		elseif mission.Type == 4 then -- Failed
			
		end
	end

end


return Dialogues;