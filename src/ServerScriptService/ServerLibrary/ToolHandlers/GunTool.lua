local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;

--== Modules;
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modTools = require(game.ReplicatedStorage.Library.Tools);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modModsLibrary = Debugger:Require(game.ReplicatedStorage.Library.ModsLibrary);

local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);

local ToolHandler = {};
ToolHandler.__index = ToolHandler;
--== Script;

function ToolHandler:OnPrimaryFire(...)

end

function ToolHandler.new(player, storageItem, toolPackage, toolModels)
	local self = {
		Player = player;
		StorageItem = storageItem;
		Prefabs = toolModels;
		ToolPackage = toolPackage;
		
		LastFire = nil;
	};
	self.ToolConfig = toolPackage.NewToolLib(self);

	if storageItem and storageItem.MockItem then
		self.MockItem = true;
	end

	setmetatable(self, ToolHandler);
	return self;
end

function ToolHandler:KeyToggleSpecial(inputData)
	local player = self.Player;
	local weaponStorageItemID = self.StorageItem.ID;
	local modInfo = inputData.PrimaryEffectMod
	if modInfo == nil then return end;
	
	local storageItemModID = modInfo.StorageItemID;
	
	
	local storageOfWeapon = modStorage.Get(weaponStorageItemID, player);
	local storageItemOfMod = storageOfWeapon and storageOfWeapon:Find(storageItemModID) or nil;
	
	if storageItemOfMod == nil then 
		Debugger:Warn("Mod(",storageItemModID,") does not belong to triggered weapon(", weaponStorageItemID,").") 
		return
	end;
	
	--local profile = shared.modProfile:Get(player);
	--local toolModule = profile:GetItemClass(weaponStorageItemID);

	local modLib = modModsLibrary.Get(storageItemOfMod.ItemId);
	if modLib == nil then return end;
	
	if modLib.EffectTrigger == modModsLibrary.EffectTrigger.Activate then
		local activationDuration = modLib.ActivationDuration;
		local cooldownDuration = modLib.CooldownDuration;

		local activationTime = storageOfWeapon:GetValues(storageItemModID, "AT") or 0;
		local lastActiveTime = activationTime + activationDuration;

		local unixTime = DateTime.now().UnixTimestamp;

		if unixTime >= (lastActiveTime + cooldownDuration) then
			storageOfWeapon:SetValues(storageItemModID, {AT=unixTime;});
			
			local modsModule = modLib:GetModule()
			if modsModule.OnActivate then
				modsModule.OnActivate(self);
			end
		else
			--storageOfWeapon:SyncItem(storageItemModID);
			storageItemOfMod:Sync();
			
			Debugger:Warn("Active or on cooldown.", (lastActiveTime + cooldownDuration) - unixTime);
			
		end
		
	elseif modLib.EffectTrigger == modModsLibrary.EffectTrigger.Trigger then
		
	end
end

function ToolHandler:OnInputEvent(inputData)
	if inputData.InputType ~= "Begin" then return end;
	
	for keyId, _ in pairs(inputData.KeyIds) do
		if self[keyId] then
			self[keyId](self, inputData);
		end
	end
end

return ToolHandler;
