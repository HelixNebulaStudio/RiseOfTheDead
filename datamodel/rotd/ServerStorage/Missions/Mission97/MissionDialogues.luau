local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Nate={};
};

local MISSION_ID = 97;
--==

Dialogues.Nate.DialogueStrings = {
	["advguncomponent_start"]={
		CheckMission=MISSION_ID;
		Say="You seem upset, Nate. What happened?";
		Reply="Ugh. Don't even get me started. I asked the Rats for an Advance Gun Component Blueprint. ONE blueprint. They looked at me like I asked to marry their queen.";
		Face="Angry";
	};
	["advguncomponent_rant"]={
		Say="What about the Bandits?";
		Reply="So I went to the Bandits. The BANDITS. You know what they said? 'We don't do business with residentials people.' RESIDENTIALS PEOPLE. That's not even a thing!";
		Face="Frustrated";
	};
	["advguncomponent_rant2"]={
		Say="Why not just take one?";
		Reply="I'd sneak into their headquarters and take one, but last time I tried that I got chased by a guy with a helmet made of road signs, are you kidding me!";
		Face="Skeptical";
	};
	["advguncomponent_deal"]={
		Say="What do you need?";
		Reply="...You've got a face they don't hate yet. Buy the Advance Gun Component Blueprint from the Rats or the Bandits for me, and I'll finally upgrade this scrappy pile of junk I call a gun.";
		Face="Skeptical";
	};
	["advguncomponent_give"]={
		Say="I have the Advance Gun Component Blueprint.";
		Reply="No waay, you actually got one?";
		Face="Surprise";
	};
	["advguncomponent_thanks"]={
		Say="Here it is.";
		Reply="HA! Take THAT, Rats! Take THAT, Bandits!";
		Face="Happy";
	};
	["advguncomponent_reward"]={
		Say="Happy to help.";
		Reply="Give me a bit to build the component and upgrade my gun. Then the next Rat or Bandit who gives me a look is getting a history lesson.";
		Face="Confident";
	};
	["advguncomponent_done"]={
		Say="How's the new gun?";
		Reply="Advance tier. Beautiful. I named it 'The Fast-Bullet Injector', because it's RPM is off the charts..";
		Face="Confident";
	};
};

if RunService:IsServer() then

	Dialogues.Nate.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		local profile = shared.modProfile:Get(player);
		local inventory = profile:GetActiveSave().Inventory;

		if mission.Type == 2 then -- Available;
			dialog:SetInitiate("Stupid Rats.. and Bandits. Or anyone with a growly voice.");
			dialog:AddChoice({
				"advguncomponent_start"; "advguncomponent_rant"; "advguncomponent_rant2"; "advguncomponent_deal"
			}, function(dialog)
				modMission:StartMission(player, MISSION_ID);
			end)

		elseif mission.Type == 1 then -- Active
			local hasBlueprint = inventory:FindByItemId("advgunpartbp") ~= nil;

			if hasBlueprint then
				dialog:SetInitiate("Well? Are you smiling because you got the blueprint?");
				dialog:AddChoice({
					"advguncomponent_give"; "advguncomponent_thanks"; "advguncomponent_reward"
				}, function(dialog)
					local storageItem = inventory:FindByItemId("advgunpartbp");
					if storageItem == nil then
						shared.Notify(player, "Unable to find the Advance Gun Component Blueprint in your inventory.", "Negative");
						return;
					end

					inventory:Remove(storageItem.ID, 1);
					shared.Notify(player, "You gave Nate 1 Advance Gun Component Blueprint.", "Reward");

					modMission:CompleteMission(player, MISSION_ID);
				end)

			else
				dialog:SetInitiate("The blueprint's sold at the Rat's Special and the Bandit's Special pages. 6000 bucks. I'd pay you back, but I spent it all on... you don't want to know.", "Angry");

			end

		elseif mission.Type == 3 then -- Complete
			if modMission:GetData(player, MISSION_ID, "done") == nil then
				modMission:SetData(player, MISSION_ID, "done", 1);
				dialog:AddChoice("advguncomponent_done");
			end

		elseif mission.Type == 4 then -- Failed

		end
	end

end


return Dialogues;
