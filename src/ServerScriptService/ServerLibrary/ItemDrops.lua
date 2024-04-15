local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local CollectionService = game:GetService("CollectionService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modDropRateCalculator = require(game.ReplicatedStorage.Library.DropRateCalculator);
local modDropAppearance = require(game.ReplicatedStorage.Library.DropAppearance);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modRatShopLibrary = require(game.ReplicatedStorage.Library.RatShopLibrary);
local modGoldShopLibrary = require(game.ReplicatedStorage.Library.GoldShopLibrary);
local modGameModeLibrary = require(game.ReplicatedStorage.Library.GameModeLibrary);
local modCrateLibrary = require(game.ReplicatedStorage.Library.CrateLibrary);

--== Variables;
local ItemDrops = {};
ItemDrops.Types = modGlobalVars.ItemDropsTypes;

local _remoteItemDropRemote = modRemotesManager:Get("ItemDropRemote");

local dropPrefabs = game.ServerStorage.PrefabStorage.ItemDrops;
local itemPrefabs = game.ReplicatedStorage.Prefabs.Items;
local random = Random.new();

--== Script;
function ItemDrops.Info(itemId, isFullSearch)
	local itemLib = modItemsLibrary:Find(itemId);
	if itemLib == nil then Debugger:Log("Could not find itemlib for",itemId); return end;
	
	local r = {};
	local sourceText = {};
	local srcTable = {};
	
	if itemLib.Sources then
		for a=1, #itemLib.Sources do
			table.insert(sourceText, itemLib.Sources[a]);
		end
	end
	
	local shopIndexedList = modRatShopLibrary.Products:GetIndexList();
	for a=1, #shopIndexedList do
		if shopIndexedList[a].Id == itemId then
			srcTable.RatShop = {
				Price=shopIndexedList[a].Price;
				Currency=shopIndexedList[a].Currency;
				PremiumOnly=shopIndexedList[a].PremiumOnly == true;
			}
			
			table.insert(sourceText, (("Shop - $Price $Currency $PremiumOnly")
				:gsub("$Price", shopIndexedList[a].Price)
				:gsub("$Currency", shopIndexedList[a].Currency)
				:gsub("$PremiumOnly", shopIndexedList[a].PremiumOnly == true and "(Premium)" or "")
				));
		end
	end
	for key, _ in pairs(modGoldShopLibrary.Products.Library) do
		local lib = modGoldShopLibrary.Products.Library[key];
		if lib and lib.Product and lib.Product.ItemId == itemId then
			
			if (lib.IgnoreScan ~= true or isFullSearch == true) and lib.NotForSale ~= true then
				srcTable.GoldShop = {
					Type=lib.Product.Type;
					Price=lib.Product.Price;
				}
			end
			
			if lib.Trader then
				if lib.Trader.Buy and lib.Trader.Sell then
					srcTable.Trader = "Purchasable and sellable from <b>The Wandering Trader</b>";
				elseif lib.Trader.Buy then
					srcTable.Trader = "Purchasable from <b>The Wandering Trader</b>";
				elseif lib.Trader.Sell then
					srcTable.Trader = "Can be sold to <b>The Wandering Trader</b>";
				end
				if lib.Trader.Buy then
					table.insert(sourceText, srcTable.Trader);
				end
			end
			
			table.insert(sourceText, "Gold Shop - ".. (lib.Product.Price or "Price") .. " " ..(lib.Product.Type or "Currency") ); 
		end
	end

	local rewardSrcs = {};
	
	local function searchDrops(dropId , forId)
		local gameMode, stageName;
		for gm, _ in pairs(modGameModeLibrary.GameModes) do
			for sn, _ in pairs(modGameModeLibrary.GameModes[gm].Stages) do
				local stageLib = modGameModeLibrary.GameModes[gm].Stages[sn];

				if stageLib.RewardsId == dropId then
					gameMode, stageName = gm, sn;
					if gameMode then break; end;
				elseif stageLib.RewardsIds then
					for a=1, #stageLib.RewardsIds do
						if stageLib.RewardsIds[a] == dropId then
							gameMode, stageName = gm, sn;
							if gameMode then break; end;
						end
					end
				end

			end
			if gameMode then break; end;
		end
		if gameMode and stageName then
			table.insert(rewardSrcs, {GameMode=gameMode; StageName=stageName;})
		end
		
		local existTable = {};
		local indexedRewardsList = modRewardsLibrary:GetIndexList();
		for i=1, #indexedRewardsList do
			local lib = indexedRewardsList[i];
			local rewardId = lib.Id;
			
			if lib.IgnoreScan == true and isFullSearch ~= true then Debugger:Log("ignore rewardId", rewardId); continue end;
			
			local rewards = lib.Rewards;
			for a=1, #rewards do
				
				if rewards[a] and (rewards[a].ItemId == dropId or rewards[a].Type == dropId) then
					local groups = modDropRateCalculator.Calculate(lib, {HardMode=true});
					local dropRate = "Unknown";
					for a=1, #groups do
						local chance = 0;
						for b=1, #groups[a] do
							local rewardInfo = groups[a][b];
							chance = chance + rewardInfo.Chance;
							if rewardInfo.ItemId == dropId or rewardInfo.Type == dropId then
								dropRate = rewardInfo.Weekday or (math.ceil((rewardInfo.Chance/groups[a].TotalChance)*100000)/1000 .."%");
								break;
							end
						end
					end								

					if lib.Hidden == true then
						table.insert(sourceText, "From Mystery Chest");

					else
						if existTable[lib.Id] == nil then
							existTable[lib.Id] = true;
							table.insert(rewardSrcs, {RewardId=lib.Id; Chance=dropRate; SpecialEvent=lib.SpecialEvent;});
						end
						local eventHint = "";
						if lib.SpecialEvent then
							eventHint = "<b>"..lib.SpecialEvent..":</b>  ";
						end
						table.insert(sourceText, (
							((forId and "For "..forId.." > " or "").."Drop - $DropId ("..dropRate..")")
							:gsub("$DropId", lib.Name and lib.Name.."("..eventHint..lib.Id..")" or eventHint..lib.Id)
							));
					end
				end
			end
		end
	end
	
	local modBlueprintLibrary = Debugger:Require(game.ReplicatedStorage.Library.BlueprintLibrary);
	modBlueprintLibrary:Loop(function(key, lib)
		if lib.Product == itemId then
			srcTable.Blueprint = lib.Id;
			table.insert(sourceText, (("Blueprint - $Name ($ItemId)"):gsub("$Name", lib.Name):gsub("$ItemId", lib.Id)) );
			searchDrops(lib.Id, lib.Name);
		end
	end)
	searchDrops(itemId);
	
	if #rewardSrcs > 0 then
		for a=1, #rewardSrcs do
			if rewardSrcs[a].RewardId then
				for _, lib in pairs(modCrateLibrary.Library) do
					if lib.RewardsId == rewardSrcs[a].RewardId then
						rewardSrcs[a] = {CrateId=lib.Id;}
						break;
					end
				end
			end
		end
		
		srcTable.RewardSrcs = rewardSrcs;
	end
	r.SourceText = sourceText;
	r.SourceTable = srcTable;
	
	return r;
end

function ItemDrops.Spawn(itemDrop, cframe, whitelist, despawnTime)
	if modConfigurations.DisableItemDrops then warn("ItemDrops>> DisableItemDrops is enabled."); return end;
	
	local prefabName = itemDrop.Type or itemDrop.ItemId;
	local newPrefab: Model = dropPrefabs:FindFirstChild(prefabName);
	
	if itemDrop.Type == "Tool" and itemDrop.ItemId and newPrefab == nil then
		local modTools = require(game.ReplicatedStorage.Library.Tools);
		local toolLib = modTools[itemDrop.ItemId];
		if toolLib and toolLib.Prefab then
			newPrefab = toolLib.Prefab;
		end
	end
	
	if newPrefab == nil and itemDrop.ItemId then
		newPrefab = dropPrefabs.Custom;
		itemDrop.Type = "Custom";
	end
	if newPrefab == nil then Debugger:Warn("Couldn't find item prefab for (",prefabName,")"); return end;
	
	newPrefab = newPrefab:Clone();
	newPrefab:AddTag("ItemDrop");
	
	for a=1, 60 do if newPrefab.PrimaryPart then break; else task.wait() end end;
	local primaryPart = newPrefab.PrimaryPart;
	for _, obj in pairs(primaryPart:GetDescendants()) do
		if not obj:IsA("BasePart") then continue end;
		obj.CanCollide = false;
		obj.CanQuery = false;
	end
	
	local newItemPrefab: Model;
	local offset = Vector3.new(0, 0, 0);

	local itemLib = modItemsLibrary:Find(itemDrop.ItemId);
	if itemDrop.Type == "Tool" or itemDrop.Type == "Food" then
		if itemDrop.ItemId == nil then Debugger:Error("Tool drop item id missing (",itemDrop,")"); return end;
		
		local setPrefabColor = nil;
		local prefabObject = itemPrefabs:FindFirstChild(itemDrop.ItemId);
		if prefabObject == nil then
			Debugger:Warn("Couldn't find tool prefab for (",itemDrop.ItemId,")");
			
			if itemLib.CraftFor then
				prefabObject = itemPrefabs:FindFirstChild(itemLib.CraftFor);
				
				local modWorkbenchLibrary = require(game.ReplicatedStorage.Library.WorkbenchLibrary);
				local wbInfo = modWorkbenchLibrary.ItemUpgrades[itemLib.CraftFor];
				local weaponTier = wbInfo.Tier or 1;
				local tierColor = modItemsLibrary.TierColors[weaponTier];
				
				setPrefabColor = tierColor;
			end
			
			if prefabObject == nil then return end;
		end;
		
		newItemPrefab = prefabObject:Clone();
		assert(newItemPrefab.PrimaryPart, "PrefabObject likely missing default PrimaryPart.");
		
		newItemPrefab.PrimaryPart.Anchored = true;
		newItemPrefab:PivotTo(primaryPart.CFrame);
		newItemPrefab.Parent = primaryPart;
		
		if setPrefabColor then
			local h,s = setPrefabColor:ToHSV();
			local color = Color3.fromHSV(h, s, 1);
			task.spawn(function()
				for _, obj in pairs(newItemPrefab:GetDescendants()) do
					if obj:IsA("BasePart") then
						obj.Material = Enum.Material.SmoothPlastic;
						obj.Color = color;
					end
				end
			end)
			local newHighlight = Instance.new("Highlight");
			newHighlight.OutlineColor = Color3.fromRGB(255, 255, 255);
			newHighlight.FillColor = color;
			newHighlight.FillTransparency = 0;
			newHighlight.DepthMode = Enum.HighlightDepthMode.Occluded;
			task.delay(0.1, function()
				newHighlight.Parent = newItemPrefab;
			end)
		end
		
		newItemPrefab:SetAttribute("InteractableParent", true);
		primaryPart:SetAttribute("InteractableParent", true);

		offset = Vector3.new(0, newItemPrefab:GetExtentsSize().Y/2, 0);
		
	elseif itemDrop.Type == "Crate" then
		offset = Vector3.new(0, 1, 0);
		
	elseif itemDrop.Type == "Custom" then
		primaryPart = newPrefab:WaitForChild("Base");
		
		local itemIconLabel = newPrefab:WaitForChild("BillboardGui"):WaitForChild("ItemIcon");
		itemIconLabel.Image = itemLib.Icon;
	else
		offset = Vector3.new(0, 0.2, 0);
		
	end
	
	if primaryPart.CanCollide then
		primaryPart.CollisionGroup = "Debris";
	end
	
	newPrefab:PivotTo(CFrame.new(cframe.p) + offset);
	newPrefab.Name = itemDrop.ItemId or newPrefab.Name;
	
	CollectionService:AddTag(newPrefab, "ItemDrop");
	
	local deathTimer = 60;
	
	local prefabModule = newPrefab:WaitForChild("Interactable");
	local interactData = require(prefabModule);
	interactData.Script = prefabModule;
	
	if itemDrop.OnceOnly then
		local tag = Instance.new("BoolValue");
		tag.Name = "OnceOnly";
		tag.Parent = prefabModule;
	end
	
	if itemDrop.SharedDrop == false then
		interactData.SharedDrop = false;
	end
	
	newPrefab.Destroying:Connect(function()
		interactData:Destroy();
	end)

	if despawnTime ~= false then
		Debugger.Expire(newPrefab, tonumber(despawnTime) or 60);
	end
	
	if itemDrop.StorageItem then
		itemDrop.Quantity = itemDrop.StorageItem.Quantity;
	end
	prefabModule:SetAttribute("Quantity", itemDrop.Quantity or 1);
	interactData.ItemId = itemDrop.ItemId or interactData.ItemId;
	interactData.StorageItem = itemDrop.StorageItem;
	interactData.Quantity = itemDrop.Quantity or 1;
	
	if itemDrop.Values then
		interactData.ItemValues = itemDrop.Values;
	end
	
	interactData.OnPickUp = function(player)
		local players = game.Players:GetPlayers();
		deathTimer = deathTimer-(60/#players);
		if despawnTime ~= false and deathTimer <= 0 then
			newPrefab:Destroy();
		end
	end;
	if whitelist then
		whitelist = type(whitelist) ~= "table" and {whitelist} or whitelist;
		
		interactData.Whitelist = {};
		for a=1, #whitelist do
			interactData.Whitelist[whitelist[a].Name] = true;
		end
	end
	
	local rewardsLib = modRewardsLibrary:Find(itemDrop.ItemId);
	if rewardsLib and rewardsLib.Level then
		interactData.LevelRequired = rewardsLib.Level;
	end
	
	local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	if itemDrop.Type == ItemDrops.Types.Blueprint then
		local owners = {};
		for _, player in pairs(game.Players:GetPlayers()) do
			if modMission:IsComplete(player, 5) then
				table.insert(owners, player);
			end
		end
		modReplicationManager.ReplicateIn(owners, newPrefab, workspace.Interactables);
		
	elseif itemDrop.Type == ItemDrops.Types.Tool then

		if whitelist then
			modReplicationManager.ReplicateIn(whitelist, newPrefab, workspace.Interactables);
			
		else
			local owners = {};
			for _, player in pairs(game.Players:GetPlayers()) do
				if itemDrop.OnceOnly then
					local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
					local item = modStorage.FindItemIdFromStorages(itemDrop.ItemId, player);
					if modMission:IsComplete(player, 5) and item == nil then
						table.insert(owners, player);
					end
				else
					table.insert(owners, player);

				end
			end
			modReplicationManager.ReplicateIn(owners, newPrefab, workspace.Interactables);
			
		end
		
	else
		if whitelist then
			modReplicationManager.ReplicateIn(whitelist, newPrefab, workspace.Interactables);
		else
			newPrefab.Parent = workspace.Interactables;
		end
	end

	if itemDrop.Type ~= "Custom" then
		
		local dropAppearanceLib = modDropAppearance:Find(itemDrop.ItemId);
		if dropAppearanceLib then
			local body = newItemPrefab or newPrefab;

			if itemDrop.Type == "Crate" then
				assert(newPrefab.PrimaryPart);
				body = newPrefab.PrimaryPart:WaitForChild("Body");
				
			end

			if newItemPrefab then
				newItemPrefab:PivotTo(primaryPart.CFrame * dropAppearanceLib.Offset);
				
				if dropAppearanceLib.Scale then
					local scale = dropAppearanceLib.Scale/(newItemPrefab:GetExtentsSize().Magnitude);
					modGlobalVars.ScaleModel(newItemPrefab, scale);
				end
			end

			modDropAppearance.ApplyAppearance(dropAppearanceLib, body);
			
			local dropParticle = newPrefab:FindFirstChild("DropGlow", true);
			if dropParticle and dropAppearanceLib.GlowImageSize then
				pcall(function()
					dropParticle.Glow.Size = dropAppearanceLib.GlowImageSize;
					dropParticle.Rays.Size = dropAppearanceLib.GlowImageSize;
				end)
			end
		end
	end
	
	--if not primaryPart.Anchored then
	--	primaryPart.Anchored = true;
		
	--	Debugger:Log("Sim projectile")
	--	local projectile = {};
	--	projectile.Prefab = primaryPart;
		
	--	modProjectile.Simulate(projectile, primaryPart.Position, Vector3.new(), {workspace.Environment})
	--end
	
	interactData:Sync();
	return newPrefab, interactData;
end

function ItemDrops.ChooseDrop(rewardsLib)
	local rewards = modDropRateCalculator.RollDrop(rewardsLib);
	local winner = #rewards > 0 and rewards[1] or nil;
	if winner == nil then return end;
	
	return {
		ItemId=winner.ItemId;
		Type=winner.Type;
		Quantity=(winner.Quantity and (type(winner.Quantity) ~= "table" and winner.Quantity or random:NextInteger(winner.Quantity.Min, winner.Quantity.Max)) or 1);
		OnceOnly=winner.OnceOnly;
		Values=winner.Values;
		Chance=rewards.Chance;
	};
end

return ItemDrops;