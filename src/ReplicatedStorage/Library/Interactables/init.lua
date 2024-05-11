local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
-- Settings;
local Types={
	Message="Message";
	Hint="Hint";
	Door="Door";
	Workbench="Workbench";
	Shop="Shop";
	Pickup="Pickup";
	Dialogue="Dialogue";
	Travel="Travel";
	BossExit="BossExit";
	Storage="Storage";
	Trigger="Trigger";
	GameMode="GameMode";
	Collectible="Collectible";
	GameModeExit="GameModeExit";
	SupplyCrate="SupplyCrate";
	Toggle="Toggle";
	Interface="Interface";
	Revive="Revive";
	Hold="Hold";
	CardGame="CardGame";
	Seat="Seat";
	Terminal="Terminal";
	InteractProxy="InteractProxy";
};

-- Variables;
local Interactable={};
Interactable.__index=Interactable;
Interactable.Types=Types;
Interactable.Cache = {};

Interactable.TypeIcons={
	["BossDoor_"] = {Icon="rbxassetid://6328469902"; Color=Color3.fromRGB(255, 255, 255)};
	["RogueDoor_"] = {Icon="rbxassetid://6328466558"; Color=Color3.fromRGB(255, 255, 255)};
	["ExtremeDoor_"] = {Icon="rbxassetid://6328526813"; Color=Color3.fromRGB(152, 45, 45)};
	["Travel_"] = {Icon="rbxassetid://3694599252"; Color=Color3.fromRGB(255, 255, 255)};
	["TravelLock_"] = {Icon="rbxassetid://3694599252"; Color=Color3.fromRGB(255, 255, 255)};
	["Shop_"] = {Icon="http://www.roblox.com/asset/?id=4629984614"; Color=Color3.fromRGB(255, 255, 255)};
	["RaidSolo_"] = {Icon="http://www.roblox.com/asset/?id=6328469902";  Color=Color3.fromRGB(255, 255, 255)};
	["Raid_"] = {Icon="http://www.roblox.com/asset/?id=6328528439"; Color=Color3.fromRGB(255, 255, 255)};
	["RaidBandit_"] = {Icon="http://www.roblox.com/asset/?id=6361537388"; Color=Color3.fromRGB(255, 255, 255)};
	["Survival_"] = {Icon="http://www.roblox.com/asset/?id=6328528439"; Color=Color3.fromRGB(152, 45, 45)};
	["Coop_"] = {Icon="http://www.roblox.com/asset/?id=13336462553"; Color=Color3.fromRGB(255, 255, 255)};
}

local RunService = game:GetService("RunService");
local SoundService = game:GetService("SoundService");
local CollectionService = game:GetService("CollectionService");
local player = game.Players.LocalPlayer;

local modAudio = Debugger:Require(game.ReplicatedStorage.Library.Audio);
local modItem = Debugger:Require(game.ReplicatedStorage.Library.ItemsLibrary);
local modBranchConfigs = Debugger:Require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = Debugger:Require(game.ReplicatedStorage.Library.RemotesManager);
local modGameModeLibrary = Debugger:Require(game.ReplicatedStorage.Library.GameModeLibrary);
local modDoors = Debugger:Require(game.ReplicatedStorage.Library.Doors);
local modTableManager = require(game.ReplicatedStorage.Library.TableManager);

local remotes = game.ReplicatedStorage.Remotes;
local remoteInteractableSync = modRemotesManager:Get("InteractableSync");
local remotePickUpRequest = remotes.Interactable.PickUpRequest;
local remoteWorldTravelRequest = remotes.Interactable.WorldTravelRequest;
local remoteOpenStorageRequest = remotes.Interactable.OpenStorageRequest;
local remoteOnTrigger = remotes.Interactable.OnTrigger;
local remoteGameModeLobbies = modRemotesManager:Get("GameModeLobbies");
local remoteGameModeExit = modRemotesManager:Get("GameModeExit");
local remoteReviveInteract = modRemotesManager:Get("ReviveInteract");
local remoteInteractionUpdate = modRemotesManager:Get("InteractionUpdate");
local remoteInteractableToggle = modRemotesManager:Get("InteractableToggle");
local remoteEnterDoorRequest = modRemotesManager:Get("EnterDoorRequest");
local remoteCardGame = modRemotesManager:Get("CardGame");
local remoteCharacterInteractions = modRemotesManager:Get("CharacterInteractions");

local bindLeavingBossArena = remotes.BossInterface.LeavingBossArena;

local bindOpenLobbyInterface = remotes.LobbyInterface.OpenLobbyInterface;

local ID = 1;

Interactable.OnCancel = nil;
-- Script;
local function acquireInteractable(obj)
	if obj:IsA("ModuleScript") and obj.Name == "Interactable" then
		CollectionService:AddTag(obj, "Interactable");
	end
end

if RunService:IsServer() then
	remoteInteractionUpdate.OnServerEvent:Connect(function(player, moduleScript, parentPart, action)
		local classPlayer = shared.modPlayers.Get(player);
		if action == "stop" then
			local interactData = classPlayer.ActiveInteract
			
			if interactData then
				if interactData.Type ==  "Hold" then
					interactData.Active = false;
					
					if interactData.OnHoldUpdate then
						interactData:OnHoldUpdate(player)
					end
				end
			end
			
			classPlayer.ActiveInteract = nil;
			return;
		end
		
		-- Script sanity check;
		if moduleScript == nil or typeof(moduleScript) ~= "Instance" or not moduleScript:IsA("ModuleScript") or moduleScript.Name ~= "Interactable" then 
			return;
		end;
		
		-- Object sanity check;
		if parentPart == nil or (not moduleScript:IsDescendantOf(parentPart) and not parentPart:IsDescendantOf(moduleScript.Parent)) then 
			Debugger:Warn("Invalid Interact Part", parentPart); 
			return;
		end;
		
			
		local interactData = shared.saferequire(player, moduleScript);
		if interactData == nil then return end;
		
		interactData.Script = moduleScript;
		interactData.Object = parentPart;
		
		if action == "start" then
			classPlayer.ActiveInteract = interactData;
			
			if interactData.Type ==  "Hold" then
				interactData.Active = true;
				
				if interactData.OnHoldUpdate then
					interactData:OnHoldUpdate(player)
				end
			end
			
		elseif action == "trigger" then
			if interactData.OnServerTrigger then
				interactData:OnServerTrigger(player);
			end
			
		end
	end)
	
	remoteInteractableSync.OnServerEvent:Connect(function(player, moduleScript)
		if typeof(moduleScript) ~= "Instance" or not moduleScript:IsA("ModuleScript") or moduleScript.Name ~= "Interactable" then return end;
		
		local interactData = shared.saferequire(player, moduleScript);
		if interactData == nil then return end;
		
		interactData.Script = moduleScript;
		interactData:Sync(player);
	end)
	
	if workspace.Environment:FindFirstChild("Game") then
		workspace.Environment.Game.ChildAdded:Connect(function(child)
			for _, obj in pairs(child:GetDescendants()) do
				acquireInteractable(obj);
			end
		end)
	end
	
	workspace.Interactables.ChildAdded:Connect(function(child)
		for _, obj in pairs(child:GetDescendants()) do
			acquireInteractable(obj);
		end
	end)
