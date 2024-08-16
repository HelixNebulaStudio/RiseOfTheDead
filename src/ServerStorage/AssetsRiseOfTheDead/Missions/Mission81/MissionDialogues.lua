local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local modDialogueService = require(game.ReplicatedStorage.Library.DialogueService);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modBitFlags = require(game.ReplicatedStorage.Library.BitFlags);

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

local cooperPrefab = workspace.Entity:WaitForChild("Cooper");
local davidPrefab = workspace.Entity:WaitForChild("David");

local checkpointFlags = modBitFlags.new();
checkpointFlags:AddFlag("david_askWalkieTalkie", 1);
checkpointFlags:AddFlag("cooper_betAway", 2);
checkpointFlags:AddFlag("cooper_askWalkie", 3);


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

		if mission.ProgressionPoint == 1 then
			dialog:SetInitiate("I swear if we were scammed by those Rats..", "Suspicious");

		end

	end
end


-- MARK: David Handler
Dialogues.David.DialogueHandler = function(player, dialog, data, mission)
	local saveFlag = mission.SaveData.Flags;

	if mission.Type ~= 1 then return end;
	if mission.ProgressionPoint ~= 1 then return end;

	if checkpointFlags:Test("cooper_askWalkie", saveFlag) then
		dialog:SetInitiate("Cooper has them! And I'm pretty sure he won't give it away.", "Skeptical");
		
		dialog:AddDialog({
			Face="Skeptical";
			Say="...";
			Reply="...";
			
		}, function(dialog)
			mission.SaveData.Flags = checkpointFlags:Set(saveFlag, "david_revealCooperHas", true);
			
			modDialogueService:InvokeDialogue(player, "talk", {
				NpcModel=cooperPrefab;
			});

		end);

	elseif checkpointFlags:Test("david_askWalkieTalkie", saveFlag) == false then
		dialog:SetInitiate("...cheater! How did you win again!..\n*Turns to you* Uggh, what do you want?", "Frustrated");

		dialog:AddDialog({
			Face="Skeptical";
			Say="Ummm, I'm sent by Joseph, here for a box of walkie talkies?";
			Reply="...";
			
		}, function(dialog)
			mission.SaveData.Flags = checkpointFlags:Set(saveFlag, "david_askWalkieTalkie", true);

			Debugger:Warn("David saveFlag", saveFlag);
			dialog:TalkTo(cooperPrefab);

		end);

	else
		dialog:SetInitiate("", "Suspicious");

	end

	dialog:SkipOtherDialogues();
end

-- MARK: Cooper Handler
Dialogues.Cooper.DialogueHandler = function(player, dialog, data, mission)
	local saveFlag = mission.SaveData.Flags;

	if mission.Type ~= 1 then return end;
	if mission.ProgressionPoint ~= 1 then return end;

	Debugger:Warn("Cooper saveFlag", saveFlag);
	if checkpointFlags:Test("david_askWalkieTalkie", saveFlag) then
		dialog:SetInitiate("Box of walkie talkies ey? David over here bet them away earlier!", "Smirk");

		dialog:AddDialog({
			Face="Confident";
			Say="...";
			Reply="...";
			
		}, function(dialog)
			mission.SaveData.Flags = checkpointFlags:Set(saveFlag, "cooper_betAway", true);
			
			dialog:TalkTo(davidPrefab);

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

	dialog:SkipOtherDialogues();
end

return Dialogues;