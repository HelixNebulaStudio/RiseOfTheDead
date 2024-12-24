local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;
local CollectionService = game:GetService("CollectionService");

--== Modules;
local modTools = require(game.ReplicatedStorage.Library.Tools);
local modGarbageHandler = require(game.ReplicatedStorage.Library.GarbageHandler);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modBlueprintLibrary = require(game.ReplicatedStorage.Library.BlueprintLibrary);

local modPlannerInterface = require(game.ReplicatedStorage.BaseLibrary.InterfaceModule.PlannerInterface);

local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);

local remoteEngineersPlanner = modRemotesManager:Get("EngineersPlanner");

local plannerLibrary = modPlannerInterface.PlannerLibrary;


local plansFolder = Instance.new("Folder");
plansFolder.Name = "EngineersPlans";
plansFolder.Parent = game.ReplicatedStorage;


local ToolHandler = {};
ToolHandler.__index = ToolHandler;
--== Script;

function ToolHandler:OnPrimaryFire(isActive, ...)
	if typeof(self.Player) == "Instance" and self.Player:IsA("Player") then
		self.Character = self.Player.Character;
	end
	
	local character = self.Character;
	local humanoid = character and character:FindFirstChild("Humanoid");
	
	if humanoid and humanoid.Health > 0 then
		if self.ToolConfig.OnPrimaryFire then
			self.ToolConfig.OnPrimaryFire(self, isActive, ...);
		end
	end
end

function ToolHandler:OnSecondaryFire(...)
	if typeof(self.Player) == "Instance" and self.Player:IsA("Player") then
		self.Character = self.Player.Character;
	end
	
	local character = self.Character;
	local humanoid = character and character:FindFirstChild("Humanoid");
	
	if humanoid and humanoid.Health > 0 then
		if self.ToolConfig.OnSecondaryFire then
			self.ToolConfig.OnSecondaryFire(self, ...);
		end
	end
end

function ToolHandler:OnToolEquip(toolModule)
	if self.ToolConfig.OnEquip then
		self.ToolConfig.OnEquip(self);
	end
end

function ToolHandler:OnToolUnequip()
	if self.ToolConfig.OnUnequip then
		self.ToolConfig.OnUnequip(self);
	end
	
	if self.Garbage then
		self.Garbage:Destruct();
	end
end

function ToolHandler:OnInputEvent(inputData)
	if typeof(self.Player) == "Instance" and self.Player:IsA("Player") then
		self.Character = self.Player.Character;
	end
	
	local character = self.Character;
	local humanoid = character and character:FindFirstChild("Humanoid");
	
	if humanoid and humanoid.Health > 0 then
		if self.ToolConfig.OnInputEvent then
			self.ToolConfig.OnInputEvent(self, inputData);
		end
	end
end

function ToolHandler.new(player, storageItem, toolLib, toolModels)
	local self = {
		Player = player;
		StorageItem = storageItem;
		ToolLib = toolLib;
		Prefabs = toolModels;
		ToolConfig = toolLib.NewToolLib();
		Garbage = modGarbageHandler.new();
	};

	if typeof(player) == "Instance" and player:IsA("Player") then
		self.Character = player.Character;
	end
	
	if storageItem and storageItem.MockItem then
		self.MockItem = true;
	end
	
	setmetatable(self, ToolHandler);
	return self;
end