end

function Interactable:SyncAll(func)
	if RunService:IsServer() then
		if workspace.Environment:FindFirstChild("Game") then
			for _, obj in pairs(workspace.Environment.Game:GetDescendants()) do
				acquireInteractable(obj);
			end
		end
		
		for _, obj in pairs(workspace.Interactables:GetDescendants()) do
			acquireInteractable(obj);
		end
		
		for _, interactableScript in pairs(CollectionService:GetTagged("Interactable")) do
			local interactObject = require(interactableScript);
			interactObject.Script = interactableScript;
			if func then func(interactObject); end
			interactObject:Sync();
		end
	end
end

function Interactable:Sync(scr, players, data)
	players = type(players) == "table" and players or {players};
	if RunService:IsClient() then return end;
	if scr.Parent == nil then Debugger:Warn(":Sync scr.Parent == nil."); return end;
	
	local syncRange = data.SyncRange or 128;
		
	for a=1, #players do
		local player: Player = players[a];
		
		if syncRange <= 512 then
			local pvInstance = scr.Parent;
			
			if pvInstance:IsA("BasePart") then
				if player:DistanceFromCharacter(pvInstance.Position) >= syncRange then
					continue;
				end
				
			else
				while not scr:IsA("PVInstance") do
					local findChild = pvInstance:FindFirstChildWhichIsA("PVInstance");
					if findChild then
						pvInstance = findChild;
						break;
					end
					pvInstance = pvInstance.Parent;
					if not workspace:IsAncestorOf(pvInstance) then
						break;
					end
				end

				if pvInstance:IsA("PVInstance") then
					if player:DistanceFromCharacter(pvInstance:GetPivot().Position) >= syncRange then
						continue;
					end
				end
				
			end
		end

		if RunService:IsStudio() then
			Debugger:Warn("[Studio] Interactable Sync: ",scr:GetFullName(),"(",modRemotesManager.PacketSizeCounter.GetPacketSize{PacketData={data};},")","to", player);
		end
		remoteInteractableSync:FireClient(player, scr, data);
	end
	
end

