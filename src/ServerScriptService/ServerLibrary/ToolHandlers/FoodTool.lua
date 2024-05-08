local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;

--== Modules;
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modTools = require(game.ReplicatedStorage.Library.Tools);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modPlayers = require(game.ReplicatedStorage.Library.Players);

local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);

local remotes = game.ReplicatedStorage.Remotes;
local bindServerUnequipPlayer = remotes.Inventory.ServerUnequipPlayer;

local ToolHandler = {};
ToolHandler.__index = ToolHandler;
--== Script;

function ToolHandler:OnPrimaryFire(...)
	Debugger:Log("OnPrimaryFire ", ...);
	
	local actionIndex = ...;
	local classPlayer = modPlayers.GetByName(self.Player.Name);
	if classPlayer and classPlayer.Humanoid then
		local humanoid = classPlayer.Humanoid;
		
		if humanoid and humanoid.Health > 0 then
			if actionIndex == 1 then
				self.LastFire = tick();
				
			elseif actionIndex == 2 then
				local profile = modProfile:Get(self.Player);
				local playerSave = profile:GetActiveSave();
				local inventory = profile.ActiveInventory;
				profile:AddPlayPoints(3);
				
				local itemLib = modItemsLibrary:Find(self.StorageItem.ItemId);
				local configurations = self.ToolConfig.Configurations;
				
				local useDuration = configurations.UseDuration;
				
				local lapsed = tick() - self.LastFire;
				local inValidTimeRange = lapsed >= useDuration-0.5 and lapsed <= useDuration+0.5;
				
				--if lapsed >= configurations.UseDuration-0.5 and lapsed <= configurations.UseDuration+0.5 then
				if inValidTimeRange then
					if self.StorageItem and self.StorageItem.Quantity <= 0 then return end;
					
					local duration = configurations.EffectDuration;
					
					-- Skill: Efficient Metabolism;
					if classPlayer.Properties.effmet and duration then
						duration = duration * ((classPlayer.Properties.effmet.Percent/100)+1);
					end
					
					if configurations.EffectType == "Heal" then
						classPlayer:SetHealSource(configurations.HealSourceId, {
							Amount=configurations.HealRate;
							ExpiresOnDeath=true;
							Expires=modSyncTime.GetTime()+duration;
							Duration=duration;
						});
						
					elseif configurations.EffectType == "Status" then
						local statusId = typeof(configurations.StatusId) == "table" and configurations.StatusId[math.random(1, #configurations.StatusId)] or configurations.StatusId;
						if modStatusEffects[statusId] then
							modStatusEffects[statusId](self.Player, duration);
						end

					elseif configurations.EffectType == "Perks" then
						
						if playerSave:GetStat("Perks") >= modGlobalVars.MaxPerks then
							shared.Notify(self.Player, "You are too full to eat this. Perks maxed.", "Negative");
							return;
						end

						playerSave:AddStat("Perks", 1000);
					end
					
					if self.StorageItem.Quantity == 1 then
						bindServerUnequipPlayer:Invoke(self.Player);
					end
					inventory:Remove(self.StorageItem.ID, 1);
					shared.Notify(self.Player, ("1 $Item removed from your Inventory."):gsub("$Item", itemLib.Name), "Negative");

				else
					Debugger:Warn("TimeLapsed invalid", inValidTimeRange, "configurations.UseDuration", configurations.UseDuration, "useDuration", useDuration);
					
				end
			end
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
