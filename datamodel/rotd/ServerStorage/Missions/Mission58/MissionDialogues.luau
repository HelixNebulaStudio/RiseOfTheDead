local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Patrick={};
	Revas={};
	Caitlin={};
};

local missionId = 58;
--==

-- MARK: Patrick Dialogues
Dialogues.Patrick.DialogueStrings = {		
	["doubleCross_init"]={
		Face="Disbelief"; 
		Reply="Thank god you're here. I need your help, something big is happening..";
	};
	["doubleCross_1"]={
		Say="What's going on?";
		Face="Serious"; 
		Reply="Zark is planning a meet with the leader of R.A.T., Revas Remington, for an exchange and I am involved..";
	};
	["doubleCross_2"]={
		Face="Serious";
		Say="What!? Are they friends or something?";
		Reply="Definitely not, there's a power struggle between the Bandits and the Rats for months and now Zark wants to make a \"peace\" offering.";
	};
	["doubleCross_3"]={
		Face="Angry";
		Say="Sounds kinda sus..";
		Reply="Exactly, it's a trap and there's internal conflicts among the Bandits because Zark is about to trigger a war.";
	};
	["doubleCross_4"]={
		Face="Frustrated";
		Say="Oh god, a war between the Bandits and the Rats..";
		Reply="I got to defect, the Bandits are chaotic, disorganized and I can't leave on my own, they will hunt me down.";
	};
	["doubleCross_5"]={
		CheckMission=missionId;
		Face="Confident";
		Say="What can I do to help?";
		Reply="I need you to help me convince Revas to let me into their ranks by telling them about the trap.";
		FailResponses = {
			{Reply="Come back when you are prepared."};
		};	
	};

	["doubleCross_6"]={
		Face="Surprise"; 
		Reply="Did you manage to talk to Revas?";
	};
	["doubleCross_7"]={
		Face="Skeptical";
		Say="Yes, he said you need to prove yourself if you want to join the Rats. Here's the instructions...";
		Reply="*Takes envelope & reads letter* Hmmm.. Okay, I know what to do. We will have to meet at the Rat's cargo ship..";
	};
	["doubleCross_travelToCargoShip"]={
		Face="Confident";
		Say="Meet you at the Rat's cargo ship then..";
		Reply="I'll see you there soon..";
	};

	["doubleCross_17"]={
		Face="Frustrated"; 
		Reply="*groan* Bring me a medkit would ya?";
	};
	["doubleCross_giveMedkit"]={
		Face="Serious";
		Say="Here you go.. *give medkit*";
		Reply="Thanks.. Heh, guess getting into the Rats wasn't that easy.. Revas is more calculated than I thought.";
	};
	["doubleCross_18"]={
		Face="Skeptical";
		Say="Just another tyrant I guess.. You're better off here.";
		Reply="Yeah! You know what, we could band up people to form our own group instead! Let's talk more about it later, I need some rest..";
	};

	["banditmapGift"]={
		Face="Happy";
		Say="Hey, how's the wound?";
		Reply="It's getting better.. Oh and I want to give you this..";
	};
};


-- MARK: Revas Dialogues
Dialogues.Revas.DialogueStrings = {
	["doubleCross_1"]={
		Face="Smirk";
		Say="I have insider knowledge of what the Bandits are planning..";
		Reply="And who is this informant may I ask?";
	};
	["doubleCross_2"]={
		Face="Confident";
		Say="A bandit who wants to defect. He is willing to give up information if you let him into the Rats.";
		Reply="Interesting.. I already know the trap they are planning. If this person is true to their word, I just need one thing done.";
	};
	["doubleCross_3"]={
		Face="Smirk";
		Say="Oh.. What is it?";
		Reply="Give these the instructions to your friend, it will tell you what to do to join us..";
	};


	["doubleCross_4"]={
		Face="Confident"; 
		Reply="Soo, have you given Patrick the envelope?";
	};
	["doubleCross_5"]={
		Face="Smile";
		Say="Yes. I gave him the instructions... Wait, how did you know it was Patrick?";
		Reply="That's not important right now, I have one task for you..";
	};
	["doubleCross_6"]={
		Face="Smile";
		Say="What do I need to do?..";
		Reply="You are going to hide in this crate behind me. We want to welcome the bandits without a threat. They are going to skim the place for security.";
	};
	["doubleCross_7"]={
		Face="Smile";
		Say="Okay..";
		Reply="Come out when the meeting happens and keep an eye out. If things goes wrong.. pull that lever.";
	};
	["doubleCross_8"]={
		Face="Confident";
		Say="Alright, but what does the lever do?";
		Reply="Don't worry about it.. Alright, in the crate you go..";
	};

};


-- MARK: Caitlin Dialogues
Dialogues.Caitlin.DialogueStrings = {
	["doubleCross_1"]={
		Face="Suspicious";
		Say="Hey err.. I need to talk to Revas Remington about something important.";
		Reply="What makes you think Mr. Remington would want to meet you?";
	};
	["doubleCross_2"]={
		Face="Suspicious";
		Say="Let's just say I know an informant who has information on the Bandits.";
		Reply="Is that so.. I'll pass the information up the chain, if he wants to talk to you, he will let you know.";
	};
	["doubleCross_3"]={
		Face="Confident";
		Say="Soo.. What did he say?";
		Reply="Guess it's your lucky day, head on up..";
	};
};

