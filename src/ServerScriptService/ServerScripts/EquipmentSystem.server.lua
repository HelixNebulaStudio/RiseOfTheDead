local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
repeat task.wait() until shared.MasterScriptInit == true;

--== Variables;
local RunService = game:GetService("RunService");

local modGlobalVars = Debugger:Require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modItemsLibrary = Debugger:Require(game.ReplicatedStorage.Library.ItemsLibrary);
local modWeapons = Debugger:Require(game.ReplicatedStorage.Library.Weapons);
local modColorsLibrary = Debugger:Require(game.ReplicatedStorage.Library.ColorsLibrary);
local modSkinsLibrary = Debugger:Require(game.ReplicatedStorage.Library:WaitForChild("SkinsLibrary"));
local modProjectile = Debugger:Require(game.ReplicatedStorage.Library.Projectile);
local modWeaponAttributes = Debugger:Require(game.ReplicatedStorage.Library.WeaponsAttributes);
local modAudio = Debugger:Require(game.ReplicatedStorage.Library.Audio);
local modDropAppearance = Debugger:Require(game.ReplicatedStorage.Library.DropAppearance);
local modRemotesManager = Debugger:Require(game.ReplicatedStorage.Library.RemotesManager);
local modGarbageHandler = Debugger:Require(game.ReplicatedStorage.Library.GarbageHandler);
local modConfigurations = Debugger:Require(game.ReplicatedStorage.Library.Configurations);
local modItemSkinWear = Debugger:Require(game.ReplicatedStorage.Library.ItemSkinWear);
local modTools = Debugger:Require(game.ReplicatedStorage.Library.Tools);

local modProfile = Debugger:Require(game.ServerScriptService.ServerLibrary.Profile);
local modMission = Debugger:Require(game.ServerScriptService.ServerLibrary.Mission);
local modOnGameEvents = Debugger:Require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modAnalytics = Debugger:Require(game.ServerScriptService.ServerLibrary.GameAnalytics);


local prefabsItems = game.ReplicatedStorage.Prefabs.Items;

--ToolHandler
local remotes = game.ReplicatedStorage.Remotes;
local remoteToolHandler = modRemotesManager:Get("ToolHandler");
local remoteToolInputHandler = modRemotesManager:Get("ToolInputHandler");
local remoteToolPrimaryFire = modRemotesManager:Get("ToolHandlerPrimaryFire");
local remoteReloadWeapon = modRemotesManager:Get("ReloadWeapon");

shared.EquipmentSystem = {};
local bindServerEquipPlayer = remotes.Inventory.ServerEquipPlayer;
local bindServerUnequipPlayer = remotes.Inventory.ServerUnequipPlayer;

local debounce = {};
--== Script

local function OnPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		Debugger:Log(character.Name,"spawned.");
		local profile = modProfile:Get(player);
		if profile == nil then Debugger:WarnClient(player, "Could not retrieve profile. Equipment system disabled, please respawn to try again."); return end;
		
		local modGearAttachments = require(player.Character:WaitForChild("GearAttachments"));
		
		for itemId, toolHandler in pairs(profile.ToolsCache) do
			local prefabs = {};
			if toolHandler.ToolConfig == nil then
				Debugger:Log(itemId,"tool missing toolconfig");
			end
			local storageItem = toolHandler.StorageItem;
			
			if toolHandler.ToolConfig and toolHandler.ToolConfig.Holster then
				for attachmentName, holsterLib in pairs(toolHandler.ToolConfig.Holster) do
					local prefabName = holsterLib.PrefabName;
					local prefabTool = prefabsItems:FindFirstChild(prefabName);
					if prefabTool == nil then
						Debugger:Warn("Tool prefab for (",itemId,") does not exist for holster!");
						return;
					end;
					
					local cloneTool = prefabTool:Clone();
					local handle = cloneTool:WaitForChild("Handle");
					if handle:CanSetNetworkOwnership() then handle:SetNetworkOwner(player); end
					table.insert(prefabs, cloneTool);
					
					local attachment = character:FindFirstChild(attachmentName, true);
					local motor = modGearAttachments:CreateAttachmentMotor(attachment);
					motor.Name = prefabName.."Holster";

					if holsterLib.C1 then
						motor.C1 = holsterLib.C1;
					end
					if holsterLib.Offset then
						motor.C1 = motor.C1 * holsterLib.Offset;
					end
					
					cloneTool.Parent = player.Character;
					motor:SetAttribute("CanQuery", false);
					modGearAttachments:AttachMotor(cloneTool, motor, attachment.Parent, 2);
					modColorsLibrary.ApplyAppearance(cloneTool, storageItem.Values);
				end
			end
			profile.ToolsCache.Prefabs = prefabs;
		end
	end)
