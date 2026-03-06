local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

local modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);

local modTilePrototypeClass = shared.require(game.ReplicatedStorage.Library.WaveCollapseSystem.TilePrototypeClass);

local COLOR_CLOSED = Color3.fromRGB(150, 85, 85);
local COLOR_OPENED = Color3.fromRGB(44, 101, 29);

local TilePrototypePackage = {};

--==
function TilePrototypePackage.onRequire()
	shared.modEventService:OnInvoked("Minigames_BindLockHydra", function(event: EventPacket, ...)
		local player: Player? = event.Player;
		if player == nil then return end;

		local action: string, interactable: InteractableInstance = ...;
		if interactable == nil then return end;

		Debugger:Warn("OnLockHydra", player, action, interactable);

		local newModel = interactable.Values.RoomModel;
		if newModel == nil or not newModel:IsAncestorOf(interactable.Config) then return end;
		
		if action == "submit" then
			local selectedCell = interactable.Values.SelectedCell;
			local lockHydraInfo = interactable.Values.LockHydra;
			Debugger:Warn("Unlock door", selectedCell, lockHydraInfo);

			local jailDoorConfigs = interactable.Values.JailDoorConfigs;
			for a=1, #jailDoorConfigs do
				local jailDoorConfig = jailDoorConfigs[a];
				if jailDoorConfig:GetAttribute("CellIndex") ~= selectedCell then continue end;
				
				jailDoorConfig:SetAttribute("Locked", false);
			end

			interactable.Values.SelectedCell = nil;
			newModel:SetAttribute("Refresh", not newModel:GetAttribute("Refresh"));
		end
	end)

	shared.modEventService:OnInvoked("Interactables_BindButtonInteract", function(eventPacket: EventPacket, ...)
		local player: Player? = eventPacket.Player;
		if player == nil then return end;

		local interactable: InteractableInstance = ...;
		if interactable == nil or interactable.Values.BindTrigger == nil then return end;

		interactable.Values.BindTrigger(interactable);
	end)

end

