local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Frank={};
	Greg={};
	Diana={};
};

local missionId = 71;
--==

-- !outline: Frank Dialogues
Dialogues.Frank.DialogueStrings = {
	["hvp_collect"]={
		Say="I'm here to deliver this high value package to you..";
		Face="Happy"; 
		Reply="Ah yes, put it here dude.";
	};
	["hvp_collectfull"]={
		Say="I'm here to deliver this high value package to you..";
		Face="Happy"; 
		Reply="Got any space for this dude?";
	};
	["hvp_lost"]={
		Say="I was suppose to deliver a package to you, but I lost it..";
		Face="Serious"; 
		Reply="Ah welp, you should go back and get another one..";
	};
};

-- !outline: Greg Dialogues
Dialogues.Greg.DialogueStrings = {
	["hvp_init"]={
		Say="Hey, heard you need someone for a delivery?";
		Face="Welp"; 
		Reply="Yes, here take this package and bring it to wherever man.";
	};
	["hvp_package"]={
		Say="Umm, what's in the package?";
		Face="Serious"; 
		Reply="None of your business, you imbecile.";
	};
	["hvp_lost"]={
		Say="Umm, I think I lost the package..";
		Face="Angry"; 
		Reply="What! Are you serious man!";
	};
};

-- !outline: Diana Dialogues
Dialogues.Diana.DialogueStrings = {
	["hvp_collect"]={
		Say="I'm here to deliver this high value package to you..";
		Face="Happy"; 
		Reply="Awesome, I hope it wasn't much trouble.";
	};
	["hvp_collectfull"]={
		Say="I'm here to deliver this high value package to you..";
		Face="Happy"; 
		Reply="Great, but you're gonna need space for this..";
	};
	["hvp_lost"]={
		Say="I was suppose to deliver a package to you, but I lost it..";
		Face="Serious"; 
		Reply="Ah.. You might have to get another one.";
	};
};


if RunService:IsServer() then
	-- !outline: Frank Handler
	Dialogues.Frank.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 2 then
				local profile = shared.modProfile:Get(player);
				local activeInventory = profile.ActiveInventory;

				local inventory = profile.ActiveInventory;
				local total, itemList = inventory:ListQuantity("highvaluepackage", 1);

				if itemList then

					if modMission:CanCompleteMission(player, missionId, true) then
						dialog:AddChoice("hvp_collect", function(dialog)
							for a=1, #itemList do
								inventory:Remove(itemList[a].ID, itemList[a].Quantity);
							end
							task.wait(0.5);

							modMission:CompleteMission(player, missionId);
						end)
					else
						dialog:AddChoice("hvp_collectfull");
					end

				else
					dialog:AddChoice("hvp_lost", function(dialog)
						modMission:FailMission(player, missionId, "You somehow lost the package.");
					end)

				end
			end
			
		end
	end

	-- !outline: Greg Handler
	Dialogues.Greg.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			local profile = shared.modProfile:Get(player);
			local activeInventory = profile.ActiveInventory;

			if mission.ProgressionPoint == 1 then
				dialog:AddChoice("hvp_init", function(dialog)

					local hasSpace = activeInventory:SpaceCheck{{ItemId="highvaluepackage"; Data={Quantity=1};}};
					if not hasSpace then
						shared.Notify(player, "Not enough inventory space to receive mission reward.", "Negative");
						return;
					end

					activeInventory:Add("highvaluepackage", {Quantity=1;}, function()
						shared.Notify(player, "You received a High Value Package.", "Reward");
					end);

					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint < 2 then
							mission.ProgressionPoint = 2;
						end;
					end)
				end)

			else

				local inventory = profile.ActiveInventory;
				local total, itemList = inventory:ListQuantity("highvaluepackage", 1);

				if total <= 0 then
					dialog:AddChoice("hvp_lost", function(dialog)
						modMission:FailMission(player, missionId, "You somehow lost the package.");
					end)
				end

				dialog:AddChoice("hvp_package");

			end
		end
	end
	

	-- !outline: Diana Handler
	Dialogues.Diana.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
		
		if mission.Type == 1 then
			if mission.ProgressionPoint == 2 then
				local profile = shared.modProfile:Get(player);
				local activeInventory = profile.ActiveInventory;

				local inventory = profile.ActiveInventory;
				local total, itemList = inventory:ListQuantity("highvaluepackage", 1);

				if itemList then
					dialog:AddChoice("hvp_collect", function(dialog)
						for a=1, #itemList do
							inventory:Remove(itemList[a].ID, itemList[a].Quantity);
						end
						task.wait(0.5);

						modMission:CompleteMission(player, missionId);
					end)

				else
					dialog:AddChoice("hvp_lost", function(dialog)
						modMission:FailMission(player, missionId, "You somehow lost the package.");
					end)

				end
			end
		end
	end
	
end


return Dialogues;