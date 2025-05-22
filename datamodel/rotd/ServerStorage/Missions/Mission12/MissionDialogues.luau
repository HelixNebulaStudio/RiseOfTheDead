local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Mason={};
};

local missionId = 12;
--==

-- !outline: Mason Dialogues
Dialogues.Mason.DialogueStrings = {
	["restock_factory"]={
		CheckMission=missionId; 
		Say="Sure, where are we going?"; 
		Face="Confident"; Reply="I recently scouted out the factory, it seems like there might be some supplies there.";
		FailResponses = {
			{Reply="Hmmm, looks like you'll need more training first."};
		};	
	};
	["restock_holdOn"]={
		Say="Let's go then"; 
		Face="Skeptical"; 
		Reply="Hold on.. We better refill our weapons before we enter, there were a lot of noises when I scouted the place.";
	}; --end
	["restock_refilled"]={
		Say="Yes"; 
		Face="Confident"; 
		Reply="Great, follow me..";
	};
	["restock_notRefilled"]={
		Say="No"; 
		Face="Surprise"; 
		Reply="Alright, I'll wait.";
	};

	["restock_whatsInside"]={
		Say="What's inside?"; 
		Face="Suspicious"; 
		Reply="Base on the floor plan of the place, it's probably just a couple rooms with machines and crates.";
	};
	["restock_areYouGoing"]={
		Say="Are you going in with me?"; 
		Face="Smirk"; 
		Reply="Of course, it's going to be #### in there, so you need all the help you got.";
	};
	["restock_turnBack"]={
		Say="Can we turn back?"; 
		Face="Hehe"; 
		Reply="Hmmmmm, no. I hope you have your med kits ready.";
	};
	["restock_imAlright"]={
		Say="I'm alright, thanks."; 
		Face="Confident"; 
		Reply="Great, glad we're still in one piece.. There's not much around here, but it will do. I'll take some of these resources back to the safehouse.\n\nYou should check the crate over there and see if you find anything.";
	}; --end

};

if RunService:IsServer() then
	-- !outline: Mason Handler
	Dialogues.Mason.DialogueHandler = function(player, dialog, data, mission)
		local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
		local remoteSetHeadIcon = remotes:WaitForChild("SetHeadIcon");
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available;
			dialog:SetInitiate("Hey $PlayerName, we are running low on supplies. Do you want to go scavenge for some supplies?");
			dialog:AddChoice("restock_factory", function(dialog)
				dialog:AddChoice("restock_holdOn", function(dialog)
					modMission:StartMission(player, missionId);
				end)
			end)
			
		elseif mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			if stage == 1 then
				remoteSetHeadIcon:FireClient(player, 0, "Mason", "HideAll");
				
				dialog:SetInitiate("Have you refilled your weapons yet?");
				dialog:AddChoice("restock_refilled", function(dialog)
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint < 2 then
							mission.ProgressionPoint = 2;
						end;
					end)
				end)
				dialog:AddChoice("restock_notRefilled");
				
			elseif stage == 3 or stage == 4 then
				dialog:SetInitiate("What are you waiting for?"..(mission.Cache.Blockade and " Help me destroy the barricade.. I heard you're pretty good at that." or ""));
				dialog:AddChoice("restock_whatsInside");
				dialog:AddChoice("restock_areYouGoing");
				dialog:AddChoice("restock_turnBack");
				
			elseif stage == 5 then
				dialog:SetInitiate("That was quite a fight, are you alright?");
				dialog:AddChoice("restock_imAlright", function(dialog)
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint < 6 then
							mission.ProgressionPoint = 6;
						end;
					end)
				end)
				
			elseif stage == 6 then
				dialog:SetInitiate("Let's get back to the safehouse.");
				
			end
			
		elseif mission.Type == 4 then -- Failed
			
		end
	end

end


return Dialogues;