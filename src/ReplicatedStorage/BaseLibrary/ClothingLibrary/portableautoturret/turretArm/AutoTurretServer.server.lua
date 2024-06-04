if not workspace:IsAncestorOf(script) then return end;
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Dependencies;
repeat task.wait() until shared.MasterScriptInit == true;

local modColorsLibrary = require(game.ReplicatedStorage.Library.ColorsLibrary);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

local modVector = require(game.ReplicatedStorage.Library.Util.Vector);
local modRaycastUtil = require(game.ReplicatedStorage.Library.Util.RaycastUtil);

local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modToolService = require(game.ServerScriptService.ServerLibrary.ToolService);

local turretArm: Model = script.Parent;
local accessory: Accessory = turretArm.Parent :: Accessory;
local accessoryHandle = accessory:WaitForChild("Handle") :: BasePart;
local character: Model = accessory.Parent :: Model;
local player: Player = game.Players:GetPlayerFromCharacter(character);
local handlePoint: Attachment = turretArm:WaitForChild("Arm2"):WaitForChild("HandlePoint") :: Attachment;

local accessorySiid = accessory:GetAttribute("StorageItemId");
local accessoryStorageItem = modStorage.FindIdFromStorages(accessorySiid, player);

local autoTurretClient: Script = turretArm:WaitForChild("AutoTurretClient") :: Script;
local targetValue: ObjectValue = autoTurretClient:WaitForChild("Target") :: ObjectValue;

local hydraulicRod = turretArm:WaitForChild("HydraulicRod");
local arm1 = turretArm:WaitForChild("Arm1");
local jointHarCf = CFrame.new(hydraulicRod:WaitForChild("JointHRA").CFrame.Position);
local jointAa2Cf = CFrame.new(arm1:WaitForChild("JointAA2").CFrame.Position);

local vec3Scale = accessoryHandle.Size/accessoryHandle:GetAttribute("DefaultSize");
local scale = (vec3Scale.X+vec3Scale.Y+vec3Scale.Z)/3;
turretArm:ScaleTo(math.clamp(scale, 0.1, 1));

local prefabsItems = game.ReplicatedStorage.Prefabs.Items;

local customWeaponScale = {
	["revolver454"]=1;
	["p250"]=1;
	["cz75"]=1;
	["minigun"]=0.6;
	["rec21"]=0.6;
	["awp"]=0.7;
}

local remoteAutoTurret = modRemotesManager:Get("AutoTurret");

local patItemLib = modItemsLibrary:Find("portableautoturret");
local TurretConfigs = patItemLib.GetTurretConfigs();

local onlineLoop: boolean = false;
local lastWeaponId: string = nil;
local selectedTargets: {Model} = {};
local activeWeaponModel: Model? = nil;

local drainCost = 100;
local drainRate = (60*60)/3

local delta = 1/30;
local canReactivate = tick();
--==