end;

function unequipTool(player, returnPacket)
	local profile = modProfile:Find(player.Name);
	local lastStorageItem = profile and profile.EquippedTools and profile.EquippedTools.StorageItem;
	local lastId = profile and profile.EquippedTools and profile.EquippedTools.ID;
	
	returnPacket = returnPacket or {};
	
	Debugger:Log("unequipTool returnPacket", returnPacket, " EquippedTools",profile.EquippedTools);
	
	if lastId then
		local itemId = lastStorageItem.ItemId;
		
		returnPacket.Unequip = {
			Id=lastId;
			StorageItem=lastStorageItem;
		}
		
		local toolLib = modWeapons[itemId] or modTools[itemId];
		if toolLib == nil then error("Attempt to find toolLib with key, "..(itemId or "nil")); end;
		local handler = profile.ToolsCache[lastId];
		
		if player == nil or player.Character == nil then return returnPacket; end;
		local modGearAttachments = require(player.Character:FindFirstChild("GearAttachments"));
		
		if profile.EquippedTools.WeaponModels then
			local preexistingMotors = {};
			for a=1, #profile.EquippedTools.ToolWelds do
				local motor = profile.EquippedTools.ToolWelds[a];
				if handler and handler.ToolConfig.Holster and motor.Part1 then
					modGearAttachments:Detach(motor.Part1.Parent, motor.Name);
				end
				table.insert(preexistingMotors, motor);
				game.Debris:AddItem(motor, 1);
			end
			
			for a=1, #profile.EquippedTools.WeaponModels do
				local weaponModel = profile.EquippedTools.WeaponModels[a];
				weaponModel:SetAttribute("Equipped", false);
				
				if weaponModel.Parent ~= nil and (handler == nil or handler.ToolConfig.Holster == nil) then
					for _, obj in pairs(weaponModel:GetDescendants()) do
						if obj:IsA("RopeConstraint") then obj.Visible = false; end;
					end
					game.Debris:AddItem(weaponModel, returnPacket.ToolSwap and 0 or 0.6);
					modGearAttachments:DestroyAttachments(weaponModel);
					Debugger:Log("Destroy toolModel");
					
				elseif handler and handler.ToolConfig.Holster then
					for attachmentName, holsterLib in pairs(handler.ToolConfig.Holster) do
						local prefabName = holsterLib.PrefabName;
						if prefabName == weaponModel.Name and player.Character:FindFirstChild(prefabName.."Holster", true) == nil then
							local attachment = player.Character:FindFirstChild(attachmentName, true);
							local motorName = attachmentName.."Motor";
							
							local motor = modGearAttachments:CreateAttachmentMotor(attachment);
							if motor then
								local baseMotorC1 = motor.C1;
								if holsterLib.C1 then
									motor.C1 = holsterLib.C1;
									baseMotorC1 = motor.C1;
								end
								if RunService:IsStudio() then
									if holsterLib.Offset then
										motor:SetAttribute("Offset", holsterLib.Offset);
									end
									motor:GetAttributeChangedSignal("Offset"):Connect(function()
										local offset = motor:GetAttribute("Offset");
										motor.C1 = baseMotorC1 * offset;
										Debugger:Warn(motor.Name,"Offset updated");
									end)
								end
								if holsterLib.Offset then
									motor.C1 = baseMotorC1 * holsterLib.Offset;
								end
								motor.Name = prefabName.."Holster";
								motor:SetAttribute("CanQuery", false);
								
								modGearAttachments:AttachMotor(weaponModel, motor, attachment.Parent, 2);
							end
						end
					end
					
					for _, motor in pairs(preexistingMotors) do
						game.Debris:AddItem(motor, 0);
					end
					
				end
			end
			
		end
		
		local inventory = profile.ActiveInventory;
		local storageItem = inventory and inventory.Find and inventory:Find(lastId);
		if storageItem then
			storageItem:DeleteValues("IsEquipped"):Sync();
		end
		--if inventory then inventory:DeleteValues(lastId, "IsEquipped"); end
		
		if profile.EquippedTools.Tick and profile.EquippedTools.ItemId then
			pcall(function()
				local playerSave = profile:GetActiveSave();
				local playerLevel = playerSave:GetStat("Level") or 0;
				
				local duration = math.floor(tick()-profile.EquippedTools.Tick);
				if duration <= 10 then return end;
				
				local key = "Wield:"..profile.EquippedTools.ItemId;

				if toolLib.IsWeapon then
					if playerLevel > (modGlobalVars.MaxLevels * 0.75) then
						modAnalytics.RecordDesign(player.UserId, key, duration);
					end
				else
					profile.Analytics:LogTime(key, duration);
					
				end
			end)
		end
		
		if lastStorageItem.MockItem then
			profile.ToolsCache[lastStorageItem.ItemId] = nil;
		end
		
		if toolLib.IsWeapon ~= true then
			if handler and handler.OnToolUnequip then
				handler:OnToolUnequip();
			end
			
		end
		
		modOnGameEvents:Fire("OnToolUnequipped", player, storageItem);
		profile.EquippedTools = {};
	end
	
	Debugger:Log("Unequip");
