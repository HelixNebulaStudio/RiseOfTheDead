local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Mason={};
	Nick={};
};

local missionId = 2;
--==

-- !outline: Mason Dialogues
Dialogues.Mason.Dialogues = function()
	return {
		{Tag="whereAmI_deniski"; Dialogue="Not so well, where are we?"; Face="Happy";
			Reply="You're in the warehouse. You're safe here, that's why we also call it the safehouse, haaha.. You should talk to the doctor to get you fixed up."};
		{Tag="whereAmI_canHeal"; Dialogue="Where is he?"; Face="Skeptical";
			Reply="Dr. Deniski should be here somewhere, follow me, he'll gladly help you out."};
		
		{Tag="whereAmI_found"; Dialogue="Much better now, thanks for saving me back there."; Face="Surprise";
			Reply="You're welcome, I was scavenging when I found you unconscious. It's really a miracle being out there unconscious for days."};
		{Tag="whereAmI_apocalypse"; Dialogue="Are we stuck here?"; Face="Disgusted";
			Reply="Probably... we have no clue where to go and how wide spread is the apocalypse..."};
		{Tag="whereAmI_talkToNick"; Dialogue="What can I do to help?"; Face="Happy";
			Reply="Talk to Nick, he might need some help."};
		
	};
end

Dialogues.Nick.Dialogues = function()
	return {
		{Tag="whereAmI_hmm";
			Face="Suspicious"; Reply="Hmmm?";};

		{Tag="whereAmI_hello";
			Face="Surprise"; Reply="Hello, I see you're new here, what's your name?";};
		
		{Tag="whereAmI_welcome"; Dialogue="Oh, ummm, I think my name is.. $PlayerName. I can't remember much after waking from that car crash on the bridge."; 
			Reply="Oh, I'm sorry to hear that, $PlayerName. We haven't found any new survivors lately and I'm glad to see a new face."};
		{Tag="whereAmI_neededHelp"; Dialogue="Thanks, Mason said you needed help?"; 
			Reply="Oh yes, but first you might want to refill your gun."};
		{Tag="whereAmI_howToRefill"; Dialogue="Oh, not yet, where do I refill my gun?"; 
			Reply="The store behind me, click on Inventory and select your weapon and purchase ammo."};
		{Tag="whereAmI_firstTask"; Dialogue="Yes, I refilled the gun."; 
			Reply="Alrighty, there are a couple of zombies outside the warehouse, perhaps you can take care of it?"};

		{Tag="whereAmI_refill";
			Face="Happy"; Reply="Have you refilled your weapon yet?";};
		
		
		{Tag="whereAmI_acceptTask"; Dialogue="Sure, I'll get right to it."; 
			Face="Confident"; Reply="Talk to you later then."};
		{Tag="whereAmI_why"; Dialogue="Hmmm, why should I help you?"; 
			Reply="Well, the zombies are starting to break down our gates and we need to protect this place in order to survive."};
		{Tag="whereAmI_denyTask"; Dialogue="No, I don't want to."; 
			Reply="Ummm, alrighty, I understand."};

		{Tag="whereAmI_reacceptTask"; Dialogue="Yes, sorry, I want to help out now."; 
			Reply="Alrighty then, come back once you're done."};
		{Tag="whereAmI_redenyTask"; Dialogue="No, I'm still not going to help you."; 
			Reply="Well, it's okay, someone else will help out with the zombies."};
		{Tag="whereAmI_taskComplete"; Dialogue="There were too many, but I killed enough to prevent more damage on the gates."; 
			Face="Confident"; Reply="Hmmm, I guess that will do for now, thanks.\n\nTalk to Mason, he can teach you how to upgrade your weapons."};
	};
end

if RunService:IsServer() then
	local modAnalyticsService = require(game.ServerScriptService.ServerLibrary.AnalyticsService);

	-- !outline: Mason Handler
	Dialogues.Mason.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available;
			
		elseif mission.Type == 1 then -- Active
			local checkpoint = mission.ProgressionPoint;
			if checkpoint <= 2 then
				dialog:InitDialog{
					Text="Oh hey, you're finally awake. I'm Mason, how are you feeling?";
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
					Player=player;
					OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission2_TalkToMason;
				};
				
			elseif checkpoint == 3 or checkpoint == 4 then
				dialog:InitDialog{
					Text="How do you feel now?";
					Face="Happy";
				}
				
				if checkpoint == 4 then
					dialog:InitDialog{
						Text="How do you feel now?";
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
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

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
						Text="Oh, have you changed your mind?";
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
							Player=player;
							OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission2_Complete;
						};
					end)
					
				end
				
			elseif checkpoint >= 8 and checkpoint <= 10 then
				dialog:InitDialog{
					Text="Have you killed the zombies outside the warehouse yet?";
					Face="Surprise";
				}
				
				if checkpoint == 10 then
					dialog:AddChoice("whereAmI_taskComplete", function(dialog)
						modMission:CompleteMission(player, missionId);
						modAnalyticsService:LogOnBoarding{
							Player=player;
							OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission2_Complete;
						};
					end)
				end
				
			end

		elseif mission.Type == 4 then -- Failed

		end
	end
end


return Dialogues;