local halfPi = math.pi/2;
local lastSec = tick();
function TurretRuntime(weaponStorageItem)
	if activeWeaponModel == nil then return end;
	task.wait(0.1);
	
	--==
	local mode = autoTurretClient:GetAttribute("Mode");
	local angleYaw = turretArm:GetAttribute("AngleYaw") or 0;
	local anglePitch = turretArm:GetAttribute("AnglePitch") or 0;
	
	local hydraulicYaw = 0;
	local hydraulicPitch = 0;
	local armPitch = 0;
	
	if mode == 1 then
		if targetValue.Value == nil or not workspace:IsAncestorOf(targetValue.Value) then
			mode = 2;
		end
	end
	if mode == 1 then -- Online
		hydraulicYaw = halfPi + angleYaw;
		hydraulicPitch = math.clamp(anglePitch+math.rad(30), 0, math.rad(80))
		armPitch = -math.rad(120);
		
	elseif mode == 2 then -- Idle
		local y = (halfPi*3 + math.sin(tick()))/3; 
		hydraulicYaw = y;
		hydraulicPitch = math.rad(30);
		armPitch = -math.rad(120);
		
	elseif mode == 3 then -- Offline
		hydraulicYaw = math.rad(180);
		hydraulicPitch = -math.rad(90);
		armPitch = -math.rad(90);
		
	elseif mode == 4 then -- reload
		hydraulicYaw = math.rad(90);
		hydraulicPitch = -math.rad(90);
		armPitch = -math.rad(90);
		
	end
	
	--hydraulicRod.HydraulicRod.CFrame = CFrame.Angles(0, hydraulicYaw, 0);
	hydraulicRod.JointHRA.CFrame  = jointHarCf * CFrame.Angles(hydraulicPitch, 0, 0);
	arm1.JointAA2.CFrame = jointAa2Cf * CFrame.Angles(armPitch, 0, 0);
	
	weaponStorageItem:Sync({"A"; "MA"});
	--==
	local configValues = accessoryStorageItem:GetValues("Config") or {};
	
	local isSec = tick()-lastSec >= 3;
	if isSec then
		lastSec = tick();
		modAudio.Play("TurretTick", turretArm.PrimaryPart);
		
		task.spawn(function()
			local profile = shared.modProfile:Get(player);
			local patStorage = modStorage.Get("portableautoturret", player);

			local _weaponStorageItem = patStorage:FindByIndex(1);
			local batteryStorageItem = patStorage:FindByIndex(2);

			local noBattery = false;
			if batteryStorageItem then
				local powVal = batteryStorageItem:GetValues("Power");
				
				local newDrainCost = drainCost;
				
				local skill = profile.SkillTree:GetSkill(player, "enecon");
				if skill and skill.Points > 0 then
					local _level, skillStats = profile.SkillTree:CalStats(skill.Library, skill.Points);
					local conserveRatio = 1-(skillStats.Percent.Value/100);

					newDrainCost = newDrainCost * conserveRatio;
				end
				
				powVal = math.clamp(powVal- (newDrainCost/drainRate) , 0, 100);
				if powVal > 0 then
					batteryStorageItem:SetValues("Power", powVal);
				else
					patStorage:Remove(batteryStorageItem.ID, 1);
					noBattery = true;
				end

			else
				noBattery = true;

			end

			if noBattery == true then
				shared.Notify(player, "Your Portable Auto Turret battery is depleted.", "Inform");

				modAudio.Play("TurretOffline", turretArm.PrimaryPart); 
				accessoryStorageItem:SetValues("Online", false):Sync{"Online"};

				task.wait(0.2);
				Update();
			end
		end)
	end
	
	
	local targetModel: Model = nil;
	local targetPart: BasePart = nil;
	local targetDamagable;
	
	local recomputeChecks = {};
	local checkForRecompute = false;
	
	--- Configs
	local distSortMode = configValues.TargetDistancePriority or 1; if distSortMode == 3 then distSortMode = math.random(1, 2) end
	local healthSortMode = configValues.TargetHealthPriority or 1; if healthSortMode == 3 then healthSortMode = math.random(1, 2) end
	local speedSortMode = configValues.TargetSpeedPriority or 1;
	
	local sortForToxicMod = configValues.ToxicBarrage or 1;
	local sortForFrostMod = configValues.Frostbite or 1;
	
	local useHitlist = (configValues.UseHitlist or 1) == 2;
	local hitlistBitString = configValues.Hitlist or TurretConfigs.UseHitlist.DefaultBitString;
	local hitlistDict = TurretConfigs.UseHitlist.HitListBitFlag:List(hitlistBitString);
	
	local chargeFocus = configValues.ChargeFocus or 1;
	local shootToDebuffOnly = configValues.DebuffOnly or 1;
	local crowdFireOnly = configValues.CrowdFire and (configValues.CrowdFire-1)*5 or 0;
	local capFireRate = configValues.CapFireRate and configValues.CapFireRate > 1 and TurretConfigs.CapFireRate.OptionValues[configValues.CapFireRate] or 0;
	
	local sortedTargets = {};
	local canCrowdFire;
	
	if #selectedTargets > 0 then
		local _computeCost = tick();
		for a=1, #selectedTargets do
			local selectedTargetModel = selectedTargets[a];
			
			local damagable = modDamagable.NewDamagable(selectedTargetModel);
			if damagable == nil or not damagable:CanDamage(player) then continue end;
			if damagable:IsDead() then continue end;
			if damagable.Object.ClassName ~= "NpcStatus" then continue end;
			
			local npcStatus = damagable.Object;
			local npcModule = npcStatus:GetModule();
			local entityStatus = npcModule.EntityStatus;
			
			if npcModule.Detectable == false then continue end;
			if npcModule.SpawnTime and tick()-npcModule.SpawnTime <= 0.3 then continue end;
			
			if npcModule and npcModule.Properties and npcModule.Properties.BasicEnemy ~= true then
				hitlistDict[selectedTargetModel.Name] = hitlistDict.Bosses;
			end
			
			if useHitlist then
				if hitlistDict[selectedTargetModel.Name] ~= true then continue end;
			end
			
			
			local humanoid = npcModule.Humanoid;
			
			local dist = modVector.DistanceSqrd(handlePoint.WorldPosition, selectedTargets[a]:GetPivot().Position);
			
			table.insert(sortedTargets, {
				Dist = dist;
				Health = humanoid.Health or 0;
				Speed = humanoid.WalkSpeed or 0;
				Target = selectedTargets[a];
				
				Damagable = damagable;
				ToxicMod = entityStatus:GetOrDefault("ToxicMod");
				FrostMod = entityStatus:GetOrDefault("FrostMod");
			});
		end
		
		canCrowdFire = #sortedTargets <= crowdFireOnly;
		
		if #sortedTargets > 1 then
			table.sort(sortedTargets, function(a, b)
				if distSortMode == 1 then
					return a.Dist < b.Dist;
				elseif distSortMode == 2 then
					return a.Dist > b.Dist;
				end
				return;
			end)
		end

		for a=1, #sortedTargets do
			sortedTargets[a].DistIndex = a;
		end

		if #sortedTargets > 1 then
			table.sort(sortedTargets, function(a, b)
				if healthSortMode == 1 then
					return a.Health < b.Health;
				elseif healthSortMode == 2 then
					return a.Health > b.Health;
				end
				return;
			end)
		end

		for a=1, #sortedTargets do
			sortedTargets[a].HealthIndex = a;
		end

		if #sortedTargets > 1 then
			table.sort(sortedTargets, function(a, b)
				if speedSortMode == 1 then
					return a.Speed > b.Speed;
				elseif speedSortMode == 2 then
					return a.Speed < b.Speed;
				end
				return;
			end)
		end
		
		for a=1, #sortedTargets do
			sortedTargets[a].SpeedIndex = a;
		end
		
		-------
		local targetsCount = #sortedTargets;
		local tieCount = math.ceil(targetsCount/2);
		
		for a=#sortedTargets, 1, -1 do
			local sTarget = sortedTargets[a];
			
			sTarget.Index = 0;

			-- 2 = active;
			if sortForToxicMod == 2 then
				if sTarget.ToxicMod then
					sTarget.Index = tieCount;
				else
					checkForRecompute = true;
				end
			end
			if sortForFrostMod == 2 then
				if sTarget.FrostMod and sTarget.FrostMod.CompleteTick then
					sTarget.Index = tieCount;
				else
					checkForRecompute = true;
				end
			end
			if shootToDebuffOnly == 2 then
				if sTarget.ToxicMod	
				or (sTarget.FrostMod and sTarget.FrostMod.CompleteTick) then
					table.remove(sortedTargets, a);
				end
			end
		end
		
		-------
		if #sortedTargets > 0 then
			table.sort(sortedTargets, function(a, b)
				local aPoints = a.DistIndex + a.HealthIndex + a.SpeedIndex + a.Index;
				local bPoints = b.DistIndex + b.HealthIndex + b.SpeedIndex + b.Index;

				return aPoints < bPoints;
			end)


			for a=1, math.min(#sortedTargets, 3) do
				local selectTargetInfo = sortedTargets[a];

				local hitList = modRaycastUtil.GetHittable(handlePoint.WorldPosition, 64, selectTargetInfo.Target);
				if #hitList <= 0 then continue end;

				targetDamagable = selectTargetInfo.Damagable;
				targetModel = selectTargetInfo.Target;
				targetPart = hitList[math.random(1, #hitList)];

				break;
			end
		end
	end;
	

	local itemValues = weaponStorageItem.Values;

	local profile = shared.modProfile:Get(player);
	local toolModule = profile:GetItemClass(weaponStorageItem.ID);


	local maistPercent = 1;
	local skill = profile.SkillTree:GetSkill(player, "maist");
	if skill and skill.Points > 0 then
		local _level, skillStats = profile.SkillTree:CalStats(skill.Library, skill.Points);

		maistPercent = 1-(skillStats.Percent.Value/100);
	end


	local tryReload = itemValues.A and itemValues.A <= 0;

	local configurations = toolModule.Configurations;
	if profile.InfAmmo then
		configurations.InfiniteAmmo = profile.InfAmmo;
	end

	if configurations.ReloadMode == modAttributes.ReloadModes.Single and targetModel == nil and itemValues.MA > 0 then
		tryReload = itemValues.A and itemValues.A < configurations.AmmoLimit;
	end

	if tryReload then
		modAudio.Play(toolModule.Audio.Empty.Id, turretArm.PrimaryPart);

		local reloadPacket = {
			StorageItem = weaponStorageItem;
			ToolModel = activeWeaponModel;
			ToolModule = toolModule;

			IsPat = true;
		};
		autoTurretClient:SetAttribute("Mode", 4);

		modAudio.Play("BattleRifleUnload", turretArm.PrimaryPart);
		local reloadLoop = modAudio.Play("MachineServos", turretArm.PrimaryPart);
		reloadLoop.RollOffMaxDistance = 16;
		reloadLoop.Volume = 0.2;
		local reloadLoop2 = modAudio.Play("LoadShotgunShell", turretArm.PrimaryPart);
		reloadLoop2.RollOffMaxDistance = 16;
		reloadLoop2.Volume = 0.5;
		reloadLoop2.Looped = true;
		reloadLoop2.PlaybackSpeed = 2;

		local sucess;
		task.spawn(function()
			sucess = modToolService.ReloadWeapon(reloadPacket);
		end)
		while sucess == nil do
			task.wait();
			canReactivate = tick();

			if onlineLoop == false then
				sucess = false;
				break;
			end
		end

		reloadLoop:Stop();
		reloadLoop2:Stop();
		modAudio.Play("BattleRifleLoad", turretArm.PrimaryPart);
		autoTurretClient:SetAttribute("Mode", 1);

		if sucess == false then
			modAudio.Play("TurretOffline", turretArm.PrimaryPart); 
			accessoryStorageItem:SetValues("Online", false):Sync{"Online"};
			shared.Notify(player, "Your Portable Auto Turret ammo is depleted.", "Inform");

			task.wait(0.2);
			Update();
			return;
		end
	end

	if canCrowdFire then return end;
	
	if targetModel == nil then return end;
	targetPart = targetPart or targetModel.PrimaryPart;
	targetValue.Value = targetPart;
	
	local npcStatus = targetDamagable.Object;
	local npcModule = npcStatus:GetModule();
	local entityStatus = npcModule.EntityStatus;
	
	local rapidFireStart = tick();

	modAudio.Play("TurretTarget", turretArm.PrimaryPart);
	
	if activeWeaponModel.PrimaryPart == nil then return end;
	local bulletOriginAtt: Attachment = activeWeaponModel.PrimaryPart:WaitForChild("BulletOrigin") :: Attachment;

	while onlineLoop do
		local origin = bulletOriginAtt.WorldPosition;
		
		local targetHead = npcModule.Head;
		if targetHead == nil then break; end;
		
		local targetPos = targetPart.Position;
		if targetPos.Y < (targetHead.Position.Y-0.5) then
			targetPos = targetPos + Vector3.new(0, math.random(0, 150)/100, 0);
		end
		local direction = (targetPos-origin).Unit;
		

		local firePacket = {
			StorageItem = weaponStorageItem;
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
			};

			IsPat = true;
			MaistPercent = maistPercent;
		};
		
		if configurations.FocusDuration > 0 then
			if chargeFocus == 2 then -- true;
				task.wait(configurations.FocusDuration);
				canReactivate = tick();
				firePacket.FocusCharge = 1;
			end
		end
		
		modToolService.PrimaryFireWeapon(firePacket);
		canReactivate = tick();

		local baseFr = 60/math.max(capFireRate, toolModule.Properties.Rpm);
		local firerate = baseFr;

		if configurations.RapidFire then
			local f = math.clamp((tick()-rapidFireStart)/configurations.RapidFire, 0, 1);
			firerate = baseFr + f*(delta - baseFr);
			
			if toolModule.Cache.AudioPrimaryFire then
				toolModule.Cache.AudioPrimaryFire.PlaybackSpeed = 1+(f/2);
			end
		end

		firerate = math.clamp(firerate, configurations.RapidFireMax or delta, 999);
		weaponStorageItem:Sync({"A"; "MA"});
		task.wait(firerate);
		
		if sortForToxicMod == 2 and checkForRecompute then
			local toxicMod = entityStatus:GetOrDefault("ToxicMod")
			if toxicMod then
				break;
			end
		end
		if sortForFrostMod == 2 and checkForRecompute then
			local frostMod = entityStatus:GetOrDefault("FrostMod");
			if frostMod and frostMod.CompleteTick then
				break;
			end
		end
		if shootToDebuffOnly == 2 then
			break;
		end

		local breakRequest = false;
		for a=1, #recomputeChecks do
			breakRequest = recomputeChecks[a]();
			if breakRequest then
				break;
			end
		end
		if breakRequest then break; end;
		
		if itemValues.A and itemValues.A <= 0 then break; end;
		if targetDamagable:IsDead() then break; end
		
		local hitList = modRaycastUtil.GetHittable(handlePoint.WorldPosition, 64, targetPart);
		if #hitList <= 0 then break end;
	end
	
	modToolService.CancelPrimaryFire{
		ToolModule = toolModule;
	};
end


function Update()
	if accessory.Parent and accessory.Parent.Name == "voodoodoll" then return end;
	accessoryStorageItem = modStorage.FindIdFromStorages(accessorySiid, player);
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
			remoteAutoTurret:InvokeClient(player, "refresh", accessoryStorageItem.Values);
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
		weaponModel:SetAttribute("ItemId", itemId);
		weaponModel:ScaleTo( customWeaponScale[itemId] or (weaponModel:GetScale()*0.8) );
		
		local handle = weaponModel:WaitForChild("Handle");
		if handle:CanSetNetworkOwnership() then handle:SetNetworkOwner(player); end

		for _, obj in pairs(weaponModel:GetDescendants()) do
			obj:SetAttribute("FPIgnore", nil);
		end

		local rigidConstraint = Instance.new("RigidConstraint");
		rigidConstraint.Attachment0 = handlePoint;
		rigidConstraint.Attachment1 = handle:WaitForChild("GripPoint");
		rigidConstraint.Parent = handle;

		weaponModel.Parent = turretArm;
		
		modColorsLibrary.ApplyAppearance(weaponModel, weaponStorageItem.Values);
		
		for _, obj in pairs(weaponModel:GetChildren()) do
			if obj.Name == "Magazine" then
				obj.Name = "patMagazine";
			end
		end

		activeWeaponModel = weaponModel;
	end
	
	
	local isOnline = accessoryStorageItem.Values.Online == true;
	
	if isOnline then
		autoTurretClient:SetAttribute("Mode", 1);
		if onlineLoop == false then
			onlineLoop = true;

			lastSec = tick()-3;
			task.spawn(function()
				while (tick()-canReactivate) < 1 do
					task.wait();
				end
				while onlineLoop do
					TurretRuntime(weaponStorageItem);
					canReactivate = tick();
				end
				canReactivate = tick();
				autoTurretClient:SetAttribute("Mode", 3);
			end)
		end
		
	else
		autoTurretClient:SetAttribute("Mode", 3);
		onlineLoop = false;
		selectedTargets = {};
		
	end
	
end

modOnGameEvents:ConnectEvent("OnEnemiesAttract", function(p, st)
	if p ~= player then return end;
	selectedTargets = st or {};
end)

accessory:GetAttributeChangedSignal("Update"):Connect(function()
	if accessory:GetAttribute("Update") == nil then return end;
	accessory:SetAttribute("Update", nil);
	
	Update();
end)
accessory:GetAttributeChangedSignal("WeaponStorageItemID"):Connect(Update);
Update();