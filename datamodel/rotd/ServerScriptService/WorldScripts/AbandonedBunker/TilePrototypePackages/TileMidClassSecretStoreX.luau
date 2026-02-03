local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);

local modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);

local modTilePrototypeClass = shared.require(game.ReplicatedStorage.Library.WaveCollapseSystem.TilePrototypeClass);

local TilePrototypePackage = {};
--==

function TilePrototypePackage:Init(raidController, waveCollapseSystem)
	if self.Initiated == true then return; end;
	self.Initiated = true;
	
	Debugger:Warn("Init SecretStore");
	self.Controller = raidController;
	self.WaveCollapseSystem = waveCollapseSystem;
	
	local newModel = self.Model:WaitForChild("Layout");

	local lootSpawnPart = newModel:WaitForChild("LootSpawn");
	local lootSpawns = {};
	for _, obj in pairs(lootSpawnPart:GetChildren()) do
		if obj:IsA("Attachment") then
			table.insert(lootSpawns, obj);
		end
	end
	
	for _, child in pairs(newModel:GetChildren()) do
		if child:FindFirstChild("Destructible") == nil then continue end;
		if child.Destructible:IsA("Configuration") == false then continue end;

		local destructible: DestructibleInstance = modDestructibles.getOrNew(child.Destructible);
		if destructible == nil then continue end;

		destructible.OnDestroy:Connect(function()
			local primaryPart = destructible.Model.PrimaryPart;
			if primaryPart then
				modAudio.Play("MetalCollapse2", primaryPart.Position);
			end
			
			for _, obj in pairs(destructible.Model:GetChildren()) do
				if not obj:IsA("BasePart") then continue end;
				
				if obj.Name == "Hitbox" then
					game.Debris:AddItem(obj, 0);
				else
					obj.Anchored = false;
				end
			end
			
			if self.Active ~= true then
				self.Active = true;
				
				local itemDrop = modItemDrops.ChooseDrop(modRewardsLibrary:Find("ab:arelshiftpartsdrop"));
				if itemDrop then
					modItemDrops.spawn{
						ItemId = itemDrop.ItemId;
						Quantity = itemDrop.Quantity;
						SpawnCFrame = lootSpawns[math.random(1, #lootSpawns)].WorldCFrame;
						DespawnDuration = false;
						Anchored = true;
						DisableTouchPickup = true;
					};
				end
			end
		end)

	end
end

function TilePrototypePackage.new(tileModel)
	local self = modTilePrototypeClass.new(TilePrototypePackage);

	self.Model = tileModel;
	self.Active = false;
		
	self.Controller = nil;
	self.WaveCollapseSystem = nil;

	return self;
end

return TilePrototypePackage;
