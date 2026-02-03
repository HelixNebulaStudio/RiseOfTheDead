local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local modDoors = shared.require(game.ReplicatedStorage.Entity.Doors);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);
local modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);

local modTilePrototypeClass = shared.require(game.ReplicatedStorage.Library.WaveCollapseSystem.TilePrototypeClass);

local TilePrototypePackage = {};
--==

function TilePrototypePackage.onRequire()
	modDoors.OnDoorToggle:Connect(function(doorInstance: DoorInstance, player: Player?)
		Debugger:Warn("OnDoorToggle");

		local lootSpawnAtt: Attachment = doorInstance.Values.LootSpawn;
		if lootSpawnAtt:GetAttribute("Spawned") == true then return end;
		lootSpawnAtt:SetAttribute("Spawned", true);
		
		local itemDrop = modItemDrops.ChooseDrop(modRewardsLibrary:Find("ab:arelshiftpartsdrop"));
		if itemDrop then
			modItemDrops.spawn{
				ItemId = itemDrop.ItemId;
				Quantity = itemDrop.Quantity;
				SpawnCFrame = lootSpawnAtt.WorldCFrame;
				DespawnDuration = false;
				Anchored = true;
				DisableTouchPickup = true;
			}
		end
	end)
end

function TilePrototypePackage:Init(raidController, waveCollapseSystem)
	if self.Initiated == true then return; end;
	self.Initiated = true;
	
	Debugger:Warn("Init Fancy Bed Rooms");
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

	local chosenLootSpawn = lootSpawns[math.random(1, #lootSpawns)];
	
	for _, child in pairs(newModel:GetChildren()) do
		local doorConfig = child:FindFirstChild("Door");
		if doorConfig == nil or not doorConfig:IsA("Configuration") then continue end;

		local door: DoorInstance = modDoors.getOrNew(doorConfig);
		door.Values.LootSpawn = chosenLootSpawn;
		table.insert(self.Doors, door);
	end
end

function TilePrototypePackage.new(tileModel)
	local self = modTilePrototypeClass.new(TilePrototypePackage);

	self.Model = tileModel;
	self.Active = false;
		
	self.Controller = nil;
	self.WaveCollapseSystem = nil;
			
	self.Doors = {};

	return self;
end

return TilePrototypePackage;