function Interactable.new()
	local interactMeta = {};
	interactMeta.__index = interactMeta;
	interactMeta.CanInteract = false;
	interactMeta.LastSync = 0;
	interactMeta.LastServerTrigger = 0;
	
	function interactMeta:RemoteTriggerEvent()
		if RunService:IsServer() then return end;
		
		if tick()-self.LastServerTrigger >= 1 then
			self.LastServerTrigger = tick();
			remoteInteractionUpdate:FireServer(self.Script, self.Object, "trigger");
		end
	end
	
	function interactMeta:SyncRequest()
		if RunService:IsServer() then return end;
		
		if tick()-self.LastSync >= 5 then
			self.LastSync = tick();
			remoteInteractableSync:FireServer(self.Script);
		end
	end
	
	function interactMeta:Sync(players, data)
		if self.Script == nil then Debugger:Warn("Missing Interactable Script."); return end;
		Interactable:Sync(self.Script, (players or game.Players:GetPlayers()), data or self);
	end
	
	function interactMeta:SetMeta(k, v)
		interactMeta[k] = v;
	end
	
	function interactMeta:Trigger()
		self:RemoteTriggerEvent();
		
		local metaSelf = getmetatable(self);
		
		local library = {};
		library.modCharacter = self.CharacterModule;
		library.modData = require(player:WaitForChild("DataModule") :: ModuleScript);

		library.interface = library.modData:GetInterfaceModule();
		if library.interface == nil then Debugger:Warn("Missing library.interface"); return end;
		
		if self.InspectMode == true then
			self.Disabled = "Disabled in Inspect Mode";
			return;
		else
			self.Disabled = nil;
		end
		
		if self.Premium == true then
			local isPremium = library.modData and library.modData.Profile and library.modData.Profile.Premium == true or false;
			
			if isPremium then
				self.Disabled = nil;
			else
				self.Disabled = "Requires Premium";
				return;
			end
			
		else
			self.Disabled = nil;
		end
		
		if self.LevelRequired then
			local localplayerStats = library.modData.GetStats();
			
			if localplayerStats and localplayerStats.Level and localplayerStats.Level >= self.LevelRequired then
				
				self.Disabled = nil;
			else
				self.Disabled = ("Mastery Level $lvl Required"):gsub("$lvl", self.LevelRequired);
				return;
			end
		end
		
		if self.MissionRequired then
			local modData = library.modData;
			
			local missionId = self.MissionRequired.Id;
			local missionType = self.MissionRequired.Type or {3};
			local missionPoint = self.MissionRequired.ProgressionPoint;
			
			local modMissionLibrary = require(game.ReplicatedStorage.Library.MissionLibrary);
			local missionLib = modMissionLibrary.Get(missionId);
			
			local missionFulfilled = false;
			
			if modData.GameSave and modData.GameSave.Missions then
				local missionsList = modData.GameSave.Missions;
				for a=1, #missionsList do
					local missionData = missionsList[a];
					if missionData.Id ~= missionId then continue end;
					
					if table.find(missionType, missionData.Type) == nil then continue; end
					if missionPoint and table.find(missionPoint, missionData.ProgressionPoint) == nil then continue; end
					
					missionFulfilled = true;
					break;
				end
			end
			
			if missionFulfilled then
				self.Locked = false;
				self.Disabled = nil;
				
			else
				self.Locked = true;
				if missionLib then
					self.Disabled = "Mission \"".. missionLib.Name .."\" required to access.";
				else
					self.Disabled = "Mission in development for accessing this area.";
				end
				return;
			end
		end
		
		if self.ItemRequired and self.ItemRequired ~= "" then
			if self.ItemRequired ~= (self.CharacterModule.EquippedItem and self.CharacterModule.EquippedItem.ItemId) then
				local itemLib = modItem:Find(self.ItemRequired);
				
				self.Disabled = "Requires a "..(itemLib.Name or "Unknown Item");
				return;
			else
				self.Disabled = nil;
			end
		end
		
		local classPlayer = shared.modPlayers.Get(player);
		if classPlayer.Properties.InBossBattle ~= nil and self.Type ~= Types.GameModeExit then
			self.Disabled = "Cant Interact";
			return;
			
		else
			self.Disabled = nil;
			
		end
		
		if metaSelf.OnTrigger then
			metaSelf.OnTrigger(self, library);
		end
		if self.OnTrigger then
			self:OnTrigger(library);
		end
		
		self:SyncRequest();
	end
	
	function interactMeta:Interact()
		if self.Disabled then return end;
		if self.CanInteract == false then return end;
		if self.Coop then return end;
		
		local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
		
		local library = {};
		library.modCharacter = self.CharacterModule;
		library.modData = modData;
		library.interface = modData:GetInterfaceModule();
		
		if self.LevelRequired then
			local localplayerStats = library.modData.GetStats();
			
			if localplayerStats and localplayerStats.Level and localplayerStats.Level < self.LevelRequired then
				return;
			end
		end
		
		if self.Prompt then
			local promptWindow = library.interface:PromptQuestion(self.Prompt.Title, self.Prompt.Description);
			local YesClickedSignal, NoClickedSignal;

			YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
				library.interface:PlayButtonClick();
				promptWindow:Close();

				if self.OnInteracted then
					self:OnInteracted(library);
				end
				
				YesClickedSignal:Disconnect();
				NoClickedSignal:Disconnect();
			end);
			NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
				library.interface:PlayButtonClick();
				promptWindow:Close();
				YesClickedSignal:Disconnect();
				NoClickedSignal:Disconnect();
			end);
			
		else
			if self.OnInteracted then
				self:OnInteracted(library);
			end
			
		end
		
		
		return true;
	end

	function interactMeta:Disable()
		self.ShowIndicator = false;
		self.CanInteract = false;
	end
	
	function interactMeta:Enable()
		self.ShowIndicator = true;
		self.CanInteract = true;
	end

	interactMeta.Debounce = {};
	function interactMeta:CheckDebounce(name, duration)
		local t = tick();
		if interactMeta.Debounce[name] and t-interactMeta.Debounce[name] <= (duration or 0.1) then return false end;
		interactMeta.Debounce[name] = t;
		for k,_ in pairs(interactMeta.Debounce) do
			if game.Players:FindFirstChild(k) == nil then
				interactMeta.Debounce[k] = nil;
			end
		end
		return true;
	end
	
	function interactMeta:Change()
		
	end
	
	function interactMeta:Destroy()
		self = nil;
	end

	local interact = setmetatable({}, interactMeta);
	interact.ID = ID;
	ID = ID+1;
	return interact;
end

function Interactable.Message(msg)
	local interact = Interactable.new();
	local interactMeta = getmetatable(interact);
	interactMeta.Label = msg or "Enter Door";
	
	interact.Type = Types.Message;
	return interact;
end

function Interactable.Hint(src, msg, paramPacket)
	local interactObj = Interactable.new();
	local interactMeta = getmetatable(interactObj);
	interactMeta.Label = msg or "Message";

	interactObj.Script = src;
	
	paramPacket = paramPacket or {};
	if paramPacket.Blacklight and not CollectionService:HasTag(src, "BlacklightInteractables") then
		CollectionService:AddTag(src, "BlacklightInteractables");
		
		interactObj.InteractableRange = 0;
		
		local blacklightGui = src.Parent:FindFirstChild("BlacklightHint");
		if blacklightGui then
			for _, textLabel in pairs(blacklightGui:GetChildren()) do
				if not textLabel:IsA("TextLabel") then continue end;

				textLabel.TextTransparency = 1;
				textLabel.Text = interactObj.Label;
			end
		end
	end
	
	function interactMeta:OnTrigger()
	end

	interactObj.Type = Types.Hint;
	return interactObj;
end

