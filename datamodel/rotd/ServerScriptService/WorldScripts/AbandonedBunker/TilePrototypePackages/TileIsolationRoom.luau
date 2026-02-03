local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modDoors = shared.require(game.ReplicatedStorage.Entity.Doors);
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

		local newModel = interactable.Values.RoomModel;
		Debugger:Warn("OnLockHydra", player, action, interactable);
		if not newModel:IsAncestorOf(interactable.Config) then return end;
		
		if action == "submit" then
			local selectedCell = interactable.Values.SelectedCell;
			local lockHydraInfo = interactable.Values.LockHydra;
			Debugger:Warn("Unlock door", selectedCell, lockHydraInfo);
			
			if lockHydraInfo.Id == "firstKey" then
				local firstDoorInteractable: InteractableInstance = modInteractables.getOrNew(newModel.FirstDoor.Interactable);

				if firstDoorInteractable.Values.Locked == true then
					firstDoorInteractable.Values.Locked = false;
					
					Debugger:Warn("First door unlocked");
					
					local randomSpawns = newModel:WaitForChild("RandomSpawns"):GetChildren();
					
					local itemDrop = modItemDrops.ChooseDrop(modRewardsLibrary:Find("ab:isolationdrop"));
					if itemDrop then
						modItemDrops.spawn{
							ItemId = itemDrop.ItemId;
							Quantity = itemDrop.Quantity;
							SpawnCFrame = (randomSpawns[math.random(1, #randomSpawns)]).CFrame;
							DespawnDuration = false;
							Anchored = true;
							DisableTouchPickup = true;
						}
					end
				end
				
				firstDoorInteractable.Values.Locked = false;
				modAudio.Play("KeyLock", firstDoorInteractable.Part).PlaybackSpeed = 2.5;
				firstDoorInteractable:Sync();
				
				return;
			end
			
			newModel:SetAttribute("Refresh", not newModel:GetAttribute("Refresh"));
		end
	end)
end

function TilePrototypePackage:Init(raidController, waveCollapseSystem)
	if self.Initiated == true then return; end;
	self.Initiated = true;

	self.Controller = raidController;
	self.WaveCollapseSystem = waveCollapseSystem;

	self.WaveCollapseSystem.InsolationIndex = (self.WaveCollapseSystem.InsolationIndex or 0) + 1;
	
	Debugger:Warn("Init Isolation Room");
	
	local newModel = self.Model:WaitForChild("Layout");
	newModel:SetAttribute("Refresh", false);

	local keyPad = newModel:WaitForChild("keyPad");

	local keyPadInteractable: InteractableInstance = modInteractables.getOrNew(keyPad.Interactable);
	keyPadInteractable.Values.RoomModel = newModel;
	
	local lockLights = newModel:WaitForChild("LockLights");
	local jailDoors = newModel:WaitForChild("JailDoors"):GetChildren();
	
	local jailDoorInteractables = {};
	local function SetJailLock(index, value)
		for a=1, #jailDoors do
			local jailDoor = jailDoors[a];
			
			if index == nil or jailDoor.Name == "JailDoor"..index then
				local jailDoorInteractable: InteractableInstance = modInteractables.getOrNew(jailDoor.Interactable);
				
				if jailDoorInteractable.Values.Locked == nil then
					jailDoorInteractable.Values.OnChanged:Connect(function(k, nv, ov)
						if k == "Locked" then
							local lockLight: BasePart = lockLights:FindFirstChild(string.gsub(jailDoor.Name, "JailDoor", ""));
							if lockLight then
								lockLight.Color = nv and COLOR_CLOSED or COLOR_OPENED;
							end
						end
					end)
				end
				jailDoorInteractable.Values.Locked = value == true;

				jailDoorInteractables[jailDoor.Name] = jailDoorInteractable;
			end
		end
	end
	SetJailLock(nil, true);
	
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
	
	local function bindButtonTrigger(interactable: InteractableInstance, info: InteractInfo)
		Debugger:Warn("BindTrigger", interactable.Id);

		local config: Configuration = interactable.Config;
		if not newModel:IsAncestorOf(config) then return end;
		
		local triggerId = interactable.Id;
		if triggerId:sub(1, 7) ~= "Select " then return end;
		local cellIndex = interactable.Values.CellIndex;
		
		Debugger:Warn("Select", cellIndex);
		
		config:SetAttribute("CellIndex", cellIndex);
		keyPadInteractable.Values.SelectedCell = tostring(cellIndex);
		
		updateCellSelectionLights();
	end

	for a=1, #selectionButtons do
		local buttonPart = selectionButtons[a];
		local cellIndex = buttonPart.Name;
		local triggerKey = `Select {cellIndex}`;
		
		local newInteractConfig = modInteractables.createInteractable("Button");
		newInteractConfig:SetAttribute("TriggerKey", triggerKey);
		newInteractConfig:SetAttribute("CellIndex", cellIndex);
		newInteractConfig:SetAttribute("Id", `IsolationRoom:{self.WaveCollapseSystem.InsolationIndex}:{cellIndex}`);
		newInteractConfig.Parent = buttonPart;

		local buttonInteractable: InteractableInstance = modInteractables.getOrNew(newInteractConfig);
		buttonInteractable.Values.BindTrigger = bindButtonTrigger;
	end
	
	updateCellSelectionLights();

	newModel:GetAttributeChangedSignal("Refresh"):Connect(function()
		SetJailLock(keyPadInteractable.Values.SelectedCell, false);
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
