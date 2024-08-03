local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Jane={};
	Robert={};
	Carlson={};
	Erik={};
};

local missionId = 18;
--==

-- !outline: Jane Dialogues
Dialogues.Jane.DialogueStrings = {
	["aNewCommunity_okay"]={
		Say="Okay..";
		Face="Surprise"; 
		Reply="Radio: *Static*..Help!..*Static*..Anyone..out..there....*Static*\n\n*Static*Please..respond..*Static*...We..are..in..the..sewers!..*Static*..";
	};
	["aNewCommunity_help"]={
		CheckMission=missionId;
		Say="Oh no, they need help.";
		Face="Disbelief"; 
		Reply="Sounds like they're deep inside the sewers. They could be in danger, you need to find them. Oh, and ask Robert to go along with you, he can help..";
		FailResponses = {
			{Reply="Prepare yourself before we go further out there.."};
		};	
	};

};

-- !outline: Robert Dialogues
Dialogues.Robert.DialogueStrings = {
	["aNewCommunity_joinMe"]={
		Say="We heard someone calling for help on the Radio, they said they were in the sewers.\n\nJane wants you to join me to find them.";
		Face="Question"; 
		Reply="Umm alright, but the sewers sure is going to be nasty.";
	};
	["aNewCommunity_warn"]={
		Say="Alright, be careful on your way back. I'll talk to Carlson to know more about these bandits.";
		Face="Confident"; 
		Reply="Ok dude, stay safe.";
	};
};

-- !outline: Carlson Dialogues
Dialogues.Carlson.DialogueStrings = {
	["aNewCommunity_help"]={
		Say="Hey, how can I help you?";
		Face="Frustrated"; 
		Reply="I just need some medkits please..";
	};
	["aNewCommunity_again"]={
		Say="Sorry, what do you need again?";
		Face="Tired"; 
		Reply="Some medkits, please..";
	};
	["aNewCommunity_here"]={
		Say="Here's some medkits.";
		Face="Yeesh"; 
		Reply="Thanks a lot.. I'll be much better later.";
	};

	["aNewCommunity_event"]={
		Say="What happened here?";
		Face="Frustrated"; 
		Reply="We were attacked by a group of scavenging bandits. They asked us to prepare enough food next time otherwise they will kill us..";
	};
	["aNewCommunity_bandits"]={
		Say="Do you know where the bandits live?";
		Face="Skeptical";
		Reply="No idea, but they have weapons and a lot of people, fighting them would not be a good idea.";
	};

};

-- !outline: Erik Dialogues
Dialogues.Erik.DialogueStrings = {
	["aNewCommunity_who"]={
		Say="Who attacked you?";
		Face="Disgusted"; 
		Reply="We were attacked by bandits and they took our food.";
	};
	["aNewCommunity_took"]={
		Say="I think they are gone now, you don't have to worry.";
		Face="Worried"; 
		Reply="Oh, okay, Thanks.";
	};

};


if RunService:IsServer() then
	-- !outline: Jane Handler
	Dialogues.Jane.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available;
			dialog:SetInitiate("Hey $PlayerName, I found something. Listen to this..");
			dialog:AddChoice("aNewCommunity_okay", function(dialog)
				dialog:AddChoice("aNewCommunity_help", function(dialog)
					modMission:StartMission(player, missionId);
				end)
			end)
			
		end
	end
	
	
	-- !outline: Robert Handler
	Dialogues.Robert.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 1 then
				dialog:SetInitiate("Yo, $PlayerName.");
				dialog:AddChoice("aNewCommunity_joinMe", function(dialog)
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint < 2 then
							mission.ProgressionPoint = 2;
						end;
					end)
				end)
				
			elseif mission.ProgressionPoint == 8 then
				dialog:SetInitiate("$PlayerName, I think I should head back to Sunday's to warn the others..");
				dialog:AddChoice("aNewCommunity_warn", function(dialog)
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint < 9 then
							mission.ProgressionPoint = 9;
						end;
					end)
				end)
			end
			
		end
	end

	-- !outline: Carlson Handler
	Dialogues.Carlson.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 6 then
				dialog:SetInitiate("Ugh.. I'm badly hurt.");
				dialog:AddChoice("aNewCommunity_help", function()
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint == 6 then
							mission.ProgressionPoint = 7;
						end;
					end)
				end)

			elseif mission.ProgressionPoint == 7 then
				dialog:SetInitiate("This is hella painful..");

				local profile = shared.modProfile:Get(player);
				local playerSave = profile:GetActiveSave();
				local inventory = playerSave.Inventory;
				local total, itemList = inventory:ListQuantity("medkit", 2);
				if total >= 2 then
					dialog:AddChoice("aNewCommunity_here", function()
						if itemList then
							for a=1, #itemList do
								inventory:Remove(itemList[a].ID, itemList[a].Quantity);
								shared.Notify(player, ("$Amount Medkit removed from your Inventory."):gsub("$Amount", itemList[a].Quantity > 1 and itemList[a].Quantity.." " or ""), "Negative");
							end
							modMission:Progress(player, missionId, function(mission)
								if mission.ProgressionPoint == 7 then
									mission.ProgressionPoint = 8;
								end;
							end)
						else
							shared.Notify(player, ("Unable to find items from inventory."), "Negative");
						end
					end)
				else
					dialog:AddChoice("aNewCommunity_again");
				end

			elseif mission.ProgressionPoint == 9 then
				dialog:SetInitiate("So much better now, thanks again. Man, I owe you, let me know when you need something.");
				dialog:AddChoice("aNewCommunity_event", function(dialog)
					dialog:AddChoice("aNewCommunity_bandits", function(dialog)
						modMission:CompleteMission(player, missionId);
					end)
				end)

			end
			
		end
	end

	-- !outline: Erik Handler
	Dialogues.Erik.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 6 then
				dialog:SetInitiate("We were attacked..");
				dialog:AddChoice("aNewCommunity_who", function(dialog)
					dialog:AddChoice("aNewCommunity_took");
				end);
			end
			
		end
	end
end


return Dialogues;