local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	["Bunny Man"]={};
};

local missionId = 50;
--==

-- MARK: Bunny Man Dialogues
Dialogues["Bunny Man"].Dialogues = function()
	return {
		{CheckMission=missionId; Tag="eb2_greet";
			Dialogue="What task do you have for me?"; 
			Reply="The people who caused this apocalypse, is no single person. The groups that are responsible.. are powerful people. But not powerful enough to contain what they have created."};
		{Tag="eb2_greet2";
			Dialogue="Hmm"; 
			Reply="Scattered to pieces by their own creation, they now struggle.. fight.. and hunt to survive. They almost killed me, left me to die out in the woods."};
		{Tag="eb2_greet3";
			Dialogue="I see"; 
			Reply="They should have made sure they finished what they started, because I will get back at them."};
		{Tag="eb2_greet4";
			Dialogue="..."; 
			Reply="As we have been reborn, we have nothing to fear. We shall make contact with the cultist. They have something I need."};
		{Tag="eb2_start";
			Dialogue="Alright"; 
			Reply="We will commence when you are ready."};
		
		{Tag="eb2_letsgo";
			Dialogue="I am ready, let's go."; 
			Reply="Follow me.."};
		{Tag="eb2_lead";
			Dialogue="Okay."; 
			Reply="Come."};
		{Tag="eb2_end1";
			Dialogue="I see, who is omega?"; 
			Reply="The one who exiled me."};
		{Tag="eb2_end2";
			Dialogue="What do we do now?"; 
			Reply="We are done for today, that earlier is going to raise some alarms. We will need to lay low, we will continue this next time."};
		
	};
end

if RunService:IsServer() then
	-- MARK: Bunny Man Handler
	Dialogues["Bunny Man"].DialogueHandler = function(player, dialog, data, mission)
		local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
		local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		local profile = shared.modProfile:Get(player);
		local activeSave = profile:GetActiveSave();

		if mission.Type == 1 then -- Active
			if not modBranchConfigs.IsWorld("EasterButchery") then
				dialog:AddChoice("eb2_letsgo", function(dialog)
					data:Set("World", modBranchConfigs.WorldName);
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint == 1 then
							mission.ProgressionPoint = 2;
						end;
					end)

					if profile and activeSave then
						activeSave.Spawn = "EasterButchery2";
					end
					modServerManager:Travel(player, "EasterButchery");
				end)
			else
				if mission.ProgressionPoint == 1 then
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint == 1 then
							mission.ProgressionPoint = 2;
						end;
					end)
					
					if profile and activeSave then
						activeSave.Spawn = "EasterButchery2";
					end
					
					local spawnPart = workspace:FindFirstChild("EasterButchery2");
					if spawnPart then
						shared.modAntiCheatService:Teleport(player, spawnPart.CFrame * CFrame.new(0, 2, 0));
					end
					
				elseif mission.ProgressionPoint == 2 then
					dialog:SetInitiate("Cultists are always watching.. Their meet signal is boric acid fire, it creates a green flame. Follow my lead.");
					
					dialog:AddChoice("eb2_lead", function(dialog)
						
						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint == 2 then
								mission.ProgressionPoint = 3;
							end;
						end)
					end)
					
				elseif mission.ProgressionPoint == 8 then
					dialog:SetInitiate("You did well, looks like I know how to make the cultists crumple.");
					dialog:AddChoice("eb2_end1", function(dialog)
						dialog:AddChoice("eb2_end2", function(dialog)
							modMission:CompleteMission(player, missionId);

							-- MARK: To do: bunnymanheadbenefactor
						end)
					end)
					
				else
					dialog:SetInitiate("Hmmm?");

				end
			end
			
		elseif mission.Type == 2 then -- Available
			dialog:SetInitiate("You are me, Bunny Man. I have another task for you.");
			dialog:AddChoice("eb2_greet", function(dialog)
				dialog:AddChoice("eb2_greet2", function(dialog)
					dialog:AddChoice("eb2_greet3", function(dialog)
						dialog:AddChoice("eb2_greet4", function(dialog)
							dialog:AddChoice("eb2_start", function(dialog)
								modMission:StartMission(player, missionId);
							end)
						end)
					end)
				end)
			end)
			
		elseif mission.Type == 3 then -- Complete
			if not modBranchConfigs.IsWorld("EasterButchery") then
				dialog:AddChoice("reborn_travel", function(dialog)
					data:Set("World", modBranchConfigs.WorldName);
					modServerManager:Travel(player, "EasterButchery");
				end)

			else
				-- MARK: TODO: add obtain bunnymanheadbenefactor

				dialog:AddChoice("reborn_home", function(dialog)
					local worldName = data:Get("World") or "TheResidentials";
					modServerManager:Travel(player, worldName);
				end)

			end
			
		end
	end
end


return Dialogues;