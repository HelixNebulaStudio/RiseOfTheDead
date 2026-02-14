local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Dallas={};
	Joseph={};
	Molly={};
	Nate={};
	Robert={};
};

local MISSION_ID = 52;
--==

-- MARK: Dallas Dialogues
Dialogues.Dallas.DialogueStrings = {
	["investigation_wakeUp"]={
		Say="Hey Dallas, wake up!!"; 
		Reply="Ohh.. God dumm... I was knocked out cold.."};
};

-- MARK: Joseph Dialogues
Dialogues.Joseph.DialogueStrings = {
	["investigation_zombieface"]={
		Face="Surprise";
		Say="Robert has been acting strange and I feel like it's bad. He had this zombie look the last time I saw him, but when I went up close to him, he was fine."; 
		Reply="Zombie look? Who else saw it? Could it be just you?";
	};
	["investigation_fast"]={
		Face="Skeptical";
		Say="Not sure, that's why I have some questions. How long has Robert been here? He went missing for a couple days and next thing I know, he's here.."; 
		Reply="He's been here for a couple days. He saved one of our members, Nate, from a dire situation when he was caught under some debris after an explosion while scavenging for supplies.. He somehow lifted the heavy debris and got Nate out of there..";
	};
	["investigation_zark"]={
		Face="Question";
		Say="I see. I had an encounter with the Bandit leader, Zark. He mentioned something about Infectors.. Do you know anything about them?"; 
		Reply="Hmmm, I've only heard of them, but I know that they are physically stronger and can disguise as a normal person. There are rumors about infectors lurking around in the train stations..";
	};
	["investigation_keepEye"]={
		CheckMission=MISSION_ID;
		Face="Question";
		Say="Hmmm, I'm going to talk to the others to get more information.";
		Reply="Alright, I'll try to keep an eye on Robert while you do that.";
	};
	
	
	["investigation_patchJoseph"]={
		Face="Frustrated";
		Say="*Wrap strap around arm to stop bleeding*";
		Reply="Ugh... Alright, this will stop the bleeding..";
	};
	["investigation_complete"]={
		Face="Serious";
		Say="Are you sure? You should just rest here..";
		Reply="... I rather not. Our people needs us, the community needs us.";
	};
	["investigation_complete2"]={
		Face="Serious";
		Say="Alright..";
		Reply="Don't worry kid, you did well.. We will be fine, we will continue once I'm well rested.";
	};
	
};

-- MARK: Molly Dialogues
Dialogues.Molly.DialogueStrings = {
	["investigation_convince"]={
		Face="Question";
		Say="Can you help my friend?! An infector ripped out his arm!!";
		Reply="Afraid not sir.. Why can't just help everyone that comes in here..";
	};
	["investigation_convince2"]={
		Face="Welp"; 
		Say="What?! Why not?!";
		Reply="Look, you guys aren't the first to come here for help. Many came here for help and still didn't make it, we don't have a choice. Supplies are limited.";
	};
	["investigation_convince3"]={
		Face="Suspicious"; 
		Say="What resources do you need? Maybe I can get you some..";
		Reply="I'll need advance med kits. You better make it quick if you want to help your friend here cause I'm not starting until I get the resource I need..";
	};
	["investigation_medkit"]={
		Face="Surprise"; 
		Say="*Give Advance Medkit*";
		Reply="I'm surprise you actually got it. Alright, I'll patch him up.";
	};
	["investigation_needAdvmedkit"]={
		Face="Welp"; 
		Say="I don't have an advance medkit.";
		Reply="Then you should look for some..";
	};
};

-- MARK: Nate Dialogues
Dialogues.Nate.DialogueStrings = {
	["investigation_robert"]={
		Face="Serious";
		Say="Hey, have you noticed anything suspicious with Robert? Joseph and I suspect that he might be an infector..";
		Reply="Now that you mention it, after the explosion from my scavenge, I was trapped and my vision was blurry. I didn't believe it at the time, but he had this zombie look on his face.";
	};
	["investigation_face"]={
		Face="Angry";
		Say="So I wasn't the only one who saw it.. We need to do something..";
		Reply="We made a cell in the basement of one of the buildings in case of event like these. I'll set it up, I need you to lure him there.";
	};
	["investigation_wakeUp"]={
		Face="Skeptical";
		Say="Nate, wake up. Wake up!";
		Reply="Ahhh. My heaad.. It hurts..";
	};
	["investigation_wHappen"]={
		Face="Skeptical";
		Say="Robert knocked you out, then the bandits came. They took Robert's severed hand and left.";
		Reply="OH MY GOD, Joseph! Bring him to the hospital now!";
	};
};

-- MARK: Robert Dialogues
Dialogues.Robert.DialogueStrings = {
	["investigation_sus"]={
		Face="Smile";
		Say="Oh umm, what are doing here?";
		Reply="Just checking this place out, not sure why it's blocked up.. It might have some useful supplies.";
	};
	["investigation_lure"]={
		Face="Skeptical";
		Say="Robert, Nate needs our help. Come, I think he's in the basement.";
		Reply="Oh alright..";
	};
};


