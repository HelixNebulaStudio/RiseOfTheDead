local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modDialogueService = shared.require(game.ReplicatedStorage.Library.DialogueService);

--=
local Dialogues = {
	Rachel={};
	Mike={};
	Molly={};
	["Dr. Deniski"]={};
};

local MISSION_ID = 75;
local cache = {
	SecondBribe=nil;
};

--==

-- !outline: Rachel Dialogues
Dialogues.Rachel.DialogueStrings = {
	["medbre_init"]={
		Face="Worried"; 
		Reply="Stan saved my life, I was trapped and he heard me cried for help. I miss him so much..";
	};

	["medbre_start"]={
		CheckMission=MISSION_ID; 
		Say="Hey, it's okay. I have some news about Stan.";
		Face="Worried"; 
		Reply="News.. about Stan?";
	};
	["medbre_start2"]={
		Say="Yes, so apparently Stan is still alive.";
		Face="Disbelief"; 
		Reply="...";
	};
	["medbre_start3"]={
		Say="But.. He's an infector..";
		Face="Skeptical"; 
		Reply="That explains a lot.. But he never tried to infect me, or you..";
	};
	["medbre_start4"]={
		Say="I'm not sure why either.";
		Face="Suspicious"; 
		Reply="Hmmm.. If that's true, I have something I need you to do. I have Stan's blood sample from all the time I had to take care of him.";
	};
	["medbre_start5"]={
		Say="What do I need to do?";
		Face="Confident"; 
		Reply="There's a clinic near the W.D. Mall, there should be some testing labs there. I've worked there before, there should be instructions on how to test these samples. Then bring back the reports and I'll see if there are dormant parasites lingering.";
	};

	["medbre_ready"]={
		Face="Worried"; 
		Reply="When you're ready, bring these blood sample to the clinic.";
	};
	["medbre_takesample"]={
		Say="I'm ready to go.";
		Face="Confident"; 
		Reply="Here you go, keep the samples safe! (When you take damage, the samples also takes damage!)";
	};

	["medbre_reready"]={
		Face="Worried"; 
		Reply="You're back so soon?";
	};
	["medbre_retakesample"]={
		Say="Sorry but I hope you have more of those samples..";
		Face="Bored"; 
		Reply="You are lucky I have more backups. Here, keep them safe!";
	};
	

	["medbre_return1"]={
		Face="Worried"; 
		Reply="Wow, you look roughed up. What happened?";
	};
	["medbre_banditsAttacked"]={
		Say="Yeah, a group of rogue bandits attacked.. But I took care of them and got the results.";
		Face="Surprise"; 
		Reply="Oh noo, I didn't mean to put you in danger..";
	};

	["medbre_return2"]={
		Face="Worried"; 
		Reply="Welcome back, have you got the results?";
	};
	["medbre_banditsBribed"]={
		Say="Yeah, I had to bribe a rouge bandit just so I can stay in the lab.";
		Face="Surprise"; 
		Reply="Oh noo, I didn't mean to put you in danger..";
	};
	
	["medbre_showResults"]={
		Say="It's okay, I can handle myself. Anyways, here are the results for the 4 samples.. *Shows reports*";
		Face="Surprise"; 
		Reply="Hmmm.. This has information beyond my understanding at the moment. I think I'll need some time researching this..";
	};
	["medbre_drden"]={
		Say="Wait, I actually know a guy who might be able to help. He goes by Dr. Deniski and he has been researching zombie blood..";
		Face="Surprise"; 
		Reply="Oh wonderful, do help me get his insights on the reports. I'll continue my own research.";
	};
	

	["medbre_final"]={
		Face="Happy"; 
		Reply="So how did it go?";
	};
	["medbre_insights"]={
		Say="Here's the insight Dr. Deniski written. *Gives report*";
		Face="Skeptical"; 
		Reply="fascinating.. We might have a breakthrough here, but I'll need some time to figure out the chemistry..";
	};
	["medbre_end"]={
		Say="Sure, if you need anything let me know!";
		Face="Confident"; 
		Reply="Come back after a while and I'll let you know what I need.";
	};
};

-- !outline: Mike Dialogues
Dialogues.Mike.DialogueStrings = {
	["medbre_init"]={
		Face="Bored"; 
		Reply="You look like you're in a rush.";
	};
	["medbre_helplab"]={
		Say="Yeah, I'm looking for the laboratories.";
		Face="Bored"; 
		Reply="It should be on the third floor. But the doors are locked, I think Molly might be able to help.";
	};
};

