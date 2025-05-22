local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	["Bunny Man"]={};
};

local missionId = 32;
--==

-- MARK: Bunny Man Dialogues
Dialogues["Bunny Man"].DialogueStrings = {
	["reborn_init"]={
		CheckMission=missionId;
		Say="Yeah, what do you need me for?"; 
		Reply="You helped me, I will help you back, you need to be reborn. Complete my challenge and you will be reborn..";
	};

	["reborn_what"]={
		Say="What challenge?"; 
		Reply="Err.. I will bring you there. Let me know if you are ready for the challenge.";
	};

	["reborn_alright"]={
		Say="Umm, alright."; 
		Reply="Err.. Good, good..";
	};
	
	["reborn_travel"]={
		Say="Bring me to the butchery."; 
		Reply="Follow me..";
	};
		
	["reborn_complete"]={
		Say="Ummm.."; 
		Reply="Now I can tell you anything you want to know..";
	};
		 
	["reborn_home"]={
		Say="Okay, can you bring me home now?"; 
		Reply="Err.. alright.";
	};
};

if RunService:IsServer() then
	-- MARK: Bunny Man Handler
	Dialogues["Bunny Man"].DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		local modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);
		local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

		local mission50 = modMission:GetMission(player, 50);
		local function addLoreOptions(dialog)
			if mission50 and mission50.Type ~= 3 then return end;
			
			dialog:AddChoice("reborn_lore1", function(dialog)
				addLoreOptions(dialog);
			end);
			dialog:AddChoice("reborn_lore2", function(dialog)
				addLoreOptions(dialog);
			end);
			dialog:AddChoice("reborn_lore3", function(dialog)
				addLoreOptions(dialog);
			end);
			dialog:AddChoice("reborn_lore4", function(dialog)
				addLoreOptions(dialog);
			end);
			dialog:AddChoice("reborn_home", function(dialog)
				local worldName = data:Get("World") or "TheResidentials";
				modServerManager:Travel(player, worldName);
			end)
		end
		
		if mission.Type == 1 then -- Active
			if not modBranchConfigs.IsWorld("EasterButchery") then
				dialog:AddChoice("reborn_travel", function(dialog)
					data:Set("World", modBranchConfigs.WorldName);
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint == 1 then
							mission.ProgressionPoint = 2;
						end;
					end)
					modServerManager:Travel(player, "EasterButchery");
				end)
			else
				if mission.ProgressionPoint == 3 then
					dialog:SetInitiate("You have been reborn. You are now a Bunny Man. You are me.");
					
					dialog:AddChoice("reborn_complete", function(dialog)
						modMission:CompleteMission(player, missionId);
						addLoreOptions(dialog);
					end)
					
				end
			end
			
		elseif mission.Type == 2 then -- Available
			dialog:SetInitiate("Err.. You. Yes, you.");
			dialog:AddChoice("reborn_init", function(dialog)
				dialog:AddChoice("reborn_what", function(dialog)
					dialog:AddChoice("reborn_alright", function(dialog)
						modMission:StartMission(player, missionId);
					end)
				end)
			end)
			
		elseif mission.Type == 3 then -- Complete
			if mission50 == nil or mission50.Type ~= 1 then
				if not modBranchConfigs.IsWorld("EasterButchery") then
					dialog:AddChoice("reborn_travel", function(dialog)
						data:Set("World", modBranchConfigs.WorldName);
						modServerManager:Travel(player, "EasterButchery");
					end)
					
				else
					dialog:AddChoice("reborn_home", function(dialog)
						local worldName = data:Get("World") or "TheResidentials";
						modServerManager:Travel(player, worldName);
					end)
				
				end
			end;
			addLoreOptions(dialog);
			
		end
	end
end


return Dialogues;