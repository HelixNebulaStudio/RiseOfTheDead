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
Dialogues.Mason.Dialogues = function()
	return {
		{Tag="hsh_init"; CheckMission=missionId; Dialogue="Yeah, sure.";
			Face="Confident"; Reply="There's this place, I don't think it's been scavenged before.. We should check it out. Let me know when you're ready to head out.";
			FailResponses = {
				{Reply="Come back later, I'm just preparing some stuff.."};
			};	
		};

		{Tag="hsh_letsgo"; Dialogue="Alright, I'm ready.";
			Face="Confident"; Reply="Here we go.."};
		{Tag="hsh_quiet"; Dialogue="Hmmm, it's so quiet here.";
			Face="Skeptical"; Reply="Yeah.. Now that you mention it.. \n\nAnyways, follow me."};

		{Tag="hsh_safehouse"; Dialogue="This place seems pretty sturdy, it could work as another safehouse.";
			Face="Welp"; Reply="It could, but this place might be a bit too far out.\n\nYou know what, you could make it your own!"};
		{Tag="hsh_mine"; Dialogue="My own?"; 
			Face="Happy"; Reply="Yes, your very own safehouse. You have been surviving on your own for quite some time, I'm sure you can take care of yourself here!"};
		{Tag="hsh_work"; Dialogue="I guess I could make something work..";
			Face="Confident"; Reply="Yeah! Maybe one day you could shelter survivors here and we could get more people to fight this apocalypse or something.."};

		{Tag="tpwarehouse"; Dialogue="Let's go back to the warehouse"; Face="Confident";
			Reply="Alright."};

		{Tag="tpsafehome"; Dialogue="Let's go to my safehome."; Face="Confident";
			Reply="Alright."};
	};
end

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
			
			--dialog:SetInitiateTag("medbre_init");

			--dialog:AddChoice("medbre_start", function(dialog)
			--	modMission:StartMission(player, missionId);
				
			--	modMission:CompleteMission(player, 75);
				
			--	modMission:Progress(player, missionId, function(mission)
			--		if mission.ProgressionPoint <= 1 then
			--			mission.ProgressionPoint = 1;
			--		end
			--	end);
			--end)
			
			
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