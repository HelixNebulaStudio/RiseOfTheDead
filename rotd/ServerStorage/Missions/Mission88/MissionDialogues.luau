local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Joseph={};
	Caitlin={};
};

local MISSION_ID = 88;
--==

-- MARK: Joseph DialogueStrings
Dialogues.Joseph.DialogueStrings = {
	["sot_joseph_init"] = {
		Face = "Skeptical";
		Reply = "Now that we have our walkies, our scavenge runs are much smoother. What's up, $PlayerName?";
	};

	-- O1; Inform Joseph about Caitlin's situation
	["sot_j1"] = {
		Face = "Confident";
		Say = "Hey, Caitlin needs your help.";
		Reply = "Hah! No dice. I don't want anything to do with her nor the RATs. The walkie talkies were the last straw.";
	};
	["sot_j2"] = {
		Face = "Serious";
		Say = "Well, it's not really about her. She said something about you making a cure for her sister?";
		Reply = "...What nonsense is she spewing now?";
	};
	["sot_j3"] = {
		Face = "Serious";
		Say = "She thinks you were some scientist involved in some project about making miracle cures.";
		Reply = "I... what? Where did she hear this from?";
	};
	["sot_j4"] = {
		Face = "Suspicious";
		Say = "No idea. You can ask her if you want?";
		Reply = "No... I'm not believing in any of her lies. Tell her to bring me proof or I'll get Nate to escort her out of here.";
	};
	["sot_j5"] = {
		Face = "Surprise";
		Say = "She said she's in contact with some researchers who worked on the project.";
		Reply = "What? But... they were all... No, this is impossible.";
	};
	["sot_j6"] = {
		Face = "Suspicious";
		Say = "Aha! So you do know something about this!";
		Reply = "As I said, she is lying to you, $PlayerName.";
	};
	["sot_j7"] = {
		Face = "Skeptical";
		Say = "Err... how about this - I could go meet them and confirm their identities? I'll let you know, and you can decide for yourself if they're legit.";
		Reply = "Hmm... *Sigh* Alright. Just be careful, okay? I don't trust her one bit.";
	};

	["sot_joseph_p1_init"] = {
		Face = "Skeptical";
		Reply = "I don't trust her $PlayerName?";
	};
};

-- MARK: Caitlin DialogueStrings
Dialogues.Caitlin.DialogueStrings = {
	["sot_init"]={
		Face="Worried";
		Reply="....";
	};

	["sot_lore1a"] = {
		Face = "Smile";
		Say = "You have a sister?";
		Reply = "Yes, her name is Kimiko.";
	};
	["sot_lore1b"] = {
		Face = "Suspicious";
		Say = "How is Joseph suppose to help save your sister?";
		Reply = "Well, back then, my sister was sick and Joseph approached her and claimed that he was working on a \"miracle cure\" that could save her..";
	};
	["sot_lore2b"] = {
		Face = "Smile";
		Say = "\"Miracle cure\"?";
		Reply = "That's what Kimiko told me, I'm not sure of the details..";
	};
	["sot_lore1c"] = {
		Face = "Suspicious";
		Say = "Doesn't the Rats have a BioX scientist as well?";
		Reply = "Yes, but I don't think he works on the same project as Joseph..";
	};
	["sot_lore2c"] = {
		Face = "Bored";
		Say = "...";
		Reply = "I think Eugene is more in the genetic modification department.";
	};

	-- O2: Talk to Caitlin
	["sot_c1"] = {
		Face = "Confident";
		Say = "Joseph needs me to confirm those researcher friends of yours.";
		Reply = "Careful as always, huh? I don't blame him. No worries, just give me a moment.";
	};

	["sot_headout"] = {
		Face = "Confident";
		Say = "Alright, let's head out.";
		Reply = "Good, follow me.";
	};

	-- O4: 
	["sot_enterradiostation"] = {
		Face = "Confident";
		Say = "Alright, how do I look?";
		Reply = "Ha! Don't worry about it.";
	};
};

if RunService:IsServer() then
	local modPlayerNpcs = shared.require(game.ReplicatedStorage.Library.PlayerNpcs);
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	-- MARK: Joseph Handler
	Dialogues.Joseph.DialogueHandler = function(player, dialog, data, mission)
		if mission.Type == 2 then -- Available
			dialog:SetInitiateTag("sot_joseph_init");

			dialog:AddChoice({"sot_j1"; "sot_j2"; "sot_j3"; "sot_j4"; "sot_j5"; "sot_j6"; "sot_j7"}, function(dialog)
				modMission:StartMission(player, MISSION_ID);
			end)

		elseif mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 1 then
				dialog:SetInitiateTag("sot_joseph_p1_init");

			end
		end
	end

	-- MARK: Caitlin Handler
	Dialogues.Caitlin.DialogueHandler = function(player, dialog, data, mission)
		local modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);
		if mission.Type == 2 then -- Available
			dialog:AddChoice("sot_lore1a");
			dialog:AddChoice({"sot_lore1b"; "sot_lore2b"});
			dialog:AddChoice({"sot_lore1c"; "sot_lore2c"});

		elseif mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 1 then
					
				local caitlinPlayerNpc: PlayerNpc = modPlayerNpcs.getPlayerNpc(player, "Caitlin");
				if caitlinPlayerNpc and caitlinPlayerNpc.NpcClass then
					caitlinPlayerNpc.NpcClass.Move:Face("Player");
				end

				dialog:SetInitiate("Well? How did it go?", "Confident");

				dialog:AddChoice({"sot_c1";}, function(dialog)
					dialog:SetExpireTime(workspace:GetServerTimeNow() + 5);
					task.wait(5);
					mission.SaveData.TriggerTransmission = true;
				end)

			elseif mission.ProgressionPoint == 2 then
				dialog:SetInitiate("Give me a second..", "Confident");

			elseif mission.ProgressionPoint == 3 then
				dialog:SetInitiate("Alright, I've just talked to them. Whenever you're ready, I'll bring you to them.", "Confident");

				dialog:AddChoice({"sot_headout";}, function(dialog)
					modServerManager:TeleportToPrivateServer(
						"RadioStation", 
						modServerManager:CreatePrivateServer("RadioStation"), 
						{player}
					);
				end)


			elseif mission.ProgressionPoint == 4 then
				dialog:SetInitiate("Here we are, they are inside and ready to speak with you.", "Confident");

				dialog:AddChoice({"sot_enterradiostation";}, function(dialog)
					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint <= 5 then
							mission.ProgressionPoint = 5;
						end
					end)
				end)

			elseif mission.ProgressionPoint == 5 then
				dialog:SetInitiate("Go on in.", "Confident");
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint <= 6 then
						mission.ProgressionPoint = 6;
					end
				end)

			end
		end
	end
end


return Dialogues;