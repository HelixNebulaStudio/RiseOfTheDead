local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Stan={};
	Zark={};
	Patrick={};
};

local missionId = 33;
--==

-- !outline: Stan Dialogues
Dialogues.Stan.DialogueStrings = {
	["awokeTheBear_init"]={
		CheckMission=missionId;
		Say="Yeah, I think he should hold up his end of the bargin.";
		Face="Confident";
		Reply="Alright, let's go.";
		FailResponses = {
			{Reply="There's an increase in bandits activity, we should wait a bit.."};
		};	
	};

	["awokeTheBear_tryAgain"]={
		Say="Sorry, something came up, I had to go. Let's go again.";
		Face="Confident"; 
		Reply="Fine.. let's go.";
	};
};

-- !outline: Zark Dialogues
Dialogues.Zark.DialogueStrings = {
	["awokeTheBear_zarkInit"]={
		Say="We have some questions..";
		Face="Frustrated"; 
		Reply="And why do you think I have the answers to them?";
	};

	["awokeTheBear_robert"]={
		Say="Why did you kidnap one of ours?!";
		Face="Angry"; 
		Reply="Kidnapped? How dare you accuse me of kidnapping.";
	};

	["awokeTheBear_accuse"]={
		Say="We think you kidnapped one of ours and we need him back!";
		Face="Frustrated"; 
		Reply="I have no clue what you are talking about, you better ask your next question carefully. Your friend's life is on the line..";
	};

	["awokeTheBear_where"]={
		Say="Where is Robert?!";
		Face="Angry"; 
		Reply="I've answered that question already, I do not know who is Robert!";
	};

	["awokeTheBear_bandits"]={
		Say="WAIT!!! BUT HE WENT MISSING WHEN HE WAS TRYING TO TELL US ABOUT YOU GUYS!!";
		Face="Frustrated"; 
		Reply="That is not a question, last chance..";
	};

	["awokeTheBear_stop"]={
		Say="STOP!! SOME OF YOUR BANDITS WERE HEARD RUNNING AWAY FROM THE SEWERS WHEN HE WENT MISSING!!";
		Face="Frustrated"; 
		Reply="Hmmmm.. Yes, there was reports of that happening. But oh well. *bang*";
	};

	["awokeTheBear_why"]={
		Face="Frustrated";
		Say="WHY!!! WHY WOULD YOU DO THIS?!";
		Reply="He was already going to die the moment he stepped into this place.";
	};

	["awokeTheBear_player"]={
		Face="Angry";
		Say="?!";
		Reply="But you, you are special, aren't you. Tell me about what happened in the sewers..";
	};

	["awokeTheBear_sewers"]={
		Face="Angry";
		Say="ALL I KNOW IS YOUR GROUP OF BANDITS RAN... or was running away from something..";
		Reply="Or something.. Listen carefully now, I need you to tell me everything, or else you will end up in pieces like your friend over here.";
	};

	["awokeTheBear_banditZombie"]={
		Face="Angry";
		Say=".. one of your members changed, changed into a zombie..";
		Reply="Is that so...";
	};
};

-- !outline: Patrick Dialogues
Dialogues.Patrick.DialogueStrings = {
	["awokenTheBear_giveKey"]={
		Face="Grumpy";
		Say="Where's the room?";
		Reply="Downstairs, next to the food court..";
	};
	["newInfo"]={
		Face="Confident";
		Say="Got any new info about the Bandits?";
		Reply="I got nothing interesting for now.";
	};
};

if RunService:IsServer() then
	-- !outline: Stan Handler
	Dialogues.Stan.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available;
			dialog:SetInitiate("We've waited enough, we should talk to Patrick.", "Angry");
			dialog:AddChoice("awokeTheBear_init", function(dialog)
				modMission:StartMission(player, missionId);
			end)
			
		elseif mission.Type == 4 then -- Failed
			dialog:SetInitiate("Why did you leave me all by myself in the Bandit Camp?!", "Angry");
			dialog:AddChoice("awokeTheBear_tryAgain", function(dialog)
				mission.ProgressionPoint = 3;
				modMission:StartMission(player, missionId);
			end)
			
		end
	end

	-- !outline: Zark Handler
	Dialogues.Zark.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 7 then
				dialog:SetInitiate("So you are the one I've been hearing about.. I see you have found a way into our camp. Tell me, what brings you here?", "Angry");
				dialog:AddChoice("awokeTheBear_zarkInit", function(dialog)
					dialog:AddChoice("awokeTheBear_robert", function(dialog)
						dialog:AddChoice("awokeTheBear_accuse", function(dialog)
							modMission:Progress(player, missionId, function(mission)
								if mission.ProgressionPoint <= 7 then
									mission.ProgressionPoint = 8;
								end;
							end)
						end);
					end);
				end);

			elseif mission.ProgressionPoint == 8 then
				dialog:SetInitiate("Well.. What is it?", "Angry");
				dialog:AddChoice("awokeTheBear_where", function(dialog)
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint <= 8 then
							mission.ProgressionPoint = 9;
						end;
					end)
				end);

			elseif mission.ProgressionPoint == 9 then
				dialog:SetInitiate("...", "Angry");
				dialog:AddChoice("awokeTheBear_bandits", function(dialog)
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint <= 9 then
							mission.ProgressionPoint = 10;
						end;
					end)
				end);

			elseif mission.ProgressionPoint == 10 then
				dialog:SetInitiate("...", "Angry");
				dialog:AddChoice("awokeTheBear_stop", function(dialog)
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint <= 10 then
							mission.ProgressionPoint = 11;
						end;
					end)
				end);

			elseif mission.ProgressionPoint == 11 then
				dialog:SetInitiate("...", "Angry");
				dialog:AddChoice("awokeTheBear_why", function(dialog)
					dialog:AddChoice("awokeTheBear_player", function(dialog)
						dialog:AddChoice("awokeTheBear_sewers", function(dialog)
							dialog:AddChoice("awokeTheBear_banditZombie", function(dialog)
								modMission:Progress(player, missionId, function(mission)
									if mission.ProgressionPoint <= 11 then
										mission.ProgressionPoint = 12;
									end;
								end)
							end);
						end);
					end);
				end);

			end

		end
	end
	

	-- !outline: Patrick Handler
	Dialogues.Patrick.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 2 then
				dialog:SetInitiate("Here, took me a while to sneak this key out. This is the key to the secret room below to enter the camp.", "Confident");
				dialog:AddChoice("awokenTheBear_giveKey", function(dialog)
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint <= 2 then
							mission.ProgressionPoint = 3;
						end;
					end)
				end);

			elseif mission.ProgressionPoint == 13 then
				dialog:SetInitiate("Hey, it's me, Patrick. We need to get out of here.\nI am so sorry about Stan, I didn't think Zark wanted him dead for trying to meet him.", "Confident");
				modMission:Progress(player, missionId, function(mission)
					if mission.ProgressionPoint <= 13 then
						mission.ProgressionPoint = 14;
					end;
				end)

			end

		elseif mission.Type == 3 then -- Complete
			
			local mission58 = modMission:GetMission(player, 58);
			if mission58 == nil then
				dialog:AddChoice("newInfo");
				
			else
				if mission58.Type ~= 1 then
					if shared.modSafehomeService == nil or shared.modSafehomeService.FactionTag == nil then
						dialog:AddChoice("banditOutpost");
					end
				end
			end
			
		end
	end
end


return Dialogues;