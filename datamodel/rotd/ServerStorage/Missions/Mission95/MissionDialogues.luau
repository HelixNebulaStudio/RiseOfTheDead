local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Russell={};
};

local MISSION_ID = 95;
--==

Dialogues.Russell.DialogueStrings = {
	["basicguncomponent_start"]={
		CheckMission=MISSION_ID;
		Say="Mason says you know how more advanced weapons work?";
        Reply="Heh yep, I used to be in the military before all of this happened.";
		Face="Smirk"; 
	};
	["basicguncomponent_explain"]={
		Say="Can you teach me?";
        Reply="Advanced weapons are built from components. The most basic one is the Basic Gun Component.";
		Face="Skeptical"; 
	};
	["basicguncomponent_blueprint"]={
		Say="Where do I get the blueprint?";
        Reply="Zomborg near W.D. Mall is loaded with parts. Defeat it and you should be able to pry a Basic Gun Component Blueprint out of it.";
		Face="Suspicious"; 
	};
	["basicguncomponent_build"]={
		Say="And then?";
        Reply="Take the blueprint and some materials to a Workbench, build the Basic Gun Component, then bring it back to me.";
		Face="Bored"; 
	};
	["basicguncomponent_give"]={
		Say="I have the Basic Gun Component.";
        Reply="Let me see it then.";
		Face="Skeptical"; 
	};
	["basicguncomponent_thanks"]={
		Say="Here it is.";
        Reply="Not bad for a first build. Stick around and I'll show you how to make more advanced gun components.";
		Face="Confident"; 
	};
};

if RunService:IsServer() then

	Dialogues.Russell.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		local profile = shared.modProfile:Get(player);

		if mission.Type == 2 then -- Available;
			dialog:SetInitiate("What do you want?");
			dialog:AddChoice({
                "basicguncomponent_start"; "basicguncomponent_explain"; 
                "basicguncomponent_blueprint"; "basicguncomponent_build"
            }, function(dialog)
                modMission:StartMission(player, MISSION_ID);

			end)

		elseif mission.Type == 1 then -- Active
			local inventory = profile:GetActiveSave().Inventory;
			local hasComponent = inventory:FindByItemId("basicgunpart") ~= nil;

			if hasComponent then
				dialog:SetInitiate("Back already? Let me see what you've got.");
				dialog:AddChoice({
                    "basicguncomponent_give"; "basicguncomponent_thanks"
                }, function(dialog)
                    local storageItem = inventory:FindByItemId("basicgunpart");
                    if storageItem == nil then
                        shared.Notify(player, "Unable to find the Basic Gun Component in your inventory.", "Negative");
                        return;
                    end

                    inventory:Remove(storageItem.ID, 1);
                    modMission:CompleteMission(player, MISSION_ID);
				end)

			else
				dialog:SetInitiate("Come back when you have that Basic Gun Component.", "Angry");

			end

		elseif mission.Type == 4 then -- Failed

		end
	end

end


return Dialogues;