if RunService:IsServer() then
	local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);


	-- MARK: Dallas Handler
	Dialogues.Dallas.DialogueHandler = function(player, dialog, data, mission)
		local modNpcs = shared.modNpcs;

		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			if stage == 12 then
				dialog:SetInitiate("...");
				local dallasModule: NpcClass = modNpcs.getPlayerNpc(player, "Dallas");
				if dallasModule.Humanoid.PlatformStand then
					dialog:AddChoice("investigation_wakeUp", function(dialog)
						if dallasModule then
							dallasModule.Humanoid.PlatformStand = false;
							dallasModule.StopAnimation("Unconscious");
							dallasModule.Humanoid:ChangeState(Enum.HumanoidStateType.None);
						end
					end)
				end
				
			end
		end

	end


	-- MARK: Joseph Handler
	Dialogues.Joseph.DialogueHandler = function(player, dialog, data, mission)

		if mission.Type == 2 then -- Available
			dialog:SetInitiate("Howdy, what can I do for ya?");
			dialog:AddChoice("investigation_zombieface", function(dialog)
				dialog:AddChoice("investigation_fast", function(dialog)
					dialog:AddChoice("investigation_zark", function(dialog)
						dialog:AddChoice("investigation_keepEye", function(dialog)
							modMission:StartMission(player, MISSION_ID);
						end)
					end)
				end)
			end)
			
		elseif mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 9 then
				dialog:SetInitiate("Ugghh, I'm... losing.. a lot of.. blood..");
				modMission:Progress(player, MISSION_ID, function(mission)
					mission.ProgressionPoint = 10;
				end)
				
			elseif mission.ProgressionPoint == 10 then
				dialog:SetInitiate("Ugghh, hurry..");
				
			elseif mission.ProgressionPoint == 11 then
				dialog:SetInitiate("Ugghh, hurry..");
				dialog:AddChoice("investigation_patchJoseph", function(dialog)
					modMission:Progress(player, MISSION_ID, function(mission)
						mission.ProgressionPoint = 12;
					end)
				end)
				
			elseif mission.ProgressionPoint == 19 then
				dialog:SetInitiate("Thanks $PlayerName, I took some medicine to ease the pain. Nate and I will be heading back to the community so I can rest there.");
				dialog:AddChoice("investigation_complete", function(dialog)
					dialog:AddChoice("investigation_complete2", function(dialog)
						modMission:CompleteMission(player, MISSION_ID);
					end)
				end)
				
			elseif mission.ProgressionPoint >= 4 then
				dialog:SetInitiate("Ugghh..");
				
			elseif mission.ProgressionPoint <= 3 then
				dialog:SetInitiate("Keeping an eye on him, hasn't done anything suspicious yet..");
			end

		elseif mission.Type == 3 then
			if modBranchConfigurations.IsWorld("TheResidentials") then
				if data:Get("lostArm") == nil then
					dialog:SetInitiate("You're back, $PlayerName..");
					
					dialog:AddDialog({
						Face="Confident";
						Say="How are you feeling?";
						Reply="Much better now.. Definitely going to miss my left arm.. Going to need a hand later though, hahah..";
					}, function(dialog)
						data:Set("lostArm", true);
					end);

				end
			end
		end

	end
	

	-- MARK: Molly Handler
	Dialogues.Molly.DialogueHandler = function(player, dialog, data, mission)
		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			if stage == 16 then
				dialog:SetInitiate("Oh great.. Another survivor..", "Ugh");
				dialog:AddChoice("investigation_convince", function(dialog)
					dialog:AddChoice("investigation_convince2", function(dialog)
						dialog:AddChoice("investigation_convince3", function(dialog)
							modMission:Progress(player, MISSION_ID, function(mission)
								if mission.ProgressionPoint == 16 then
									mission.ProgressionPoint = 17;
								end
							end)
						end)
					end)
				end)
				
			elseif stage == 17 then
				local profile = shared.modProfile:Get(player);
				local playerSave = profile:GetActiveSave();
				local inventory = playerSave.Inventory;
				local total, itemList = inventory:ListQuantity("advmedkit", 1);
				
				if total > 0 then
					dialog:AddChoice("investigation_medkit", function(dialog)
						for a=1, #itemList do
							inventory:Remove(itemList[a].ID, itemList[a].Quantity);
							shared.Notify(player, "Advance Medkit removed from your Inventory.", "Negative");
						
						end
						
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint == 17 then
								mission.ProgressionPoint = 18;
							end
						end)
					end)
				else
					dialog:AddChoice("investigation_needAdvmedkit");
				end
			end
		end

	end
	

	-- MARK: Nate Handler
	Dialogues.Nate.DialogueHandler = function(player, dialog, data, mission)
		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			if stage == 1 then
				dialog:AddChoice("investigation_robert", function(dialog)
					dialog:AddChoice("investigation_face", function(dialog)
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint == 1 then
								mission.ProgressionPoint = 2;
							end
						end)
					end)
				end)
				
			elseif stage == 12 then
				dialog:SetInitiate("...");
				
				dialog:AddChoice("investigation_wakeUp", function(dialog)
					modMission:Progress(player, MISSION_ID, function(mission)
						mission.ProgressionPoint = 13;
					end)
				end)
				
			elseif stage == 13 then
				dialog:SetInitiate("...What.. happened?");
				
				dialog:AddChoice("investigation_wHappen", function(dialog)
					modMission:Progress(player, MISSION_ID, function(mission)
						mission.ProgressionPoint = 14;
					end)
				end)
			end
		end

	end
	

	-- MARK: Robert Handler
	Dialogues.Robert.DialogueHandler = function(player, dialog, data, mission)
		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			if stage == 1 then
				dialog:SetInitiate("Oh hey, $PlayerName..");
				dialog:AddChoice("investigation_sus");
				
			elseif stage == 2 then
				dialog:SetInitiate("Oh hey, $PlayerName..");
				dialog:AddChoice("investigation_lure", function(dialog)
					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint == 2 then
							mission.ProgressionPoint = 3;
						end
					end)
				end)
				
			elseif stage == 3 then
				dialog:SetInitiate("Following right behind you.");
				
			end
		end

	end


end


return Dialogues;