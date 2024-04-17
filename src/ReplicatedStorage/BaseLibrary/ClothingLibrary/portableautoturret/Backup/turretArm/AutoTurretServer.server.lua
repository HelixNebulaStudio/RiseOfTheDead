if not workspace:IsAncestorOf(script) then return end;
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Dependencies;
repeat task.wait() until shared.MasterScriptInit == true;

local modColorsLibrary = require(game.ReplicatedStorage.Library.ColorsLibrary);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local modVector = require(game.ReplicatedStorage.Library.Util.Vector);
local modRaycastUtil = require(game.ReplicatedStorage.Library.Util.RaycastUtil);

local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modToolService = require(game.ServerScriptService.ServerLibrary.ToolService);

local turretArm: Model = script.Parent;
local accessory: Accessory = turretArm.Parent;
local character: Model = accessory.Parent;
local player: Player = game.Players:GetPlayerFromCharacter(character);
local handlePoint: Attachment = turretArm:WaitForChild("Arm2"):WaitForChild("HandlePoint");

local accessorySiid = accessory:GetAttribute("StorageItemId");
local accessoryStorageItem = modStorage.FindIdFromStorages(accessorySiid, player);

local autoTurretClient: Script = turretArm:WaitForChild("AutoTurretClient");
local targetValue: ObjectValue = autoTurretClient:WaitForChild("Target");

local prefabsItems = game.ReplicatedStorage.Prefabs.Items;

local remoteAutoTurret = modRemotesManager:Get("AutoTurret");

local onlineLoop: boolean = false;
local lastWeaponId: string = nil;
local selectedTargets: {Model} = {};
local activeWeaponModel: Model = nil;
--==