function Interactable.Door(locked, label, premium)
	local interact = Interactable.new();
	local interactMeta = getmetatable(interact);
	interactMeta.Label = label or "Enter Door";
	interactMeta.CanInteract = true;
	
	interact.Type = Types.Door;
	interact.Locked = locked == true;
	interact.Label = nil;
	interact.EnterSound = "DoorClose";
	interact.InteractableRange = 10;
	interact.Premium = premium == true;
	
	interact.Animation = "OpenDoor";
	
	if locked then
		interact.CanInteract = false;
		interact.Label = interact.LockedLabel or "Door's locked";
	end
	
	function interactMeta:OnTrigger()
		if self.Locked == true then
			interact.CanInteract = false;
			interact.Label = self.LockedLabel or "Door's locked";
			return;
		else
			interact.CanInteract = true;
			interact.Label = nil;
		end
		
		local doorObject = modDoors:GetDoor(self.Object and self.Object.Parent);
		if doorObject then
			if not doorObject:HasAccess(player) then
				interact.CanInteract = false;
				interact.Label = self.LockedLabel or "Door's locked";
				return;
			end
			
			if doorObject.Prefab:FindFirstChild("Blockade") ~= nil then
				interact.CanInteract = false;
				interact.Label = "Door's blocked";
				return;
			end

			local stateRequired = doorObject.Prefab:GetAttribute("StateRequired");
			if stateRequired then
				interact.CanInteract = false;
				interact.Label = stateRequired;
				return;
				
			end
			
			local keyItemId = doorObject.Prefab:GetAttribute("KeyRequired");
			if keyItemId then
				local itemLib = modItem:Find(keyItemId);

				local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
				if modData.FindItemIdFromCharacter(keyItemId) then
					interact.Label = "Unlock with ".. (itemLib and itemLib.Name or "unknown item");
					
				else
					interact.CanInteract = false;
					interact.Label = "Requires a ".. (itemLib and itemLib.Name or "unknown item");
					return;
					
				end
			end
			
			local isOpen = doorObject.Script:GetAttribute("DoorOpen");
			interactMeta.Label = (isOpen and "Close" or "Open").." Door";
			
			if self.Label:match("Door") then
				
				if doorObject.Type == "Sliding" then
					self.Animation = "Press";
					return;
				end
				
				if isOpen then
					self.Animation = "CloseDoor"; -- doorObject.DoorsCount >= 2 and "DCloseDoor" or
				else
					self.Animation = "OpenDoor"; -- doorObject.DoorsCount >= 2 and "DOpenDoor" or 
				end
			end
		end
	end
	
	function interact:OnInteracted(library)
		local doorObject = modDoors:GetDoor(self.Object and self.Object.Parent);
		if doorObject then
			if not self.Locked then
				doorObject:RequestDoorToggle();
			end
			
		else
			local destination = self.Object and self.Object:FindFirstChild("Destination")
			
			if self.Script and self.Script:FindFirstChild("CustomDestination") then
				destination = self.Script.CustomDestination.Value;
			end
			
			if destination == nil then
				warn("Door missing destination.");
			end
			
			if not self.Locked then
				if self.RootPart ~= nil and self.RootPart.Parent ~= nil then
					library.modCharacter.CharacterProperties.IsCrouching = false;
					library.modCharacter.StopSliding();
					remoteEnterDoorRequest:InvokeServer(self.Object, self.Script);
					
				else
					warn("Missing character root part.");
					
				end
			end
			
		end
	end
	
	return interact;
end

function Interactable.Travel(worldId, label, premium)
	local interact = Interactable.new();
	local interactMeta = getmetatable(interact);
	interactMeta.Label = label or "Enter Door";
	interactMeta.CanInteract = true;
	
	interact.Type = Types.Travel;
	interact.WorldId = worldId;
	interact.Premium = premium == true;
	
	if modBranchConfigs.CurrentBranch.Worlds[worldId] == nil then
		Debugger:Log("World",worldId,"does not exist.");
		interact.CanInteract = false;
		interact.Label = "Work In Progress";
	end
	
	function interact:OnInteracted(library)
		if self.Disabled then return end;
		local worldName = self.WorldId and modBranchConfigs.GetWorldDisplayName(self.WorldId) or self.WorldId;
		
		local promptWindow = library.interface:PromptQuestion("You are about to leave this world", "Are you sure you want to travel to "..worldName.."?");
		local YesClickedSignal, NoClickedSignal;
		
		local function exitPrompt()
			library.interface:ToggleGameBlinds(true, 1);
			SoundService:SetListener(Enum.ListenerType.ObjectCFrame, library.modCharacter.RootPart);
			library.modCharacter.CharacterProperties.CanMove = true;
			library.modCharacter.CharacterProperties.CanInteract = true;
		end
		
		YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
			library.interface:PlayButtonClick();
			library.interface:ToggleGameBlinds(false, 3);
			promptWindow:Close();
			library.modCharacter.CharacterProperties.CanMove = false;
			library.modCharacter.CharacterProperties.CanInteract = false;
			local success = remoteWorldTravelRequest:InvokeServer("Interact", self.Script);
			if success then
				SoundService:SetListener(Enum.ListenerType.CFrame, CFrame.new(0, 1000, 0));
			else
				exitPrompt();
			end
			YesClickedSignal:Disconnect();
			NoClickedSignal:Disconnect();
		end);
		NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
			library.interface:PlayButtonClick();
			promptWindow:Close();
			exitPrompt();
			YesClickedSignal:Disconnect();
			NoClickedSignal:Disconnect();
		end);
	end
	
	return interact;
end

function Interactable.BossExit()
	local interact = Interactable.new();
	interact.Type = Types.BossExit;
	interact.Label = "Door's Locked";
	interact.CanInteract = false;
	interact.OnTrigger = function(self)
		if self.Object and self.Object:FindFirstChild("ExitBossArena") then
			interact.Label = "Enter Door";
			interact.CanInteract = true;
		end
	end
	
	function interact:OnInteracted()
		if self.Object:FindFirstChild("ExitBossArena") then
			self.Object.ExitBossArena:InvokeServer(self.Object);
			bindLeavingBossArena:Fire();
		end
	end
	
	return interact;
end

function Interactable.Workbench(tier)
	local interact = Interactable.new();
	local interactMeta = getmetatable(interact);
	interactMeta.Label = "Use Workbench";
	interactMeta.CanInteract = true;
	
	interact.Type = Types.Workbench;
	interact.Tier = tier;
	
	function interact:OnInteracted(library)
		library.interface.Object = self.Object;
		library.interface:ToggleWindow("Workbench");
	end
	
	return interact;
end

function Interactable.Shop(shopType)
	local interact = Interactable.new();
	local interactMeta = getmetatable(interact);
	interactMeta.Label = "Open Shop";
	interactMeta.CanInteract = true;
	interactMeta.ShopType = shopType;
	
	interact.Type = Types.Shop;
	
	function interact:OnInteracted(library)
		library.interface.Object = self.Object;
		library.interface:ToggleWindow("RatShopWindow", nil, shopType);
	end
	
	return interact;
end

