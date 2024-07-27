local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Victor={};
};

local missionId = 40;
--==

-- MARK: Victor Dialogues
Dialogues.Victor.Dialogues = function()
	return {
		{Tag="vt1_init"; Face="Skeptical";
			Dialogue="Ummm, what is it?"; 
			Reply="There is a pathway under the park's statue, a pathway to some kind of tombs."};

		{Tag="vt1_beast"; Face="Confident";
			Dialogue="What's in the tombs?"; 
			Reply="I am not sure. There are rumors about some kind of treasure but the beast is in the way. Could you clear the path to the tombs?"};

		{CheckMission=missionId; Tag="vt1_sure"; Face="Happy";
			Dialogue="Sure."; 
			Reply="Thats rad dude, let me know if you find anything."};
		
		{Tag="vt1_tombs"; Face="Suspicious";
			Dialogue="I'll be heading down to the tombs again."; 
			Reply="Alright."};
		
		{Tag="vt1_find"; Face="Happy";
			Dialogue="The tombs was overran with zombies. I found this mask in the tombs though."; 
			Reply="Wow, I'm impressed. Thanks for the mask, I will be inspecting it."};
			
		{Tag="vt1_notfind"; Face="Suspicious";
			Dialogue="The tombs was overran with zombies, and I didn't find anything special there."; 
			Reply="Hmmm, thats odd.. Anyways thanks for clearing the path there."};
		
	};
end

if RunService:IsServer() then
	-- MARK: Victor Handler
	Dialogues.Victor.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available	
			dialog:SetInitiate("Hey dude, I need help with something.", "Bored");
			dialog:AddChoice("vt1_init", function(dialog)
				dialog:AddChoice("vt1_beast", function(dialog)
					dialog:AddChoice("vt1_sure", function(dialog)
						modMission:StartMission(player, missionId);
					end)
				end)
			end)
			
		elseif mission.Type == 1 then -- Active;
			if mission.ProgressionPoint == 1 then
				dialog:SetInitiate("What's taking so long, you scared..?", "Bored");
				
			elseif mission.ProgressionPoint >= 3 and mission.ProgressionPoint <= 4 then
				dialog:SetInitiate("You need to kill the beast in the park.", "Bored");
				modMission:Progress(player, missionId, function(mission)
					mission.ProgressionPoint = 2;
				end)
				
			elseif mission.ProgressionPoint == 7 then
				dialog:SetInitiate("Well, what did you find?", "Bored");
				
				local profile = shared.modProfile:Get(player);
				local playerSave = profile:GetActiveSave();
				local inventory = playerSave.Inventory;
				local _, itemList = inventory:ListQuantity("nekronmask", 1);
				
				if itemList and #itemList > 0 then
					dialog:AddChoice("vt1_find", function(dialog)
						data:Set("gaveMask", true);
						for a=1, #itemList do
							inventory:Remove(itemList[a].ID, itemList[a].Quantity);
						end
						shared.Notify(player, "Removed Nekron Mask from your inventory.", "Negative");
						modMission:CompleteMission(player, missionId);
					end)
				end
				
				dialog:AddChoice("vt1_notfind", function(dialog)
					data:Set("gaveMask", false);
					modMission:CompleteMission(player, missionId);
				end)
			end
			
		end
		
		--
		local modGameModeManager = require(game.ServerScriptService.ServerLibrary.GameModeManager);
		local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

		local mission42 = modMission:GetMission(player, 42);
		if mission.ProgressionPoint >= 5 and (mission42 == nil or mission42.ProgressionPoint ~= 1) and not modBranchConfigs.IsWorld("VindictiveTreasure") then
			dialog:AddChoice("vt1_tombs", function(dialog)
				modGameModeManager:Assign(player, "Raid", "Tombs");
			end)
		end

	end
end


return Dialogues;