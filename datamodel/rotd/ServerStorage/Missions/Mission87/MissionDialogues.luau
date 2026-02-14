local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

--=
local Dialogues = {
	Joseph={};
	Caitlin={};
};

local MISSION_ID = 87;
--==

-- MARK: Joseph DialogueStrings
Dialogues.Joseph.DialogueStrings = {
	["buyre_init"] = {
		Face = "Frustrated";
		Reply = "You know what, enough is enough..";
	};
	
	["buyre_prologue1"] = {
		CheckMission=MISSION_ID;
		Face = "Angry"; 
		Say = "What are we going to do about the Rats?";
		Reply = "We could sneak into the Rat's Headquarters, and take the walkies..";
		FailResponses = {
			{Reply = "Yes, but wait for the right time."};
		};
	};
	["buyre_prologue2"] = {
		Face = "Skeptical";
		Say = "...";
		Reply = "Nate found one of the rat's tunnels during a scavenge, and he believe it leads into the harbor logistics basement..";
	};
	["buyre_prologue3"] = {
		Face = "Skeptical";
		Say = "Where is this tunnel?";
		Reply = "It's in the water treatment station nearby.\n\nWhen you're ready, I'll bring you there.";
	};


	["buyre_stop5"] = {
		Face = "Confident";
		Reply = "Yes, hello. I'm Joseph, I'm here about my goods.";
	};
	["buyre_stop8"] = {
		Face = "Suspicious";
		Say = "Uh, what do you think Joseph?";
		Reply = "I just want my walkies, no funny business..";
	};

	["buyre_gotoresidentials"] = {
		Face = "Confident";
		Say = "Yep, ready when you are.";
		Reply = "...";
	};
	["buyre_keepaneye"] = {
		Face = "Confident";
		Say = "I will.";
		Reply = "Good.";
	}
};

-- MARK: Caitlin DialogueStrings
Dialogues.Caitlin.DialogueStrings = {
	["buyre_stop1"] = {
		Face = "Skeptical";
		Say = "Wait! I'm just here to help my friend get his walkie talkies that he ordered..";
		Reply = "... That's not enough of an excuse, we have procedures.";
	};
	["buyre_stop2"] = {
		Face = "Ugh";
		Say = "Well it's not my fault that David failed to deliver, it's been weeks!";
		Reply = "Ugh, that guy.. Did he lose them or something?..";
	};
	["buyre_stop3"] = {
		Face = "Frustrated";
		Say = "Actually yes, he gambled it away to Cooper in a card game..";
		Reply = "Ah, of course he would gamble the goods he's suppose to deliver! And to Cooper no less, he's not gonna give it back..";
	};
	["buyre_stop4"] = {
		Face = "Bored";
		Say = "Hmm.., what should I do?";
		Reply = "Hmm.. Hang on a second.. What's your friend's name?";
	};
	["buyre_stop5"] = {
		Face = "Surprise";
		Say = "Oh right, this is Joseph, the guy who ordered the walkie talkies.";
		Reply = "Hmm..";
	};

	["buyre_stop6"] = {
		Face = "Surprise";
		Reply = "Alright $PlayerName, I can help you, but first you will have to take me to your friend's safehouse.";
	};
	["buyre_stop7"] = {
		Face = "Confident";
		Say = "What? why?";
		Reply = "Trust me, I might know where to find your walkies, I just need to know where your friend lives.";
	};

	["buyre_walkies1"] = {
		Face = "Confident";
		Say = "So where do we find the walkies now?";
		Reply = "Straight to the point huh? Alright, it's actually closer than I expect..";
	};
	["buyre_walkies2"] = {
		Face = "Confident";
		Say = "Well?";
		Reply = "My best guess is we should start in that W.D. Library over there..";
	};

	["buyre_library1"] = {
		Face = "Confident";
		Say = "Yes, let's go.";
		Reply = "Follow me..";
	};

	["buyre_stay"] = {
		Face = "Oops";
		Say = "...";
		Reply = "...";
	};


	["buyre_joseph1"] = {
		Face = "Suspicious";
		Say = "So uh.. why exactly are you helping us?";
		Reply = "...first tell me, what do you know about this... Joseph fellow?";
	};

	["buyre_joseph2a"] = {
		Face = "Surprise";
		Say = "He's the guy who runs this place. Neat, huh?";
		Reply = "Is that so... He does have that \"leader\" look on him..";
	};
	["buyre_joseph2b"] = {
		Face = "Scared";
		Say = "The guy who got his arm torn off and survived.";
		Reply = "Survived that? Tough guy huh?..";
	};
	["buyre_joseph2c"] = {
		Face = "Hehe";
		Say = "A humble farmer, it seems.";
		Reply = "Looks like it, but does he grow anything other than lettuce?..";
	};

	["buyre_joseph3"] = {
		Face = "Serious";
		Say = "...";
		Reply = "I'm just curious how a person like him ended up here..";
	};
	["buyre_joseph4"] = {
		Face = "Serious";
		Say = "Huh? What do you mean?";
		Reply = "Ever heard of the name Joseph Mahma?";
	};
	["buyre_joseph5"] = {
		Face = "Serious";
		Say = "Haha.. Oh, you're serious. No, I haven't.";
		Reply = "Yeah, that guy was a scientist from BioX who was working on a cure for my sister..";
	};
	["buyre_joseph6"] = {
		Face = "Serious";
		Say = "I see.. and you think Joseph might be him?";
		Reply = "Yes, and my sister -- she's running out of time. I was lucky to stumble on someone who might actually be Joseph Mahma.";
	};
	["buyre_joseph7"] = {
		Face = "Smile";
		Say = "Alright, I'll talk to Joseph and see how it goes.."; 
		Reply = "Sure.. I'll be here if you want to know more..";
	};
};