function Interactable.Pickup(itemId, quantity)
	local itemLib = modItem:Find(itemId);
	local interact = Interactable.new();
	local interactMeta = getmetatable(interact);
	interactMeta.Label = "Pick up "..(itemLib and itemLib.Name or itemId)..((quantity or 1) > 1 and " x"..quantity or "");
	interactMeta.CanInteract = true;
	interactMeta.TouchInteract = true;
	
	interact.Type = Types.Pickup;
	interact.ItemId = itemId;
	interact.Quantity = quantity or 1;
	
	interact.PickupCooldown = nil;

	function interact:SetQuantity(quantity)
		self.Quantity = quantity or 1;
		if self.Script then
			self.Script:SetAttribute("Quantity", quantity);
		end
		interactMeta.Label = "Pick up "..(itemLib and itemLib.Name or itemId)..((quantity or 1) > 1 and " x"..quantity or "");
	end
	
	function interact:OnSync(data)
		self.LevelRequired = data.LevelRequired or self.LevelRequired;
		self:SetQuantity(data.Quantity or self.Quantity);
	end
	
	function interact:OnInteracted(library)
		if self.PickupCooldown and tick()-self.PickupCooldown <= 1 then return end;
		self.PickupCooldown = tick();

		local interactObject = self.Object;
		if not interactObject:IsDescendantOf(workspace) then return end;
		
		local objectParent = interactObject.Parent;
		
		interactObject.Parent = game.ReplicatedStorage;
		if objectParent:FindFirstChild("BillboardGui") then
			objectParent.BillboardGui.Enabled = false;
		end
		local invokeRequest, partialPickup = remotePickUpRequest:InvokeServer(interactObject, self.Script);

		if invokeRequest == true or partialPickup == true then
			if self.OnSuccessfulPickup then self.OnSuccessfulPickup(self) end;
			
			if partialPickup ~= true then
				if objectParent:IsA("Model") then
					objectParent:Destroy();
				else
					interactObject:Destroy();
				end
				
			else
				if objectParent then
					interactObject.Parent = objectParent;
					if objectParent:IsA("Model") then
						objectParent.PrimaryPart = interactObject;
					end
				end
				if objectParent:FindFirstChild("BillboardGui") then
					objectParent.BillboardGui.Enabled = true;
				end
				
			end

			--library.interface = library.modData:GetInterfaceModule();
			--if library.interface.modInventoryInterface then
			--	library.interface.modInventoryInterface.InventoryVisibleChanged(true);
			--end
			
			local sound;
			if self.PickUpSound then
				sound = modAudio.Play(self.PickUpSound, nil, nil, false);
				
			else
				if itemLib and itemLib.Type == modItem.Types.Resource then
					if itemLib.Name == "Metal Scraps" then
						sound = modAudio.Play("StorageMetalPickup", nil, nil, false);
					elseif itemLib.Name == "Glass Shards" then
						sound = modAudio.Play("StorageGlassPickup", nil, nil, false);
					elseif itemLib.Name == "Wooden Parts" then
						sound = modAudio.Play("StorageWoodPickup", nil, nil, false);
					elseif itemLib.Name == "Cloth" then
						sound = modAudio.Play("StorageClothPickup", nil, nil, false);
					else
						sound = modAudio.Play("StorageItemPickup", nil, nil, false);
					end
				elseif itemLib and itemLib.Type == modItem.Types.Blueprint then
					sound = modAudio.Play("StorageBlueprintPickup", nil, nil, false);
				elseif itemLib and itemLib.Type == modItem.Types.Tool then
					sound = modAudio.Play("StorageWeaponPickup", nil, nil, false);
				elseif itemLib and itemLib.Type == modItem.Types.Clothing then
					sound = modAudio.Play("StorageClothPickup", nil, nil, false);
				else
					sound = modAudio.Play("StorageItemPickup", nil, nil, false);
				end
			end
			if sound then sound.PlaybackSpeed = math.random(70, 120)/100; end;
			
		else
			if interactObject.Parent ~= nil then
				if objectParent then
					interactObject.Parent = objectParent;
					if objectParent:IsA("Model") then
						objectParent.PrimaryPart = interactObject;
					end
				end
				if objectParent:FindFirstChild("BillboardGui") then
					objectParent.BillboardGui.Enabled = true;
				end
				
				print("Interactable:PickUp>> Failed to pick up",self.ItemName," due to:", invokeRequest);
			end
		end
	end
	
	return interact;
end

function Interactable.Dialogue(npcName)
	local interact = Interactable.new();
	interact.NpcName = npcName;
	
	local interactMeta = getmetatable(interact);
	interactMeta.Label = "Talk to "..npcName;
	interactMeta.CanInteract = true;
	
	interact.Type = Types.Dialogue;
	interact.IndicatorPresist = false;
	interact.InteractableRange = 10;
	
	function interact:OnInteracted(library)
		if not library.interface:IsVisible("Dialogue") then
			library.interface.Object = self.Object;
			library.interface:OpenWindow("Dialogue", interact);
		end
	end
	
	return interact;
end

