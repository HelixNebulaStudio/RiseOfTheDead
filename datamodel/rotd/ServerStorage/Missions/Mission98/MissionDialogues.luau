local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Russell={};
};

local MISSION_ID = 98;
--==

Dialogues.Russell.DialogueStrings = {
	["bgctopgc_offer"]={
		Say="You free right now to upgrade my Basic Gun Components?";
		Reply="Sure, bring me 2 Basic Gun Components and I'll hand you back a Prime one.";
		Face="Smirk";
	};
	["bgctopgc_give"]={
		Say="I have the 2 Basic Gun Components.";
		Reply="Well don't keep them in your pocket! Hand 'em over before I change my mind.";
		Face="Happy";
	};
	["bgctopgc_thanks"]={
		Say="Here you go.";
		Reply="Alright, give me a moment here... unscrew, re-seat, tighten... and boom. One Prime Gun Component, fresh off the workbench.";
		Face="Confident";
	};
};

if RunService:IsServer() then

	Dialogues.Russell.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		local profile = shared.modProfile:Get(player);
		local inventory = profile:GetActiveSave().Inventory;

		if mission.Type == 1 then -- Active
            dialog:SetInitiate("Oh, it's you. What do you want?", "Bored");

            dialog:AddChoice("bgctopgc_offer", function(dialog)
                local itemsCount = inventory:CountItemId("basicgunpart");

                if itemsCount >= 2 then
                    dialog:AddChoice({"bgctopgc_give"; "bgctopgc_thanks";}, function(dialog)
                        local _, itemList = inventory:ListQuantity("basicgunpart", 2);
                        if itemList then
                            for a=1, #itemList do
                                inventory:Remove(itemList[a].ID, itemList[a].Quantity);
                            end
                            
                            shared.Notify(player, "You gave Russell 2 Basic Gun Components.", "Reward");

                            modMission:CompleteMission(player, MISSION_ID);
                        end
                    end)
                end
			end)

		end
	end

end


return Dialogues;