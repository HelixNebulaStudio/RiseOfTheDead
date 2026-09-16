local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--
local Dialogues = {
	Caitlin={};
};

local MISSION_ID = 100;
--==

Dialogues.Caitlin.DialogueStrings = {
	["advtoelite_start"]={
		CheckMission=MISSION_ID;
		Say="Yeah, this place could use some repair, but we lack people.";
		Reply="I could help, I'll need some materials though.";
		Face="Happy";
	};
	["advtoelite_needs"]={
		Say="That would be great! What do you need?";
		Reply="Circuit boards. Good ones. At least three of them..";
		Face="Confident";
	};
	["advtoelite_give"]={
		Say="I have the 3 Circuit Boards.";
		Reply="Ooh, and they're not even fried.";
		Face="Happy";
	};
	["advtoelite_thanks"]={
		Say="Here you go.";
		Reply="Give me a minute... solder here, bridge there... annnd done.. Thanks again, these will come in handy.";
		Face="Confident";
	};
    ["advtoelite_found"]={
		Say="You're welcome.";
		Reply="Oh right, I found these on my scavenge.. You can have it.";
		Face="Confident";
	};
	["advtoelite_done"]={
		Say="Need more circuit boards?";
		Reply="Always, but this time, I'll trade you these Elite Gun Components for them.";
		Face="Smirk";
	};
};

if RunService:IsServer() then

	Dialogues.Caitlin.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		local profile = shared.modProfile:Get(player);
		local inventory = profile:GetActiveSave().Inventory;

		if mission.Type == 2 then -- Available;
			dialog:SetInitiate("This safehouse is starting to feel like home. Anyways, I notice the state of repair this place is in.");
			dialog:AddChoice({
				"advtoelite_start"; "advtoelite_needs"
			}, function(dialog)
				modMission:StartMission(player, MISSION_ID);
			end)

		elseif mission.Type == 1 then -- Active
			local hasCircuitBoards = inventory:CountItemId("circuitboards") >= 3;

			if hasCircuitBoards then
				dialog:SetInitiate("Welcome back, you got the circuit boards?");
				dialog:AddChoice({
					"advtoelite_give"; "advtoelite_thanks"; "advtoelite_found"
				}, function(dialog)
					local _, itemList = inventory:ListQuantity("circuitboards", 3);
					if itemList then
						for a=1, #itemList do
							inventory:Remove(itemList[a].ID, itemList[a].Quantity);
						end

						shared.Notify(player, "You gave Caitlin 3 Circuit Boards.", "Reward");

						modMission:CompleteMission(player, MISSION_ID);
					end
				end)

			else
				dialog:SetInitiate("Three circuit boards, that's all I need.", "Happy");

			end

		elseif mission.Type == 3 then -- Complete
			dialog:SetInitiate("I still got some spare Elite Gun Components if you need more.");
			dialog:AddChoice("advtoelite_done", function(dialog)
				local storageItem = inventory:FindByItemId("circuitboards");
				if storageItem <= 3 then
					shared.Notify(player, "You don't have enough Circuitboards in your inventory.", "Negative");
					return;
				end

				inventory:Remove(storageItem.ID, 3);
				inventory:Add("elitegunpart", {Quantity=1});
				shared.Notify(player, "You traded 3 Circuitboards for 1 Elite Gun Component.", "Reward");
				profile:GuiAction("specialpickup", {"eliteguncomponent";});
			end)

		elseif mission.Type == 4 then -- Failed

		end
	end

end


return Dialogues;