function Interactable.Storage(moduleScript, storageId, storageName, configurations)
	local interact = Interactable.new();
	local interactMeta = getmetatable(interact);
	interactMeta.Label = "Open Storage";
	interactMeta.CanInteract = true;
	interactMeta.Configurations = {};
	
	function interactMeta:SetStorageId(storageId)
		interact.StorageId = storageId;
		interact.Script:SetAttribute("StorageId", storageId);
	end
	
	interact.Script = moduleScript;
	interact.Type = Types.Storage;
	interact.StorageId = storageId or "empty";
	interact.StorageName = storageName or "Empty";
	interact.Configurations = configurations;
	interact.Label = nil;
	interact.EmptyLabel = "Empty";
	interact.IndicatorPresist = false;
	
	interact.Animation = "OpenStorage";
	
	function interact:OnSync(data)
		self.InspectMode = data.InspectMode or self.InspectMode;
		
		self.StorageId = data.StorageId or self.StorageId;
		self.StorageName = data.StorageName or self.StorageName;
		self.Whitelist = data.Whitelist or self.Whitelist;
		self.EmptyLabel = data.EmptyLabel or self.EmptyLabel;
		self.LoadingLabel = data.LoadingLabel or self.LoadingLabel;
		self.LevelRequired = data.LevelRequired or self.LevelRequired;
		self.Label = data.Label;
		
		if data.StorageName then
			interactMeta.Label = "Open "..data.StorageName;
			--self.Label = "Open "..data.StorageName;
		end
	end
	
	function interact:OnInteracted(library)
		if not library.interface.StorageVisible then
			library.interface.Object = self.Object;
			library.interface.InteractScript = self.Script
			local storage = remoteOpenStorageRequest:InvokeServer(self.Object, self.Script);
			if storage and type(storage) == "table" then
				modAudio.Play(self.OpenSound or "CrateOpen", self.Object, nil, false);
				library.modData.SetStorage(storage);
				library.interface:OpenWindow("ExternalStorage", storage.Id, storage);
			else
				Debugger:Warn("Storage does not exist.");
			end
		end
	end
	
	local lastInvoke = tick();
	function interact:OnTrigger(library)
		self.StorageId = self.Script:GetAttribute("StorageId") or self.StorageId;
		
		local exist = false;
		if library.modData.Storages[self.StorageId] == nil then
			interactMeta.Label = self.LoadingLabel or "Loading...";
			
			if tick()-lastInvoke < 1 then return end;
			lastInvoke = tick();
			
			local storage = remoteOpenStorageRequest:InvokeServer(self.Object, self.Script);
			if typeof(storage) ~= "table" then
				Debugger:Warn("Fail to load storage:", storage);
			end
			if storage then library.modData.SetStorage(storage); end
			
			if library.modData.Storages[self.StorageId] == nil then
				self.CanInteract = false;
				interactMeta.Label = self.EmptyLabel or "Empty "..self.StorageName;
				
			else
				exist = true;
			end
		else
			exist = true;
		end
		
		if exist then
			self.CanInteract = true;
			interactMeta.Label = "Open "..self.StorageName;
		end
	end
	
	return interact;
end

function Interactable.Trigger(tag, label, premium)
	local interact = Interactable.new();
	local interactMeta = getmetatable(interact);
	interactMeta.Label = label or "Activate";
	interactMeta.CanInteract = true;
	
	interact.Type = Types.Trigger;
	interact.TriggerTag = tag;
	interact.Label = label;
	--interact.IndicatorPresist = false;
	interact.Premium = premium == true;
	
	function interactMeta:OnInteracted(library)
		task.spawn(function()
			if self.TriggerEffect then 
				self.TriggerEffect(self);
			end
		end)
		remoteOnTrigger:InvokeServer(self.Object, self.Script);
	end
	
	return interact;
end

-- name Raid, stage SectorF;
function Interactable.GameMode(name, stage, label)
	local interact = Interactable.new();
	local interactMeta = getmetatable(interact);
	interactMeta.CanInteract = true;
	interactMeta.Label = "Enter "..name..": "..stage;
	
	if stage == "Random" then
		interact.Random = true;
	end
	interact.Type = Types.GameMode;
	interact.Name = name;
	interact.Stage = stage;
	interact.Label = label;
	
	function interact:OnSync(data)
		self.Label = data.Label or self.Label;
		
		self.CanInteract = data.CanInteract or self.CanInteract;
		self.InspectMode = data.InspectMode or self.InspectMode;
		
	end
	
	function interactMeta:OnTrigger()
		if self.Random == true and (self.LastRandom == nil or tick()-self.LastRandom > 1) then
			self.LastRandom = tick();
			
			local list = {};
			for k, v in pairs(modGameModeLibrary.GameModes.Boss.Stages) do
				if v.IsExtreme ~= true then
					table.insert(list, {Index=(v.Index or 999); Key=k;});
				end
			end
			table.sort(list, function(a, b) return a.Index < b.Index; end);
			
			if self.SelectIndex == nil or self.SelectIndex >= #list then
				self.SelectIndex = 1;
				
			else
				self.SelectIndex = self.SelectIndex +1;
				
			end
			
			stage = list[self.SelectIndex].Key;
			self.Stage = stage;
			
			self.CanInteract = true;
			self.Label = "Enter "..name..": "..stage;
		end
		
		local stageLib = modGameModeLibrary.GameModes[name] and modGameModeLibrary.GameModes[name].Stages[stage];
		if self.Random == true then
		elseif stageLib == nil or modGameModeLibrary.GameModes[name].Stages[stage].Disabled then
			if RunService:IsStudio()
			and modGameModeLibrary.GameModes[name]
			and modGameModeLibrary.GameModes[name].Stages[stage]
			and modGameModeLibrary.GameModes[name].Stages[stage].Disabled then
				Debugger:Log("Work In Progress");
				return;
			end
			self.CanInteract = false;
			self.Label = "Work In Progress";
			
		else
			if stageLib.IsExtreme then
				interactMeta.Label = "Enter Extreme Boss: "..stage;
			end
			
		end
	end
	
	function interact:OnInteracted(library)
		task.delay(1, function()
			library.interface:ToggleGameBlinds(true, 0.5);
		end)
		library.interface:ToggleGameBlinds(false, 0.5);
		
		local timeLapse = tick();
		local lobbyData = remoteGameModeLobbies:InvokeServer(self.Object, self.Script, {StageSelect=self.Random == true and self.Stage or nil;});
		task.wait(math.clamp(0.5-(tick()-timeLapse), 0, 0.5));

		if lobbyData == nil then return; end

		bindOpenLobbyInterface:Fire(lobbyData);
	end
	
	return interact;
end