-- !outline: Molly Dialogues
Dialogues.Molly.DialogueStrings = {
	["medbre_init"]={
		Face="Bored"; 
		Reply="This better be important..";
	};
	["medbre_helplab"]={
		Say="I need to get to the laboratories, how do I get pass the locked doors?";
		Face="Bored"; 
		Reply="About that, we can't access that area ever since the military took over. You're gonna need to find another way in.";
	};
};

-- !outline: Dr. Deniski Dialogues
Dialogues["Dr. Deniski"].DialogueStrings = {
	["medbre_init"]={
		Face="Confident"; 
		Reply="привет, my friend..\n\nThat means hello, haha!";
	};
	["medbre_showReport"]={
		Say="Hey doc, I have some blood reports of infector blood and need some insight on it. Maybe you could help us?\n\n*Shows reports*";
		Face="Suspicious"; 
		Reply="Oh sure.. Hmmm... Very interesting..\nSo they are parasites, but they are in like a hibernating state because they aren't multiplying much..";
	};
	["medbre_showReport2"]={
		Say="...";
		Face="Suspicious"; 
		Reply="And during this state, they seem to be producing some kind of regenerative enzymes byproduct..";
	};
	["medbre_showReport3"]={
		Say="...";
		Face="Joyful"; 
		Reply="Haha, don't worry. I'll write it down, this is definately huge discover!\n\n*Writing up summary report*";
	};
	["medbre_showReport4"]={
		Say="Wait, but how does this compare to zombie blood?";
		Face="Happy"; 
		Reply="Well, in my tests, there aren't any dormant parasites in zombie blood.. My hypothesis is that the parasites only resides in the brain after the body is dead or something.\n*Finishes writing* annd done. Show this to your friend.";
	};
};

