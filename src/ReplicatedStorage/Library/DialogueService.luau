local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modDialogueLibrary = require(game.ReplicatedStorage.Library.DialogueLibrary);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modMissionLibrary = require(game.ReplicatedStorage.Library.MissionLibrary);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modAssetHandler = require(game.ReplicatedStorage.Library.AssetHandler);
local modLazyLoader = require(game.ReplicatedStorage.Library.LazyLoader);


local DialogueService = {
    Handlers = {};
};
--==

function DialogueService:InitServer(baseDialogueHandlers)
    if RunService:IsClient() then return end;

    local modDialogues = require(game.ServerScriptService.ServerLibrary.DialogueSave);
    local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

    local bindOnTalkedTo = game.ReplicatedStorage.Remotes.Dialogue.OnTalkedTo;
    local remoteDialogueHandler = modRemotesManager:Get("DialogueHandler");

    --== Script;
    local function OnDialogue(player, npcModel, npcName, choiceTag)
        local profile = shared.modProfile:Get(player);
        if profile then
            profile:AddPlayPoints(3, "Gameplay:Dialogue");
        end

        npcName = npcName or "nilName";
        local activeDialogues = modDialogues:Get(player);
        local npcDialogData = activeDialogues and activeDialogues:Get(npcName) or nil;
        
        local npcPrefab = npcModel;
        if npcPrefab == nil then Debugger:Warn("Player ("..player.Name..") Attempt to dialogue with non-existing npc ("..npcName..")."); return end;
        
        local function checkInRange()
            if player == nil then return end;
            if shared.modAntiCheatService:GetLastTeleport(player) <= 3 then
                return false;
            end;
            
            return true;
        end
        
        -- if DialogueService.Handlers[npcName] == nil and modDialogueHandlers.Script:FindFirstChild(npcName) then
        --     local npcDialogueHandler = modDialogueHandlers.Script[npcName];

        --     DialogueService.Handlers[npcName] = require(npcDialogueHandler);

        --     MissionDialogueModules[npcName] = {};
        --     for _, module in pairs(npcDialogueHandler:GetChildren()) do
        --         if module.ClassName ~= "ModuleScript" then continue end;
                
        --         MissionDialogueModules[npcName][module.Name] = require(module);
        --     end
        -- end

        -- if DialogueService.Handlers[npcName] == nil and baseDialogueHandlers:FindFirstChild(npcName) then
        --     DialogueService.Handlers[npcName] = require(baseDialogueHandlers[npcName]);
            
        --     MissionDialogueModules[npcName] = {};
        --     for _, module in pairs(baseDialogueHandlers[npcName]:GetChildren()) do
        --         if module.ClassName == "ModuleScript" then
        --             MissionDialogueModules[npcName][module.Name] = require(module);
        --         end
        --     end
        -- end
        
        if npcDialogData == nil then
            npcDialogData = activeDialogues.new(npcName);
            npcDialogData.ChoiceHandleData = {};
            
            local lambda = 0;
            local orderCount = 1;
            npcDialogData.Reset = function()
                lambda = 0;
                orderCount = 1;
                table.clear(npcDialogData.ChoiceHandleData);
            end

            npcDialogData.Invoke = function(choiceTag)
                local dialog = {}; -- Sent to client;
                dialog.Player = player;
                dialog.Name = npcName;
                dialog.Prefab = npcPrefab;
                dialog.InRange = checkInRange;

                dialog.Choices = {};

                local npcStatus = npcPrefab:FindFirstChild("NpcStatus") and require(npcPrefab.NpcStatus) or nil;
                
                function dialog:GetNpcModule()
                    local npcModule = npcStatus and npcStatus:GetModule();
                    return npcModule;
                end
                
                function dialog:SetExpireTime(t)
                    dialog.ExpireTime = t;
                end

                function dialog:InteractRequest(interactableModule, obj)
                    local remoteInteractionUpdate = modRemotesManager:Get("InteractionUpdate");
                    remoteInteractionUpdate:FireClient(player, interactableModule, obj, "interact")
                end

                function dialog:AddDialog(dialoguePacket, func, data)
                    lambda = lambda +1;
                    local tag = dialoguePacket.Tag or `tag{lambda}`;

                    local choiceInfo = table.clone(dialoguePacket);
                    choiceInfo.Data = data;
                    choiceInfo.Func = func;
                    choiceInfo.Order = orderCount
                    orderCount = orderCount + 1;

                    dialog.Choices[tag] = choiceInfo;
                    npcDialogData.ChoiceHandleData[tag] = choiceInfo;
                end

                function dialog:AddChoice(tag, func, data)
                    local dialoguePacket = modDialogueLibrary:Get(npcName, tag);
                    dialoguePacket.Tag = tag;
                    self:AddDialog(dialoguePacket, func, data);
                end
                
                function dialog:InitDialog(dialoguePacket)
                    dialog.InitReply = dialoguePacket.Reply;

                    local npcModule = self:GetNpcModule();
                    if npcModule and npcModule.AvatarFace then
                        if dialoguePacket.Face then
                            npcModule.AvatarFace:DialogSet(dialoguePacket.Face, player);
                        end
                    end
                end

                function dialog:SetInitiate(text, face)
                    self:InitDialog({
                        Face=face;
                        Reply=text;
                    });
                end
                
                function dialog:SetInitiateTag(tag)
                    local dialoguePacket = modDialogueLibrary:Get(npcName, tag);
                    self:InitDialog(dialoguePacket);
                end
                
                local choiceInfo = choiceTag and npcDialogData.ChoiceHandleData[choiceTag];
                if choiceInfo then  -- MARK: client choice
                    npcDialogData:Reset();

                    local data = choiceInfo and choiceInfo.Data;
                    local unlockTime = data and data.ChoiceUnlockTime and (data.ChoiceUnlockTime-modSyncTime.GetTime())
                    
                    if unlockTime and unlockTime > -0.3 then
                        Debugger:Warn("Dialogue (",choiceTag,") is currently locked for", player);
                        return;
                    end
                    
                    if choiceInfo.Func then
                        choiceInfo.Func(dialog);
                        choiceInfo.Func = nil;
                    end
                    
                    if choiceInfo.ReturnToInit ~= true then
                        return dialog;
                    end
                end
                
                -- MARK: On Dialogue Initiate;
                npcDialogData:Reset();
                local initDialoguePacket = nil;

                -- Mission dialogues;
                local missionProfile = modMission.GetMissions(player.Name);
                if missionProfile then
                    for a=1, #missionProfile do
                        local missionData = missionProfile[a];
                        local missionId = missionData.Id;
                        local missionLib = missionData and modMissionLibrary.Get(missionId);

                        if missionLib.DialogueScript then
                            local missionDialogues = require(missionLib.DialogueScript);
                            local npcDialogueResources = missionDialogues[npcName];
                            if npcDialogueResources == nil then continue end;

                            if npcDialogueResources.DialogueStrings then
                                for tag, dialoguePacket in pairs(npcDialogueResources.DialogueStrings) do
                                    dialoguePacket.MissionId = missionId;
                                    modDialogueLibrary:Load(npcName, tag, dialoguePacket);
                                end
                            end

                            if npcDialogueResources.DialogueHandler then
                                npcDialogueResources.DialogueHandler(player, dialog, npcDialogData, missionData);
                            end
                        end
                    end
                end


                -- Base dialogues;
                local baseDialoguesScript = modAssetHandler:GetServer(`Npc/{npcName}/Dialogues`);
                if baseDialoguesScript then
                    local dialogueResources = require(baseDialoguesScript);
                    
                    local initReplies = {};
                    for _, dialoguePacket in pairs(dialogueResources.InitStrings) do
                        table.insert(initReplies, dialoguePacket);
                    end
                    initDialoguePacket = initReplies[math.random(1, #initReplies)];

                    for tag, dialoguePacket in pairs(dialogueResources.DialogueStrings) do
                        modDialogueLibrary:Load(npcName, tag, dialoguePacket);
                    end

                    if dialogueResources.DialogueHandler then
                        dialogueResources.DialogueHandler(player, dialog, npcDialogData);
                    end
                end


                if dialog.InitReply == nil and initDialoguePacket then
                    dialog:InitDialog(initDialoguePacket);
                end

                return dialog;
            end
        end;
        
        bindOnTalkedTo:Fire(npcPrefab, player, choiceTag);
        return npcDialogData.Invoke(choiceTag);
    end

    -- MARK: OnDialogueHandler(player, action, packet)
    local function OnDialogueHandler(player, action, packet)
        
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
            
        elseif action == "dialogue" then
            return OnDialogue(player, packet.NpcModel, packet.NpcName, packet.ChoiceTag);

        elseif action == "talk" then
            
            local npcModel = packet.NpcModel;
            local npcName = npcModel.Name;
            
            local dialogPacket = OnDialogue(player, npcModel, npcName);
            
            task.spawn(function()
                remoteDialogueHandler:InvokeClient(player, "talk", dialogPacket);
            end)
        end;
        
        return;
    end

    remoteDialogueHandler.OnServerInvoke = OnDialogueHandler;

    function DialogueService:InvokeDialogue(...)
        return OnDialogueHandler(...);
    end
end

function DialogueService:LoadHandlers(dialogues)
    for npcName, npcData in pairs(dialogues) do
        local dialogueHandlerFunc = npcData.DialogueHandler;
        
        DialogueService.Handlers[npcName] = dialogueHandlerFunc;
    end
end

return DialogueService;