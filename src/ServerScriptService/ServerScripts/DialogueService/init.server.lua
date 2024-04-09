local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
repeat task.wait() until shared.MasterScriptInit == true;

--== Variables;
local modDialogueLibrary = require(game.ReplicatedStorage.Library.DialogueLibrary);

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modMissionLibrary = require(game.ReplicatedStorage.Library.MissionLibrary);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modAssetHandler = require(game.ReplicatedStorage.Library.AssetHandler);

local modDialogues = require(game.ServerScriptService.ServerLibrary.DialogueSave);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);

local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
--local remoteSelectDialogue = remotes.Dialogue.SelectDialogue;

local bindOnTalkedTo = game.ReplicatedStorage.Remotes.Dialogue.OnTalkedTo;
local remoteDialogueHandler = modRemotesManager:Get("DialogueHandler");

local random = Random.new();
local Logic = {};
local MissionDialogueModules = {};

--== Script;
function OnDialogue(player, npcModel, npcName, choice)
	npcName = npcName or "nilName";
	local activeDialogues = modDialogues:Get(player);
	local npcDialogData = activeDialogues and activeDialogues:Get(npcName) or nil;
	
	if modDialogueLibrary.GetDialogues(npcName) == nil then Debugger:Warn("Player ("..player.Name..") Npc dialogues does not exist ("..npcName..")."); return end;
	local npcPrefab = npcModel;
	if npcPrefab == nil then Debugger:Warn("Player ("..player.Name..") Attempt to dialogue with non-existing npc ("..npcName..")."); return end;
	if npcPrefab.PrimaryPart == nil and npcPrefab:FindFirstChild("HumanoidRootPart") then npcPrefab.PrimaryPart = npcPrefab.HumanoidRootPart end;
	local function checkInRange()
		if player == nil then return end;
		if shared.modAntiCheatService:GetLastTeleport(player) <= 3 then
			return false;
		end;
		
		return true;
		
	end
	
	if Logic[npcName] == nil and script:FindFirstChild(npcName) then
		Logic[npcName] = require(script[npcName]);
		
		MissionDialogueModules[npcName] = {};
		for _, module in pairs(script[npcName]:GetChildren()) do
			if module.ClassName == "ModuleScript" then
				MissionDialogueModules[npcName][module.Name] = require(module);
			end
		end
	end
	
	if npcDialogData == nil and Logic[npcName] then
		npcDialogData = activeDialogues.new(npcName);
		npcDialogData.ChoiceHandleData = {};
		
		npcDialogData.Invoke = function(choice)
			local dialog = {};
			dialog.Name = npcName;
			dialog.Prefab = npcPrefab;
			dialog.Choices = {};
			dialog.InRange = checkInRange;

			local npcStatus = npcPrefab:FindFirstChild("NpcStatus") and require(npcPrefab.NpcStatus) or nil;
			
			function dialog:GetNpcModule()
				local npcModule = npcStatus and npcStatus:GetModule();
				return npcModule;
			end
			
			function dialog:AddChoice(tag, func, data)
				local choiceData, choiceIndex = modDialogueLibrary.GetByTag(npcName, tag);
				
				local exist = false;
				for a=1, #dialog.Choices do
					if dialog.Choices[a].Index == choiceIndex then
						exist = true;
						break;
					end;
				end
				if not exist then
					local choiceInfo = {Index=choiceIndex; Data=data; Func=func;}
					table.insert(dialog.Choices, choiceInfo);
					npcDialogData.ChoiceHandleData[#dialog.Choices] = choiceInfo;
				end;
			end
			
			function dialog:AddDialog(dialogue, func, data)
				local choiceInfo = {Dialogue=dialogue; Data=data; Func=func;};
				table.insert(dialog.Choices, choiceInfo);
				npcDialogData.ChoiceHandleData[#dialog.Choices] = choiceInfo;
			end
			
			function dialog:SetExpireTime(t)
				dialog.ExpireTime = t;
			end
			
			function dialog:SetInitiate(str, face)
				dialog.Initial = str;
				
				local npcModule = npcStatus and npcStatus:GetModule();
				if face and npcModule.AvatarFace then
					npcModule.AvatarFace:DialogSet(face, player);
				end
			end
			
			function dialog:SetInitiateTag(tag)
				local choiceData, choiceIndex = modDialogueLibrary.GetByTag(npcName, tag);
				
				dialog.Initial = choiceIndex;
				
				local npcModule = npcStatus and npcStatus:GetModule();
				if choiceData.Face and npcModule and npcModule.AvatarFace then
					npcModule.AvatarFace:DialogSet(choiceData.Face, player);
				end
			end
			
			if choice ~= nil then
				if npcDialogData.ChoiceHandleData[choice] then
					local choiceInfo = npcDialogData.ChoiceHandleData[choice];
					
					local data = choiceInfo and choiceInfo.Data;
					
					local unlockTime = data and data.ChoiceUnlockTime and (data.ChoiceUnlockTime-modSyncTime.GetTime())
					
					if unlockTime == nil or unlockTime <= 0 then
						if choiceInfo.Func then
							
							dialog.Player = player;
							dialog.NpcDialogData = npcDialogData;
							
							choiceInfo.Func(dialog);
							choiceInfo.Func = nil;
						end
					else
						Debugger:Warn("Dialogue (",choice,") is currently locked for", player)
					end
				end
				
			else
				local missionProfile = modMission.GetMissions(player.Name);
				if missionProfile then
					for a=1, #missionProfile do
						local missionData = missionProfile[a];
						local missionLib = missionData and modMissionLibrary.Get(missionData.Id);
						
						local missionDialogueFunc = missionLib and MissionDialogueModules[npcName][missionLib.Name];
						if missionDialogueFunc then
							missionDialogueFunc(player, dialog, npcDialogData, missionData);
							
						elseif missionLib.UseAssets == true then
							local missionAssets = modAssetHandler:Get("Mission"..tostring(missionData.Id));
							
							if missionAssets and missionAssets:FindFirstChild("MissionDialogues") then
								local missionDialogues = require(missionAssets.MissionDialogues);
								local missionDialogueFunc = missionDialogues[npcName] and missionDialogues[npcName].DialogueHandler;
								
								if missionDialogueFunc then
									missionDialogueFunc(player, dialog, npcDialogData, missionData);
								end
							end
						end
					end
				end
				
				Logic[npcName](player, dialog, npcDialogData);
			end
			
			return dialog;
		end
	end;
	
	bindOnTalkedTo:Fire(npcPrefab, player, choice);
	if npcDialogData then
		return npcDialogData.Invoke(choice);
	end
end

--remoteSelectDialogue.OnServerInvoke = OnDialogue;

--remoteNpcDialogue.OnServerEvent:Connect(function(player, npcModel, cmd)
--	if npcModel == nil then Debugger:Log("Missing npcmodel.") return end;
--	if npcModel:FindFirstChild("NpcStatus") == nil then return end;
--	local npcStatus = require(npcModel.NpcStatus);
--	local npcModule = npcStatus:GetModule();
	
--	if cmd == "close" and npcModule.AvatarFace then
--		npcModule.AvatarFace:DialogSet(nil, player);
--	end
--end)


-- !outline: OnDialogueHandler(player, action, packet)
function OnDialogueHandler(player, action, packet)
	
	-- "close", {NpcName=NpcName;}
	-- "converse", {NpcName=NpcName; SelectTag=data.Tag;}
	
	if action == "close" then
		local npcModel = packet.NpcModel;
		if npcModel == nil then return end;
		if npcModel:FindFirstChild("NpcStatus") == nil then return end;
		
		local npcStatus = require(npcModel.NpcStatus);
		local npcModule = npcStatus:GetModule();

		if npcModule.AvatarFace then
			npcModule.AvatarFace:DialogSet(nil, player);
		end
		bindOnTalkedTo:Fire(npcModel, player, "close");
		
	elseif action == "oldconverse" then
		return OnDialogue(player, packet.NpcModel, packet.NpcName, packet.SelectIndex);
		
	elseif action == "talk" then
		
		local npcModel = packet.NpcModel;
		local npcName = npcModel.Name;
		
		local dialogPacket = OnDialogue(player, npcModel, npcName);
		
		task.spawn(function()
			remoteDialogueHandler:InvokeClient(player, "talk", dialogPacket);
		end)
	end;
	
end

shared.OnDialogueHandler = OnDialogueHandler;
remoteDialogueHandler.OnServerInvoke = OnDialogueHandler;