if RunService:IsServer() then
	-- MARK: Patrick Handler
	Dialogues.Patrick.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
		local modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);

		if mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 17 then
				if modBranchConfigurations.IsWorld("DoubleCross") then
					dialog:SetInitiate("*groan* Bring me somewhere safe..");
				else
					dialog:SetInitiateTag("doubleCross_17");
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint == 17 then
							mission.ProgressionPoint = 18;
						end;
					end)
				end
				return;
			end

			dialog:SetInitiate("Well..?");

			if mission.ProgressionPoint == 7 then
				dialog:SetInitiateTag("doubleCross_6");
				dialog:AddChoice("doubleCross_7", function(dialog)
					dialog:AddChoice("doubleCross_travelToCargoShip", function(dialog)
						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint <= 7 then
								mission.ProgressionPoint = 8;
							end;
						end)
						
						local npcModel = dialog.Prefab;
						if npcModel:FindFirstChild("doubleCrossInteractable") then
							dialog:InteractRequest(npcModel.doubleCrossInteractable, npcModel.PrimaryPart);
						end
					end)
				end)

			elseif mission.ProgressionPoint == 8 then
				dialog:AddChoice("doubleCross_travelToCargoShip", function()
					local npcModel = dialog.Prefab;
					if npcModel:FindFirstChild("doubleCrossInteractable") then
						dialog:InteractRequest(npcModel.doubleCrossInteractable, npcModel.PrimaryPart);
					end
				end);

			elseif mission.ProgressionPoint == 18 then
				local profile = shared.modProfile:Get(player);
				local playerSave = profile:GetActiveSave();
				local inventory = playerSave.Inventory;
				local total, itemList = inventory:ListQuantity("medkit", 1);

				dialog:SetInitiate("Still need that medkit buddy.");

				if total <= 0 then
					total, itemList = inventory:ListQuantity("largemedkit", 1);
				end
				if total <= 0 then
					total, itemList = inventory:ListQuantity("advmedkit", 1);
				end

				if total >=	1 then
					dialog:AddChoice("doubleCross_giveMedkit", function(dialog)
						dialog:AddChoice("doubleCross_18", function(dialog)
							if itemList then
								for a=1, #itemList do
									inventory:Remove(itemList[a].ID, itemList[a].Quantity);
									shared.Notify(player, "Medkit removed from your Inventory.", "Negative");
								end
							end

							task.wait(2);
							modMission:CompleteMission(player, missionId);
							shared.Notify(player, "You have unlocked factions! Open your faction menu to join or create a faction.", "Inform");
						end)
					end)
				end
			end

		elseif mission.Type == 2 then -- Available
			dialog:SetInitiateTag("doubleCross_init");
			dialog:AddChoice("doubleCross_1", function(dialog)
				dialog:AddChoice("doubleCross_2", function(dialog)
					dialog:AddChoice("doubleCross_3", function(dialog)
						dialog:AddChoice("doubleCross_4", function(dialog)
							dialog:AddChoice("doubleCross_5", function(dialog)
								modMission:StartMission(player, missionId);
							end)
						end)
					end)
				end)
			end);

		elseif mission.Type == 3 then -- Complete

			if modEvents:GetEvent(player, "banditoutpostMapGift") == nil then

				dialog:AddChoice("banditmapGift", function(dialog)
					local profile = shared.modProfile:Get(player);
					local playerSave = profile:GetActiveSave();
					local inventory = playerSave.Inventory;

					local hasSpace = inventory:SpaceCheck{{ItemId="banditoutpostmap"}};
					if not hasSpace then
						shared.Notify(player, "Inventory is full!", "Negative");

					else
						inventory:Add("banditoutpostmap");
						shared.Notify(player, "You received a Bandit Outpost Map.", "Reward");
						modEvents:NewEvent(player, {Id="banditoutpostMapGift"});

					end
				end)

			end
		end
	end
	
	-- MARK: Revas Handler
	Dialogues.Revas.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			if stage == 5 then
				dialog:SetInitiate("Hmm?");
				dialog:AddChoice("doubleCross_1", function(dialog)
					dialog:AddChoice("doubleCross_2", function(dialog)
						dialog:AddChoice("doubleCross_3", function(dialog)
							modMission:Progress(player, missionId, function(mission)
								if mission.ProgressionPoint < 6 then
									mission.ProgressionPoint = 6;
								end;
							end)
						end)
					end)
				end);

			elseif stage == 9 then
				dialog:SetInitiateTag("doubleCross_4");
				dialog:AddChoice("doubleCross_5", function(dialog)
					dialog:AddChoice("doubleCross_6", function(dialog)
						dialog:AddChoice("doubleCross_7", function(dialog)
							dialog:AddChoice("doubleCross_8", function(dialog)
								modMission:Progress(player, missionId, function(mission)
									if mission.ProgressionPoint < 10 then
										mission.ProgressionPoint = 10;
									end;
								end)
							end)
						end)
					end)
				end)

			end
		end
	end
	
	-- MARK: Caitlin Handler
	Dialogues.Caitlin.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			if stage == 1 then
				dialog:AddChoice("doubleCross_1", function(dialog)
					dialog:AddChoice("doubleCross_2", function(dialog)
						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint < 2 then
								mission.ProgressionPoint = 2;
							end;
						end)
						
						dialog:SetExpireTime(workspace:GetServerTimeNow()+1);
					end)
				end);

			elseif stage == 3 then
				dialog:AddChoice("doubleCross_3", function(dialog)
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint < 4 then
							mission.ProgressionPoint = 4;
						end;
					end)
				end)
			end
		end
	end
end


return Dialogues;