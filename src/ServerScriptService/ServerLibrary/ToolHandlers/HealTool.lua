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
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

local remotes = game.ReplicatedStorage.Remotes;
local bindServerUnequipPlayer = remotes.Inventory.ServerUnequipPlayer;

local ToolHandler = {};
ToolHandler.__index = ToolHandler;
--== Script;

function ToolHandler:ProcessHeal(packet)
	local configurations = self.ToolConfig.Configurations;
	
	local healDamagable = packet.HealDamagable;
	local targetRootPart = packet.TargetRootPart;
	
	healDamagable:TakeDamagePackage(modDamagable.NewDamageSource{
		Damage=configurations.HealAmount;
		Dealer=packet.HealDealer or self.Player;
		ToolStorageItem=self.StorageItem;
		TargetPart=targetRootPart;
		DamageType="Heal";
	});
end

function ToolHandler:OnActionEvent(packet)
	local profile = modProfile:Get(self.Player);
	local actionIndex = packet.ActionIndex;

	local ownerClassPlayer = modPlayers.Get(self.Player);
	
	local targetPlayer = packet.TargetPlayer or self.Player;
	local targetClassPlayer = modPlayers.Get(targetPlayer);
	
	local humanoid = targetClassPlayer.Humanoid;
	if humanoid.Health <= 0 and targetClassPlayer.Properties.Wounded == nil then return end;

	if actionIndex == 1 then
		self.LastFire = tick();

	elseif actionIndex == 2 then

		local configurations = self.ToolConfig.Configurations;
		local useDuration = configurations.UseDuration;

		-- Skill: First Aid Training;
		if ownerClassPlayer.Properties.fiaitr then
			useDuration = useDuration * (100-ownerClassPlayer.Properties.fiaitr.Percent)/100;
		end
		
		if targetClassPlayer.Properties.Wounded then
			useDuration = useDuration *3;
		end
		
		local lapsed = tick() - self.LastFire;
		local inValidTimeRange = lapsed >= useDuration-0.5 and lapsed <= useDuration+0.5;

		if inValidTimeRange then
			if self.StorageItem and self.StorageItem.Quantity <= 0 then Debugger:Warn("Insufficient quantity") return end;

			-- Skill: Meet the Medic;
			local skill = profile.SkillTree:GetSkill(self.Player, "methme");

			if skill and targetPlayer ~= self.Player then
				local level, stats = profile.SkillTree:CalStats(skill.Library, skill.Points);
				local medicMulti = (level > 0 and stats.Percent.Value or 0)/100;
				
				if medicMulti > 0 then
					ownerClassPlayer:TakeDamagePackage(modDamagable.NewDamageSource{
						Damage=(configurations.HealAmount * medicMulti);
						Dealer=self.Player;
						ToolStorageItem=self.StorageItem;
						TargetPart=ownerClassPlayer.RootPart;
						DamageType="Heal";
					});
					
				end
			end
			
			self:ProcessHeal({
				HealDamagable = targetClassPlayer;
				TargetRootPart = targetClassPlayer.RootPart;
			});

			if self.StorageItem.Quantity == 1 then
				bindServerUnequipPlayer:Invoke(self.Player);
			end
			
			local playerSave = profile:GetActiveSave();
			local inventory = profile.ActiveInventory;
			inventory:Remove(self.StorageItem.ID, 1);
			
			local itemLib = modItemsLibrary:Find(self.StorageItem.ItemId);
			shared.Notify(self.Player, ("1 $Item removed from your Inventory."):gsub("$Item", itemLib.Name), "Negative");

		else
			Debugger:Warn("TimeLapsed invalid", inValidTimeRange, "configurations.UseDuration", configurations.UseDuration, "useDuration", useDuration);
		end
	end
		
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

return ToolHandler;
