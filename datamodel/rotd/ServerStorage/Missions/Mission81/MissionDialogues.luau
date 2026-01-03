local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
local modBitFlags = shared.require(game.ReplicatedStorage.Library.BitFlags);
local modCardGame = shared.require(game.ReplicatedStorage.Library.CardGame);

--=
local Dialogues = {
	Joseph={};

	David={};
	Cooper={};

	Caitlin={};
	Greg={};
	Lewis={};
};

local MISSION_ID = 81;


local checkpointFlags = modBitFlags.new();
checkpointFlags:AddFlag("david_askWalkieTalkie", 1);
checkpointFlags:AddFlag("cooper_betAway", 2);
checkpointFlags:AddFlag("cooper_askWalkie", 3);
checkpointFlags:AddFlag("david_revealCooperHas", 4);
checkpointFlags:AddFlag("david_winBack", 5);
--==


-- MARK: Joseph DialogueStrings
Dialogues.Joseph.DialogueStrings = {
	["fotl_init"]={
		Face="Skeptical";
		Reply="Should be here by now.. Oh hello, $PlayerName.";
	};
	["fotl_prologue1"]={
		CheckMission=MISSION_ID;
		Face="Skeptical"; 
		Say="Hey Joseph, what was that about something should be here now?";
		Reply="Yeah, these Rats.. I made a deal with them for some walkie talkies a while ago..";
		FailResponses = {
			{Reply="We'll wait a while and see when it will be delivered first."};
		};
	};
	["fotl_prologue2"]={
		Face="Skeptical";
		Say="...";
		Reply="...Til this day, they have yet to deliver.";
	};
	["fotl_prologue3"]={
		Face="Suspicious";
		Say="Hmmm, would you like me to talk to them?";
		Reply="Are you sure? You will have to head to the W.D. Harbor to talk to them.";
	};
	["fotl_prologue4"]={
		Face="Confident";
		Say="Yeah, I don't mind. I can go talk to them.";
		Reply="In that case, it's a box of 3 walkie talkies. Good luck out there!";
	};
};

-- MARK: Joseph Handler
Dialogues.Joseph.DialogueHandler = function(player, dialog, data, mission)
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	if mission.Type == 2 then -- Available
		dialog:SetInitiateTag("fotl_init");

		dialog:AddChoice("fotl_prologue1", function(dialog)
			dialog:AddChoice("fotl_prologue2", function(dialog)
				dialog:AddChoice("fotl_prologue3", function(dialog)
					dialog:AddChoice("fotl_prologue4", function(dialog)
						modMission:StartMission(player, MISSION_ID);
					end)
				end)
			end)
		end)

	elseif mission.Type == 1 then -- Active

		if mission.ProgressionPoint <= 3 then
			dialog:SetInitiate("I swear if we were scammed by those Rats again..", "Suspicious");

		elseif mission.ProgressionPoint == 10 then

			dialog:SetInitiate("How'd it go with the Rats?", "Suspicious");

			dialog:AddDialog({
				Face="Frustrated";
				Say="David gambled it away and they wouldn't give it back..";
				Reply="Those darn Rats.. This isn't the first time they failed to deliver.";
				
			}, function(dialog)
				dialog:AddDialog({
					Face="Skeptical";
					Say="What happened?";
					Reply="We exchanged a large amount of food for better farming equipments. They never delivered, they said they lost the cargo at sea or something.. But I bet they were lying.";
					
				}, function(dialog)
					dialog:AddDialog({
						Face="Skeptical";
						Say="How about the walkies?";
						Reply="We exchanged money and this time, we're going to get what we paid for..\nWe'll plan something..";
						
					}, function(dialog)
						modMission:CompleteMission(player, MISSION_ID);
			
					end);
		
				end);
	
			end);


			dialog:SkipOtherDialogues();
		end

	end
end