if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	-- MARK: Joseph Handler
	Dialogues.Joseph.DialogueHandler = function(player, dialog, data, mission)
		if mission.Type == 2 then -- Available
			dialog:SetInitiateTag("buyre_init");

			dialog:AddChoice({"buyre_prologue1"; "buyre_prologue2"; "buyre_prologue3"}, function(dialog)
				modMission:StartMission(player, MISSION_ID);
			end)
		
		elseif mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 1 then
				local dialogPacket = {
					Face = "Confident";
					Say = "I'm ready to go.";
					Reply = "Alrighty, follow me.";
					MissionId = MISSION_ID;
				};
				
				dialog:AddDialog(dialogPacket, function(dialog)
					modMission:Progress(player, MISSION_ID, function()
						if mission.ProgressionPoint <= 2 then
							mission.ProgressionPoint = 2;
						end
					end)
					
					local josephNpcClass: NpcClass = dialog:GetNpcClass();
					josephNpcClass.Chat(player, "Alrighty, follow me.");
				end)

			elseif mission.ProgressionPoint == 2 then
				if modBranchConfigurations.IsWorld("TheResidentials") then
					local josephNpcClass: NpcClass = dialog:GetNpcClass();

					if josephNpcClass:DistanceFromCharacter(Vector3.new(787.386, 41.301, 441.39)) <= 32 then
						dialog:SetInitiate("Head on in..", "Confident");
					end
					
				elseif modBranchConfigurations.IsWorld("TheHarbor") then
					local josephNpcClass: NpcClass = dialog:GetNpcClass();

					if josephNpcClass:DistanceFromCharacter(Vector3.new(-271.475, 40.961, 230.21)) <= 32 then
						dialog:SetInitiate("Okay, let's look for the walkies and get out quick..", "Confident");
					end

				end

			elseif mission.ProgressionPoint == 4 then
				dialog:SetInitiateTag("buyre_stop5");
				dialog:SetExpireTime(workspace:GetServerTimeNow() + 5);

			elseif mission.ProgressionPoint == 5 then
				dialog:SetInitiate("Hmm..", "Suspicious");

				dialog:AddChoice({"buyre_stop8";}, function(dialog)
					dialog:SetExpireTime(workspace:GetServerTimeNow() + 5);
					modMission:Progress(player, MISSION_ID, function()
						if mission.ProgressionPoint <= 6 then
							mission.ProgressionPoint = 6;
						end
					end)
				end);

			elseif mission.ProgressionPoint == 6 then
				dialog:SetInitiate("Fine, let's get going..", "Suspicious");
				dialog:AddChoice("buyre_gotoresidentials", function(dialog)
					modMission:Progress(player, MISSION_ID, function()
						if mission.ProgressionPoint <= 7 then
							mission.ProgressionPoint = 7;

							local josephClass = dialog:GetNpcClass();
							josephClass.Chat(player, "Alright, let's get going..");
						end
					end)
				end)

			elseif mission.ProgressionPoint == 7 then
				dialog:SetInitiate("C'mon now $PlayerName", "Bored");
				
			elseif mission.ProgressionPoint == 8 then
				dialog:SetInitiate("Get her to tell us where to find the walkies.", "Bored");

			elseif mission.ProgressionPoint == 19 then
				dialog:SetInitiate("Fine, but not for too long..\n\n$PlayerName, keep an eye on her, I got stuff to do..", "Skeptical");
				dialog:AddChoice("buyre_keepaneye", function(dialog)
					modMission:Progress(player, MISSION_ID, function()
						if mission.ProgressionPoint <= 20 then
							mission.ProgressionPoint = 20;

							task.wait(2);
							local caitlinClass = shared.modNpcs.getPlayerNpc(player, "Caitlin");
							dialog:TalkTo(caitlinClass.Character);
						end
					end)
				end)

			end
		end
	end

	-- MARK: Caitlin Handler
	Dialogues.Caitlin.DialogueHandler = function(player, dialog, data, mission)
		if mission.Type == 1 then
			if mission.ProgressionPoint == 3 then
				dialog:SetInitiate("Stop right there! You can't just willy-nilly bring strangers here.", "Angry");

				dialog:AddChoice({"buyre_stop1"; "buyre_stop2"; "buyre_stop3"; "buyre_stop4"}, function(dialog)
					modMission:Progress(player, MISSION_ID, function()
						if mission.ProgressionPoint <= 4 then
							mission.ProgressionPoint = 4;
						end
					end)

					task.wait(2);
					local josephClass = shared.modNpcs.getPlayerNpc(player, "Joseph");
					dialog:TalkTo(josephClass.Character);
				end)

			elseif mission.ProgressionPoint == 4 then
				dialog:SetInitiate("Are you listening?", "Bored");

			elseif mission.ProgressionPoint == 5 then
				dialog:SetInitiateTag("buyre_stop6");
				
				dialog:AddChoice({"buyre_stop7";}, function(dialog)
					task.wait(5);
					local josephClass = shared.modNpcs.getPlayerNpc(player, "Joseph");
					dialog:TalkTo(josephClass.Character);
				end);

			elseif mission.ProgressionPoint == 6 then
				dialog:SetInitiate("Are we going or not?", "Bored");

			elseif mission.ProgressionPoint == 7 then
				dialog:SetInitiate("What are we doing here?", "Bored");

			elseif mission.ProgressionPoint == 8 then
				dialog:SetInitiate("Hmph, not a bad place you got here.", "Confident");
				
				dialog:AddChoice({"buyre_walkies1"; "buyre_walkies2";}, function(dialog)
					modMission:Progress(player, MISSION_ID, function()
						if mission.ProgressionPoint <= 9 then
							mission.ProgressionPoint = 9;
						end
					end)
				end);

			elseif mission.ProgressionPoint == 9 then
				dialog:SetInitiate("Are you ready to go?", "Confident");
				
				dialog:AddChoice({"buyre_library1";}, function(dialog)
					modMission:Progress(player, MISSION_ID, function()
						if mission.ProgressionPoint <= 10 then
							mission.ProgressionPoint = 10;
						end
					end)
					
					--dialog:SetExpireTime(workspace:GetServerTimeNow() + 5);

					local caitlinClass = dialog:GetNpcClass();
					dialog:TalkTo(caitlinClass.Character);
				end);

			elseif mission.ProgressionPoint == 19 then
				dialog:SetInitiate("Alright, I helped you guys out, can I stay here for a while?", "Oops");

				dialog:AddChoice({"buyre_stay"}, function(dialog)
					local josephClass = shared.modNpcs.getPlayerNpc(player, "Joseph");
					dialog:TalkTo(josephClass.Character);
				end)

			elseif mission.ProgressionPoint == 20 then
				dialog:SetInitiate("Hmph, not a bad place you got here.", "Oops");

				dialog:AddChoice({"buyre_joseph1";}, function(dialog)
					local function joseph3(dialog)
						dialog:AddChoice({"buyre_joseph3"; "buyre_joseph4"; "buyre_joseph5"; "buyre_joseph6"; "buyre_joseph7";}, function(dialog)
							modMission:CompleteMission(player, MISSION_ID);
						end)
					end
					dialog:AddChoice("buyre_joseph2a", joseph3);
					dialog:AddChoice("buyre_joseph2b", joseph3);
					dialog:AddChoice("buyre_joseph2c", joseph3);
				end);

			end
		end
	end

	
end


return Dialogues;