local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModsLibrary = require(game.ReplicatedStorage.Library.ItemModsLibrary);
local modItemModifierClass = require(game.ReplicatedStorage.Library.ItemModifierClass);
local modConfigVariable = require(game.ReplicatedStorage.Library.ConfigVariable);

local EquipmentClass = {};
EquipmentClass.__index = EquipmentClass;
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

function EquipmentClass:ApplyModifiers(storageItem)
    if storageItem == nil then return end;
    
    local siid = storageItem.ID;
    local configurations = self.Configurations;

    local attachmentStorage;
    local player;

    if RunService:IsClient() then
        player = game.Players.LocalPlayer;
        local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
        attachmentStorage = modData.GetItemStorage(siid);

    else
        player = storageItem.Player;

        if player then
            local profile = shared.modProfile:Get(player);
            local playerSave = profile:GetActiveSave();
            attachmentStorage = playerSave.Storages[siid];
        end
    end

    local function updateModifier(itemModifier, index, itemModStorageItem)
        itemModifier.Priority = index or itemModifier.Priority;

        itemModifier.EquipmentClass = self;
        itemModifier.EquipmentStorageItem = storageItem;
        itemModifier.ItemModStorageItem = itemModStorageItem;

        if itemModifier.Attach and itemModifier.IsAttached == false then
            itemModifier.IsAttached = nil;
            itemModifier:Attach();
        end
        if itemModifier.Update then
            itemModifier:Update();
        end
    end

    if player then
        local playerClass: PlayerClass = shared.modPlayers.Get(player);
        local playerModifierList = {};
        for _, playerModifier in pairs(playerClass.Configurations.Modifiers) do
            if playerModifier.IsEquipmentModifier ~= true then continue end;
            table.insert(playerModifierList, playerModifier);
        end

        if #playerModifierList > 0 then
            local modifiedValues = modConfigVariable.calculate(playerModifierList);

            local playerEquipmentModifierId = `playerEquipmentModifier`;
            local itemModifier = shared.modPlayerEquipment.getItemModifier(playerEquipmentModifierId, player);
            if itemModifier == nil then
                itemModifier = modConfigVariable.newModifier(playerEquipmentModifierId, 999);
                configurations:AddModifier(itemModifier, false);
                shared.modPlayerEquipment.setItemModifier(playerEquipmentModifierId, itemModifier, player);
            end

            for k, v in pairs(modifiedValues.AddValues) do
                itemModifier.AddValues[k] = v;
            end

            for k, v in pairs(modifiedValues.SetValues) do
                itemModifier.SetValues[k] = v;
            end

        end
    end

    if self.BaseModifiers then
        for modifierName, config in pairs(self.BaseModifiers) do
            local baseItemModifier = config.BaseItemModifier;
            local modifierId = `{siid}:{modifierName}`;
    
            local itemModifier = shared.modPlayerEquipment.getItemModifier(modifierId, player);
            if itemModifier == nil then
                itemModifier = baseItemModifier:Instance(modifierId);

                for k, v in pairs(config.AddValues) do
                    itemModifier.AddValues[k] = v;
                end
                for k, v in pairs(config.SetValues) do
                    itemModifier.SetValues[k] = v;
                end
            end
    
            configurations:AddModifier(itemModifier, false);
            shared.modPlayerEquipment.setItemModifier(modifierId, itemModifier, player);
    
            updateModifier(itemModifier);
        end
    end

    if attachmentStorage == nil or next(attachmentStorage.Container) == nil then return end;
    
    local updatedModifiers = {};

	for _, itemModStorageItem in pairs(attachmentStorage.Container) do
        local index = itemModStorageItem.Index;
		local modLib = modItemModsLibrary.Get(itemModStorageItem.ItemId);
        if modLib.Module == nil then continue end;

        local baseItemModifier = require(modLib.Module);
        if baseItemModifier == nil then continue end;

        local itemModifier = shared.modPlayerEquipment.getItemModifier(itemModStorageItem.ID, player);
        if itemModifier == nil then
            itemModifier = baseItemModifier:Instance(itemModStorageItem.ID, modLib);
            itemModifier.Player = player;
            itemModifier.IsItemMod = true;

            configurations:AddModifier(itemModifier, false);
            
            shared.modPlayerEquipment.setItemModifier(itemModStorageItem.ID, itemModifier, player);
        end

        updateModifier(itemModifier, index, itemModStorageItem);

        updatedModifiers[itemModStorageItem.ID] = itemModifier;
    end

    for a=1, #configurations.Modifiers do
        local itemModifier = configurations.Modifiers[a];
        if itemModifier.IsItemMod == nil or updatedModifiers[itemModifier.Id] then continue end;

        if itemModifier.Detach and itemModifier.IsAttached == nil then
            itemModifier.IsAttached = false;
            itemModifier:Detach();
        end
        configurations:RemoveModifier(itemModifier, false);
    end
end

function EquipmentClass:AddModifier(modifierId, config)
    local modifierScript = modItemModifierClass.Script:FindFirstChild(modifierId);
    local baseItemModifier = modifierScript and require(modifierScript) or nil;
    if baseItemModifier == nil then return end;

    if self.BaseModifiers == nil then
        self.BaseModifiers = {};
    end

    config = config or {};
    config.AddValues = config.AddValues or {};
    config.SetValues = config.SetValues or {};
    config.BaseItemModifier = baseItemModifier;

    self.BaseModifiers[modifierId] = config;
end

function EquipmentClass:Init(super)
    local function loadModified(m: ModuleScript)
        if not m:IsA("ModuleScript") or m.Name == "Template" then return end;

        local superScript = super.Script;
        local baseEquipmentClassScript = superScript:FindFirstChild(m.Name);
        if baseEquipmentClassScript then
            baseEquipmentClassScript:Destroy();
        end

        m.Parent = superScript;
    end

	for _, m in pairs(script:GetChildren()) do
        loadModified(m);
	end
	script.ChildAdded:Connect(loadModified);


    -- @Hook
    super.AddModifier = EquipmentClass.AddModifier;
    super.ApplyModifiers = EquipmentClass.ApplyModifiers;
    super.ProcessModifiers = EquipmentClass.ProcessModifiers;

    -- @Override
    function super:Update(storageItem)
        if self[self.Class] then
            self[self.Class]:Update(self, storageItem);
        end

        self:ApplyModifiers(storageItem);

        self.Configurations:Calculate();
    end
end

return EquipmentClass;