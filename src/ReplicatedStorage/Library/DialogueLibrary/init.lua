local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local RunService = game:GetService("RunService");

local libMeta = {};
local DialogueLibrary = setmetatable({}, libMeta);
local dialogueModules = {};

DialogueLibrary.Script = script;
DialogueLibrary.Modules = dialogueModules;

function libMeta:__index(name) -- loads if not loaded before
	if dialogueModules[name] then
		local loadMod = require(dialogueModules[name]);
		
		DialogueLibrary[name] = {
			Name=name;
			Initial=loadMod.Initial or {};
			Dialogues=loadMod.Dialogues or {};
			
			UnevaluableAnswers=loadMod.UnevaluableAnswers;
			FortuneAnswers=loadMod.FortuneAnswers;
		};
		
		for a=1, #DialogueLibrary[name].Dialogues do
			DialogueLibrary[name].Dialogues[a].Index = a;
		end
		
		return DialogueLibrary[name];
	end
end

function DialogueLibrary.AddDialogues(name, dialogues, params)
	local lib = DialogueLibrary[name];
	
	for a=1, #dialogues do
		local dialog = dialogues[a];
		if params.MissionId and dialog.MissionId == nil then
			dialog.MissionId = params.MissionId;
		end
		table.insert(lib.Dialogues, dialog);
	end
end

function DialogueLibrary.LoadDialog(npcName, dialogPacket)
	dialogPacket = dialogPacket or {};
	
	local dialoguesLib = DialogueLibrary[npcName];
	if dialoguesLib then
		local initPrompt = dialogPacket.Initial;
		
		if initPrompt then
			if type(initPrompt) == "number" then
				local dialogueData = dialoguesLib.Dialogues[initPrompt];
				
				dialogPacket.Initial = {dialogueData.Reply};
				dialogPacket.AskMe = dialogueData.AskMe;
			end
			
		else
			dialogPacket.Initial = dialoguesLib.Initial;
		end
		
		local choiceTable = dialogPacket.Choices or {};
		
		for a=1, #choiceTable do
			local choice = choiceTable[a];
			if choice.Index then
				choice.Dialogue = dialoguesLib.Dialogues[choice.Index];
			end
		end
		dialogPacket.Choices = choiceTable;
		
	end
	
	return dialogPacket;
end


function DialogueLibrary.GetByTag(name, tag)
	local CharacterDialogues = DialogueLibrary[name];
	if CharacterDialogues and CharacterDialogues.Dialogues then
		for a=1, #CharacterDialogues.Dialogues do
			if CharacterDialogues.Dialogues[a].Tag == tag then
				return DialogueLibrary[name].Dialogues[a], a;
			end
		end
	end
	
	return;
end

function DialogueLibrary.GetDialogues(name)
	return DialogueLibrary[name];
end


for _, mod in pairs(script:GetChildren()) do
	if dialogueModules[mod.Name] then error("DialogueLibrary>>  Npc ("..mod.Name..") already exist."); end;
	dialogueModules[mod.Name] = mod;
end

local modModEngineService = require(game.ReplicatedStorage.Library.ModEngineService);
local moddedSelf = modModEngineService:GetModule(script.Name);
if moddedSelf then moddedSelf:Init(DialogueLibrary); end

return DialogueLibrary;