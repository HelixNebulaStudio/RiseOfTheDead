local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Patrick={};
	Bandit={};
	Loran={};
	Zark={};
};

local missionId = 63;
--==

-- MARK: Patrick Dialogues
Dialogues.Patrick.DialogueStrings = {
	["theRecruit_settleB"]={
		Face="Confident"; 
		Say="How are you settling in?";
		Reply="It's great, the place is really cozy.";
	};
	["theRecruit_settle2B"]={
		Face="Confident"; 
		Say="Hear anything about the Bandits or the Rats?";
		Reply="Yes actually, I heard the Bandits are recruiting, and they are looking specifically for you because they somehow found out you helped them.";
	};
	["theRecruit_zark1"]={
		Face="Surprise"; 
		Say="Should I talk to Zark?";
		Reply="That would be quite risky, but if you want to take the Bandits down, you might have to take them down from within.";
	};
};

-- MARK: Bandit Dialogues
Dialogues.Bandit.DialogueStrings = {
	["banditRecruit_banditCampGate"]={
		Face="Serious"; 
		Reply="Halt right here! What do you want?";
	};
	
	["banditRecruit_recruit1"]={
		Face="Serious";
		Say="I heard you guys are recruiting?";
		Reply="Yes, and if you dare to join, you are going to have to prove your loyalty..";
	};
	["banditRecruit_recruit2"]={
		Face="Skeptical";
		Say="How do I prove my loyalty?";
		Reply="If you're sure about proving your loyalty, I will take you to our recruitment leader..";
	};
	["banditRecruit_recruit3"]={
		Face="Serious";
		Say="I want to prove my loyalty.";
		Reply="Alright, follow me..";
	};
};

-- MARK: Loran Dialogues
Dialogues.Loran.DialogueStrings = {
	["theRecruit_init"]={
		Face="Frustrated"; 
		Reply="I'm going to start counting again..";
	};

	["theRecruit_wait"]={
		Face="Frustrated";
		Say="Wait wait wait wait";
		Reply="...\n\n<b>Stranger:</b> Stop!";
	};

	["theRecruit_help"]={
		Face="Skeptical";
		Say="Umm, sorry. I forgot what I'm suppose to look for.";
		Reply="You're dumber than you look. Zark said 2 Nekron Particulate Caches!";
	};
	["theRecruit_nekronParticulateCache"]={
		Face="Skeptical";
		Say="Here's the 2 Nekron Particulate Caches.";
		Reply="Good...\n\nWhy are you still here?";
	};
};

-- MARK: Zark Dialogues
Dialogues.Zark.DialogueStrings = {
	["theRecruit_zarkInit"]={
		Face="Confident"; 
		Reply="Well well well, look who it is..";
	};

	["theRecruit_recruit1"]={
		Face="Confident";
		Say="I heard you were recruiting and you are looking for me..";
		Reply="Bold of you to come directly to me, hahah. You are quite a warrior, and it would be great to have someone like you among our ranks.";
	};
	["theRecruit_recruit2"]={
		Face="Confident";
		Say="I only came to talk, what makes you think I want to join you?";
		Reply="It's kill or to be killed, allow me to convince you to join us..";
	};

	["theRecruit_zarkInit2"]={
		Face="Confident"; 
		Reply="Anyways, I will need somethings from you.. Remember your friend Stan?";
	};
	["theRecruit_recruit3"]={
		Face="Skeptical";
		Say="Yeah, you shot him dead and now he's in your rejuvenation chamber which you wanted to trade to the Rats..";
		Reply="Yes, I had a hunch he was an infector, but he wasn't the one which took out one of our squads.";
	};
	["theRecruit_recruit4"]={
		Face="Confident";
		Say="So what are you doing with Stan?";
		Reply="Stan has some levels of immunity to the parasite.. You are going to help me if you want to save him.";
	};
	["theRecruit_recruit5"]={
		Face="Confident";
		Say="What do you need?";
		Reply="Get these items, and bring it back to the mall. Loran will be there to collect.";
	};
};


