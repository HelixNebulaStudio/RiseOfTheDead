local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Wilson={};
	Walter={};
	Michael={};
};

local MISSION_ID = 53;
--==

-- !outline: Wilson Dialogues
Dialogues.Wilson.DialogueStrings = {		
	["qa2_arrive"]={
		CheckMission=MISSION_ID;
		Face="Joyful"; 
		Say="Alright."; 
		Reply="Let's head up to the roof.";
		FailResponses = {
			{Reply="He will be here in no time.."};
		};	
	};
	["qa2_goodnews"]={
		Face="Oops";
		Say="Good news?"; 
		Reply="According to Walter, the quarantine seems successful, the rest of the world is keeping an eye on us.";
	};
	["qa2_badnews"]={
		Face="Tired";
		Say="Bad news?"; 
		Reply="They are not going to let anyone or anything out of the quarantine zone. They will fire at anyone who gets near the borders of the quarantine zone.. They are just monitoring the developments within the quarantine zone and if the zombie grows out of control, they might nuke us.";
	};
	["qa2_walter"]={
		Face="Serious";
		Say="What about walter?"; 
		Reply="Err.. I think he's a bit of a kook. He volunteered to dive into the zone for research. Kudos to him, I guess..";
	};
};

-- !outline: Walter Dialogues
Dialogues.Walter.DialogueStrings = {		
	["qa2_yes"]={
		Face="Oops";
		Say="Yeah, I guess.."; 
		Reply="I need you to catch me a zombie..";
	};
	["qa2_how"]={
		Face="Hehe";
		Say="What?! How?"; 
		Reply="You'll need a Entity Leash. It hooks on to a target and controls it's limbs with electrical signals.";
	};
	["qa2_entityleash"]={
		Face="Smirk";
		Say="Okay, where can I get that?"; 
		Reply="From the militaries intelligence, the R.A.T. shops might sell some..";
	};

	["qa2_caughtfail"]={
		Face="Skeptical";
		Say="Here's the zombie I caught."; 
		Reply="... I don't see any..";
	};

	["qa2_caught"]={
		Face="Joyful";
		Say="Here's the zombie I caught."; 
		Reply="Wow, you actually caught one. I'll take it from here..";
	};
};

-- !outline: Michael Dialogues
Dialogues.Michael.DialogueStrings = {		
	["qa2_catch"]={
		Face="Confident"; 
		Say="Yeah, the military sent in an inspector. Now I have to catch a zombie for him.."; 
		Reply="Oh, alright. Good luck.";
	};
};


if RunService:IsServer() then
	-- !outline: Wilson Handler
	Dialogues.Wilson.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			if stage >= 1 and stage < 9 then
				dialog:SetInitiate("Just does as he says for now. I'll talk to him to figure things out..");

			elseif stage == 9 then
				dialog:SetInitiate("Okay, good news and bad news..");
				dialog:AddChoice("qa2_goodnews", function(dialog)
					dialog:AddChoice("qa2_badnews", function(dialog)
						dialog:AddChoice("qa2_walter", function(dialog)
							modMission:CompleteMission(player, MISSION_ID);
						end)
					end)
				end)
			end

		elseif mission.Type == 2 then -- Available
			dialog:SetInitiate("$PlayerName, the assessment team is arriving soon.");
			dialog:AddChoice("qa2_arrive", function(dialog)
				modMission:StartMission(player, MISSION_ID);
			end)

		end
	end
	
	
	-- !outline: Walter Handler
	Dialogues.Walter.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		local modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);

		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			if stage == 3 then
				dialog:SetInitiate("Are you good at handling yourself out there?");
				dialog:AddChoice("qa2_yes", function(dialog)
					dialog:AddChoice("qa2_how", function(dialog)
						dialog:AddChoice("qa2_entityleash", function(dialog)
							modMission:Progress(player, MISSION_ID, function(mission)
								mission.ProgressionPoint = 4;
							end)
						end)
					end)
				end)

			elseif stage == 4 then
				dialog:SetInitiate("Got it yet?");

			elseif stage == 5 then
				dialog:SetInitiate("Nice, you got it, now use it on a zombie.");

			elseif stage == 6 and stage == 7 then
				dialog:SetInitiate("What's stopping ya?");

			elseif stage == 8 then
				local npcModule;

				local character = player and player.Character;
				if character and character:FindFirstChild("entityleash") then
					local toolModel = character.entityleash;
					local storageItemId = toolModel:GetAttribute("StorageItemId");

					local profile = shared.modProfile:Get(player);
					local storageItem = storageItemId and modStorage.FindIdFromStorages(storageItemId, player);
					local handler = profile:GetToolHandler(storageItem);

					if handler and handler.NpcModule then
						npcModule = handler.NpcModule;
					end
				end

				if npcModule then
					dialog:AddChoice("qa2_caught", function(dialog)
						Debugger.Expire(npcModule.Prefab, 0);
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint == 8 then
								mission.ProgressionPoint = 9;
							end
						end)
					end)

				else
					dialog:AddChoice("qa2_caughtfail");

				end

			end

		end
	end
	

	-- !outline: Michael Handler
	Dialogues.Michael.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		
		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			if stage >= 5 and stage < 8 then
				dialog:SetInitiate("Heard a helicopter flew by..");
				dialog:AddChoice("qa2_catch", function(dialog)
					modMission:Progress(player, MISSION_ID, function(mission)
						mission.ProgressionPoint = 8;
					end)
				end)


			end

		end
	end
end


return Dialogues;