end

local function equipTool(player, paramPacket)
	local id = paramPacket.Id;
	local profile = modProfile:Get(player);
	
	local returnPacket = {};
	
	local mockEquip = paramPacket.MockEquip == true;
	
	local function equip()
		if player.Character == nil or player.Character.Parent == nil then
			Debugger:Warn("Player(",player.Name,") attempting to equip while parented to nil.");
			return;
		end
		
		local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid");
		local modGearAttachments = require(player.Character:FindFirstChild("GearAttachments"));
		
		if humanoid == nil then
			Debugger:Warn("Player(",player.Name,") attempting to equip without humanoid.");
			return;
		end
		
		local inventory = profile.ActiveInventory;
		local storageItem = inventory and inventory.Find and inventory:Find(id);
		
		if mockEquip then
			local itemId = paramPacket.ItemId;
			
			if profile.ItemClassesCache["MockStorageItem"] then
				profile.ItemClassesCache["MockStorageItem"] = nil;
			end
			storageItem = profile.MockStorageItem;
			table.clear(storageItem.Values);
			storageItem:SetItemId(itemId);
			storageItem:Sync();
			id = storageItem.ID;
			
			Debugger:Log("Mock equip",paramPacket, " StorageItem:", storageItem, storageItem.ItemId);
		else
			if modConfigurations.DisableNonMockEquip == true then
				Debugger:Log("Attempt to equip non-mock item.");
				return;
			end
		end
		
		if storageItem then
			modItemSkinWear.Generate(player, storageItem);
			
			local itemId = storageItem.ItemId;
			local itemProperties = modItemsLibrary:Find(itemId);
			
			local toolLib = modWeapons[itemId] or modTools[itemId];
			
			if toolLib == nil then warn("Attempt to find toolLib with key, "..(itemId or "nil")); end;
			if humanoid.Health <= 0 and toolLib.WoundEquip ~= true then Debugger:Warn("Player(",player.Name,") attempt to equip when wounded.") return end;
			
			if itemProperties.Equippable and toolLib then
				local toolModule = profile:GetItemClass(id, mockEquip);
				
				task.spawn(function()
					if toolLib.IsWeapon then
						if profile.InfAmmo then
							toolModule.Configurations.InfiniteAmmo = profile.InfAmmo;
						end
						
						if toolModule.Configurations.BulletMode == modWeaponAttributes.BulletModes.Projectile then
							modProjectile.Load(toolModule.Configurations.ProjectileId);
						end
					end
				end);
				
				local newWelds, newModels = {}, {};
				local weldPacket = {};
				
				local weldsCount = 0;
				for _,_ in pairs(toolLib.Welds) do
					weldsCount = weldsCount+1;
				end
				if weldsCount == 0 then Debugger:Warn("Tool (",itemId,") does not have any welds"); end;
				
				for weldName, prefabName in pairs(toolLib.Welds) do
					
					local prefabTool = prefabsItems:FindFirstChild(prefabName);
					if prefabTool == nil then
						Debugger:Warn("Tool prefab for (",itemId,") does not exist!");
						return returnPacket;
					end;
					
					local motor;
					if prefabTool:FindFirstChild("WieldConfig") and prefabTool.WieldConfig:FindFirstChild(weldName) then
						motor = prefabTool.WieldConfig[weldName]:Clone();
						
					elseif toolLib.Module:FindFirstChild(weldName) then
						motor = toolLib.Module[weldName]:Clone();
						
					end
					
					local toolModelName = prefabName;
					if weldName == "RightToolGrip" and weldName ~= "ToolGrip" then
						toolModelName = "Right"..prefabName;

					elseif weldName == "LeftToolGrip" then
						toolModelName = "Left"..prefabName;

					end
					
					
					local cloneTool = modGearAttachments:GetAttachedPrefab(toolModelName) or prefabTool:Clone(); -- getExistingPrefab or

					cloneTool:SetAttribute("ItemId", itemId);
					cloneTool:SetAttribute("StorageItemId", id);
					
					local handle = cloneTool:WaitForChild("Handle");
					if handle:CanSetNetworkOwnership() then handle:SetNetworkOwner(player); end
					cloneTool.Parent = player.Character;
					if profile.InfAmmo then
						cloneTool:SetAttribute("InfAmmo", profile.InfAmmo);
					end
					cloneTool:SetAttribute("Equipped", true);
					table.insert(newModels, cloneTool);
					
					local dropAppearanceLib = modDropAppearance:Find(itemId);
					if dropAppearanceLib then
						modDropAppearance.ApplyAppearance(dropAppearanceLib, cloneTool);
					end
					
					for _, part in pairs(cloneTool:GetChildren()) do
						if part:IsA("BasePart") then
							part.CollisionGroup = "Tool";
							
						elseif part:IsA("Humanoid") then
							part.PlatformStand = true;
							
						end
					end
					
					cloneTool.Destroying:Connect(function()
						if cloneTool:GetAttribute("Equipped") == true and profile.EquippedTools.ID == id then
							Debugger:Log("Destroying unequip");
							unequipTool(player, returnPacket)
						end
					end)
					
					
					local handPart, toolGrip;
					if weldName == "ToolGrip" or weldName == "RightToolGrip" then
						toolGrip = motor:Clone();
						handPart = player.Character:FindFirstChild("RightHand");
						modGearAttachments:AttachMotor(cloneTool, toolGrip, handPart, 5);
						table.insert(newWelds, toolGrip);
						
					elseif weldName == "LeftToolGrip" then
						
						toolGrip = motor:Clone();
						handPart = player.Character:FindFirstChild("LeftHand");
						modGearAttachments:AttachMotor(cloneTool, toolGrip, handPart, 5);
						table.insert(newWelds, toolGrip);
						
					end
					
					cloneTool.Name = toolModelName;
					cloneTool:SetAttribute("Grip", weldName);
					table.insert(weldPacket, {
						Hand=handPart;
						Weld=toolGrip;
						Prefab=cloneTool;
					})
					modColorsLibrary.ApplyAppearance(cloneTool, storageItem.Values);
					
				end

				task.spawn(function() -- Converting old weapon skins to new LockedPatterns;
					if storageItem.Values.LockedPattern then return end;
					
					local isSpecial;
					if storageItem.Values.Textures then
						for partKey, skinLibId in pairs(storageItem.Values.Textures) do
							local skinLib = modSkinsLibrary.Get(skinLibId);
							if skinLib and skinLib.Pack == "Special" then
								isSpecial = skinLibId;
								break;
							end
						end
					end

					if isSpecial then
						inventory:SetValues(storageItem.ID, {LockedPattern=isSpecial});
						inventory:DeleteValues(storageItem.ID, {"SkinLocked"});
						
						if newModels[1] then
							local newTool = newModels[1];
							local valsTextures = {};
							for _, part in pairs(newTool:GetChildren()) do
								if storageItem.Values.Textures[part.Name] == nil then
									valsTextures[part.Name]=0;
								end
							end
							inventory:SetValues(storageItem.ID, {Textures=valsTextures});
						end
					end
				end)

				
				modOnGameEvents:Fire("OnToolEquipped", player, storageItem);
				
				storageItem:SetValues("IsEquipped", true):Sync();
				if toolLib.IsWeapon then
					storageItem:Sync({"L"; "E"; "EG"; "Tweak"});
					
				else
					local handler = profile:GetToolHandler(storageItem, toolLib, newModels);
					if handler and handler.OnToolEquip then
						handler:OnToolEquip(toolModule);
					end
					
				end
				profile.EquippedTools = {ItemId=storageItem.ItemId; ID=id; ToolWelds=newWelds; WeaponModels=newModels; Tick=tick(); StorageItem=storageItem;};
				
				profile:SyncAuthSeed(false);
				returnPacket.Equip = {
					AuthSeed=profile.Cache.AuthSeed;
					Id=id;
					Welds=newWelds;
					StorageItem=storageItem;
					MockEquip=mockEquip;
					WeldPacket=weldPacket;
				};
				
				Debugger:Log("Equip returnPacket to client", returnPacket);
			else
				warn("Player(",player.Name,") tried to equip non-tool (",id,").");
			end
		else
			warn("Player(",player.Name,") missing item id(",id,") or inventory(",inventory,").");
		end
		
		Debugger:Log("Equip");
	end
	
	if profile.EquippedTools.ID == nil then
		equip();
		
	else
		local lastId = profile.EquippedTools.ID;
		local lastStorageItem = profile.EquippedTools.StorageItem;
		
		if lastStorageItem.MockItem and mockEquip then
			Debugger:Log("Mock swap:", lastStorageItem.MockItem);
			returnPacket.ToolSwap = lastId;
			
			shared.EquipmentSystem.ToolHandler(player, "unequip", returnPacket);
			equip();
			
		else
			if id ~= lastId then
				returnPacket.ToolSwap = lastId;

			end
			unequipTool(player, returnPacket);

			if id ~= lastId then
				equip();
			end
			
		end
	end
	
	return returnPacket;
