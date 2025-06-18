local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

--==
local UsablePreset = shared.require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();

function UsablePreset:ClientUse(storageItem)
	modClientGuis.toggleWindow("DisguiseKit", true, storageItem);
end

function UsablePreset:ClientInit()
	local localPlayer = game.Players.LocalPlayer;

	CollectionService:GetInstanceAddedSignal("DisguiseObject"):Connect(function(object)
		if localPlayer.Character == nil then return end;
		if not localPlayer.Character:IsAncestorOf(object) then return end;
		object.CanCollide = true;
	end)
end


--== MARK: Server
if RunService:IsClient() then return UsablePreset; end;

function UsablePreset:ServerInit()
	local modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);
	local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
	local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
	local modDisguiseMechanics = shared.require(game.ReplicatedStorage.Library.DisguiseMechanics);

	local remoteDisguiseKitRemote = modRemotesManager:Get("DisguiseKitRemote");

	function remoteDisguiseKitRemote.OnServerInvoke(player, id, action, disguiseId)
		local profile = shared.modProfile:Get(player);
		local activeSave = profile:GetActiveSave();
		local storageItem, storage = shared.modStorage.FindIdFromStorages(id, player);
		
		local traderProfile = profile and profile.Trader;
		
		if storageItem == nil then Debugger:Warn("StorageItem(",id,") does not exist."); return end;
		local disguiseLib = modDisguiseMechanics.Library:Find(disguiseId);
		
		if storageItem.ItemId ~= "disguisekit" then
			Debugger:Warn("Invalid disguisekit.");
			return;
		end
		
		if action == "open" then
			local playerKills = activeSave and activeSave.GetStat and activeSave:GetStat("Kills");
			if playerKills then
				local userId = player.UserId;
				local kills = storageItem:GetValues("InitKills");

				if kills == nil then
					storageItem:SetValues("InitKills", playerKills);
					
				else -- cap kills
					local kCount = math.clamp(playerKills-kills, 0, 5000);
					storageItem:SetValues("InitKills", playerKills-kCount);
					
				end

				storageItem:SetValues("UserId", userId);
				storageItem:Sync({"InitKills"});
			end
			return;

		elseif disguiseLib and action == "disguise" then
			if modBranchConfigs.IsWorld("Slaughterfest") then
				Debugger:Warn("Can't manual disguise in Slaughterfest");
				return;
			end
			
			local disguises = storageItem:GetValues("Disguises") or {};
			
			if disguises[disguiseId] or disguiseLib.Price == nil then
				modDisguiseMechanics:Disguise(player, disguiseId);
			else
				Debugger:Warn("Failed to disguise, not yet unlocked.", disguiseId);
			end
			
		elseif disguiseLib and disguiseLib.Price and (action == "purchaseKills" or action == "purchaseGold") then
			local disguises = storageItem:GetValues("Disguises") or {};
			
			if action == "purchaseKills" then
				local playerKills = activeSave and activeSave.GetStat and activeSave:GetStat("Kills");
				local initKills = storageItem:GetValues("InitKills");
				
				if initKills and (playerKills-initKills)>= disguiseLib.Price then
					if disguises[disguiseId] == nil then
						disguises[disguiseId] = 1;
						
						initKills = initKills + disguiseLib.Price;
						
						storageItem:SetValues("Disguises", disguises);
						storageItem:SetValues("InitKills", initKills);

						storageItem:Sync({"Disguises"; "InitKills"});

						return 1;
					else
						return 2;
					end
					
				else
					return 3;
				end
				
			elseif action == "purchaseGold" then
				local playerGold = traderProfile.Gold;

				if playerGold >= disguiseLib.Price then
					if disguises[disguiseId] == nil then
						disguises[disguiseId] = 1;
						
						storageItem:SetValues("Disguises", disguises);
						storageItem:Sync({"Disguises"; "InitKills"});

						traderProfile:AddGold(-disguiseLib.Price);

						modAnalyticsService:Sink{
							Player=player;
							Currency=modAnalyticsService.Currency.Gold;
							Amount=disguiseLib.Price;
							EndBalance=traderProfile.Gold;
							ItemSKU=`Unlock:disguisekit`;
						};

						return 1;
					else
						return 2;
					end
				else
					return 3;
				end
			end
			
		end

		return;
	end

end

return UsablePreset;