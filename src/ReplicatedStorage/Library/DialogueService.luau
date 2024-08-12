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
    local function OnDialogue(player, npcModel, npcName, packet)
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
        
        if npcDialogData == nil then
            npcDialogData = activeDialogues.new(npcName);
        end

        if npcDialogData.Invoke == nil then
            npcDialogData.ChoiceHandleData = {};
            
            local lambda = 0;
            local orderCount = 10;
            npcDialogData.Reset = function()
                lambda = 0;
                orderCount = 10;
                table.clear(npcDialogData.ChoiceHandleData);
            end

            npcDialogData.Invoke = function(packet)
                local choiceTag = packet.ChoiceTag;
                
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
                    if dialoguePacket == nil then
                        Debugger:WarnClient(player, `Missing {npcName} dialogue with tag ({tag}).`);
                        return;
                    end

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
                    if dialoguePacket == nil then
                        Debugger:WarnClient(player, `Missing {npcName} dialogue with tag ({tag}).`);
                        return;
                    end
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

                -- MARK: UserPrompt;
                if packet.UserPrompt then
                    local userPrompt = packet.UserPrompt;
                    Debugger:Warn("UserPrompted(",player.Name,") to (",npcName,"):", userPrompt);

                    local promptProfile = nil;
                    if baseDialoguesScript then
                        local dialogueResources = require(baseDialoguesScript);
                        promptProfile = dialogueResources.PromptProfile;

                        if dialogueResources.PromptHandler then
                            dialogueResources.PromptHandler(player, dialog, npcDialogData, userPrompt);
                        end
                    end

                    local canQueryLLM = RunService:IsStudio();
                    local approvedUserIds = {
                        16170943;
                        3295490081;
                        86976526;
                        32911077;
                        117392244;
                        99496471;
                    };
                    if promptProfile then
                        for a=1, #approvedUserIds do
                            if approvedUserIds[a] == player.UserId then
                                canQueryLLM = true;
                                Debugger:Warn(player,"is allowed to query npc.");
    
                                local DataStoreService = game:GetService("DataStoreService");
                                local dataStore = DataStoreService:GetDataStore("LLMQuery");
                                local newVal = dataStore:IncrementAsync(tostring(player.UserId), nil, {player.UserId});
                                
                                if newVal < 99 then
                                    shared.Notify(player, `AI NPC query quota: {100-newVal}/100`, "Inform");
                                else
                                    canQueryLLM = false;
                                    shared.Notify(player, "No more quotas for AI NPC query.", "Negative");
                                end
                                
                                break;
                            end
                        end
                    end

                    if promptProfile and canQueryLLM then
                        local modLLMService = require(game.ServerScriptService.ServerLibrary.LLMService);
                        if npcDialogData.PromptChain == nil then
                            npcDialogData.PromptChain = modLLMService.InitPrompt(npcName, promptProfile);
                        end
                        
                        npcDialogData.PromptChain = npcDialogData.PromptChain..`\n$PlayerName:{userPrompt}`;
    
                        local llmResponse = modLLMService.Query(npcDialogData.PromptChain);
                        local npcResponded = false;
                        local suggestedRespond = 0;

                        for k, v in string.gmatch(llmResponse, `([$%w]+):.-"(.-)"`) do
                            if k == "$Me" then
                                dialog:SetInitiate(v);
                                npcDialogData.PromptChain = npcDialogData.PromptChain..`\n$Me:{v}`;
                                Debugger:Warn("PromptResponse(",npcName,"):",v);
                                npcResponded = true;
    
                            elseif tonumber(k) and npcResponded then
                                dialog:AddDialog({
                                    Say=v;
                                    Reply=`*thinking...*`;
                                }, nil, {
                                    Order=tonumber(k);
                                    UserPrompt=true;
                                });
                                suggestedRespond = suggestedRespond +1;

                            end
                        end
                        Debugger:StudioLog("Npc response:", npcResponded, {llmResponse});

                        dialog.ExpireTime = nil;
                    end

                end

                if dialog.InitReply == nil and initDialoguePacket then
                    dialog:InitDialog(initDialoguePacket);
                end

                return dialog;
            end
        end;
        
        bindOnTalkedTo:Fire(npcPrefab, player); -- , packet.ChoiceTag
        return npcDialogData.Invoke(packet);
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
            return OnDialogue(player, packet.NpcModel, packet.NpcName, {ChoiceTag=packet.SelectIndex});
            
        elseif action == "dialogue" then
            return OnDialogue(player, packet.NpcModel, packet.NpcName, {ChoiceTag=packet.ChoiceTag});

        elseif action == "talk" then
            
            local npcModel = packet.NpcModel;
            local npcName = npcModel.Name;
            
            local dialogPacket = OnDialogue(player, npcModel, npcName);
            
            task.spawn(function()
                remoteDialogueHandler:InvokeClient(player, "talk", dialogPacket);
            end)

        elseif action == "userprompt" then
            return OnDialogue(player, packet.NpcModel, packet.NpcName, {
                UserPrompt=packet.UserPrompt;
            });

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