-- MARK: David Handler
Dialogues.David.DialogueHandler = function(player, dialog, data, mission)
	local cooperChar = workspace.Entity:FindFirstChild("Cooper");

	local saveFlag = mission.SaveData.Flags;

	if mission.Type ~= 1 then return end;

	local activeCardGameLobby = modCardGame.GetLobby(player);
	
	if activeCardGameLobby then
		if activeCardGameLobby.Host == dialog.Character then
			dialog:SetInitiate("You're going down.", "Smirk");

		else
			return;

		end
	elseif mission.ProgressionPoint == 1 then 
		if checkpointFlags:Test("cooper_askWalkie", saveFlag) then
			dialog:SetInitiate("Cooper has them! And I'm pretty sure he won't give it away.", "Skeptical");
			
			dialog:AddDialog({
				Face="Skeptical";
				Say="...";
				Reply="...";
				
			}, function(dialog)
				mission.SaveData.Flags = checkpointFlags:Set(saveFlag, "david_revealCooperHas", true);
				
				dialog:TalkTo(cooperChar);
	
			end);
	
		elseif checkpointFlags:Test("david_askWalkieTalkie", saveFlag) == false then
			dialog:SetInitiate("...cheater! How did you win again!..\n*Turns to you* Uggh, what do you want?", "Frustrated");
	
			dialog:AddDialog({
				Face="Skeptical";
				Say="Ummm, I'm sent by Joseph, here for a box of walkie talkies?";
				Reply="...";
				
			}, function(dialog)
				mission.SaveData.Flags = checkpointFlags:Set(saveFlag, "david_askWalkieTalkie", true);
	
				dialog:TalkTo(cooperChar);
	
			end);
	
		elseif checkpointFlags:Test("cooper_betAway", saveFlag) == true then
			dialog:SetInitiate("Uhh.. Yeah.. I made some bad bets.", "Suspicious");

			dialog:AddDialog({
				Face="Skeptical";
				Say="I need those walkie talkies for Joseph..";
				Reply="Look, I was about to win them back.";
				
			}, function(dialog)
				mission.SaveData.Flags = checkpointFlags:Set(saveFlag, "david_winBack", true);
				dialog:TalkTo(cooperChar);

			end);

		else
			dialog:SetInitiate("Uhh", "Suspicious");
	
		end

	elseif mission.ProgressionPoint == 2 then
		dialog:SetInitiate("Fine, I'll teach you how to play.", "Skeptical");
		
		dialog:AddDialog({
			Face="Serious";
			Say="...";
			Reply="I'll teach you the basic gist, the rest you will have to learn by yourself.";
			
		}, function(dialog)
			dialog:AddDialog({
				Face="Serious";
				Say="Okay..";
				Reply="The game is about strategy, bluffing and enemy deductioning.. Whenever it's your turn, you can pick any action you can afford with your resource.";
				
			}, function(dialog)
				dialog:AddDialog({
					Face="Serious";
					Say="Okay, what are these actions?";
					Reply="The actions are based on the cards. You are given 2 random cards, whatever card you are holding allows you to play an action without bluffing. If you don't have a specific card, you can bluff their action.";
					
				}, function(dialog)
					
					dialog:AddDialog({
						Face="Smirk";
						Say="What happens if I bluff an action?";
						Reply="Well, if you play it smart, you get away with bluffing an action. If your opponents calls you out, you might have to fold a card, and once you lose all your cards, you are defeated.";
						
					}, function(dialog)

						local function tutorialLoop(dialog)
							
							dialog:AddDialog({
								Face="Confident";
								Say="How do I win?";
								Reply="If you want to win, you have to really pay attention to what actions people play. If someone's playing multiple actions, they are likely bluffing since they only have at most 2 different legit action to play.";
								
							}, tutorialLoop);

							dialog:AddDialog({
								Face="Confident";
								Say="Can I recover my cards?";
								Reply="No, once you lose a card, it's permanent for the rest of the match.";
								
							}, tutorialLoop);

							dialog:AddDialog({
								Face="Confident";
								Say="How do I make others lose their cards?";
								Reply=[[You have 3 options:
	1. Heavy attack which cost 10 resources allows you to take out an opponent's card and can't be blocked and doesn't require a card.
	2. Attack with 4 resources which requires a Rogue (red) card or bluff. Oppenents can block your attach with a Zombie (green) card.
	3. Calling someone's bluff correctly and they'll have to surrender one of their cards.
								]];
								
							}, tutorialLoop);
				
							dialog:AddDialog({
								Face="Confident";
								Say="I think I get it.";
								Reply="Alright then, play against me and lets test your skill.";
								
							}, function(dialog)
								modMission:Progress(player, MISSION_ID, function()
									if mission.ProgressionPoint <= 2 then
										mission.ProgressionPoint = 3;
									end
								end)
		
								dialog:TalkTo(dialog.Character);
							end);

						end

						dialog:AddDialog({
							Face="Confident";
							Say="I see.";
							Reply="That's the general idea, do you want more detail or do you get the idea?";
							
						}, tutorialLoop);

					end);
		
				end);
	
			end);

		end);

	elseif mission.ProgressionPoint == 9 then
		dialog:SetInitiate("Soo yeah...", "Oops");

		dialog:AddDialog({
			Face="Sad";
			Say="You owe us those walkies..";
			Reply="Sorry homie, I can't do anything about it.";
			
		}, function(dialog)
			dialog:AddDialog({
				Face="Question";
				Say="But you gambled it away!";
				Reply="Like I said, can't do anything about it..";
				
			}, function(dialog)
				modMission:Progress(player, MISSION_ID, function()
					if mission.ProgressionPoint <= 9 then
						mission.ProgressionPoint = 10;
					end
				end)

			end);
		end);

	end
	
	local function StartCardGame(dialog)
		local npcName = dialog.Name;
		local npcChar = dialog.Character;
		
		local cardGameLobby = modCardGame.NewLobby(npcChar);
		local npcTable = cardGameLobby:GetPlayer(npcChar);

		local npcClass: NpcClass = dialog:GetNpcClass();

		local npcQuips = {
			CaughtNotBluffing = {
				"Bad guess";
				"Thought I was bluffing ey?";
				"Nice try pal";
				"Sike! It's genuine!";
			};
			CaughtBluffing = {
				"Ain't no way";
				"Lucky guess";
				"You got me";
				"What gave it away?";
			};
			CardLoss = {
				"Yikes, down a card";
				"Uoh noo";
				"How could you!";
			};
			FailAccuse = {
				"How!?";
				"But I thought..";
				"I've guessed wrong..";
			};
			CallBluff = {
				"I have a feeling you're bluffing..";
				"Bluffing?";
				"Pretty sure you're bluffing";
			};
			PlayerDefeated = {
				"Better luck next time $PlayerName";
				"Good try, you just need a bit more practice $PlayerName";
			};
		};

		local function cardGameQuips(quipType, param)
			param = param or {};

			local quipsList = npcQuips[quipType];
			if quipsList == nil then return end;

			local pickQuip = quipsList[math.random(1, #quipsList)];
			pickQuip = string.gsub(pickQuip, "$PlayerName", (param.PlayerName or "pal"));

			npcClass.Chat(game.Players:GetPlayers(), pickQuip);
 		end

		-- MARK: David Fotl Agent
		npcTable.ComputerAutoPlay = modCardGame.NewComputerAgentFunc(npcChar, cardGameLobby, {
			BluffChance=0;
			CheatChance=0;
			Actions = {
				Scavenge = {Genuine=0.3;};
				RogueAttack = {CallBluff=1; Genuine=0.3; Bluff=0.1; AccuseFailPenalty=0.7;};
				BanditRaid = {CallBluff=1; Genuine=0.6; Bluff=0.35; AccuseFailPenalty=0.7;};
				RatSmuggle = {CallBluff=1; Genuine=0.8; Bluff=0.6; AccuseFailPenalty=0.7;};
				BioXSwap = {CallBluff=0.1; Genuine=0.6; Bluff=0.2;};
				ZombieBlock = {CallBluff=1; Bluff=0.5; AccuseFailPenalty=0.7;};
			};
			OnCaughtNotBluffing=function()
				cardGameQuips("CaughtNotBluffing");
			end;
			OnCaughtBluffing=function()
				cardGameQuips("CaughtBluffing");
			end;
			OnCardLoss=function()
				cardGameQuips("CardLoss");
			end;
			OnCallBluff=function()
				cardGameQuips("CallBluff");
			end;
			OnFailAccuse=function()
				cardGameQuips("FailAccuse");
			end;
			OnPlayerDefeated=function(defeatedPlayer)
				cardGameQuips("CardLoss", {
					PlayerName=defeatedPlayer and defeatedPlayer.Name;
				});
			end;
		});

		cardGameLobby:Join(player, true);
		cardGameLobby:Start();

		dialog:SetExpireTime(workspace:GetServerTimeNow()+2);
	end
	
	if mission.ProgressionPoint == 3 then
		dialog:SetInitiate("Want to put your skill to the test?", "Suspicious");

		dialog:AddDialog({
			Face="Confident";
			Say="Let's play";
			Reply="Alright. *Hands you two cards*";
			
		}, StartCardGame);

	elseif mission.ProgressionPoint == 4 then
		dialog:SetInitiate("Best 2 out of 3?", "Welp");

		dialog:AddDialog({
			Face="Confident";
			Say="Let's play";
			Reply="Alright. *Hands you two cards*";
			
		}, StartCardGame);

	end

	dialog:SkipOtherDialogues();
end

-- MARK: Cooper Handler
Dialogues.Cooper.DialogueHandler = function(player, dialog, data, mission)
	local davidChar = workspace.Entity:FindFirstChild("David");
	local saveFlag = mission.SaveData.Flags;

	if mission.Type ~= 1 then return end;

	if mission.ProgressionPoint == 1 then
		if checkpointFlags:Test("david_winBack", saveFlag) == true then
			dialog:SetInitiate("David won't be winning them back any time soon.", "Smirk");
			
			dialog:AddDialog({
				Face="Confident";
				Say="Is there any way I could get them back?";
				Reply="Hmmm.. Do you know how to play the card game Fall of the Living?";
			}, function(dialog)

				dialog:AddDialog({
					Face="Confident";
					Say="No, I don't know how to play.";
					Reply="Okay, David will teach you.";
				}, function(dialog)
					
					dialog:AddDialog({
						Face="Confident";
						Say="...";
						Reply="...";
					}, function(dialog)
						
						modMission:Progress(player, MISSION_ID, function()
							if mission.ProgressionPoint <= 1 then
								mission.ProgressionPoint = 2;
							end
						end)

						dialog:TalkTo(davidChar);

					end)

				end)

				dialog:AddDialog({
					Face="Confident";
					Say="Yes, I know how to play.";
					Reply="Alright, I'll give you a chance to practice by playing against David first.";
				}, function(dialog)
					
					dialog:AddDialog({
						Face="Confident";
						Say="Okay";
						Reply="...";
					}, function(dialog)
						
						modMission:Progress(player, MISSION_ID, function()
							if mission.ProgressionPoint <= 1 then
								mission.ProgressionPoint = 3;
							end
						end)

						dialog:TalkTo(davidChar);

					end)
					
				end)

			end)
	
		elseif checkpointFlags:Test("david_askWalkieTalkie", saveFlag) then
			dialog:SetInitiate("Box of walkie talkies ey? David over here gambled them away earlier!", "Smirk");
	
			dialog:AddDialog({
				Face="Confident";
				Say="...";
				Reply="...";
				
			}, function(dialog)
				mission.SaveData.Flags = checkpointFlags:Set(saveFlag, "cooper_betAway", true);
				
				dialog:TalkTo(davidChar);
	
			end)
	
		elseif checkpointFlags:Test("david_revealCooperHas", saveFlag) == true then
			dialog:SetInitiate("Okay, that may be true.. But David over here gambled it away fair and square.", "Smirk");
	
			dialog:AddDialog({
				Face="Confident";
				Say="But it's meant for Joseph..";
				Reply="Not my problem.";
				
			}, function(dialog)
				dialog:AddDialog({
					Face="Confident";
					Say="Is there any way I could get them back?";
					Reply="Hmmm.. Do you know how to play the card game Fall of the Living?";
				}, function(dialog)
	
					dialog:AddDialog({
						Face="Confident";
						Say="No, I don't know how to play.";
						Reply="Okay, David will teach you.";
					}, function(dialog)
						
						dialog:AddDialog({
							Face="Confident";
							Say="...";
							Reply="...";
						}, function(dialog)
							
							modMission:Progress(player, MISSION_ID, function()
								if mission.ProgressionPoint <= 1 then
									mission.ProgressionPoint = 2;
								end
							end)
	
							dialog:TalkTo(davidChar);
	
						end)
	
					end)
	
					dialog:AddDialog({
						Face="Confident";
						Say="Yes, I know how to play.";
						Reply="Alright, ";
					}, function(dialog)
						
						modMission:Progress(player, MISSION_ID, function()
							if mission.ProgressionPoint <= 1 then
								mission.ProgressionPoint = 3;
							end
						end)
	
						dialog:TalkTo(dialog.Character);
	
					end)
	
				end)
				
	
			end)
	
		else
			dialog:SetInitiate("Boom, not bluffing! Game over buddy..\n*Turns to you* Oh, how may I help you?", "Joyful");
	
			dialog:AddDialog({
				Face="Confident";
				Say="Ummm, I'm sent by Joseph, here for a box of walkie talkies?";
				Reply="...";
				
			}, function(dialog)
				mission.SaveData.Flags = checkpointFlags:Set(saveFlag, "cooper_askWalkie", true);
	
				dialog:TalkTo(davidChar);
	
			end)
	
		end
	
	elseif mission.ProgressionPoint == 2 then
		dialog:SetInitiate("Learnt to play Fall of the Living yet?", "Skeptical");

	elseif mission.ProgressionPoint == 3 then
		dialog:SetInitiate("I'll give you some time to practice your skill against David first.", "Smirk");

	elseif mission.ProgressionPoint == 4 then
		
		local function StartCardGame(dialog)
			local npcName = dialog.Name;
			local npcChar = dialog.Character;
			
			local cardGameLobby = modCardGame.NewLobby(npcChar);
			local npcTable = cardGameLobby:GetPlayer(npcChar);

			local npcClass: NpcClass = dialog:GetNpcClass();


			local npcQuips = {
				CaughtNotBluffing = {
					"Too bad";
					"Haha! Gotcha";
				};
				CaughtBluffing = {
					"";
				};
				CardLoss = {
					"Hmmm";
					"It is what it is..";
				};
				FailAccuse = {
					"";
				};
				CallBluff = {
					"You think you can bluff me?";
					"Nice bluff, try that again";
					"Not slipping that bluff by me";
				};
				PlayerDefeated = {
					"You need to play better than that, $PlayerName";
					"What was thaat? $PlayerName";
				};
			};

			local function cardGameQuips(quipType, param)
				param = param or {};

				local quipsList = npcQuips[quipType];
				if quipsList == nil then return end;

				local pickQuip = quipsList[math.random(1, #quipsList)];
				pickQuip = string.gsub(pickQuip, "$PlayerName", (param.PlayerName or "pal"));

				npcClass.Chat(game.Players:GetPlayers(), pickQuip);
			end

			-- MARK: Cooper Fotl Agent
			npcTable.ComputerAutoPlay = modCardGame.NewComputerAgentFunc(npcChar, cardGameLobby, {
				BluffChance=0.5;
				CheatChance=1;
				Actions = {
					Scavenge = {Genuine=0.3;};
					RogueAttack = {CallBluff=1; Genuine=0.5; Bluff=0.5;};
					BanditRaid = {CallBluff=1; Genuine=0.7; Bluff=0.8;};
					RatSmuggle = {CallBluff=1; Genuine=0.5; Bluff=0.5;};
					BioXSwap = {CallBluff=1; Genuine=0.5; Bluff=0.5;};
					ZombieBlock = {CallBluff=1; Bluff=0.5;};
				};
				OnCaughtNotBluffing=function()
					cardGameQuips("CaughtNotBluffing");
				end;
				OnCaughtBluffing=function()
					--cardGameQuips("CaughtBluffing");
				end;
				OnCardLoss=function()
					cardGameQuips("CardLoss");
				end;
				OnCallBluff=function()
					cardGameQuips("CallBluff");
				end;
				OnFailAccuse=function()
					cardGameQuips("FailAccuse");
				end;
				OnPlayerDefeated=function(defeatedPlayer)
					Debugger:Warn("defeatedPlayer", defeatedPlayer);
					cardGameQuips("CardLoss", {
						PlayerName=defeatedPlayer and defeatedPlayer.Name;
					});
				end;
			});


			cardGameLobby:Join(player, true);
			cardGameLobby:Start();

			dialog:SetExpireTime(workspace:GetServerTimeNow()+2);
		end

		if mission.SaveData.CooperRematch == 1 then
			dialog:SetInitiate("It's okay, I'll give you another try. Rematch?", "Smirk");

			dialog:AddDialog({
				Face="Smirk";
				Say="Rematch";
				Reply="*Hands you two cards*";
				
			}, StartCardGame);

		else
			dialog:SetInitiate("Alright, now that you're ready..\nHere's the deal, you beat me in Fall of the Living, and I'll give you the box of walkies.", "Smirk");

			dialog:AddDialog({
				Face="Smirk";
				Say="Okay.. And if you beat me?";
				Reply="Don't worry, I don't want much. Let's play.";
				
			}, function(dialog)
				dialog:AddDialog({
					Face="Smirk";
					Say="Okay..";
					Reply="*Hands you two cards*";
					
				}, StartCardGame);
			end);
	
		end


	elseif mission.ProgressionPoint == 5 or mission.ProgressionPoint == 6 then
		dialog:SetInitiate("Welp.. I did say I don't ask for much, how about you dance for me too and I'll give you your box of walkies.", "Smirk");

		if mission.ProgressionPoint == 5 then
			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint <= 5 then
					mission.ProgressionPoint = 6;
				end
			end)
		end
		
		dialog:AddDialog({
			Face="Question";
			Say="Okay, fine. I'll dance, just give me the walkies..";
			Reply="Show me what you got first hahah!";
		});
		
		dialog:AddDialog({
			Face="Question";
			Say="No way, I'm not dancing, just give me the walkies..";
			Reply="That's not what I want to hear! You're not getting your walkies.";
			
		}, function(dialog)
			dialog:AddDialog({
				Face="Frustrated";
				Say="Are you serious!";
				Reply="...";
			}, function(dialog)
			
				modMission:Progress(player, MISSION_ID, function()
					if mission.ProgressionPoint <= 7 then
						mission.ProgressionPoint = 8;
					end
				end)

				dialog:TalkTo(dialog.Character);

			end);
		end);

	elseif mission.ProgressionPoint == 7 then
		dialog:SetInitiate("I can't believe you actually danced for me..", "Hehe");

		dialog:AddDialog({
			Face="Question";
			Say="Well? Where's my walkies?!";
			Reply="Woah the attitude, you're not getting walklies..";
			
		}, function(dialog)
			dialog:AddDialog({
				Face="Frustrated";
				Say="Are you serious!";
				Reply="...";
			}, function(dialog)
			
				modMission:Progress(player, MISSION_ID, function()
					if mission.ProgressionPoint <= 7 then
						mission.ProgressionPoint = 8;
					end
				end)

				dialog:TalkTo(dialog.Character);

			end);
		end);

	elseif mission.ProgressionPoint == 8 then
		dialog:SetInitiate("Yeah, now get lost!", "Hehe");
		
		modMission:Progress(player, MISSION_ID, function()
			if mission.ProgressionPoint <= 8 then
				mission.ProgressionPoint = 9;
			end
		end)
		
	end

	dialog:SkipOtherDialogues();
end


-- MARK: Caitlin Handler
Dialogues.Caitlin.DialogueHandler = function(player, dialog, data, mission)
	if mission.ProgressionPoint == 1 then
		dialog:SetInitiate("On look out duty again.. So boring.", "Bored");

		dialog:AddDialog({
			Face="Suspicious";
			Say="Hey, who do I talk to about undelivered goods?";
			Reply="Hmm, not my department. Talk to the guys upstairs..";
		})
	end
end


-- MARK: Greg Handler
Dialogues.Greg.DialogueHandler = function(player, dialog, data, mission)
	if mission.ProgressionPoint == 1 then
		dialog:SetInitiate("What do you want?!", "Angry");

		dialog:AddDialog({
			Face="Angry";
			Say="Hey, Joseph has been waiting for his box of walkie talkies delivered.";
			Reply="What do I look like, the delivery boy? Get lost!";
		})
	end
end


-- MARK: Lewis Handler
Dialogues.Lewis.DialogueHandler = function(player, dialog, data, mission)
	if mission.ProgressionPoint == 1 then
		dialog:SetInitiate("Hmm?", "Skeptical");

		dialog:AddDialog({
			Face="Suspicious";
			Say="Hey, Do you know anything about a box of walkie talkies that should had been delivered.";
			Reply="Hmm, I think one of the guys had it on the table for a bet. Guess who won, hah!";
		})
	end
end

return Dialogues;