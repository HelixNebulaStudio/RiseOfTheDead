local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Mason={};
	Nick={};
	["Dr. Deniski"]={};
};

local missionId = 2;
--==

-- !outline: Mason Dialogues
Dialogues.Mason.DialogueStrings = {
	["whereAmI_deniski"]={
		Face="Happy";
		Say="Not so well, where are we?";
		Reply="You're in the warehouse. You're safe here, that's why we also call it the safehouse, haaha.. You should talk to the doctor to get you fixed up.";
	};
	["whereAmI_canHeal"]={
		Face="Skeptical";
		Say="Where is he?";
		Reply="Dr. Deniski should be here somewhere, follow me, he'll gladly help you out.";
	};
	
	["whereAmI_found"]={
		Face="Surprise";
		Say="Much better now, thanks for saving me back there.";
		Reply="You're welcome, I was scavenging when I found you unconscious. It's really a miracle being out there unconscious for days.";
	};
	["whereAmI_apocalypse"]={
		Face="Disgusted";
		Say="Are we stuck here?"; 
		Reply="Probably... we have no clue where to go and how wide spread is the apocalypse...";
	};
	["whereAmI_talkToNick"]={
		Face="Happy";
		Say="What can I do to help?"; 
		Reply="Talk to Nick, he might need some help.";
	};
	
};

Dialogues.Nick.DialogueStrings = {
	["whereAmI_hmm"]={
		Face="Suspicious"; 
		Reply="Hmmm?";
	};

	["whereAmI_hello"]={
		Face="Surprise"; 
		Reply="Hello, I see you're new here, what's your name?";
	};
	
	["whereAmI_welcome"]={
		Say="Oh, ummm, I think my name is.. $PlayerName. I can't remember much after waking from that car crash on the bridge."; 
		Reply="Oh, I'm sorry to hear that, $PlayerName. We haven't found any new survivors lately and I'm glad to see a new face.";
	};
	["whereAmI_neededHelp"]={
		Say="Thanks, Mason said you needed help?"; 
		Reply="Oh yes, but first you might want to refill your gun.";
	};
	["whereAmI_howToRefill"]={
		Say="Oh, not yet, where do I refill my gun?"; 
		Reply="The store behind me, click on Inventory and select your weapon and purchase ammo.";
	};
	["whereAmI_firstTask"]={
		Say="Yes, I refilled the gun."; 
		Reply="Alrighty, there are a couple of zombies outside the warehouse, perhaps you can take care of it?";
	};

	["whereAmI_refill"]={
		Face="Happy"; 
		Reply="Have you refilled your weapon yet?";
	};
	
	
	["whereAmI_acceptTask"]={
		Face="Confident"; 
		Say="Sure, I'll get right to it."; 
		Reply="Talk to you later then.";
	};
	["whereAmI_why"]={
		Say="Hmmm, why should I help you?"; 
		Reply="Well, the zombies are starting to break down our gates and we need to protect this place in order to survive.";
	};
	["whereAmI_denyTask"]={
		Say="No, I don't want to."; 
		Reply="Ummm, alrighty, I understand.";
	};

	["whereAmI_reacceptTask"]={
		Say="Yes, sorry, I want to help out now."; 
		Reply="Alrighty then, come back once you're done.";
	};
	["whereAmI_redenyTask"]={
		Say="No, I'm still not going to help you."; 
		Reply="Well, it's okay, someone else will help out with the zombies.";
	};
	["whereAmI_taskComplete"]={
		Face="Confident"; 
		Say="There were too many, but I killed enough to prevent more damage on the gates."; 
		Reply="Hmmm, I guess that will do for now, thanks.\n\nTalk to Mason, he can teach you how to upgrade your weapons.";
	};
};