function Interactable.GameModeExit(name, stage, label)
	local interact = Interactable.new();
	local interactMeta = getmetatable(interact);
	interactMeta.CanInteract = true;
	interactMeta.Label = "Exit";
	
	interact.Type = Types.GameModeExit;
	interact.Name = name;
	interact.Stage = stage;
	interact.Label = label;
	interact.Enabled = false;
	
	function interact:OnInteracted(library)
		if name == "Raid" and workspace:GetAttribute("GameModeComplete") == true then
			task.delay(0.5, function()
				library.interface:ToggleGameBlinds(true, 0.5);
			end)
			library.interface:ToggleGameBlinds(false, 0.5);

			local timeLapse = tick();
			local gameTable = remoteGameModeLobbies:InvokeServer(self.Object, self.Script, {StageSelect=self.Random == true and self.Stage or nil;});
			task.wait(math.clamp(0.5-(tick()-timeLapse), 0, 0.5));
			
			bindOpenLobbyInterface:Fire(gameTable);
			return;
		end 
		
		local worldName = modBranchConfigs.GetWorldDisplayName(modBranchConfigs.WorldName);
		local promptWindow = library.interface:PromptQuestion("Leave ".. worldName .."?", "Are you sure you want to leave?");
		local YesClickedSignal, NoClickedSignal;
		
		local function exitPrompt()
			library.interface:ToggleGameBlinds(true, 1);
			SoundService:SetListener(Enum.ListenerType.ObjectCFrame, library.modCharacter.RootPart);
			library.modCharacter.CharacterProperties.CanMove = true;
			library.modCharacter.CharacterProperties.CanInteract = true;
		end
		
		YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
			library.interface:PlayButtonClick();
			library.interface:ToggleGameBlinds(false, 3);
			promptWindow:Close();
			library.modCharacter.CharacterProperties.CanMove = false;
			library.modCharacter.CharacterProperties.CanInteract = false;
			local success = remoteGameModeExit:InvokeServer(self.Object, self.Script);
			if success then
				SoundService:SetListener(Enum.ListenerType.CFrame, CFrame.new(0, 1000, 0));
			else
				exitPrompt();
				library.interface:ToggleGameBlinds(true, 1);
			end
			YesClickedSignal:Disconnect();
			NoClickedSignal:Disconnect();
		end);
		NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
			library.interface:PlayButtonClick();
			promptWindow:Close();
			exitPrompt();
			YesClickedSignal:Disconnect();
			NoClickedSignal:Disconnect();
		end);
	end
	
	return interact;
end

function Interactable.Collectible(collectibleId, desc)
	--local lib = modCollectiblesLibrary:Find(collectibleId);
	local interact = Interactable.new();
	local interactMeta = getmetatable(interact);
	interactMeta.Label = desc;
	interactMeta.CanInteract = true;
	
	interact.Type = Types.Collectible;
	interact.Id = collectibleId;
	
	function interact:OnInteracted(library)
		local interactObject = self.Object;
		local objectParent = interactObject.Parent;
		interactObject.Parent = game.ReplicatedStorage;
		local invokeRequest = remotePickUpRequest:InvokeServer(interactObject, self.Script);

		if invokeRequest == true then
			interactObject:Destroy();
			if self.OnSuccessfulPickup then self.OnSuccessfulPickup(self) end;
			modAudio.Play("Collectible", nil, nil, false);

		else
			if interactObject.Parent ~= nil then
				interactObject.Parent = objectParent;
				if objectParent:IsA("Model") then
					objectParent.PrimaryPart = interactObject;
				end
				Debugger:Print("Failed to collect",self.ItemName," due to:", invokeRequest);
			end

		end
	end
	
	function interact:OnTrigger(library)
		local collectiblesData = modTableManager.GetDataHierarchy(library.modData.Profile, "Collectibles");
		
		if collectiblesData and collectiblesData[self.Id] then
			Debugger.Expire(self.Object, 0);
		end
	end
	
	return interact;
end

function Interactable.SupplyCrate(src, boxName)
	local interact = Interactable.new();
	local interactMeta = getmetatable(interact);
	interactMeta.Label = "Supply Crate";
	interactMeta.CanInteract = true;
	
	interact.Type = Types.SupplyCrate;
	interact.Script = src;
	
	interact.UseLimit = src:GetAttribute("UseLimit");
	if interact.UseLimit ~= nil then
		interact.PlayerUses = {};
	end
	
	interact.IndicatorPresist = false;

	function interactMeta:OnTrigger()
		if self.UseLimit and self.PlayerUses and (self.PlayerUses[game.Players.LocalPlayer.Name] or 0) >= self.UseLimit then
			self.Disabled = "You have exhausted your uses.";
			
			if self.Object and self.Object.Parent:FindFirstChild("AmmoBoxBase") then
				for _, obj in pairs(self.Object.Parent:GetChildren()) do
					if obj.Name == "Ammo" then
						Debugger.Expire(obj, 0);
					end
				end
			end
			
			return;
		end

		self.Label = "Use ".. (boxName or "Supply Crate");
	end
	
	function interact:OnInteracted(library)
		if self.Disabled then return end;
		
		library.interface.Object = self.Object;
		library.interface:ToggleWindow("SupplyStation", self);
	end
	
	return interact;
end

function Interactable.Toggle(label)
	local interact = Interactable.new();
	local interactMeta = getmetatable(interact);
	interactMeta.Label = label;
	interactMeta.CanInteract = true;
	
	interact.Type = Types.Toggle;
	interact.Active = false;
	interact.Label = nil;
	
	function interactMeta:OnTrigger()
		if self.Label:match("Lever") then
			if self.Active then
				self.Animation = "UnpullLever";
			else
				self.Animation = "PullLever";
			end
		end
	end
	
	function interact:OnInteracted()
		if RunService:IsServer() then return end;
		
		if self.OnToggle then
			self:OnToggle(player);
		end
		
		remoteInteractableToggle:FireServer(self.Object, self.Script);
	end
	
	return interact;
end

function Interactable.Interface(windowName, label, ...)
	local interact = Interactable.new();
	local interactMeta = getmetatable(interact);
	interactMeta.Label = label or "Open Interface";
	interactMeta.CanInteract = true;
	
	interact.Type = Types.Interface
	interact.IndicatorPresist = false;
	interact.InterfaceName = windowName;
	
	local params = {...};
	function interact:OnInteracted(library)
		if library.interface:IsVisible(self.InterfaceName) then return end;
		
		library.interface.Object = self.Object;
		library.interface.InteractData = self;
		library.interface:ToggleWindow(self.InterfaceName, nil, unpack(params));
	end
	
	return interact;
end

