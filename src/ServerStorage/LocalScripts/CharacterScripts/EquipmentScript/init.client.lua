local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local function lerp(a, b, t) return a * (1-t) + (b*t); end

--== Variables;
local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;
local character = script.Parent;
local humanoid: Humanoid = character:WaitForChild("Humanoid");
local animator = humanoid:WaitForChild("Animator");

for a=0, 60 do
	if workspace:IsAncestorOf(animator) then
		break;
	else
		task.wait();
	end
end
if not workspace:IsAncestorOf(animator) then return end;

local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
local modCharacter = modData:GetModCharacter();

local toolHandlers = script:WaitForChild("ToolHandlers");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modWeapons = require(game.ReplicatedStorage.Library.Weapons);
local modTools = require(game.ReplicatedStorage.Library.Tools);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modGarbageHandler = require(game.ReplicatedStorage.Library.GarbageHandler);
local modWeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

--== Handlers
local modWeaponHandler = require(script:WaitForChild("WeaponHandler"));
local modMeleeHandler = require(script.ToolHandlers:WaitForChild("Melee")); modMeleeHandler:InitStaminaSystem();
local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);

--== Remotes;
local bindCharacterInput = script:WaitForChild("CharacterInput");

local remoteToolHandler = modRemotesManager:Get("ToolHandler");
local remoteToolInputHandler = modRemotesManager:Get("ToolInputHandler") :: RemoteEvent;

local BaseEquipped = {LeftHand={}; RightHand={}; Animations={};};
local Equipped = modGlobalVars.CloneTable(BaseEquipped);
Equipped.Garbage = modGarbageHandler.new();
Equipped.Player = localPlayer;

local instanceCache = {};
--== Script;
modWeaponHandler.InstanceCache = instanceCache;
modWeaponHandler:Initialize(Equipped);
modWeaponProperties.LoadExternalModifiers();

function getToolHandler(itemId)
	local handler;
	
	if game.ReplicatedStorage:FindFirstChild("ModLibrary") then
		handler = game.ReplicatedStorage.ModLibrary:FindFirstChild("ClientToolHandlers")
			and game.ReplicatedStorage.ModLibrary.ClientToolHandlers:FindFirstChild(modTools[itemId].Type);
	elseif game.ReplicatedStorage:FindFirstChild("BaseLibrary") then
		handler = game.ReplicatedStorage.BaseLibrary:FindFirstChild("ClientToolHandlers")
			and game.ReplicatedStorage.BaseLibrary.ClientToolHandlers:FindFirstChild(modTools[itemId].Type);
	end

	if handler == nil then
		handler = toolHandlers:FindFirstChild(modTools[itemId].Type);
	end
	
	return handler;
end

function equip(equipPacket, toolWelds)
	local id = equipPacket and equipPacket.StorageItem and equipPacket.StorageItem.ID;
	
	if id == nil then Debugger:Warn("Failed to equip item, missing id."); return end;
	if modCharacter.CharacterProperties.IsEquipped then return end;
	
	if equipPacket.MockEquip then
		for k, v in pairs(equipPacket.StorageItem) do
			modData.MockStorageItem[k] = v;
		end
	end
	
	local equipmentItem = modData.GetItemById(id);
	if equipmentItem then
		local itemId = equipmentItem.ItemId;

		for k, obj in pairs(instanceCache) do
			if obj then obj:Destroy() end;
			instanceCache[k] = nil;
		end
		
		local toolModels = {};
		for a=1, #equipPacket.WeldPacket do
			local weldPacket = equipPacket.WeldPacket[a];
			local equippedTable = Equipped[weldPacket.Hand.Name];
			if equippedTable then
				for k, v in pairs(weldPacket) do
					equippedTable[k] = v;
				end
				
			end
			
			table.insert(toolModels, weldPacket.Prefab);
		end
		
		for k, equippedTable in pairs(Equipped) do
			if k == "LeftHand" or k == "RightHand" then
				equippedTable.Item = equipmentItem;
			end;
		end
		
		for a=1, #toolModels do
			local toolModel = toolModels[a] :: Model;
			local handle = toolModel.PrimaryPart;

			if localPlayer.Character:FindFirstChild("EditMode") then
				if handle:FindFirstChild("SightViewModel") == nil then
					local new = Instance.new("Attachment");
					new.Name = "SightViewModel";
					new.Parent = handle;
				end
			end

			-- Make sure to unequip locally if tool gets deleted
			Equipped.Garbage:Tag(character.ChildRemoved:Connect(function(child) 
				if child ~= toolModel then return end;
				task.wait(0.6);
				if modCharacter.EquippedItem == nil then return end;
				if modCharacter.EquippedItem and id ~= modCharacter.EquippedItem.ID then return end;
				if id == "MockStorageItem" then if modCharacter.EquippedItem.ItemId ~= itemId then return end end;

				modData.HandleTool("local", {Unequip={
					Id=modCharacter.EquippedItem.ID;
					StorageItem = equipmentItem;
				};});
			end));
		end
		
		if modData.Profile and modData.Profile.ItemCustomizationBan and modData.Profile.ItemCustomizationBan >= 1 then
			local modCustomizationData = require(game.ReplicatedStorage.Library.CustomizationData);

			local weaponModelsData = modCustomizationData.LoadWeaponModelsData(itemId, toolModels);
			local partDataList = modCustomizationData.LoadPartDataList(itemId, weaponModelsData);
			modCustomizationData.ClientLoadCustomizations(equipmentItem, partDataList);
		end
		

		if modWeapons[itemId] then 
			modWeaponHandler:Equip(modWeapons[itemId], id);
		end
		if modTools[itemId] then
			local handler = getToolHandler(itemId);
			
			if handler then
				handler = require(handler);
				handler.InstanceCache = instanceCache;
				handler:Initialize(Equipped);
				handler:Equip(equipmentItem, toolModels);
				
			end
		end
		
		local toolModule = modData:GetItemClass(id);
		if toolModule and toolModule.SetActive then
			toolModule:SetActive(true);
		end

		modCharacter.CharacterProperties.IsEquipped = true;
		modCharacter.EquippedItem = equipmentItem; -- StorageItem;
		modCharacter.EquippedToolModule = toolModule;
		
		if modCharacter.CharacterProperties.ActiveInteract then
			modCharacter.CharacterProperties.ActiveInteract:Trigger();
		end
	else
		Debugger:Warn("Item (",id,") does not exist in inventory.");
	end
