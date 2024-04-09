local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;
local PhysicsService = game:GetService("PhysicsService");
local CollectionService = game:GetService("CollectionService");

--== Modules;
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modTools = require(game.ReplicatedStorage.Library.Tools);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);


local prefabsItems = game.ReplicatedStorage.Prefabs.Items;

local ToolHandler = {};
ToolHandler.__index = ToolHandler;
--== Script;

function ToolHandler:OnPrimaryFire(...)
	local actionIndex = ...;
	local character = self.Player.Character;
	local humanoid = character and character:FindFirstChild("Humanoid");
	local rootPart = character and character:FindFirstChild("HumanoidRootPart");
	
	if humanoid and humanoid.Health > 0 then
		if actionIndex == 1 then
			self.LastFire = tick();
		elseif actionIndex == 2 then
			local profile = modProfile:Get(self.Player);
			local playerSave = profile:GetActiveSave();
			local inventory = profile.ActiveInventory;
			
			local itemLib = modItemsLibrary:Find(self.StorageItem.ItemId);
			local configurations = self.ToolConfig;
			local prefab = typeof(configurations.Prefab) == "string" and prefabsItems[configurations.Prefab] or configurations.Prefab;
			local prefabSize = prefab:GetExtentsSize();
			
			local lapsed = tick() - self.LastFire;
			if lapsed >= configurations.BuildDuration-0.5 and lapsed <= configurations.BuildDuration+0.5 then
				
				local origin = character.PrimaryPart.CFrame.p + character.PrimaryPart.CFrame.LookVector*2.5;
				local ray = Ray.new(origin, Vector3.new(0, -8, 0));
				local hit, pos = workspace:FindPartOnRayWithWhitelist(ray, {workspace.Environment; workspace.Terrain});
				
				if hit then
					local placeCFrame = CFrame.new(pos) * rootPart.CFrame.Rotation * configurations.PlaceOffset;
					
					local includeList = CollectionService:GetTagged("EngineersPlans");
					table.insert(includeList, workspace.Interactables);

					if configurations.BuildAvoidTags then
						for _, tag in pairs(configurations.BuildAvoidTags) do
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

					local placeSpacing = configurations.PlaceSpacing or Vector3.new(0.2, 4, 0.2);
					local hits = workspace:GetPartBoundsInBox(placeCFrame, prefabSize + placeSpacing, overlapParams)
					
					if #hits > 0 then
						shared.Notify(self.Player, "Could not place "..itemLib.Name..", try again.", "Negative");
						return
					end;
					if self.StorageItem and self.StorageItem.Quantity <= 0 then return end;
					
					inventory:Remove(self.StorageItem.ID, 1);
					shared.Notify(self.Player, ("1 $Item removed from your Inventory."):gsub("$Item", itemLib.Name), "Negative");
					
					if configurations.CustomSpawn then
						configurations:CustomSpawn(CFrame.new(pos));
						
					else
						local structure = prefab:Clone();
						structure.PrimaryPart.Anchored = true;
						structure:SetPrimaryPartCFrame(placeCFrame);
						structure.Parent = hit.Parent;
						
						for _, obj in pairs(structure:GetDescendants()) do
							if obj:IsA("BasePart") then
								obj.CollisionGroup = "Structure";
							end
						end
						
						if configurations.OnSpawn then configurations:OnSpawn(structure); end
					end
				else
					shared.Notify(self.Player, "Could not place "..itemLib.Name..", try again.", "Negative");
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
	
	self.__index = self;
	setmetatable(self, ToolHandler);
	return self;
end

return ToolHandler;
