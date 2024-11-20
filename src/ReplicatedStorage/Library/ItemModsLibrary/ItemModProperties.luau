local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modEntityComponentSystem = require(game.ReplicatedStorage.Library.EntityComponentSystem);
local modModsLibrary = require(game.ReplicatedStorage.Library.ItemModsLibrary);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

local remoteItemModifier = modRemotesManager:Get("ItemModifier");

local modifierSystem = modEntityComponentSystem.newSystem(0.1);
modifierSystem:Update(function(delta, itemModifier)
    if itemModifier.OnUpdate == nil then
        modifierSystem:Remove(itemModifier);
        return;
    end
    
    itemModifier:OnUpdate(delta);
end)


local ClassItemModifier = {};
ClassItemModifier.__index = ClassItemModifier;
ClassItemModifier.ClassName = "ItemModifier";
ClassItemModifier.Library = modModsLibrary;

function ClassItemModifier.new(src)
    local self = {
        Script=src;
        ActivateMod=nil;
        TriggerType=modModsLibrary.TriggerType.None;
    };
    
    self.__index = self;
    setmetatable(self, ClassItemModifier);
    return self;
end

function ClassItemModifier:Instance(storageItem)
    local new = setmetatable({
        Disabled = true;
        StorageItem = storageItem;
    }, self);
    return new;
end

function ClassItemModifier:SetActive(val)
    self.Disabled = val;
    
    if self.OnUpdate then
        if val == true then
            modifierSystem:Add(self);
        else
            modifierSystem:Remove(self);
        end
    end

    if val == true then
        if self.OnActivate then
            self:OnActivate();
        end
    else
        if self.OnDeactivate then
            self:OnDeactivate();
        end
    end
end

function ClassItemModifier:Sync(keys)
    if RunService:IsClient() then return end;

    if self.StorageItem == nil then return end;
    local storageItem = self.StorageItem 

    local player = self.Player or (storageItem and storageItem.Player) or nil;
    if player == nil then Debugger:Log(`ItemModifier missing player to sync.`, self); return end;

    local modifierId = self.Script.Name;

    local syncPacket = {};
    for a=1, #keys do
        syncPacket[keys[a]] = self[keys[a]];
    end
    remoteItemModifier:FireClient(player, modifierId, "sync", syncPacket);
end

return ClassItemModifier;