function TilePrototypePackage:Init(raidController, waveCollapseSystem)
	if self.Initiated == true then return; end;
	self.Initiated = true;

	self.Controller = raidController;
	self.WaveCollapseSystem = waveCollapseSystem;

	self.WaveCollapseSystem.InsolationIndex = (self.WaveCollapseSystem.InsolationIndex or 0) + 1;
	local isolationIndex = self.WaveCollapseSystem.InsolationIndex;

	Debugger:Warn("Init Isolation Room");
	
	local newModel = self.Model:WaitForChild("Layout");
	newModel:SetAttribute("Refresh", false);

	local firstKeyPadConfig = newModel:WaitForChild("firstkeyPad"):WaitForChild("Interactable");
	firstKeyPadConfig:SetAttribute("Id", `FirstKeyPad_{isolationIndex}`);

	local firstKeyPadInteractable: InteractableInstance = modInteractables.getOrNew(firstKeyPadConfig);

	local firstDoorConfig = newModel:WaitForChild("FirstDoor"):WaitForChild("Interactable");
	local firstDoorInteractable: InteractableInstance = modInteractables.getOrNew(newModel.FirstDoor.Interactable);

	local randomRewardSpawns = newModel:WaitForChild("RandomSpawns"):GetChildren();

	local spawnedReward = false;
	local _dropPrefab, dropInteractable;
	local rewardCellIndex = nil;

	firstKeyPadInteractable.Values.OnChanged:Connect(function(k, nv, ov)
		if k == "Locked" then
			firstDoorConfig:SetAttribute("Locked", nv == true);

			if nv == false and not spawnedReward then
				spawnedReward = true;
				
				local pickSpawnPart = randomRewardSpawns[math.random(1, #randomRewardSpawns)];
				
				local itemDrop = modItemDrops.ChooseDrop(modRewardsLibrary:Find("ab:isolationdrop"));
				if itemDrop then
					rewardCellIndex = pickSpawnPart.Name;
					_dropPrefab, dropInteractable = modItemDrops.spawn{
						ItemId = itemDrop.ItemId;
						Quantity = itemDrop.Quantity;
						SpawnCFrame = pickSpawnPart.CFrame;
						DespawnDuration = false;
						Anchored = true;
						DisableTouchPickup = true;
					};
					dropInteractable:SetPermissions("CanInteract", false);
				end
			end
		end
	end)

	local keyPadConfig = newModel:WaitForChild("keyPad"):WaitForChild("Interactable");
	keyPadConfig:SetAttribute("Id", `KeyPad_{isolationIndex}`);

	local keyPadInteractable: InteractableInstance = modInteractables.getOrNew(keyPadConfig);
	keyPadInteractable.Values.RoomModel = newModel;
	keyPadInteractable.Values.JailDoorConfigs = {};
	
	local lockLights = newModel:WaitForChild("LockLights");
	local jailDoors = newModel:WaitForChild("JailDoors"):GetChildren();
	
	local jailDoorInteractables = {};
	for a=1, #jailDoors do
		local jailDoor = jailDoors[a];
		
		local index = jailDoor.Name:gsub("JailDoor", "");
		
		local jailDoorConfig = jailDoor:WaitForChild("Interactable");
		jailDoorConfig:SetAttribute("CellIndex", index);
		jailDoorConfig:SetAttribute("Locked", true);
		if jailDoorConfig == nil or not jailDoorConfig:IsA("Configuration") then continue end;

		table.insert(keyPadInteractable.Values.JailDoorConfigs, jailDoorConfig);
		
		local jailDoorInteractable: InteractableInstance = modInteractables.getOrNew(jailDoorConfig);
		jailDoorInteractable.Values.OnChanged:Connect(function(k, isLocked, ov)
			if k == "Locked" then
				local lockLight: BasePart = lockLights:FindFirstChild(string.gsub(jailDoor.Name, "JailDoor", ""));
				if lockLight then
					lockLight.Color = isLocked and COLOR_CLOSED or COLOR_OPENED;
				end

				if not isLocked and rewardCellIndex == index then
					dropInteractable:SetPermissions("CanInteract", true);
				end
			end
		end)
		jailDoorInteractables[jailDoor.Name] = jailDoorInteractable;
	end

	
	local selectionButtons = newModel:WaitForChild("SelectionButtons"):GetChildren();
	local function updateCellSelectionLights()
		for a=1, #selectionButtons do
			local buttonPart = selectionButtons[a];
			
			if buttonPart.Name == tostring(keyPadInteractable.Values.SelectedCell) then
				buttonPart.Color = Color3.fromRGB(126, 104, 63);
				
			else
				for jailName, jailDoorInteractable in pairs(jailDoorInteractables) do
					if jailName ~= "JailDoor".. buttonPart.Name then continue end;
					
					buttonPart.Color = jailDoorInteractable.Values.Locked and COLOR_CLOSED or COLOR_OPENED;
				end
			end
		end
	end
	
	local function bindButtonTrigger(interactable: InteractableInstance)
		Debugger:Warn("BindTrigger", interactable.Id);

		local cellIndex = interactable.Values.CellIndex;
		Debugger:Warn("Select", cellIndex);

		keyPadInteractable.Values.SelectedCell = tostring(cellIndex);
		
		updateCellSelectionLights();
	end

	for a=1, #selectionButtons do
		local buttonPart = selectionButtons[a];
		local cellIndex = buttonPart.Name;
		
		local newInteractConfig = modInteractables.createInteractable("Button");
		newInteractConfig:SetAttribute("CellIndex", cellIndex);
		newInteractConfig:SetAttribute("_Label", `Select Cell {cellIndex}`);
		newInteractConfig:SetAttribute("Id", `IsolationRoom:{isolationIndex}:{cellIndex}`);
		newInteractConfig.Parent = buttonPart;

		local buttonInteractable: InteractableInstance = modInteractables.getOrNew(newInteractConfig);
		buttonInteractable.Values.BindTrigger = bindButtonTrigger;
	end
	
	updateCellSelectionLights();

	newModel:GetAttributeChangedSignal("Refresh"):Connect(function()
		updateCellSelectionLights();
	end)
end


function TilePrototypePackage.new(tileModel)
	local self = modTilePrototypeClass.new(TilePrototypePackage);

	self.Model = tileModel;
	self.Active = false;
		
	self.Controller = nil;
	self.WaveCollapseSystem = nil;
			
	self.Doors = {};
	self.Pistons = {};

	return self;
end

return TilePrototypePackage;