end

-- MARK: Unequip()
function Unequip(unequipPacket)
	local storageItem = unequipPacket and unequipPacket.StorageItem or nil;
	local id = storageItem and storageItem.ID or unequipPacket.Id;
	
	if id == nil then Debugger:Warn("Failed to unequip item, missing id."); return end;
	if not modCharacter.CharacterProperties.IsEquipped then return end;
	if modCharacter.EquippedItem == nil or modCharacter.EquippedItem.ID ~= id then return end;
	
	local equipmentItem = modData.GetItemById(id) or storageItem;
	local toolModule = modData:GetItemClass(id);
	
	if storageItem and storageItem.MockItem == true then
		equipmentItem = storageItem;
	end

	if toolModule and toolModule.SetActive then
		toolModule:SetActive(false);
	end

	if equipmentItem then
		local itemId = equipmentItem.ItemId;
		
		modCharacter.MouseProperties.Mouse1Down = false;
		modCharacter.MouseProperties.Mouse2Down = false;
		
		if modWeapons[itemId] then
			modWeaponHandler:Unequip(id);

		end
		if modTools[itemId] then 
			local handler = getToolHandler(itemId);
			
			if handler then
				handler = require(handler);
				handler:Initialize(Equipped);
				handler:Unequip(equipmentItem);
				
			end
			
			for k, v in pairs(Equipped.LeftHand) do Equipped.LeftHand[k] = nil; end;
			for k, v in pairs(Equipped.RightHand) do Equipped.RightHand[k] = nil; end;
			for k, v in pairs(Equipped) do
				if BaseEquipped[k] == nil and k ~= "Garbage" then
					Equipped[k] = nil;
				end
			end
		end

		Equipped.Garbage:Destruct();
		
		modCharacter.CharacterProperties.IsEquipped = false;
		modCharacter.CharacterProperties.HideCrosshair = false;
		modCharacter.EquippedItem = nil;
		modCharacter.EquippedToolModule = nil;
		
		if modCharacter.CharacterProperties.ActiveInteract then
			modCharacter.CharacterProperties.ActiveInteract:Trigger();
		end
	end
	
	for k, v in pairs(Equipped.Animations) do
		local trackName = tostring(v);
		if trackName:match("Unequip") then continue end;
		
		Equipped.Animations[k]:Stop();
		Equipped.Animations[k] = nil;
	end;
	for k, track in pairs(animator:GetPlayingAnimationTracks()) do
		local trackName = tostring(track);
		if trackName:match(":") and trackName:match("Unequip") == nil then
			track:Stop();
		end
	end
end

function handleTool(returnPacket)
	if returnPacket.Unequip then
		Unequip(returnPacket.Unequip);
	end
	
	if returnPacket.Equip then
		local authSeed = returnPacket.Equip.AuthSeed;
		
		if modData.Profile.Cache == nil then modData.Profile.Cache = {}; end
		modData.Profile.Cache.AuthSeed = authSeed;
		modData.ShotIdGen = Random.new(authSeed);
		
		equip(returnPacket.Equip, returnPacket.Equip.Welds);
	end