if RunService:IsServer() then
	-- !outline: Rachel Handler
	Dialogues.Rachel.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		local modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);

		local profile = shared.modProfile:Get(player);
		local playerSave = profile:GetActiveSave();
		local inventory = playerSave.Inventory;
		
		local function dialogTakeSample(sampleTag)
			dialog:AddChoice(sampleTag, function(dialog)
				local hasSpace = inventory:SpaceCheck{{ItemId="bloodsample"}};
				if not hasSpace then
					shared.Notify(player, "Inventory is full!", "Negative");
					return;
				end

				if mission.Type == 4 then
					modMission:StartMission(player, MISSION_ID);
				end
				
				inventory:Add("bloodsample", {
					CustomName="Stan's Blood Samples";
					Values={
						Health=100;
						MaxHealth=100;
					};}, function(queueEvent, storageItem)
						mission.SaveData.SampleId = storageItem.ID;
						mission.SaveData.MissionItems = {};
						table.insert(mission.SaveData.MissionItems, storageItem.ID);
					end);
				
				modMission:Progress(player, MISSION_ID, function(mission)
					mission.ProgressionPoint = 2;
				end);

			end)
		end
		
		if mission.Type == 2 then -- Available;
			dialog:SetInitiateTag("medbre_init");

			dialog:AddChoice("medbre_start", function(dialog)
				dialog:AddChoice("medbre_start2", function(dialog)
					dialog:AddChoice("medbre_start3", function(dialog)
						dialog:AddChoice("medbre_start4", function(dialog)
							dialog:AddChoice("medbre_start5", function(dialog)
								modMission:StartMission(player, MISSION_ID);
							end)
						end)
					end)
				end)
			end)
			
			
		elseif mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 1 then
				dialog:SetInitiateTag("medbre_ready");
				dialogTakeSample("medbre_takesample");
				
			elseif mission.ProgressionPoint == 12 then
				local function point12(dialog)
					dialog:AddChoice("medbre_showResults", function(dialog)
						dialog:AddChoice("medbre_drden", function(dialog)

							local storageItem = inventory:Find(mission.SaveData.SampleId);
							if storageItem then
								inventory:Remove(storageItem.ID, 1);
							end
							
							modMission:Progress(player, MISSION_ID, function(mission)
								if mission.ProgressionPoint <= 13 then
									mission.ProgressionPoint = 13;
								end
							end);
						end)
					end)
				end

				--if RunService:IsStudio() then
				--	Debugger:Warn("Set FightBandits", true);
				--	mission.SaveData.FightBandits = true;
				--end
				if mission.SaveData.FightBandits == true then
					dialog:SetInitiateTag("medbre_return1");

					dialog:AddChoice("medbre_banditsAttacked", function(dialog)
						point12(dialog);
					end)
					
				else
					dialog:SetInitiateTag("medbre_return2");
					dialog:AddChoice("medbre_banditsBribed", function(dialog)
						point12(dialog);
					end)
				end
				
			elseif mission.ProgressionPoint == 13 then
				
			elseif mission.ProgressionPoint == 14 then
				dialog:SetInitiateTag("medbre_final");

				dialog:AddChoice("medbre_insights", function(dialog)
					dialog:AddChoice("medbre_end", function(dialog)

						local storageItem = inventory:Find(mission.SaveData.ReportId);
						if storageItem then
							local sampleName = storageItem and storageItem.CustomName or "n/a";

							inventory:Remove(storageItem.ID, 1);
							shared.Notify(game.Players:GetPlayers(), sampleName.." removed from your Inventory.", "Negative");
						end
						
						modEvents:NewEvent(player, {Id="medbreFirstZiphon"});
						
						modMission:CompleteMission(player, 75);
						shared.Notify(player, "Unlocked Ziphoning Serum to Missions Board.", "Inform");
						task.delay(3, function()
							modMission:AddMission(player, 76, true, true);
						end)
					end)
				end)
			end
			
		elseif mission.Type == 4 then -- Failed
			if mission.ProgressionPoint == 1 then
				dialog:SetInitiateTag("medbre_reready");
				dialogTakeSample("medbre_retakesample");
				
			end
			
		end
	end

	-- !outline: Mike Handler
	Dialogues.Mike.DialogueHandler = function(player, dialog, data, mission)
		if mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 3 then
				dialog:SetInitiateTag("medbre_init");

				dialog:AddChoice("medbre_helplab");
			end
		end
	end

	-- !outline: Molly Handler
	Dialogues.Molly.DialogueHandler = function(player, dialog, data, mission)
		if mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 3 then
				dialog:SetInitiateTag("medbre_init");

				dialog:AddChoice("medbre_helplab");
			end
		end
	end
	
	-- !outline: Dr. Deniski Handler
	Dialogues["Dr. Deniski"].DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		
		if mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 13 then
				dialog:SetInitiateTag("medbre_init");

				dialog:AddChoice("medbre_showReport", function(dialog)
					dialog:AddChoice("medbre_showReport2", function(dialog)
						dialog:AddChoice("medbre_showReport3", function(dialog)
							dialog:AddChoice("medbre_showReport4", function(dialog)
								local profile = shared.modProfile:Get(player);
								local playerSave = profile:GetActiveSave();
								local inventory = playerSave.Inventory;
								
								
								if mission.SaveData.MissionItems then
									for a, itemIDs in pairs(mission.SaveData.MissionItems) do
										inventory:Remove(itemIDs, 1);
									end
									table.clear(mission.SaveData.MissionItems);
								end
								
								modMission:Progress(player, MISSION_ID, function(mission)
									if mission.ProgressionPoint <= 14 then
										mission.ProgressionPoint = 14;
									end
								end);
		
								local hasSpace = inventory:SpaceCheck{{ItemId="samplereport"}};
								if not hasSpace then
									shared.Notify(player, "Inventory is full!", "Negative");
									return;
								end;
								
								inventory:Add("samplereport", {
									CustomName="Dr. Deniski's Report Insights";
									Values={
										Result=false;
									};}, function(queueEvent, storageItem)
										mission.SaveData.ReportId = storageItem.ID;
									end);
								shared.Notify(player, "Dr. Deniski's Report Insights added to your inventory.", "Inform");
								
							end)
						end);
					end)
				end);
			end
		end
	end
	
end