end


local function toolHandler(player, action, paramPacket)
	paramPacket = paramPacket or {};

	if action == "equip" then
		local returnPacket = equipTool(player, paramPacket);

		if paramPacket.ClientInvoked ~= true then
			remoteToolHandler:InvokeClient(player, returnPacket);
		end

		return returnPacket;

	elseif action == "unequip" then
		unequipTool(player, paramPacket);
		if paramPacket.ClientInvoked ~= true then
			remoteToolHandler:InvokeClient(player, paramPacket);
		end

		return paramPacket;
		
	elseif action == "get" then
		local profile = modProfile:Find(player.Name);
		local lastStorageItem = profile and profile.EquippedTools and profile.EquippedTools.StorageItem;
		local lastId = profile and profile.EquippedTools and profile.EquippedTools.ID;
		
		return profile and profile.EquippedTools;
	end
end

shared.EquipmentSystem.ToolHandler = toolHandler;
-- shared.EquipmentSystem.ToolHandler(player, "equip", {MockEquip=true; ItemId="fotlcardgame"});


function bindServerUnequipPlayer.OnInvoke(players)
	if type(players) ~= "table" then players = {players} end;
	
	for _, player in pairs(players) do
		task.spawn(function()
			toolHandler(player, "unequip");
		end);
	end
