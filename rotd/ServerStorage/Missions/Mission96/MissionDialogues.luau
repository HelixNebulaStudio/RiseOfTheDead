local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Wilson={};
};

local MISSION_ID = 96;
--==

Dialogues.Wilson.DialogueStrings = {
	["primeguncomponent_start"]={
		CheckMission=MISSION_ID;
		Say="Everything alright, Wilson?";
		Reply="Not really. I've been trying to reach Derrick on the radio for days... nothing but static. I think my walkie talkie signal is too weak.";
		Face="Worried";
	};
	["primeguncomponent_blueprint"]={
		Say="What do you need?";
		Reply="A Walkie Talkie Blueprint. With one I can figure out how to boost the signal and get through to him.";
		Face="Tired";
	};
	["primeguncomponent_deal"]={
		Say="I'll see what I can find.";
		Reply="I appreciate it, soldier. Find me a Walkie Talkie Blueprint and I'll make it worth your while.";
		Face="Hopeful";
	};
	["primeguncomponent_give"]={
		Say="I have the Walkie Talkie Blueprint.";
		Reply="You actually found one? Hand it over, let me take a look...";
		Face="Surprise";
	};
	["primeguncomponent_thanks"]={
		Say="Here it is.";
		Reply="...adjusting the antenna configurations, boosting the power... yes, that'll do it. Derrick, do you copy? Over...\n\n *Radio(Derrick)*: Copy, Wilson! Good to hear you, buddy. Over...";
		Face="Joyful";
	};
	["primeguncomponent_reward"]={
		Say="Glad it worked out.";
		Reply="Take this as thanks, a Prime Gun Component Blueprint. I've got plenty of spares, so come back anytime you find another Walkie Talkie Blueprint.";
		Face="Confident";
	};
	["primeguncomponent_trade"]={
		Say="I have another Walkie Talkie Blueprint.";
		Reply="Alright, one blueprint for one blueprint.";
		Face="Happy";
	};
};

if RunService:IsServer() then

	Dialogues.Wilson.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		local profile = shared.modProfile:Get(player);
		local inventory = profile:GetActiveSave().Inventory;

		if mission.Type == 2 then -- Available;
			dialog:SetInitiate("Derrick, do you copy? Over... nothing. This is not good.");
			dialog:AddChoice({
				"primeguncomponent_start"; "primeguncomponent_blueprint"; "primeguncomponent_deal"
			}, function(dialog)
				modMission:StartMission(player, MISSION_ID);
			end)

		elseif mission.Type == 1 then -- Active
			local hasBlueprint = inventory:FindByItemId("walkietalkiebp") ~= nil;

			if hasBlueprint then
				dialog:SetInitiate("Any luck with that Walkie Talkie Blueprint?");
				dialog:AddChoice({
					"primeguncomponent_give"; "primeguncomponent_thanks"; "primeguncomponent_reward"
				}, function(dialog)
					local storageItem = inventory:FindByItemId("walkietalkiebp");
					if storageItem == nil then
						shared.Notify(player, "Unable to find the Walkie Talkie Blueprint in your inventory.", "Negative");
						return;
					end

					inventory:Remove(storageItem.ID, 1);
					inventory:Add("primegunpartbp", {Quantity=1});
					shared.Notify(player, "You received 1 Prime Gun Component Blueprint from Wilson.", "Reward");
					
                    modMission:CompleteMission(player, MISSION_ID);
					profile:GuiAction("specialpickup", {"primegunpartbp";});
				end)

			else
				dialog:SetInitiate("Still no word from Derrick. Come back when you've found that Walkie Talkie Blueprint.", "Angry");

			end

		elseif mission.Type == 3 then -- Complete
			dialog:SetInitiate("I still got spare Prime Gun Component Blueprints if you need more.");
			dialog:AddChoice("primeguncomponent_trade", function(dialog)
				local storageItem = inventory:FindByItemId("walkietalkiebp");
				if storageItem == nil then
					shared.Notify(player, "You don't have any Walkie Talkie Blueprint in your inventory.", "Negative");
					return;
				end

				inventory:Remove(storageItem.ID, 1);
				inventory:Add("primegunpartbp", {Quantity=1});
				shared.Notify(player, "You traded 1 Walkie Talkie Blueprint for 1 Prime Gun Component Blueprint.", "Reward");
				profile:GuiAction("specialpickup", {"primegunpartbp";});
			end)

		elseif mission.Type == 4 then -- Failed

		end
	end

end


return Dialogues;
