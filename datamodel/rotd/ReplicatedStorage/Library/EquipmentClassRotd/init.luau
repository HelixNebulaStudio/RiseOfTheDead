local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModsLibrary = shared.require(game.ReplicatedStorage.Library.ItemModsLibrary);
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);
local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);

local EquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

function EquipmentClass:ProcessModifiers(processType, ...)
    local modifiersList = self.Configurations.Modifiers;

    for a=1, #modifiersList do
        local modifier = modifiersList[a];
        
		if modifier[processType] then
			modifier[processType](modifier, ...);
		end
    end
end

function EquipmentClass:ApplyModifiers(storageItem: StorageItem)
    if storageItem == nil then return end;
    
    local updatedModifiers = {};

    local siid = storageItem.ID;
    local configurations = self.Configurations;

    local attachmentStorage: Storage;
    local player: Player;

    if RunService:IsClient() then
        player = game.Players.LocalPlayer;
        local modData = shared.require(player:WaitForChild("DataModule") :: ModuleScript);
        attachmentStorage = modData.GetItemStorage(siid);

    else
        player = storageItem.Player;

        if player then
            local profile = shared.modProfile:Get(player);
            local playerSave = profile:GetActiveSave();
            attachmentStorage = playerSave.Storages[siid];
        end
    end

    local function getOrDefaultModifier(modifierId, defaultFunc)
        if player == nil then return end;

        local itemModifier: ItemModifierInstance = shared.modPlayerEquipment.getItemModifier(modifierId, player);
        if itemModifier == nil then
            itemModifier = defaultFunc();
        end
        if itemModifier == nil then return end;

        shared.modPlayerEquipment.setItemModifier(modifierId, itemModifier, player);

        return itemModifier;
    end

    -- MARK: PlayerClass modifiers
    if player then
        local playerClass: PlayerClass = shared.modPlayers.get(player);
        for _, playerModifier: ConfigModifier in pairs(playerClass.Configurations.Modifiers) do
            if playerModifier.Tags[`{self.Class}ExternalEquip`] == nil then continue end;

            configurations:AddModifier(playerModifier, false);
            updatedModifiers[playerModifier.Id] = playerModifier;
        end
    end

    -- MARK: EquipmentClass BaseModifiers
    if self.BaseModifiers then
        for modifierName, config in pairs(self.BaseModifiers) do
            local baseItemModifier = config.BaseItemModifier;
            local modifierId = `{siid}:{modifierName}`;
    
            local itemModifier = getOrDefaultModifier(modifierId, function()
                local newModifier: ItemModifierInstance = baseItemModifier:Instance(modifierId);
                newModifier.Tags.Base = true;

                for k, v in pairs(config.SetValues) do newModifier.SetValues[k] = v; end
                for k, v in pairs(config.SumValues) do newModifier.SumValues[k] = v; end
                for k, v in pairs(config.ProductValues) do newModifier.ProductValues[k] = v; end
                for k, v in pairs(config.MaxValues) do newModifier.MaxValues[k] = v; end
                for k, v in pairs(config.MinValues) do newModifier.MinValues[k] = v; end

                return newModifier;
            end)

            if itemModifier then
                configurations:AddModifier(itemModifier, false);
                updatedModifiers[itemModifier.Id] = itemModifier;
            end
        end
    end

    -- MARK: Attached ItemMods;
    if attachmentStorage and next(attachmentStorage.Container) then
        for _, itemModStorageItem in pairs(attachmentStorage.Container) do
            local index = itemModStorageItem.Index;
            local modLib = modItemModsLibrary.Get(itemModStorageItem.ItemId);
            if modLib.Module == nil then continue end;
    
            local baseItemModifier = shared.require(modLib.Module);
            if baseItemModifier == nil then continue end;
    
            local itemModifier = getOrDefaultModifier(itemModStorageItem.ID, function()
                local newModifier = baseItemModifier:Instance(itemModStorageItem.ID, modLib);
                
                newModifier.Player = player;
                newModifier.Tags.ItemMod = true;
                newModifier.Tags[self.Class] = true;
                
                return newModifier;
            end)

            if itemModifier then
                itemModifier.EquipmentClass = self;
                itemModifier.EquipmentStorageItem = storageItem;
                itemModifier.ItemModStorageItem = itemModStorageItem;
                itemModifier.Priority = modLib.Layer or index or itemModifier.Priority;

                configurations:AddModifier(itemModifier, false);
                updatedModifiers[itemModifier.Id] = itemModifier;
            end
        end
    end
    
    -- MARK: Detach/Update modifiers;
    for a=1, #configurations.Modifiers do
        local itemModifier: ItemModifierInstance = configurations.Modifiers[a];
        if itemModifier == nil then continue end;

        if updatedModifiers[itemModifier.Id] ~= nil or itemModifier.Tags.Base then
            if itemModifier.Update then
                itemModifier:Update();
            end
        else
            configurations:RemoveModifier(itemModifier.Id, false);
        end
    end
end

function EquipmentClass:AddModifier(modifierId: string, config)
    local modifierScript = modItemModifierClass.Script:FindFirstChild(modifierId);
    local baseItemModifier = modifierScript and require(modifierScript) or nil;
    if baseItemModifier == nil then return end;

    if self.BaseModifiers == nil then
        self.BaseModifiers = {};
    end

    config = config or {};
    config.SetValues = config.SetValues or {};
    config.SumValues = config.SumValues or {};
    config.ProductValues = config.ProductValues or {};
    config.MaxValues = config.MaxValues or {};
    config.MinValues = config.MinValues or {};
    config.BaseItemModifier = baseItemModifier;

    self.BaseModifiers[modifierId] = config;
end

function EquipmentClass:GetClassAsModifier(siid: string, configModifier: ConfigModifier?)
    if configModifier == nil then
        configModifier = self.Configurations.newModifier(siid);
    end
    if configModifier == nil then return end;

    modTables.ReplaceValues(configModifier.BaseValues, self.Configurations.BaseValues);

    return configModifier;
end

local EQUIPMENTCLASS_UPDATE = EquipmentClass.Update;
function EquipmentClass:Update(storageItem: StorageItem)
    EQUIPMENTCLASS_UPDATE(self, storageItem);

    self:ApplyModifiers(storageItem);
end

function EquipmentClass:Init()
    local function loadModified(m: ModuleScript)
        if not m:IsA("ModuleScript") or m.Name == "Template" then return end;

        local baseEquipmentClassScript = EquipmentClass.Script:FindFirstChild(m.Name);
        if baseEquipmentClassScript then
            baseEquipmentClassScript:Destroy();
        end

        m.Parent = EquipmentClass.Script;
    end

	for _, m in pairs(script:GetChildren()) do
        loadModified(m);
	end
	script.ChildAdded:Connect(loadModified);
end

return EquipmentClass;