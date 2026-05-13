local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modNpcProfileLibrary = shared.require(game.ReplicatedStorage.Library.NpcProfileLibrary);
local modDialogueLibrary = shared.require(game.ReplicatedStorage.Library.DialogueLibrary);

local Component = {};
Component.ClassName = "NpcComponent";
Component.__index = Component;

function Component.new(npcClass: NpcClass)
	local self = {
        NpcClass = npcClass;

        NpcLibrary = nil;
        NpcData = nil;
    };
	setmetatable(self, Component);
	return self;
end

function Component:Setup()
    if shared.WorldName ~= "Safehome" then return end;
    local npcClass: NpcClass = self.NpcClass;

    task.spawn(function()
        local player = npcClass.Player;
        if player == nil then Debugger:Log("Missing npc player."); return end;
        
        local profile = shared.modProfile:Get(player);
        local safehomeData = profile.Safehome;
        
        local npcName = npcClass.Name;

        local npcLib = modNpcProfileLibrary:Find(npcName);
        self.NpcLibrary = npcLib;

        local npcData = safehomeData:GetNpc(npcName);
        self.NpcData = npcData;
        
        safehomeData:RefreshStats();
        
        Debugger:Log("load npcData", npcData);

        repeat task.wait(1) until shared.WorldCore.SafehomeClass ~= nil;
        local safehomeClass = shared.WorldCore.SafehomeClass;
        
        if npcData.Active then
            local npcSpotAtt = safehomeClass:GetNpcSpot(npcName);
            npcClass:SetCFrame(npcSpotAtt.WorldCFrame);
            self.SpotAtt = npcSpotAtt;
        end

        npcClass.OnThink:Connect(function()
            self:BindThink();
        end);
    end)
end

function Component:BindThink()
    local npcClass: NpcClass = self.NpcClass;

    local npcName = npcClass.Name;
    local npcLib = self.NpcLibrary;
    local npcData = self.NpcData;
    local spotAtt = self.SpotAtt;

    local rootCf = npcClass:GetCFrame();

    local wieldComp: WieldComp = npcClass.WieldComp;

    if npcData.Level == 0 then --======================= LEVEL 0
        npcData:SetLevel(1);

        npcClass.Move:MoveTo(spotAtt.WorldPosition);
        npcClass.Move.OnMoveToEnded:Wait(15);
        npcClass.Move:Face(rootCf.Position + spotAtt.WorldCFrame.LookVector*100);

        local dialogue = modDialogueLibrary:Get(npcName, "shelter_new");
        if dialogue then
            npcClass.Chat(game.Players:GetPlayers(), dialogue.Reply);
        end
        


    elseif npcData.Level == 2 then --======================= LEVEL 2
    
        if npcLib.Class == "Medic" then
            local unlockTime = npcData.LevelUpTime+60;
            
            if os.time() < unlockTime then
                if not wieldComp.ToolHandler then
                    wieldComp:Equip{ItemId="medkit"};
                    
                    if wieldComp.ToolHandler and wieldComp.ToolHandler.ToolAnimator then
                        wieldComp.ToolHandler.ToolAnimator:Play("Use");
                        npcClass:GetComponent("AvatarFace"):Set("Welp");
                    end
                end
                task.delay(unlockTime-os.time(), function()
                    if wieldComp.ToolHandler then
                        wieldComp:Unequip();
                        npcClass:GetComponent("AvatarFace"):Set();
                    end
                end)
            end
        end
        


    elseif npcData.Level == 3 then --======================= LEVEL 3
        
        if npcLib.Class == "Medic" then
            if wieldComp.ToolHandler then
                wieldComp:Unequip();
            end
            
        end


    end
end

return Component;