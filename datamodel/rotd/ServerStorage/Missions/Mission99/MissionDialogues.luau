local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Wilson={};
};

local MISSION_ID = 99;
--==

Dialogues.Wilson.DialogueStrings = {
	["pgctoagc_offer"]={
		Say="What's going on?";
		Reply="My rifle is old and falling apart. Problem is, my scavenge runs only ever turn up Advance Gun Components. Want to trade?";
		Face="Smirk";
	};
	["pgctoagc_give"]={
		Say="I have 2 Prime Gun Components.";
		Reply="Perfect! Advance Gun Components for your 2 Prine Gun Component?";
		Face="Happy";
	};
	["pgctoagc_thanks"]={
		Say="Here you go.";
		Reply="Alright, okay. Phew, worried I won't be able to go out again without this thing fixed.";
		Face="Confident";
	};
};

if RunService:IsServer() then

	Dialogues.Wilson.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		local profile = shared.modProfile:Get(player);
		local inventory = profile:GetActiveSave().Inventory;

		if mission.Type == 1 then -- Active
			dialog:SetInitiate("Ugh, this thing is falling apart...\n\nOh hey, you need something?", "Bored");

			dialog:AddChoice("pgctoagc_offer", function(dialog)
				local itemsCount = inventory:CountItemId("primegunpart");

				if itemsCount >= 2 then
					dialog:AddChoice({"pgctoagc_give"; "pgctoagc_thanks";}, function(dialog)
						local _, itemList = inventory:ListQuantity("primegunpart", 2);
						if itemList then
							for a=1, #itemList do
								inventory:Remove(itemList[a].ID, itemList[a].Quantity);
							end

							shared.Notify(player, "You gave Wilson 2 Prime Gun Components.", "Reward");

							modMission:CompleteMission(player, MISSION_ID);
						end
					end)
				end
			end)

		end
	end

end


return Dialogues;