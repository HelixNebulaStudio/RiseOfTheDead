local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Diana={};
};

local missionId = 26;
--==

-- !outline: Diana Dialogues
Dialogues.Diana.Dialogues = function()
	return {
		{Tag="blueprint_jesse"; Dialogue="Yes, that's me.. why?..";
			Face="Smirk"; Reply="Jesse told me about you, he said you are very capable. Got time for a job?"};
		
		{Tag="blueprint_start"; CheckMission=missionId; Dialogue="Sure, what is it?";
			Face="Confident"; Reply="Got some demands for this item, see if you can find it..";
			FailResponses = {
				{Reply="Hmm, nevermind, come back later.."};
			};
		};
		{Tag="blueprint_done"; Dialogue="Got it, here you go..";
			Face="Happy"; Reply="Awesome, you are more capable than you look."};
		{Tag="blueprint_notYet"; Dialogue="Nope, not yet.";
			Face="Suspicious"; Reply="Whatever~ Just don't take too long, Revas aint going to be happy about it.."};
		{Tag="blueprint_donefull"; Dialogue="Got it, here you go..";
			Face="Happy"; Reply="Awesome, but clear your inventory first.."};

	};
end

if RunService:IsServer() then
	local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
	
	-- !outline: Diana Handler
	Dialogues.Diana.DialogueHandler = function(player, dialog, data, mission)
		local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available;
			local function m26Dialogues(dialog)
				dialog:AddChoice("blueprint_start", function(dialog)
					modMission:StartMission(player, missionId);
				end)
			end

			if modEvents:GetEvent(player, "mission26_dialogue") == nil then
				modEvents:NewEvent(player, {Id="mission26_dialogue"});
				dialog:SetInitiate("Hey, are you $PlayerName?", "Happy");
				dialog:AddChoice("blueprint_jesse", m26Dialogues);
			else
				dialog:SetInitiate("$PlayerName, I got another job for you.", "Happy");
				m26Dialogues(dialog)
			end
			
			
		elseif mission.Type == 1 then -- Active
			dialog:SetInitiate("Soo, you got the goods?");
			if mission.ObjectivesCompleted["Search"] == true then

				if modMission:CanCompleteMission(player, missionId, true) then
					dialog:AddChoice("blueprint_done", function(dialog)
						local profile = shared.modProfile:Get(player);
						local playerSave = profile:GetActiveSave();
						local inventory = playerSave.Inventory;

						local total, itemList = inventory:ListQuantity(mission.SaveData.ItemId, mission.SaveData.Amount);
						if itemList then
							for a=1, #itemList do
								local itemLib = modItemsLibrary:Find(mission.SaveData.ItemId);
								inventory:Remove(itemList[a].ID, itemList[a].Quantity);
								shared.Notify(player, ("$Amount$Item removed from your Inventory."):gsub("$Item", itemLib.Name):gsub("$Amount", itemList[a].Quantity > 1 and itemList[a].Quantity.." " or ""), "Negative");
							end
							modMission:CompleteMission(player, missionId);
						else
							shared.Notify(player, ("Unable to find items from inventory."), "Negative");
						end
					end)
					
				else
					dialog:AddChoice("blueprint_donefull");
					
				end
			else
				dialog:AddChoice("blueprint_notYet");
			end
			
		end
	end

end


return Dialogues;