end

modData.HandleTool = function(action, paramPacket)
	if action == "local" then
		handleTool(paramPacket);
		return;
	end
	
	coroutine.wrap(function()
		local returnPacket = remoteToolHandler:InvokeServer(action, {Id=paramPacket.Id});
		handleTool(returnPacket);
	end)()
end

function remoteToolHandler.OnClientInvoke(returnPacket)
	handleTool(returnPacket);
	return;
end

UserInputService.InputBegan:connect(function(inputObject, inputEvent)
	if UserInputService:GetFocusedTextBox() ~= nil or inputEvent then return end;
	if not modCharacter.CharacterProperties.IsEquipped then return end;
	
	for _, equipment in pairs(Equipped) do
		if typeof(equipment) == "table" then
			for keyId, func in pairs(equipment) do
				if typeof(func) == "function" and modKeyBindsHandler:Match(inputObject, keyId) then
					if keyId == "KeyInteract" then
						modKeyBindsHandler:HandleKey("KeyInteract", 10, function()
							func();
						end);
					else
						func();
					end
				end
			end
		end
	end
	
	for _, equipment in pairs(Equipped) do
		if typeof(equipment) ~= "table" then continue end;
		
		if equipment.OnInputEvent then
			Equipped.Player = localPlayer;
			
			local keyIds = modKeyBindsHandler:GetKeyIds(inputObject);
			
			local inputData = {
				InputType="Begin";
				InputObject = inputObject;
				
				KeyIds=keyIds and modGlobalVars.CloneTable(keyIds) or {};
				KeyCode = inputObject.KeyCode;
			};
			
			local submitInput = equipment.OnInputEvent(Equipped, inputData);
			if submitInput then
				
				inputData.Action = "input";
				remoteToolInputHandler:FireServer(modRemotesManager.Compress(inputData));
				
			end
		end
	end
end)

UserInputService.InputEnded:Connect(function(inputObject, inputEvent)
	if UserInputService:GetFocusedTextBox() ~= nil then return end;-- or inputEvent
	if not modCharacter.CharacterProperties.IsEquipped then return end;
	
	for _, equipment in pairs(Equipped) do
		if typeof(equipment) == "table" then
			if equipment.OnInputEvent then
				Equipped.Player = localPlayer;

				local keyIds = modKeyBindsHandler:GetKeyIds(inputObject);
				
				local inputData = {
					InputType="End";
					KeyIds=keyIds and modGlobalVars.CloneTable(keyIds) or {};
					KeyCode = inputObject.KeyCode;
				};
				
				local submitInput = equipment.OnInputEvent(Equipped, inputData);
				if submitInput then
					inputData.Action = "input";
					remoteToolInputHandler:FireServer(modRemotesManager.Compress(inputData));
					
				end
				
			end
		end
	end
end)

bindCharacterInput.Event:Connect(function(keyId, inputState) -- max rentry pass
	for _, equipment in pairs(Equipped) do
		if typeof(equipment) == "table" then
			local triggerEvent = equipment[keyId];
			if triggerEvent then triggerEvent(); end
			
			if equipment.OnInputEvent then
				Equipped.Player = localPlayer;

				local inputData = {
					InputType=(inputState or "Begin");
					KeyIds={[keyId]=true};
				};
				
				local submitInput = equipment.OnInputEvent(Equipped, inputData);
				if submitInput then

					inputData.Action = "input";
					remoteToolInputHandler:FireServer(modRemotesManager.Compress(inputData));
					
				end
			end
			
		end
	end
end)

humanoid.StateChanged:Connect(function(old: Enum.HumanoidStateType, new: Enum.HumanoidStateType)
	if not workspace:IsAncestorOf(humanoid) then return end;
	
	lerp(0,0,0);
	if Equipped.OnHumanoidStateChanged then
		Equipped.OnHumanoidStateChanged(old, new);
	end
end)

RunService:BindToRenderStep("ToolRender", Enum.RenderPriority.Last.Value, function(delta)
	if not workspace:IsAncestorOf(humanoid) then return end;
	if Equipped.OnToolRender then
		Equipped.OnToolRender(delta);
	end
end);

task.spawn(function()
	Debugger.AwaitShared("modPlayers");
	local classPlayer = shared.modPlayers.Get(localPlayer);
	classPlayer:OnNotIsAlive(function(character)
		if modCharacter.CharacterProperties.IsEquipped and modCharacter.EquippedItem and modCharacter.EquippedItem.ID then
			modData.HandleTool("unequip", {Id=modCharacter.EquippedItem.ID;});
		end
	end)
	
end)

script:WaitForChild("EquipReady").Value = true;