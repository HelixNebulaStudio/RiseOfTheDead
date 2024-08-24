local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local modDialogueService = require(game.ReplicatedStorage.Library.DialogueService);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modBitFlags = require(game.ReplicatedStorage.Library.BitFlags);
local modCardGame = require(game.ReplicatedStorage.Library.CardGame);

--=
local Dialogues = {
	Joseph={};

	David={};
	Caitlin={};
	Greg={};
	Cooper={};
	Lewis={};
};

local missionId = 81;


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
		CheckMission=missionId;
		Face="Skeptical"; 
		Say="Hey Joseph, what was that about something should be here now?";
		Reply="Yeah, these Rats.. I made a deal with them for some walkie talkies a while ago..";
		FailResponses = {
			{Reply="We'll wait a while and see when it will be delivered."};
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
	local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

	if mission.Type == 2 then -- Available
		dialog:SetInitiateTag("fotl_init");

		dialog:AddChoice("fotl_prologue1", function(dialog)
			dialog:AddChoice("fotl_prologue2", function(dialog)
				dialog:AddChoice("fotl_prologue3", function(dialog)
					dialog:AddChoice("fotl_prologue4", function(dialog)
						modMission:StartMission(player, missionId);
					end)
				end)
			end)
		end)

	elseif mission.Type == 1 then -- Active

		if mission.ProgressionPoint <= 3 then
			dialog:SetInitiate("I swear if we were scammed by those Rats..", "Suspicious");

		end

	end
end


-- MARK: David Handler
Dialogues.David.DialogueHandler = function(player, dialog, data, mission)
	local cooperPrefab = workspace.Entity:FindFirstChild("Cooper");

	local saveFlag = mission.SaveData.Flags;

	if mission.Type ~= 1 then return end;

	local activeCardGameLobby = modCardGame.GetLobby(player);
	
	if activeCardGameLobby then
		if activeCardGameLobby.Host == dialog.Prefab then
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
				
				dialog:TalkTo(cooperPrefab);
	
			end);
	
		elseif checkpointFlags:Test("david_askWalkieTalkie", saveFlag) == false then
			dialog:SetInitiate("...cheater! How did you win again!..\n*Turns to you* Uggh, what do you want?", "Frustrated");
	
			dialog:AddDialog({
				Face="Skeptical";
				Say="Ummm, I'm sent by Joseph, here for a box of walkie talkies?";
				Reply="...";
				
			}, function(dialog)
				mission.SaveData.Flags = checkpointFlags:Set(saveFlag, "david_askWalkieTalkie", true);
	
				dialog:TalkTo(cooperPrefab);
	
			end);
	
		elseif checkpointFlags:Test("cooper_betAway", saveFlag) == true then
			dialog:SetInitiate("Uhh.. Yeah.. I made some bad bets.", "Suspicious");

			dialog:AddDialog({
				Face="Skeptical";
				Say="I need those walkie talkies for Joseph..";
				Reply="Look, I was about to win them back.";
				
			}, function(dialog)
				mission.SaveData.Flags = checkpointFlags:Set(saveFlag, "david_winBack", true);
				dialog:TalkTo(cooperPrefab);

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
								modMission:Progress(player, missionId, function()
									if mission.ProgressionPoint <= 2 then
										mission.ProgressionPoint = 3;
									end
								end)
		
								dialog:TalkTo(dialog.Prefab);
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
	end
	
	local function StartCardGame(dialog)
		local npcName = dialog.Name;
		local npcPrefab = dialog.Prefab;
		
		local cardGameLobby = modCardGame.NewLobby(npcPrefab);
		local npcTable = cardGameLobby:GetPlayer(npcPrefab);

		local npcModule = dialog:GetNpcModule();

		npcTable.ComputerAutoPlay = modCardGame.NewComputerAgentFunc(npcPrefab, cardGameLobby, {
			OnCaughtNotBluffing=function()
				local chats = {
					"Bad guess";
					"Thought I was bluffing ey?";
					"Nice try pal";
					"Sike! It's genuine!";
				};
				npcModule.Chat(game.Players:GetPlayers(), chats[math.random(1, #chats)]);
			end;
			OnCaughtBluffing=function()
				local chats = {
					"Ain't no way";
					"Lucky guess";
					"You got me";
					"What gave it away?";
				};
				npcModule.Chat(game.Players:GetPlayers(), chats[math.random(1, #chats)]);
			end;
			OnCardLoss=function()
				local chats = {
					"Yikes, down a card";
					"Uoh noo";
					"How could you";
				};
				npcModule.Chat(game.Players:GetPlayers(), chats[math.random(1, #chats)]);
			end;
			OnPlayerDefeated=function(defeatedPlayer)
				local chats = {
					"Better luck next time "..defeatedPlayer.Name;
					"Good try, you just need a bit more practice "..defeatedPlayer.Name;
				};
				npcModule.Chat(game.Players:GetPlayers(), chats[math.random(1, #chats)]);
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
	local davidPrefab = workspace.Entity:FindFirstChild("David");
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
						
						modMission:Progress(player, missionId, function()
							if mission.ProgressionPoint <= 1 then
								mission.ProgressionPoint = 2;
							end
						end)

						dialog:TalkTo(davidPrefab);

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
						
						modMission:Progress(player, missionId, function()
							if mission.ProgressionPoint <= 1 then
								mission.ProgressionPoint = 3;
							end
						end)

						dialog:TalkTo(davidPrefab);

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
				
				dialog:TalkTo(davidPrefab);
	
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
							
							modMission:Progress(player, missionId, function()
								if mission.ProgressionPoint <= 1 then
									mission.ProgressionPoint = 2;
								end
							end)
	
							dialog:TalkTo(davidPrefab);
	
						end)
	
					end)
	
					dialog:AddDialog({
						Face="Confident";
						Say="Yes, I know how to play.";
						Reply="Alright, ";
					}, function(dialog)
						
						modMission:Progress(player, missionId, function()
							if mission.ProgressionPoint <= 1 then
								mission.ProgressionPoint = 3;
							end
						end)
	
						dialog:TalkTo(dialog.Prefab);
	
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
	
				dialog:TalkTo(davidPrefab);
	
			end)
	
		end
	
	elseif mission.ProgressionPoint == 2 then
		dialog:SetInitiate("Learnt to play Fall of the Living yet?", "Skeptical");

	elseif mission.ProgressionPoint == 3 then
		dialog:SetInitiate("I'll give you some time to practice your skill against David first.", "Smirk");

	elseif mission.ProgressionPoint == 4 then
		dialog:SetInitiate("Alright, now that you're ready..", "Smirk");
		
		local function StartCardGame(dialog)
			local npcName = dialog.Name;
			local npcPrefab = dialog.Prefab;
			
			local cardGameLobby = modCardGame.NewLobby(npcPrefab);
			local npcTable = cardGameLobby:GetPlayer(npcPrefab);

			local npcModule = dialog:GetNpcModule();

			npcTable.ComputerAutoPlay = modCardGame.NewComputerAgentFunc(npcPrefab, cardGameLobby, {
				OnCaughtNotBluffing=function()
					local chats = {
						"Bad guess";
						"Thought I was bluffing ey?";
						"Nice try pal";
						"Sike! It's genuine!";
					};
					npcModule.Chat(game.Players:GetPlayers(), chats[math.random(1, #chats)]);
				end;
				OnCaughtBluffing=function()
					local chats = {
						"Ain't no way";
						"Lucky guess";
						"You got me";
						"What gave it away?";
					};
					npcModule.Chat(game.Players:GetPlayers(), chats[math.random(1, #chats)]);
				end;
				OnCardLoss=function()
					local chats = {
						"Yikes, down a card";
						"Uoh noo";
						"How could you";
					};
					npcModule.Chat(game.Players:GetPlayers(), chats[math.random(1, #chats)]);
				end;
				OnPlayerDefeated=function(defeatedPlayer)
					local chats = {
						"Better luck next time "..defeatedPlayer.Name;
						"Good try, you just need a bit more practice "..defeatedPlayer.Name;
					};
					npcModule.Chat(game.Players:GetPlayers(), chats[math.random(1, #chats)]);
				end;
			});

			cardGameLobby:Join(player, true);
			cardGameLobby:Start();

			dialog:SetExpireTime(workspace:GetServerTimeNow()+2);
		end

		dialog:AddDialog({
			Face="Confident";
			Say="I'm ready, let's play";
			Reply="Alright. *Hands you two cards*";
			
		}, StartCardGame);

	end

	dialog:SkipOtherDialogues();
end

return Dialogues;