if modBranchConfigurations.IsWorld("MedicalBreakthrough") then
	
	Dialogues.Bandit = {};
	-- !outline: Bandit Handler
	Dialogues.Bandit.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		local modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
		
		local missionCache = modEvents:GetEvent(player, "MissionCache");
		local banditsAllied = missionCache and missionCache.Value and missionCache.Value.BanditsAllied == true;

		local patrolBanditNpcModule = dialog:GetNpcClass();
		
		--if RunService:IsStudio() then
		--	Debugger:Warn("Set banditsAllied", false);
		--	banditsAllied = false;
		--end
		
		if mission.Type == 1 and mission.ProgressionPoint == 9 then
			local playerSave = shared.modProfile:Get(player):GetActiveSave();

			if cache.SecondBribe then
				local bribeCost = 5000;
				dialog:SetInitiate("You know what.. Another $5'000 and I'll leave you alone.");

				if playerSave:GetStat("Money") >= bribeCost then
					dialog:AddDialog({
						Face="Hehe";
						Say=".. *Give $5'000 to bandit*";
						Reply="Alright, haha, see you next time.";
					}, function(dialog)
						dialog:SetExpireTime(workspace:GetServerTimeNow()+10);
						
						patrolBanditNpcModule:ToggleInteractable(false);
	
						playerSave:AddStat("Money", -bribeCost);
						
						task.wait(4);
						patrolBanditNpcModule.Movement:Move(Vector3.new(508.548, 136.42, -1184.096));
						task.wait(4);
						patrolBanditNpcModule:TeleportHide();
	
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint <= 11 then
								mission.ProgressionPoint = 11;
							end
						end);
					end);

				else
					dialog:AddDialog({
						Face="Serious";
						Say=".. I don't have any more money.";
						Reply="Ugh.. fine.";
					}, function(dialog)
						dialog:SetExpireTime(workspace:GetServerTimeNow()+10);
						
						patrolBanditNpcModule:ToggleInteractable(false);
	
						task.wait(4);
						patrolBanditNpcModule.Movement:Move(Vector3.new(508.548, 136.42, -1184.096));
						task.wait(4);
						patrolBanditNpcModule:TeleportHide();
	
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint <= 11 then
								mission.ProgressionPoint = 11;
							end
						end);
					end)
				end
				
				return;
			end
			
			dialog:SetInitiate("Identify yourself immediately!");
			dialog:SetExpireTime(workspace:GetServerTimeNow()+10);
			
			if banditsAllied then
				dialog:AddDialog({
					Face="Serious";
					Say="I'm $PlayerName! I'm one of the new recruit.";
					Reply="Oh really? And what are you doing here?";
					
				}, function(dialog)
					dialog:SetExpireTime(workspace:GetServerTimeNow()+10);
					
					dialog:AddDialog({
						Face="Serious";
						Say="[Truth] I'm testing these blood samples for dormant parasites..";
						Reply="Hmmm.. Did Zark assign you to this?";
						
					}, function(dialog)
						dialog:SetExpireTime(workspace:GetServerTimeNow()+10);
						
						dialog:AddDialog({
							Face="Angry";
							Say="[Truth] No, Zark doesn't know about this..";
							Reply="I see.. My squad is outside, hand over the samples right now! We will take it from here.";
							
						}, function(dialog)
							dialog:SetExpireTime(workspace:GetServerTimeNow()+10);
							
							dialog:AddDialog({
								Face="Serious";
								Say="Umm what?";
								Reply="You heard me, give me the samples. You are done here!";
								
							}, function(dialog)
								dialog:SetExpireTime(workspace:GetServerTimeNow()+10);
								
								dialog:AddDialog({
									Face="Serious";
									Say="Is that Zark's orders?";
									Reply="It doesn't matter! *Loads weapon*\n*Clicks walkie talkie* \"I'll be needing backup here..\"\n\nYou have a count of 3!";
									
								}, function(dialog)
									patrolBanditNpcModule.Wield.LoadRequest();

									task.wait(4);
									for a=3, 1, -1 do
										patrolBanditNpcModule.Chat(player, a..string.rep("!",3-a));
										task.wait(1);
										if mission.ProgressionPoint == 10 then
											break;
										end
									end
									
									modMission:Progress(player, MISSION_ID, function(mission)
										if mission.ProgressionPoint == 9 then
											mission.ProgressionPoint = 10;
										end
									end);
								end)
							end)
							
						end)
					end)
					
					dialog:AddDialog({
						Face="Serious";
						Say="[Lie] Zark assigned me to pick up some items here..";
						Reply="Hahah, Zark made you do his errand? Are you the only one who's put on this task?";
					}, function(dialog)
						dialog:SetExpireTime(workspace:GetServerTimeNow()+10);
						
						dialog:AddDialog({
							Face="Angry";
							Say="Um yeah..";
							Reply="Hmmm.. Now why would he put you on a solo mission..\n\nWait.. He doesn't want us to know about this isn't it?";
						}, function(dialog)
							dialog:SetExpireTime(workspace:GetServerTimeNow()+10);
							
							dialog:AddDialog({
								Face="Serious";
								Say="Not sure, it's probably unimportant..";
								Reply=".. Alright.. I'll leave you to it..";
							}, function(dialog)
								patrolBanditNpcModule:ToggleInteractable(false);
								patrolBanditNpcModule.Movement:Move(Vector3.new(508.548, 136.42, -1184.096));
								task.wait(3);
								
								patrolBanditNpcModule.Chat(player, "*Clicks Walkie Talkie* Potential high value cargo, 1 hostile, go in 3..", nil, 128);
								task.wait(3);
								
								if not patrolBanditNpcModule.IsDead then
									modMission:Progress(player, MISSION_ID, function(mission)
										if mission.ProgressionPoint == 9 then
											mission.ProgressionPoint = 10;
										end
									end);
								end
							end);
						end);
					end)
					
				end)
				
				
			else --
				
				dialog:AddDialog({
					Face="Serious";
					Say="Oh, I'm a new survivor here..";
					Reply="Oh really? What are you doing here?";
					
				}, function(dialog)
					dialog:SetExpireTime(workspace:GetServerTimeNow()+10);
					
					local function leaveNow5Sec()
						local patrolBanditNpcModule = dialog:GetNpcClass();
						patrolBanditNpcModule.Wield.LoadRequest();

						task.wait(2);
						for a=5, 1, -1 do
							patrolBanditNpcModule.Chat(player, a..string.rep("!",4-a));
							task.wait(1);
							if mission.ProgressionPoint == 10 then
								break;
							end
						end

						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint == 9 then
								mission.ProgressionPoint = 10;
							end
						end);
					end
					
					dialog:AddDialog({
						Face="Angry";
						Say="[Bribe] Just some blood tests..";
						Reply=".. You are not allowed to be here. Leave immediately, I'm not going to say it twice!"
					}, function(dialog)
						dialog:SetExpireTime(workspace:GetServerTimeNow()+10);
						
						dialog:AddDialog({
							Face="Serious";
							Say="Please, I need to do this.. Maybe we can work something out?";
							Reply="...\n\nIf you can cough up $10'000 then sure, I can pretend nothing happened here.";
						}, function(dialog)
							dialog:SetExpireTime(workspace:GetServerTimeNow()+10);
							
							local bribeCost = 10000;
							if playerSave:GetStat("Money") >= bribeCost then
								dialog:AddDialog({
									Face="Serious";
									Say="Fine, here.. *Give $10'000 to bandit*";
									Reply="Alright, you get 5 minutes!";
								}, function(dialog)
									playerSave:AddStat("Money", -bribeCost);
	
									local patrolBanditNpcModule = dialog:GetNpcClass();
									patrolBanditNpcModule:ToggleInteractable(false);
									
									cache.SecondBribe = true;
									task.wait(4);
									patrolBanditNpcModule.Movement:Move(Vector3.new(508.548, 136.42, -1184.096));
									task.wait(4)
									patrolBanditNpcModule.Chat(player, "Wait.. You know what..", nil, 128);
									patrolBanditNpcModule.Movement:Move(Vector3.new(507.441, 136.42, -1112.584));
									
									task.wait(4);
									patrolBanditNpcModule:ToggleInteractable(true);
									
									modDialogueService:InvokeDialogue(player, "talk", {
										NpcModel=patrolBanditNpcModule.Prefab;
									});
								end);
							end

							dialog:AddDialog({
								Face="Frustrated";
								Say="Noo way, that's too much!";
								Reply="Well, then you have 5 seconds to leave!";
							}, function(dialog)
								
								leaveNow5Sec();
							end);
							
						end);
					end)
					
					local lieDialog = {
						Face="Angry";
						Say="[Lie] I was helping the doctors test the machines..";
						Reply="Uh huuh.. Well, you have no permissions to be here. Leave immediately!";
					};
					dialog:AddDialog(lieDialog, function(dialog)
						dialog:SetExpireTime(workspace:GetServerTimeNow()+10);
						
						dialog:AddDialog({
							Face="Serious";
							Say="Please, I just need 5 minutes..";
							Reply="No, leave now. You have 5 seconds!";
						}, function(dialog)
							
							leaveNow5Sec();
						end)
					end)
					
					
				end)
			end
		end
	end
	
end


return Dialogues;