end

function remoteToolHandler.OnServerInvoke(player, action, paramPacket)
	if remoteToolHandler:Debounce(player) then return {}; end;
	
	paramPacket = paramPacket or {};
	paramPacket.ClientInvoked = true;
	
	return toolHandler(player, action, paramPacket);
end

remoteToolInputHandler.OnEvent:Connect(function(player, packet)
	packet = modRemotesManager.Uncompress(packet);
	
	local character = player.Character;
	if character == nil then Debugger:Warn("Missing Character"); return end;
	
	local action = packet.Action;
	local siid = packet.SiId;
	
	local profile = modProfile:Get(player);
	local playerSave = profile:GetActiveSave();
	local inventory = profile.ActiveInventory;

	local id = siid or profile.EquippedTools.ID;
	local toolModels = profile.EquippedTools.WeaponModels;

	local storageItem = inventory and inventory:Find(id);
	if id == "MockStorageItem" then
		storageItem = profile.MockStorageItem;
	end

	if toolModels == nil or #toolModels <= 0 then return end;

	for a=1, #toolModels do
		if not toolModels[a]:IsDescendantOf(character) then
			Debugger:Warn("Tool is no longer a descendant of player (",player.Name,").");
			return 
		end 
	end;

	if storageItem == nil then Debugger:Warn("StorageItem(",id,") does not exist."); return end;
	local itemid = storageItem.ItemId;

	local toolLib;
	if modWeapons[itemid] then
		toolLib = modWeapons[itemid];

	elseif modTools[itemid] then
		toolLib = modTools[itemid];

	end

	local handler = profile:GetToolHandler(storageItem, toolLib, toolModels);
	
	if action == "input"  then
		if handler and handler.OnInputEvent then
			handler:OnInputEvent(packet);
			
			if modConfigurations.RemoveForceFieldOnWeaponFire then
				local forcefield = character:FindFirstChildWhichIsA("ForceField") or nil;
				if forcefield then forcefield:Destroy() end;
			end
		end
		
	elseif action == "action" then
		if handler and handler.OnActionEvent then
			handler:OnActionEvent(packet);
		end
		
	end

end)


