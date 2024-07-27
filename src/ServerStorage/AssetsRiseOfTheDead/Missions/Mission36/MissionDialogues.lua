local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Erik={};
};

local missionId = 36;
--==

-- MARK: Erik Dialogues
Dialogues.Erik.Dialogues = function()
	return {
		{Tag="calmingtunes_start"; Face="Ugh";
			Dialogue="Hey.. hey, it can't hurt you. Don't worry."; 
			Reply="It's driving me insane, I need something to calm me down."};

		{CheckMission=missionId; Tag="calmingtunes_musicbox"; Dialogue="Okay, I have an idea. Wait here."; 
			Reply="Okay.."};
		
		{Tag="calmingtunes_wait"; Face="Worried";
			Dialogue="A music box might help calm you down."; 
			Reply="Hmm.. I'll be waiting, hope it works."};
		
		{Tag="calmingtunes_give"; Face="Joyful";
			Dialogue="Here you go, a music box."; 
			Reply="Ooh, thanks dude."};

		{Tag="calmingtunes_giveBoombox"; Face="Suspicious";
			Dialogue="Here you go, a boom box."; 
			Reply="Erik needs a Music box instead of a Boombox."};
	};
end

if RunService:IsServer() then
	-- MARK: Erik Handler
	Dialogues.Erik.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			local profile = shared.modProfile:Get(player);
			local playerSave = profile:GetActiveSave();
			local inventory = playerSave.Inventory;
			
			dialog:SetInitiate("Did you find the music box yet?");
			if mission.ObjectivesCompleted["Musicbox"] == true then
				dialog:AddChoice("calmingtunes_give", function(dialog)
					local itemId = "musicbox";
					local _, itemList = inventory:ListQuantity(itemId, 1);
					if itemList then
						for a=1, #itemList do
							
							inventory:Remove(itemList[a].ID, itemList[a].Quantity);
							shared.Notify(player, "Music box removed from your Inventory.", "Negative");
						
						end
						modMission:CompleteMission(player, missionId);
					else
						shared.Notify(player, ("Unable to find items from inventory."), "Negative");
					end
				end)
				
				--
			else
				local total, _ = inventory:ListQuantity("boombox", 1);
				if total > 0 then
					dialog:AddChoice("calmingtunes_giveBoombox");
				else
					dialog:AddChoice("calmingtunes_wait");
				end
			end
			
		elseif mission.Type == 2 then -- Available
			dialog:SetInitiate("Ahh, I can't stand the noise. The growling, I can't stop panicing when I hear it..");
			dialog:AddChoice("calmingtunes_start", function(dialog)
				dialog:AddChoice("calmingtunes_musicbox", function(dialog)
					modMission:StartMission(player, missionId);
				end)
			end)
			
		end
	end
end


return Dialogues;