function remoteEngineersPlanner.OnServerInvoke(player, storageItem, action, ...)
	local profile = modProfile:Get(player);
	local inventory = profile.ActiveInventory;
	storageItem = inventory:Find(storageItem.ID);
	if storageItem == nil then Debugger:Warn("Missing storageItem") return end;
	
	local handler = profile:GetToolHandler(storageItem);
	
	local returnPacket = {};
	
	if action == "unlock" then
		local selectItemId = ...;
		
		Debugger:Warn("Unlock selectItemId", selectItemId);
		if plannerLibrary[selectItemId] == nil then
			Debugger:Warn("Invalid selected item", selectItemId);
			return returnPacket;
		end
		local bpLib = modBlueprintLibrary.Get(selectItemId.."bp");
		if bpLib == nil then Debugger:Warn("No bp") return returnPacket; end;

		local total, itemList = inventory:ListQuantity(bpLib.Id, 1);
		
		if total <= 0 then
			shared.Notify(player, "You do not have any "..bpLib.Name..".", "Negative");
			return returnPacket;
		end;
		
		for a=1, #itemList do
			inventory:Remove(itemList[a].ID, itemList[a].Quantity);
			shared.Notify(player, bpLib.Name.." removed from your Inventory.", "Negative");
		end
		
		local unlocked = storageItem.Values.Unlocked;
		if storageItem.Values.Unlocked == nil then
			unlocked = {};
		end
		unlocked[selectItemId] = true;
		

		local rechargeTime = bpLib.PlannerRechargeTime or 60;
		local charges = storageItem.Values.Charges;
		if storageItem.Values.Charges == nil then
			charges = {};
		end
		charges[selectItemId] = workspace:GetServerTimeNow()-rechargeTime;
		
		storageItem:SetValues("Unlocked", unlocked);
		storageItem:SetValues("Charges", charges);
		storageItem:Sync({"Unlocked"; "Charges"});
		
		returnPacket.Success = true;
		returnPacket.Values = storageItem.Values;
		
		return returnPacket;
		
		
	elseif action == "place" then
		local selectItemId = ...;
		Debugger:Warn("Place selectItemId", selectItemId);

		local unlocked = storageItem.Values.Unlocked;
		local isUnlocked = unlocked and unlocked[selectItemId];
		if isUnlocked ~= true then Debugger:Warn("Is not unlocked", selectItemId) return end;
		
		local itemLib = modItemsLibrary:Find(selectItemId);
		local bpLib = modBlueprintLibrary.Get(selectItemId.."bp");
		
		local toolInfo = modTools[selectItemId];
		local toolConfig = toolInfo.NewToolLib();

		local prefabsItems = game.ReplicatedStorage.Prefabs.Items;
		local prefab = typeof(toolConfig.Prefab) == "string" and prefabsItems[toolConfig.Prefab] or toolConfig.Prefab;
		local prefabSize = prefab:GetExtentsSize();
		
		local placementHighlight;
		
		local function createHighlight()
			placementHighlight = prefab:Clone();
			placementHighlight.PrimaryPart.Anchored = true;
			
			for _, obj in pairs(placementHighlight:GetDescendants()) do
				if obj:IsA("Decal") or obj:IsA("Texture") then
					obj:Destroy();
				end
			end
			for _, obj in pairs(placementHighlight:GetDescendants()) do
				if obj:IsA("BasePart") and obj.Transparency ~= 1 then
					if obj.ClassName == "MeshPart" then
						obj.TextureID = "";
					end
					local surfApp = obj:FindFirstChildWhichIsA("SurfaceAppearance");
					if surfApp then
						surfApp:Destroy();
					end
					obj.Transparency = (obj.Name == "Hitbox" or obj.Name == "Collider") and 1 or 0.5;
					obj.Color = Color3.fromRGB(128, 183, 255);
					obj.CanCollide = false;
				end
			end
		end
		createHighlight();
		
		
		local character = player.Character;
		local rootPart = character.PrimaryPart;
		local origin = character.PrimaryPart.CFrame.p + character.PrimaryPart.CFrame.LookVector*2.5;
		local ray = Ray.new(origin, Vector3.new(0, -8, 0));
		local hit, pos = workspace:FindPartOnRayWithWhitelist(ray, {workspace.Environment; workspace.Terrain});

		if hit then
			local placeCFrame = CFrame.new(pos) * rootPart.CFrame.Rotation * toolConfig.PlaceOffset;
			
			local includeList = CollectionService:GetTagged("EngineersPlans");
			table.insert(includeList, workspace.Interactables);

			if toolConfig.BuildAvoidTags then
				for _, tag in pairs(toolConfig.BuildAvoidTags) do
					local taggedList = CollectionService:GetTagged(tag);
					for a=1, #taggedList do
						table.insert(includeList, taggedList[a]);
					end
				end
			end

			local overlapParams = OverlapParams.new();
			overlapParams.FilterType = Enum.RaycastFilterType.Include;
			overlapParams.FilterDescendantsInstances = includeList;
			overlapParams.MaxParts = 1;

			local placeSpacing = toolConfig.PlaceSpacing or Vector3.new(0.2, 4, 0.2);
			local hits = workspace:GetPartBoundsInBox(placeCFrame, prefabSize + placeSpacing, overlapParams)

			if #hits > 0 then
				shared.Notify(player, "Could not place "..itemLib.Name..", try again.", "Negative");
				return
			end;

			local plannerInfo = plannerLibrary[selectItemId];
			local charges = storageItem.Values.Charges;
			
			local liveTime = workspace:GetServerTimeNow();
			local rechargeTime = bpLib.PlannerRechargeTime or 60;
			local maxChargeTime = liveTime-plannerInfo.MaxCharges*rechargeTime;
			local amtCharge = math.clamp(math.floor((liveTime-charges[selectItemId])/rechargeTime), 0, plannerInfo.MaxCharges);

			if amtCharge <= 0 then
				shared.Notify(player, "Not charges for "..itemLib.Name..".", "Negative");
				return
			end;
			
			amtCharge = amtCharge -1;

			charges[selectItemId] = liveTime - rechargeTime*amtCharge;
			storageItem:SetValues("Charges", charges);
			storageItem:Sync({"Charges"});

			returnPacket.Success = true;
			
			
			local newPlansRenderer = script:WaitForChild("PlansRenderer"):Clone();
			newPlansRenderer.Parent = placementHighlight;
			
			placementHighlight:PivotTo(placeCFrame);
			placementHighlight:SetAttribute("EngineersPlans", true);
			placementHighlight:SetAttribute("Owner", player.Name);
			placementHighlight:SetAttribute("ItemId", selectItemId);
			placementHighlight:AddTag("EngineersPlans")
			placementHighlight.Parent = plansFolder;
			
			newPlansRenderer.Enabled = true;
			
			
		else
			shared.Notify(player, "Could not place "..itemLib.Name..", try again.", "Negative");
		end
		
		
	elseif action == "remove" then
		
		local planModel = ...;
		Debugger:Warn("Remove planModel", planModel);

		if planModel:GetAttribute("EngineersPlans") == nil then
			return;
		end
		if planModel:GetAttribute("Debounce") then return end;
		planModel:SetAttribute("Debounce", true);
		
		local planItemId = planModel:GetAttribute("ItemId");
		
		planModel:Destroy();
		
		local plannerInfo = plannerLibrary[planItemId];
		local charges = storageItem.Values.Charges;

		local liveTime = workspace:GetServerTimeNow();
		local rechargeTime = 60;
		local maxChargeTime = liveTime-plannerInfo.MaxCharges*rechargeTime;
		local amtCharge = math.clamp(math.floor((liveTime-charges[planItemId])/rechargeTime), 0, plannerInfo.MaxCharges);

		amtCharge = math.clamp(amtCharge +1, 0, plannerInfo.MaxCharges);

		charges[planItemId] = liveTime - rechargeTime*amtCharge;
		storageItem:SetValues("Charges", charges);
		storageItem:Sync({"Charges"});
	
	elseif action == "build" then
		local planModel = ...;
		Debugger:Warn("build planModel", planModel);

		local placeCFrame = planModel:GetPivot();
		local planItemId = planModel:GetAttribute("ItemId");
		
		if planModel:GetAttribute("EngineersPlans") == nil then
			return;
		end
		
		local bpItemId = planItemId.."bp";
		
		local fulfillment = modBlueprintLibrary.CheckBlueprintFulfilment(player, bpItemId);
		if fulfillment == nil then
			shared.Notify(player, "Insufficient resources.", "Negative");
			return;
		end
		for _, r in pairs(fulfillment) do
			if not r.Fulfilled then
				shared.Notify(player, "Insufficient resources.", "Negative");
				return;
			end;
		end;
		

		if planModel:GetAttribute("Debounce") then return end;
		planModel:SetAttribute("Debounce", true);
		planModel:Destroy();
		
		local profile = modProfile:Get(player);
		local playerSave = profile:GetActiveSave();
		--local function consumeRequirements(fulfillment)
		--	for _, r in pairs(fulfillment) do
		--		r.Amount = r.Amount or 1;
		--		if r.Type == "Stat" and r.Name ~= "Level" then
		--			if r.Name == "Money" then
		--				shared.Notify(player, ("-$Amount."):gsub("$Amount", "$"..r.Amount), "Negative");
		--			else
		--				shared.Notify(player, ("-$Amount $Stat."):gsub("$Amount", r.Amount):gsub("$Stat", r.Name), "Negative");
		--			end
		--			playerSave:AddStat(r.Name, -r.Amount);

		--			if r.Name == "Perks" and r.Name == "Money" then
		--				modAnalytics.RecordResource(player.UserId, r.Amount, "Sink", r.Name, "Gameplay", "Build");
		--			end

		--		elseif r.Type == "Item" then
		--			local itemLib = modItemsLibrary:Find(r.ItemId);
		--			local storageItem = inventory:FindByItemId(r.ItemId);
		--			if storageItem then
		--				inventory:Remove(storageItem.ID, r.Amount);
		--				shared.Notify(player, ("$Amount$Item removed from your Inventory."):gsub("$Item", itemLib.Name):gsub("$Amount", r.Amount > 1 and r.Amount.." " or ""), "Negative");
		--			end
		--		end
		--	end
		--end
		--consumeRequirements(fulfillment);

		local toolInfo = modTools[planItemId];
		local toolConfig = toolInfo.NewToolLib();
		
		local prefabsItems = game.ReplicatedStorage.Prefabs.Items;
		local prefab = typeof(toolConfig.Prefab) == "string" and prefabsItems[toolConfig.Prefab] or toolConfig.Prefab;
		local prefabSize = prefab:GetExtentsSize();
		
		local includeList = CollectionService:GetTagged("EngineersPlans");
		table.insert(includeList, workspace.Interactables);

		if toolConfig.BuildAvoidTags then
			for _, tag in pairs(toolConfig.BuildAvoidTags) do
				local taggedList = CollectionService:GetTagged(tag);
				for a=1, #taggedList do
					table.insert(includeList, taggedList[a]);
				end
			end
		end

		local overlapParams = OverlapParams.new();
		overlapParams.FilterType = Enum.RaycastFilterType.Include;
		overlapParams.FilterDescendantsInstances = includeList;
		overlapParams.MaxParts = 1;

		local placeSpacing = toolConfig.PlaceSpacing or Vector3.new(0.2, 4, 0.2);
		local hits = workspace:GetPartBoundsInBox(placeCFrame, prefabSize + placeSpacing, overlapParams)

		if #hits > 0 then
			shared.Notify(player, "The space is already occupied.", "Negative");
			return
		end;
		
		
		modBlueprintLibrary.ConsumeBlueprintCost(player, fulfillment);
		
		local toolInfo = modTools[planItemId];
		local toolConfig = toolInfo.NewToolLib{
			Player = player;
			StorageItem = storageItem;
		};
		

		if toolConfig.CustomSpawn then
			toolConfig:CustomSpawn(placeCFrame);

		else
			local structure = prefab:Clone();
			structure.PrimaryPart.Anchored = true;
			structure:PivotTo(placeCFrame);
			structure.Parent = workspace.Environment;

			for _, obj in pairs(structure:GetDescendants()) do
				if obj:IsA("BasePart") then
					obj.CollisionGroup = "Structure";
				end
			end

			if toolConfig.OnSpawn then
				toolConfig:OnSpawn(structure);
			end
		end
	end
	
	return returnPacket;
end

game.Players.PlayerRemoving:Connect(function()
	local playerNames = {};
	for _, player in pairs(game.Players:GetPlayers()) do
		table.insert(playerNames, player.Name);
	end
	for _, planModel in pairs(CollectionService:GetTagged("EngineersPlans")) do
		if table.find(playerNames, planModel:GetAttribute("Owner")) ~= nil then continue end;
		
		game.Debris:AddItem(planModel, 0);
	end
end)

return ToolHandler;