if RunService:IsServer() then
	local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
	local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

	
	-- MARK: Patrick Handler
	Dialogues.Patrick.DialogueHandler = function(player, dialog, data, mission)
		if mission.Type == 2 then -- Available
			if mission.ProgressionPoint == 1 then
				dialog:InitDialog({
					Face="Confident"; 
					Reply="Welcome back.";
				});
				
				dialog:AddChoice("theRecruit_settleB", function(dialog)
					dialog:AddChoice("theRecruit_settle2B", function(dialog)
						dialog:AddChoice("theRecruit_zark1", function(dialog)
							modMission:StartMission(player, missionId);
						end)
					end)
				end);
			end
		end
	end
	

	-- MARK: Bandit Handler
	Dialogues.Bandit.DialogueHandler = function(player, dialog, data, mission)
		local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);

		if mission.Type == 2 then -- Available
			if mission.ProgressionPoint == 1 then
			end

		elseif mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 1 then
				dialog:SetInitiateTag("banditRecruit_banditCampGate");
				dialog:AddChoice("banditRecruit_recruit1", function(dialog)
					dialog:AddChoice("banditRecruit_recruit2", function(dialog)
						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint <= 2 then
								mission.ProgressionPoint = 2;
							end
						end)
					end)
				end)
				
			elseif mission.ProgressionPoint == 2 then
				dialog:SetInitiate("Well?");
				dialog:AddChoice("banditRecruit_recruit3", function(dialog)
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint <= 3 then
							mission.ProgressionPoint = 3;
						end
					end)

					modServerManager:TeleportToPrivateServer("BanditsRecruitment", modServerManager:CreatePrivateServer("BanditsRecruitment"), {player});
				end)
				
			end
			
		end
	end
	

	-- MARK: Loran Handler
	Dialogues.Loran.DialogueHandler = function(player, dialog, data, mission)
		local stage = mission.ProgressionPoint;
	
		if modBranchConfigs.IsWorld("BanditsRecruitment") then
			if mission.Type == 1 then -- Active
				if stage == 5 then
					
					dialog:SetInitiateTag("theRecruit_init");
					dialog:AddChoice("theRecruit_wait", function(dialog)
						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint < 6 then
								mission.ProgressionPoint = 6;
							end;
						end)
					end);
	
				end
			end
			
		elseif modBranchConfigs.IsWorld("TheMall") then
			if mission.Type == 1 then -- Active
				if stage == 12 then
					dialog:SetInitiate("What took you so long?");
	
					local profile = shared.modProfile:Get(player);
					local playerSave = profile:GetActiveSave();
					local inventory = playerSave.Inventory;
					local total, itemList = inventory:ListQuantity("nekronparticulatecache", 2);
	
					if total >= 2 then
						dialog:AddChoice("theRecruit_nekronParticulateCache", function(dialog)
							for a=1, #itemList do
								inventory:Remove(itemList[a].ID, itemList[a].Quantity);
								shared.Notify(player, "2 Nekron Particulate Cache removed from your Inventory.", "Negative");
							end
	
							modMission:CompleteMission(player, missionId);
							
							shared.Notify(player, "You have unlockabled Bandit's Market. Talk to Loran to check it out.", "Positive");
						end)
	
					else
						dialog:AddChoice("theRecruit_help");
	
					end
				end
			end
		end
	end
	

	-- MARK: Zark Handler
	if modBranchConfigs.IsWorld("BanditsRecruitment") then
		Dialogues.Zark.DialogueHandler = function(player, dialog, data, mission)
			local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);

			if mission.Type == 1 then -- Active
				local stage = mission.ProgressionPoint;
				if stage == 9 then
					dialog:SetInitiateTag("theRecruit_zarkInit");
					dialog:AddChoice("theRecruit_recruit1", function(dialog)
						dialog:AddChoice("theRecruit_recruit2", function(dialog)
							modMission:Progress(player, 63, function(mission)
								if mission.ProgressionPoint <= 10 then
									mission.ProgressionPoint = 10;
								end
							end)
						end)
					end)
					
				elseif stage == 11 then
					dialog:SetInitiateTag("theRecruit_zarkInit2");
					dialog:AddChoice("theRecruit_recruit3", function(dialog)
						dialog:AddChoice("theRecruit_recruit4", function(dialog)
							dialog:AddChoice("theRecruit_recruit5", function(dialog)
								modMission:Progress(player, 63, function(mission)
									if mission.ProgressionPoint <= 12 then
										mission.ProgressionPoint = 12;
									end
								end)
								
								task.wait(5);
								modServerManager:Travel(player, "TheMall");

								local zarkModule = dialog:GetNpcModule();
								if zarkModule then
									zarkModule.Chat(player, "Bring it to Loran in the Bandit Camp once you obtained them.");
								end
								
							end)
						end)
					end)
					
				end
			end
		end
	end


end


return Dialogues;