function TurretRuntime(storageItem)
	if activeWeaponModel == nil then return end;
	
	task.wait(0.1);
	if #selectedTargets <= 0 then return end;

	local targetModel: Model = nil;
	local damagable;
	
	if #selectedTargets > 1 then
		local sortedTargets = {};
		
		for a=1, #selectedTargets do
			local dist = modVector.DistanceSqrd(handlePoint.WorldPosition, selectedTargets[a]:GetPivot().Position);
			
			table.insert(sortedTargets, {
				Dist = dist;
				Target = selectedTargets[a];
			})
		end
		table.sort(sortedTargets, function(a, b)
			return a.Dist < b.Dist;
		end)
		
		for a=1, math.min(#sortedTargets, 3) do
			local selectTarget = sortedTargets[a].Target;
			
			damagable = modDamagable.NewDamagable(selectTarget);
			if damagable == nil or not damagable:CanDamage(player) then continue end;
			
			local isHittable = modRaycastUtil.IsHittable(handlePoint.WorldPosition, 64, selectTarget.PrimaryPart);
			if not isHittable then continue end;
			
			targetModel = selectTarget;
			break;
		end
		
	else
		damagable = modDamagable.NewDamagable(targetModel);
		if damagable == nil or not damagable:CanDamage(player) then return end;
		if not modRaycastUtil.IsHittable(handlePoint.WorldPosition, 64, targetModel.PrimaryPart) then return end;
		
		targetModel = selectedTargets[1];
	end
	
	if targetModel == nil then return end;
	
	targetValue.Value = targetModel.PrimaryPart;

	local ammo = storageItem:GetValues("A");
	local maxAmmo = storageItem:GetValues("MA");
	
	local profile = shared.modProfile:Get(player);
	local toolModule = profile:GetItemClass(storageItem.ID);
	
	while onlineLoop do
		local origin = activeWeaponModel.PrimaryPart.BulletOrigin.WorldPosition;
		local direction = (targetModel:GetPivot().Position-origin).Unit;

		local firePacket = {
			StorageItem = storageItem;
			ToolModel = activeWeaponModel;
			ToolModule = toolModule;

			Player = player;

			ShotOrigin = origin;
			ShotDirection = direction;

			ReplicateToShotOwner = true;

			Targetable = {
				Zombie = true;
				Bandit = true;
				Cultist = true;
				Rat = true;
			}
		};
		
		modToolService.PrimaryFireWeapon(firePacket);
		task.wait(toolModule.Properties.FireRate);

		ammo = storageItem:GetValues("A");
		if ammo and ammo <= 0 then break; end;
		if damagable:IsDead() then break; end
	end
	
	modToolService.CancelPrimaryFire{
		ToolModule = toolModule;
	};
	
	if (ammo or 1) <= 0 and (maxAmmo or 1) > 0 then
		local reloadPacket = {
			StorageItem = storageItem;
			ToolModel = activeWeaponModel;
			ToolModule = toolModule;
		};
		modToolService.ReloadWeapon(reloadPacket);
	else
		modAudio.Play(toolModule.Audio.Empty.Id, turretArm.PrimaryPart); 
	end
end


function Update()
	local weaponStorageItemID = accessory:GetAttribute("WeaponStorageItemID");
	
	local isWeaponChanged = lastWeaponId ~= weaponStorageItemID;
	if isWeaponChanged then
		for _, obj in pairs(turretArm:GetChildren()) do
			if obj:GetAttribute("TurretWeapon") ~= true then continue end;
			Debugger.Expire(obj, 0);
		end
		activeWeaponModel = nil;
		
		onlineLoop = false;
		accessoryStorageItem:SetValues("Online", false):Sync{"Online"};
	end
	lastWeaponId = weaponStorageItemID;
	
	if weaponStorageItemID == nil then
		task.spawn(function()
			remoteAutoTurret:InvokeClient(player, "refresh");
		end)
		return;
	end
	
	local weaponStorageItem = modStorage.FindIdFromStorages(weaponStorageItemID, player);
	local itemId = weaponStorageItem.ItemId;
	
	if isWeaponChanged then
		local prefabTool = prefabsItems:FindFirstChild(itemId);
		if prefabTool == nil then
			Debugger:Warn("Tool prefab for (",itemId,") does not exist for turret!");
			return;
		end;

		local weaponModel: Model = prefabTool:Clone();
		weaponModel:SetAttribute("TurretWeapon", true);
		weaponModel:ScaleTo(0.8);

		local handle = weaponModel:WaitForChild("Handle");
		if handle:CanSetNetworkOwnership() then handle:SetNetworkOwner(player); end

		local rigidConstraint = Instance.new("RigidConstraint");
		rigidConstraint.Attachment0 = handlePoint;
		rigidConstraint.Attachment1 = handle:WaitForChild("GripPoint");
		rigidConstraint.Parent = handle;

		weaponModel.Parent = turretArm;
		
		modColorsLibrary.ApplyAppearance(weaponModel, weaponStorageItem.Values);
		
		activeWeaponModel = weaponModel;
	end
	
	
	local isOnline = accessoryStorageItem.Values.Online == true;
	
	if isOnline then
		autoTurretClient:SetAttribute("Mode", 1);
		if onlineLoop == false then
			onlineLoop = true;
			
			task.spawn(function()
				while onlineLoop do
					TurretRuntime(weaponStorageItem);
				end
			end)
		end
		
	else
		autoTurretClient:SetAttribute("Mode", 3);
		onlineLoop = false;
		
	end
	
end

accessory:GetAttributeChangedSignal("WeaponStorageItemID"):Connect(Update);

function remoteAutoTurret.OnServerInvoke(p, action, ...)
	if p ~= player then return end;
	
	local rPacket = {};

	local accessorySiid = accessory:GetAttribute("StorageItemId");
	if accessorySiid == nil then
		Debugger:Warn("Missing WeaponStorageItemID");
		return rPacket;
	end
	local storageItem, storage = modStorage.FindIdFromStorages(accessorySiid, player);
	
	
	if action == "toggleonline" then
		local onlineBool = not (storageItem:GetValues("Online") == true);
		storageItem:SetValues("Online", onlineBool):Sync{"Online"};
		
		rPacket.Values = storageItem.Values;
		rPacket.Success = true;
		
		task.spawn(Update);
		
		return rPacket;
	end
	
end

modOnGameEvents:ConnectEvent("OnEnemiesAttract", function(player, st)
	selectedTargets = st;
end)