function Interactable.Revive(player)
	local interact = Interactable.new();
	local interactMeta = getmetatable(interact);
	interactMeta.Label = "Heal";
	interactMeta.CanInteract = true;
	
	interact.Type = Types.Revive
	interact.IndicatorPresist = true;
	interact.Player = player;
	interact.InteractDuration = 6;
	
	function interactMeta:OnTrigger(library)
		local equippedItem = library.modCharacter.EquippedItem;
		if equippedItem == nil then
			interact.CanInteract = false;
			interact.Label = "Requires medkit";
			return;
			
		else
			local modTools = require(game.ReplicatedStorage.Library.Tools);
			local toolLib = modTools[equippedItem.ItemId];
			
			if toolLib == nil or toolLib.WoundEquip ~= true then
				interact.CanInteract = false;
				interact.Label = "Requires medkit";
				return;
			end
			
			interact.CanInteract = true;
			interact.Label = nil;
		end
		
	end
	
	function interact:OnStartInteract()
		remoteReviveInteract:FireServer(self, true);
	end
	
	function interact:OnInteracted(library)
		library.interface.Object = self.Object;
		remoteReviveInteract:FireServer(self, false);
	end
	
	return interact;
end

function Interactable.Hold(src, label)
	local interact = Interactable.new();
	local interactMeta = getmetatable(interact);
	interactMeta.Label = label or "";
	interactMeta.CanInteract = true;
	
	interact.InteractableRange = 8;
	interact.CaptureHold = true;
	interact.Script = src;
	interact.Type = Types.Hold;
	interact.Active = false;
	interact.Label = nil;
	
	return interact;
end


function Interactable.CardGame(src)
	local interact = Interactable.new();
	local interactMeta = getmetatable(interact);
	interactMeta.Label = "Request";
	interactMeta.CanInteract = true;

	interact.Type = Types.CardGame
	interact.IndicatorPresist = false;
	
	local lastFetch = tick()-2;
	function interactMeta:OnTrigger(library)
		local rPacket = {
			CanQueue = false;
			CanSpectate = false;
		};

		if tick()-lastFetch >= 1 then
			lastFetch = tick();
			rPacket = remoteCardGame:InvokeServer("request", {Interactable=src;});
		end
		
		if rPacket.CanQueue then
			interact.Label = "Request to join";
			
		elseif rPacket.CanSpectate then
			interact.Label = "Spectate";
	
		end
	end
	
	function interact:OnInteracted(library)
		library.interface.Object = self.Object;
		local rPacket = remoteCardGame:InvokeServer("requestjoin", {Interactable=src;});
		
		if rPacket.Success then
			library.interface:OpenWindow("CardGameWindow");
		end
	end

	return interact;
end


function Interactable.Seat(src)
	local interact = Interactable.new();
	local interactMeta = getmetatable(interact);
	interactMeta.Label = "Sit";
	interactMeta.CanInteract = true;

	interact.Type = Types.Seat
	interact.IndicatorPresist = false;

	function interactMeta:OnTrigger(library)
		if self.SeatPart == nil then
			self.SeatPart = src.Parent:FindFirstChildWhichIsA("Seat");
		end
		
		if self.SeatPart then
			if self.SeatPart.Occupant == nil then
				interact.Label = nil;
				interact.CanInteract = true;
			else
				interact.Label = "";
				interact.CanInteract = false;
			end
			
		else
			interact.Label = "Seat is broken";
			interact.CanInteract = false;
		end
	end

	function interact:OnInteracted(library)
		library.interface.Object = self.Object;
		
		local _returnPacket = remoteCharacterInteractions:InvokeServer("sit", {InteractableScript=src});
	end

	return interact;
end

function Interactable.Terminal()
	local interact = Interactable.new();
	local interactMeta = getmetatable(interact);
	interactMeta.Label = "Access Terminal";
	interactMeta.CanInteract = true;

	interact.Type = Types.Terminal
	interact.IndicatorPresist = false;
	interact.ItemRequired = "rcetablet";

	function interactMeta:OnTrigger(library)
		if interact.ItemRequired == "rcetablet" then
			interact.Label = "Hijack with RCE Tablet";
		end
	end
	
	function interact:OnInteracted(library)
		if library.interface:IsVisible("TerminalWindow") then return end;

		library.interface.Object = self.Object;
		library.interface.InteractData = self;
		library.interface:ToggleWindow("TerminalWindow", nil, self.TerminalData);
	end

	return interact;
end

function Interactable.InteractProxy()
	local interact = Interactable.new();
	
	local interactMeta = getmetatable(interact);
	interactMeta.Label = "Use";
	interactMeta.CanInteract = true;

	interact.Type = "InteractProxy";
	interact.IndicatorPresist = true;
	interact.Player = nil;
	interact.InteractDuration = 6;

	function interactMeta:OnTrigger(library)
	end

	function interact:OnStartInteract()
		Debugger:Warn("InteractProxy OnStartInteract");
	end

	function interact:OnInteracted(library)
		Debugger:Warn("InteractProxy OnInteracted");
	end

	return interact;
end

Interactable.Premade = {
	SafehouseStorage = Interactable.Storage(nil, "Safehouse", "Safehouse Storage", {Persistent=true; Size=24; Expandable=true; MaxSize=50; MaxPages=3;});
	Freezer = Interactable.Storage(nil, "Freezer", "Food Storage", {Persistent=true; Size=10; Expandable=true; MaxSize=20;});
	Wardrobe = Interactable.Storage(nil, "Wardrobe", "Wardrobe");
	
	RatStorage = Interactable.Storage(nil, "RatStorage", "Rat Storage", {Persistent=true; Settings={ScaleByContent=1; Rental=5;}; Size=50; MaxSize=50; MaxPages=9;});
};
Interactable.Premade.RatStorage.MissionRequired = {Id = 62; Type = {3};};

for _, obj in pairs(script:GetChildren()) do
	if obj:IsA("ModuleScript") then
		task.spawn(function()
			require(obj):Init(Interactable, Interactable);
		end)
	end
end

local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetModule(script.Name);
if moddedSelf then moddedSelf:Init(Interactable); end

return Interactable;