--remoteToolInputHandler.OnServerEvent:Connect(function(player, inputType, inputData, ...)
--	local character = player.Character;
--	if character == nil then Debugger:Warn("Missing Character"); return end;

--	local profile = modProfile:Get(player);
--	local playerSave = profile:GetActiveSave();
--	local inventory = profile.ActiveInventory;
	
--	local id = profile.EquippedTools.ID;
--	local toolModels = profile.EquippedTools.WeaponModels;
	
--	local storageItem = inventory and inventory:Find(id);
--	if id == "MockStorageItem" then
--		storageItem = profile.MockStorageItem;
--	end
	
--	if toolModels == nil or #toolModels <= 0 then return end;
	
--	for a=1, #toolModels do
--		if not toolModels[a]:IsDescendantOf(character) then
--			Debugger:Warn("Tool is no longer a descendant of player (",player.Name,").");
--			return 
--		end 
--	end;
	
--	if storageItem == nil then Debugger:Warn("StorageItem(",id,") does not exist."); return end;
--	local itemid = storageItem.ItemId;
	
--	local toolLib;
--	if modWeapons[itemid] then
--		toolLib = modWeapons[itemid];
		
--	elseif modTools[itemid] then
--		toolLib = modTools[itemid];
		
--	end
	
--	local handler = profile:GetToolHandler(storageItem, toolLib, toolModels);
--	if handler and inputType == "input" and handler.OnInputEvent then
--		handler:OnInputEvent(inputData);
--	end
	
--	if modConfigurations.RemoveForceFieldOnWeaponFire then
--		local forcefield = character:FindFirstChildWhichIsA("ForceField") or nil;
--		if forcefield then forcefield:Destroy() end;
--	end
--end)

remoteToolPrimaryFire.OnServerEvent:Connect(function(player, id, isActive, ...)
	--Debugger:Warn("Using deprecated old remoteToolPrimaryFire", id, isActive, debug.traceback());
	local character = player.Character;
	if character == nil then Debugger:Warn("Missing Character"); return end;

	local profile = modProfile:Get(player);
	local playerSave = profile:GetActiveSave();
	local inventory = profile.ActiveInventory;
	local toolModels = profile.EquippedTools.WeaponModels;

	local storageItem = inventory and inventory:Find(id);
	if id == "MockStorageItem" then
		storageItem = profile.MockStorageItem;
	end
	
	if toolModels == nil or #toolModels <= 0 then return end;
	
	for a=1, #toolModels do
		if not toolModels[a]:IsDescendantOf(character) then
			Debugger:Warn("Tool is no longer a descendant of player (",player.Name,").");
			return 
		end 
	end;
	
	if storageItem == nil then Debugger:Warn("StorageItem(",id,") does not exist."); return end;
	local itemid = storageItem.ItemId;
	if modTools[itemid] == nil then Debugger:Warn("Invalid tool (",itemid,")"); return end;
	
	local handler = profile:GetToolHandler(storageItem, modTools[itemid], toolModels);
	if handler and handler.OnPrimaryFire then
		handler:OnPrimaryFire(isActive, ...);
	end
	
	if modConfigurations.RemoveForceFieldOnWeaponFire then
		local forcefield = character:FindFirstChildWhichIsA("ForceField") or nil;
		if forcefield then forcefield:Destroy() end;
	end
end)

local modEngineCore = require(game.ReplicatedStorage.EngineCore);
modEngineCore:ConnectOnPlayerAdded(script, OnPlayerAdded);