if RunService:IsServer() then
	local modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);

	-- !outline: Mason Handler
	Dialogues.Mason.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available;
			
		elseif mission.Type == 1 then -- Active
			local checkpoint = mission.ProgressionPoint;
			if checkpoint <= 2 then
				dialog:InitDialog{
					Reply="Oh hey, you're finally awake. I'm Mason, how are you feeling?";
					Face="Happy";
				}
				
				dialog:AddChoice("whereAmI_deniski", function(dialog)
					dialog:AddChoice("whereAmI_canHeal", function(dialog)
						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint < 2 then
								mission.ProgressionPoint = 2
							end;
						end)
					end)
				end)
				
				modAnalyticsService:LogOnBoarding{
					Player = player;
					OnBoardingStep = modAnalyticsService.OnBoardingSteps.Mission2_TalkToMason;
				};
				
			elseif checkpoint == 3 or checkpoint == 4 then
				dialog:InitDialog{
					Reply="How do you feel now?";
					Face="Happy";
				}
				
				if checkpoint == 4 then
					dialog:InitDialog{
						Reply="How do you feel now?";
						Face="Happy";
					}
					dialog:AddChoice("whereAmI_found", function(dialog)
						dialog:AddChoice("whereAmI_apocalypse", function(dialog)
							dialog:AddChoice("whereAmI_talkToNick", function(dialog)
								modMission:Progress(player, missionId, function(mission)
									if mission.ProgressionPoint < 5 then
										mission.ProgressionPoint = 5;
									end;
								end)
							end)
						end)
					end)
				end
			end
			
		elseif mission.Type == 4 then -- Failed
			
		end
	end
	
	-- MARK: Nick Handler
	Dialogues.Nick.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available;

		elseif mission.Type == 1 then -- Active
			local checkpoint = mission.ProgressionPoint;
			if checkpoint < 5 then
				dialog:SetInitiateTag("whereAmI_hmm");
				
			elseif checkpoint == 5 then
				dialog:SetInitiateTag("whereAmI_hello");
				dialog:AddChoice("whereAmI_welcome", function(dialog)
					dialog:AddChoice("whereAmI_neededHelp", function()
						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint < 6 then
								mission.SaveData.Kills = 10;
								mission.ProgressionPoint = 6
							end;
						end)
					end)
				end);

			elseif checkpoint == 6 or checkpoint == 7 then
				if modMission:GetData(player, missionId, "accept") == nil then
					dialog:SetInitiateTag("whereAmI_refill");
					
					if checkpoint == 7 then
						local function taskOffer(dialog)
							dialog:AddChoice("whereAmI_acceptTask", function(dialog)
								modMission:SetData(player, missionId, "accept", 1);
								modMission:Progress(player, missionId, function(mission)
									if mission.ProgressionPoint < 8 then
										mission.ProgressionPoint = 8
									end;
								end)
							end)
							dialog:AddChoice("whereAmI_denyTask", function(dialog)
								modMission:SetData(player, missionId, "accept", 0);
							end)
							dialog:AddChoice("whereAmI_why", taskOffer);
						end
						dialog:AddChoice("whereAmI_firstTask", taskOffer);
						
					else
						dialog:AddChoice("whereAmI_howToRefill");
						
					end
					
				else
					dialog:InitDialog{
						Reply="Oh, have you changed your mind?";
						Face="Surprise";
					}
					
					dialog:AddChoice("whereAmI_reacceptTask", function(dialog)
						modMission:SetData(player, missionId, "accept", 1);
						
						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint < 8 then
								mission.ProgressionPoint = 8
							end;
						end)
					end)
					dialog:AddChoice("whereAmI_redenyTask", function(dialog)
						modMission:SetData(player, missionId, "accept", 0);
						
						modMission:CompleteMission(player, missionId);
						modAnalyticsService:LogOnBoarding{
							Player = player;
							OnBoardingStep = modAnalyticsService.OnBoardingSteps.Mission2_Complete;
						};
					end)
					
				end
				
			elseif checkpoint >= 8 and checkpoint <= 10 then
				dialog:InitDialog{
					Reply="Have you killed the zombies outside the warehouse yet?";
					Face="Surprise";
				}
				
				if checkpoint == 10 then
					dialog:AddChoice("whereAmI_taskComplete", function(dialog)
						modMission:CompleteMission(player, missionId);
						modAnalyticsService:LogOnBoarding{
							Player = player;
							OnBoardingStep = modAnalyticsService.OnBoardingSteps.Mission2_Complete;
						};
					end)
				end
				
			end

		elseif mission.Type == 4 then -- Failed

		end
	end

	-- MARK: Dr. Deniski Handler
	Dialogues["Dr. Deniski"].DialogueHandler = function(player, dialog, data, mission)
		if mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 3 then
				dialog:SetInitiate("Hey, you don't look so well.");
			end
		end
	end
end


return Dialogues;