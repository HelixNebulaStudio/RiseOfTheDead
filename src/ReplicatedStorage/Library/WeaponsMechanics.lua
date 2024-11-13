local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local modWorkbenchLibrary = require(game.ReplicatedStorage.Library:WaitForChild("WorkbenchLibrary"));
local modParticleSprinkler = require(game.ReplicatedStorage.Particles.ParticleSprinkler);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modPseudoRandom = require(game.ReplicatedStorage.Library.PseudoRandom);

local muzzleEffect = script.MuzzleFlash;
local tracerEffect = script.BulletTracer;
local smokeEffect = script.SmokeParticle;
local bloodSplash = script.BloodSplash;
local moltenEffect = script:WaitForChild("MoltenBullethole");

local muzzleLight = script.MuzzleLight;

local random = Random.new();

local WeaponsMechanics = {};

local localplayer: Player = game.Players.LocalPlayer;
local modData;
local function getModData()
	if RunService:IsServer() then return end;
	if modData then return modData end;
	modData = localplayer and require(localplayer:WaitForChild("DataModule") :: any);
	return modData;
end

--== Script;
WeaponsMechanics.EquipUpdateExperience = true;


-- !outline: function UpdateWeaponPotential(weaponLevel, weaponModule)
function WeaponsMechanics.UpdateWeaponPotential(weaponLevel, weaponModule)
	--if weaponModule == nil or weaponModule.Properties == nil then return end;
	weaponLevel = weaponLevel or 0;
	
	local minBaseDamage = weaponModule.Configurations.MinBaseDamage or 20;
	local baseDamage = weaponModule.Configurations.BaseDamage;
	local basePotential = weaponModule.Properties.BasePotential or (minBaseDamage/baseDamage);
	
	--local preClamp = basePotential + ((weaponLevel/20)^rate) * (1-basePotential);
	--local expPotential = math.clamp( preClamp , basePotential, 1);
		
	local rate = 0.4;
	local maxRatio = baseDamage/minBaseDamage;
	local intervals = maxRatio/21;
	
	local total = 0;
	
	for a=1, weaponLevel do
		local index = a -10;
		local levelWeight = intervals + (intervals * math.sign(index) * (math.abs(index)/10)^rate)
		
		total = total + levelWeight;
	end
	
	local masteryVal = minBaseDamage * math.min((1+total), maxRatio) / baseDamage;
	
	weaponModule.Properties.Potential = math.clamp(masteryVal, basePotential, 1);
	weaponModule.Configurations.PreModDamage = math.clamp(baseDamage * weaponModule.Properties.Potential, minBaseDamage, math.huge);
	weaponModule.Configurations.Damage = weaponModule.Configurations.PreModDamage;
	
	--weaponModule.Configurations.Damage = math.clamp(weaponModule.Configurations.Damage * weaponModule.Properties.Potential, minBaseDamage, math.huge);
end


-- This applies after mods.
-- !outline: function ApplyTraits(storageItem, weaponModule)
function WeaponsMechanics.ApplyTraits(storageItem, weaponModule)
	if true then return end;

	local modToolTweaks = require(game.ReplicatedStorage.Library.ToolTweaks) :: any;

	--Trait buffs;
	local traitLib = modWorkbenchLibrary.ItemUpgrades[storageItem.ItemId] and modWorkbenchLibrary.ItemUpgrades[storageItem.ItemId].TraitStats;
	local tweakId = storageItem.Values and storageItem.Values.Tweak;
	
	if traitLib and tweakId then
		local tweaks = modToolTweaks.LoadTrait(storageItem.ItemId, tweakId);
		
		local tweakStats = tweaks.Stats;
		for key, value in pairs(tweakStats) do
			local statLib;
			for a=1, #traitLib do
				if traitLib[a].Stat == key then
					statLib = traitLib[a];
					break;
				end
			end
			
			value = value/100;
			
			if statLib.Base == true then
				key = "Base"..key;
				
			end
			
			if statLib.Add then
				value = statLib.Negative and -value or value;
				
			else
				value = statLib.Negative and 1-value or 1+value;
				
			end
			
			if weaponModule.Configurations[key] then
				if key == "MaxAmmoLimit" then
					local addAmmo = math.ceil(weaponModule.Configurations.AmmoLimit * value);
					weaponModule.Configurations.MaxAmmoLimit = weaponModule.Configurations.MaxAmmoLimit + addAmmo;
					
				else
					local newV;
					if statLib.Add then
						newV = weaponModule.Configurations[key] + value;
					else
						newV = weaponModule.Configurations[key] * value;
					end

					weaponModule.Configurations[key] = statLib.Int and math.ceil(newV) or newV;
					if key == "Damage"  and weaponModule.Configurations.PreModDamage then
						weaponModule.Configurations.PreModDamage = weaponModule.Configurations[key];
					end
					
				end
				
			elseif weaponModule.Properties[key] then
				local newV;
				if statLib.Add then
					newV = weaponModule.Properties[key] + value;
				else
					newV = weaponModule.Properties[key] * value;
				end
				
				weaponModule.Properties[key] = statLib.Int and math.ceil(newV) or newV;
				
			else
				if RunService:IsStudio() then
					--Debugger:Warn("Missing key for tweak ", key);
				end
			end
			
		end
		
	end
end

-- !outline: function ApplyPassiveMods(storageItem, attachmentStorage, weaponModule)
function WeaponsMechanics.ApplyPassiveMods(storageItem, attachmentStorage, weaponModule)
	local modItemModsLibrary = require(game.ReplicatedStorage.Library.ItemModsLibrary);
	local tweakValues = storageItem.Values and storageItem.Values.TweakValues or {};
	
	local upgradeLib = modWorkbenchLibrary.ItemUpgrades[storageItem.ItemId];
	local itemTier = upgradeLib.Tier or 1;
	
	local sortedList = {};
	
	for _, storageItemMod in pairs(attachmentStorage.Container) do
		local modLib = modItemModsLibrary.Get(storageItemMod.ItemId);
		
		table.insert(sortedList, {
			StorageItem=storageItemMod;
			Lib=modLib;
			Index=storageItemMod.Index;
		});
	end
	
	table.sort(sortedList, function(a, b) return a.Index < b.Index; end);
	
	for a=1, #sortedList do
		local modLib = sortedList[a].Lib;
		local storageItemMod = sortedList[a].StorageItem;
		
		if modLib.Module then
			local modFunctions = require(modLib.Module);
			if modFunctions then
				modFunctions.Activate({
					ItemId = storageItemMod.ItemId;
					ItemTier = (itemTier or 1);
					StorageItem = storageItem;
					ModStorageItem = storageItemMod;
					WeaponModule = weaponModule;
					TweakStat = tweakValues[storageItemMod.Index];
				});
			end
			
			spawn(function()
				if RunService:IsClient() then return end;
				
				if modLib.Module.Name == "Damage" then
					local maxLevel = 10;
					for a=1, #modLib.Upgrades do
						if modLib.Upgrades[a].DataTag == "D" then
							maxLevel = modLib.Upgrades[a].MaxLevel;
							break;
						end
					end
					if storageItemMod.Values and storageItemMod.Values.D == maxLevel and shared.modProfile then
						local profile = shared.modProfile:Get(storageItemMod.Player);
						if profile then
							local activeSave = profile:GetActiveSave();
							activeSave:AwardAchievement("dammas");
						end
					end
				end
			end)
		else
			Debugger:Warn("Missing module for mod ("..modLib.Name.." Mod)");
		end
	end
	
	return weaponModule;
end;


-- !outline: function ProcessModHooks(damageSource)
function WeaponsMechanics.ProcessModHooks(damageSource)
	local modItemModsLibrary = require(game.ReplicatedStorage.Library.ItemModsLibrary);
	
	local dealer = damageSource.Dealer;
	local toolModule = damageSource.ToolModule;
	
	local modInfo = toolModule.ModHooks.PrimaryEffectMod;
	if modInfo then
		local storageItemOfMod;

		if RunService:IsServer() then
			local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
			storageItemOfMod = modStorage.FindIdFromStorages(modInfo.StorageItemID, dealer);

		else
			local modData = getModData();
			storageItemOfMod = modData.GetItemById(modInfo.StorageItemID);

		end
		
		if storageItemOfMod then
			local itemValues = storageItemOfMod.Values

			local modLib = modItemModsLibrary.Get(storageItemOfMod.ItemId);
			
			local timelapsed = modSyncTime.GetTime()-(itemValues.AT or 0); 
			local isActive = (timelapsed >= 0 and timelapsed <= modLib.ActivationDuration);

			if modLib.EffectTrigger == modItemModsLibrary.EffectTrigger.Passive then
				isActive = true;

			end
			
			if isActive then
				if RunService:IsServer() then
					if modInfo.Activate then
						task.spawn(function()
							modInfo.Activate(damageSource);
						end)
					end

				else
					damageSource.ShotData.TracerColor = modLib.Color;
					if modInfo.Activate then
						modInfo.Activate(damageSource);
					end

				end

			end
		end;
	end
	
end

type HitscanRayProperties = {
	Origin: Vector3;
	Direction: Vector3; 
	IncludeList: {any};
	Range: number;
	MaxPierce: number?;
	PenTable: unknown?;
	OnCastFunc: (() -> boolean)?;
	PenReDirection: Vector3?;
	OnPenFunc: (({
		BasePart: Instance;
		Position: Vector3;
		Normal: Vector3;
	}) -> nil)?;
	RayRadius: number?;
};

-- MARK: CastHitscanRay()
function WeaponsMechanics.CastHitscanRay(properties: HitscanRayProperties)
	local origin = properties.Origin;
	local direction = properties.Direction;
	local includeList = properties.IncludeList;
	
	-- optionals
	local range = properties.Range or 512;
	local maxPierce = properties.MaxPierce or 0;
	local onCastFunc = properties.OnCastFunc;
	local penTable = properties.PenTable or {};
	local penReDirection = properties.PenReDirection;
	local rayRadius = properties.RayRadius or 0;
	
	local newOrigin = origin;
	local distance = range;

	local penCount = 0;

	local raycastParams = RaycastParams.new();
	raycastParams.FilterType = Enum.RaycastFilterType.Include;
	raycastParams.IgnoreWater = true
	raycastParams.CollisionGroup = "Raycast";

	local prevDist = nil;
	local breakC = 0;
	repeat
		raycastParams.FilterDescendantsInstances = includeList;

		local raycastResult;
		
		if rayRadius <= 0 then
			raycastResult = workspace:Raycast(newOrigin, direction*distance, raycastParams);

		else
			raycastResult = workspace:Spherecast(origin, rayRadius, direction*distance, raycastParams);

		end

		local rayBasePart: BasePart, rayPoint, rayNormal, rayMaterial;
		if raycastResult then
			rayBasePart = raycastResult.Instance;
			rayPoint = raycastResult.Position;
			rayNormal = raycastResult.Normal;
			rayMaterial = raycastResult.Material;
		else
			rayPoint = newOrigin + direction*distance;
		end

		local endPoint = rayPoint;
		local endDistance = raycastResult and raycastResult.Distance or distance;

		local canPenetrate = rayBasePart and rayBasePart:GetAttribute("IgnoreWeaponRay") == true or false;

		if rayBasePart and not canPenetrate and Debugger.ClientFps > 45 then -- test obj for penetration;
			local maxPenLength = penTable[rayBasePart.Material] or penTable["Others"] or 0;
			if maxPenLength > 0 then
				if penReDirection then
					direction = penReDirection;
					penReDirection = nil;
				end
				local penDir = direction * (maxPenLength+0.1)
				local penEndRayOrigin = endPoint + (penDir);

				local penTestRaycastParams = RaycastParams.new();
				penTestRaycastParams.FilterType = Enum.RaycastFilterType.Include;
				penTestRaycastParams.IgnoreWater = true
				penTestRaycastParams.FilterDescendantsInstances = {rayBasePart};
				
				local penTestResult = workspace:Raycast(penEndRayOrigin, -penDir, penTestRaycastParams);
				if penTestResult and penTestResult.Instance == rayBasePart then
					--penetrated success;
					canPenetrate = true;
					
					if properties.OnPenFunc then
						properties.OnPenFunc{
							BasePart = penTestResult.Instance;
							Position = penTestResult.Position;
							Normal = penTestResult.Normal;
						}
					end
				end
			end
		end

		if onCastFunc then -- has onCastFunc
			if rayBasePart == nil or rayBasePart:GetAttribute("IgnoreWeaponRay") ~= true then
				local newIgnore = onCastFunc(rayBasePart, rayPoint, rayNormal, rayMaterial, penCount, endDistance);
				if newIgnore and maxPierce > 0 then
					local a = table.find(includeList, newIgnore);
					table.remove(includeList, a);
				end
			end
		end

		distance = distance-endDistance;
		newOrigin = endPoint;

		if rayBasePart then
			if canPenetrate then
				newOrigin = newOrigin + direction*0.1;
				distance = distance -0.1;
			else
				penCount = penCount +1;

			end
		else
			distance = 0;

		end
		
		if prevDist == nil then
			prevDist = distance;
		else
			if prevDist == distance then
				breakC = breakC +1;

				if breakC > 3 then
					Debugger:Warn("Breaking hitscan ray before potential crash.");
					break;
				end;
			else
				breakC = 0;
			end
			prevDist = distance;
		end
	until distance <= 0 or penCount > maxPierce;

	return newOrigin;
end


-- !outline: function DamageDropoff(toolModule, damage, distance)
function WeaponsMechanics.DamageDropoff(toolModule, damage, distance)
	local configurations = toolModule.Configurations; 
	local damageDropoff = configurations.DamageDropoff;
	
	local min = damageDropoff.MinDistance or 16;
	local max = damageDropoff.MaxDistance or 512;
	
	if configurations.SlugRounds then
		min = 32;
	end
	
	return distance >= min and math.clamp(damage*math.clamp((1-(distance/max)^2), 0.01, 1), 1, math.huge) or damage;
end;


-- !outline: function CreateBlood(obj, point, normal, camera)
function WeaponsMechanics.CreateBlood(obj, point, normal, camera)
	if RunService:IsClient() then
		modData = getModData();
		if modData:GetSetting("BloodParticle") == 1 then return; end
	end

	if obj:GetAttribute("IsLiquid") == true then
		return;
	end
	
	local bloodAttachment = Instance.new("Attachment");
	bloodAttachment.CFrame = obj.CFrame:toObjectSpace(CFrame.new(point, point + normal));
	bloodAttachment.Parent = obj;
	
	local bloodsplash = bloodSplash:Clone();
	bloodsplash.Parent = bloodAttachment;
	spawn(function()
		for a=1, 3 do
			bloodsplash.Acceleration = Vector3.new(0, -18-random:NextNumber(1, 2), 0);
			bloodsplash:Emit(1);
			RunService.Stepped:Wait();
		end
	end)
	game.Debris:AddItem(bloodAttachment, random:NextNumber(5, 10));
end;


-- !outline: function ImpactSound(param)
local surfaceSounds = script:WaitForChild("SurfaceSounds");
function WeaponsMechanics.ImpactSound(param)
	local use3DParticles = true;
	local limitParticles = false;
	if RunService:IsClient() then
		modData = getModData();

		if modData:GetSetting("DisableParticle3D") == 1 then
			use3DParticles = false;
		end
		limitParticles = modData:GetSetting("LimitParticles") == 1;
	end

	local obj = param.BasePart;
	local point = param.Point;
	local normal = param.Normal or Vector3.new();
	
	if obj:GetAttribute("IsLiquid") == true then
		return;
	end
	
	local newAtt = Instance.new("Attachment");
	newAtt.Parent = workspace.Terrain;
	newAtt.WorldCFrame = CFrame.new(point);
	game.Debris:AddItem(newAtt, 3);
	
	local surfaceSoundId;
	local pitchMin, pitchMax = 0.9, 1.1;
	
	if obj.Material == Enum.Material.Metal
		or obj.Material == Enum.Material.CorrodedMetal
		or obj.Material == Enum.Material.DiamondPlate then

		if use3DParticles and RunService:IsClient() and Debugger.ClientFps >= 30 then
			local sparkCountRng = math.random(4, 7);
			
			local cache = modData.Cache;
			if cache.PhySparksTick == nil or tick()-cache.PhySparksTick >= 3 then
				modData.Cache.PhySparksCount = 0;
			end
			cache.PhySparksTick = tick();
			modData.Cache.PhySparksCount = modData.Cache.PhySparksCount+ sparkCountRng;
			
			sparkCountRng = math.clamp(math.round(sparkCountRng/ (modData.Cache.PhySparksCount/30)), 0, 7);
			if sparkCountRng <= 0 and math.random(1, 3) == 1 then
				sparkCountRng = 1;
			end
			
			if sparkCountRng > 0 then
				modParticleSprinkler:Emit{
					Type=0, 
					Origin=CFrame.new(point);
					Velocity=normal;
					Speed=30;
					Rate=sparkCountRng;
					Size=0.15;
					Lifetime=1;
					CanCollide=true;
				};
			end
		end
		
		if param.HideMolten ~= true and limitParticles ~= true then
			local molten = moltenEffect:Clone();
			molten.Lifetime = NumberRange.new(math.random(15, 25)/10);
			molten.Parent = newAtt;
			molten:Emit(1);
		end
		
		surfaceSoundId = "metalImpact0"..math.random(1, 5);
		pitchMin, pitchMax = 0.4, 2.5;
		
		if param.Enemy then
			pitchMin, pitchMax = 1.5, 3;
		end
		
	elseif obj.Material == Enum.Material.Asphalt
		or obj.Material == Enum.Material.Basalt 
		or obj.Material == Enum.Material.Brick 
		or obj.Material == Enum.Material.Cobblestone 
		or obj.Material == Enum.Material.Concrete
		or obj.Material == Enum.Material.Glacier
		or obj.Material == Enum.Material.Ice 
		or obj.Material == Enum.Material.Limestone 
		or obj.Material == Enum.Material.Marble 
		or obj.Material == Enum.Material.Pavement
		or obj.Material == Enum.Material.Pebble
		or obj.Material == Enum.Material.Rock
		or obj.Material == Enum.Material.Salt
		or obj.Material == Enum.Material.Sandstone
		or obj.Material == Enum.Material.Slate then
		
		surfaceSoundId = "stoneImpact0"..math.random(1, 4);
		pitchMin, pitchMax = 0.8, 1.3;
		
	elseif obj.Material == Enum.Material.Glass then
		
		surfaceSoundId = "glassImpact0"..math.random(1, 2);
		pitchMin, pitchMax = 0.5, 1.5;
	
	elseif obj.Material == Enum.Material.Wood 
		or obj.Material == Enum.Material.WoodPlanks then
		
		surfaceSoundId = "woodImpact0"..math.random(1, 3);
		pitchMin, pitchMax = 0.5, 1.5;
		
	end
	
	if param.Enemy and surfaceSoundId == nil then
		return false;
	end
	if surfaceSoundId == nil then
		
		surfaceSoundId = "stoneImpact0"..math.random(3, 4);
		pitchMin, pitchMax = 0.9, 1.1;
	end
	
	if surfaceSoundId and Debugger.ClientFps >= 30 then
		local new = surfaceSounds:FindFirstChild(surfaceSoundId);
		if new then
			new = new:Clone();
			new.PlaybackSpeed = math.clamp((math.random(9,11)/10) * 1/(obj.Size.Magnitude/6), pitchMin, pitchMax);
			new.Parent = newAtt;
			new:Play();
			
			game.Debris:AddItem(newAtt, new.TimeLength+0.1);
		end
	end

	return;
end


-- !outline: function CreateBulletHole(obj, point, normal)
function WeaponsMechanics.CreateBulletHole(obj, point, normal)
	if RunService:IsClient() then
		modData = getModData();

		if modData:GetSetting("LimitParticles") == 1 then return; end
	end

	if obj == nil or point == nil or normal == nil then return end;
	
	if obj:GetAttribute("IsLiquid") == true then
		return;
	end
	
	WeaponsMechanics.ImpactSound{
		BasePart = obj;
		Point = point;
		Normal = normal;
	}

	if Debugger.ClientFps <= 30 then return end;
	local bulletHole = Instance.new("Part");
	bulletHole.Name = "BulletHole";
	bulletHole.Transparency = 1;
	bulletHole.Anchored = true;
	bulletHole.CanCollide = false;
	bulletHole.Size = Vector3.new(0.6, 0.6, 0);
	bulletHole.CastShadow = false;
	bulletHole.Massless = true;
	
	local smoke = smokeEffect:Clone();
	smoke.Parent = bulletHole;
	if obj then
		smoke.Color = ColorSequence.new(obj.Color)
	end;
	smoke.Transparency = NumberSequence.new(0, 1);
	
	spawn(function()
		for a=1, 8 do
			smoke.Lifetime = NumberRange.new(0.5, random:NextNumber(1, 1.5));
			smoke.Size = NumberSequence.new(random:NextNumber(0.3, 0.5), 0);
			smoke.Acceleration = normal*random:NextNumber(18, 20);
			smoke:Emit(3);
			RunService.Heartbeat:Wait();
		end
	end)
		
	game.Debris:AddItem(smoke, 10);
	
	local decal = Instance.new("Decal");
	decal.Face = Enum.NormalId.Front;
	decal.Texture = "rbxassetid://7055077279";
	decal.Transparency = 0;
	decal.Parent = bulletHole;
	
	spawn(function()
		wait(5);
		for a=0, 1, 1/5/5 do
			decal.Transparency = a;
			wait(1/5);
		end
		bulletHole:Destroy();
	end)
	
	local weld = Instance.new("WeldConstraint");
	bulletHole.Parent = workspace.CurrentCamera;
	bulletHole.CFrame = CFrame.new(point, point+normal-normal*0.025);
	bulletHole.Anchored = false;
	
	weld.Parent = bulletHole;
	weld.Part0 = obj;
	weld.Part1 = bulletHole;
	
	game.Debris:AddItem(bulletHole, 10);
end;


-- !outline: function CreateMuzzle(muzzleOrigin, bulletOrigin, multiShot, allowGenerateMuzzle)
function WeaponsMechanics.CreateMuzzle(muzzleOrigin, bulletOrigin, multiShot, allowGenerateMuzzle)
	local limitParticles = false;
	if RunService:IsClient() then
		modData = getModData();

		limitParticles = modData:GetSetting("LimitParticles") == 1;
	end

	multiShot = multiShot or 1;
	if muzzleOrigin ~= nil and allowGenerateMuzzle ~= false then

		local muzzle = muzzleEffect:Clone();
		muzzle.Parent = muzzleOrigin;
		muzzle.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.5+(0.2*(multiShot-1)), 1);
			NumberSequenceKeypoint.new(1, 0.4, 0);
		});
		muzzle:Emit(1);
		game.Debris:AddItem(muzzle, 2);

		if limitParticles then return end;

		local smoke = smokeEffect:Clone();
		smoke.Parent = bulletOrigin;
		smoke.Enabled = true;
		smoke:Emit(5);
		game.Debris:AddItem(smoke, 5);

		local newMuzzleLight = muzzleLight:Clone();
		newMuzzleLight.Parent = muzzleOrigin;
		newMuzzleLight.Enabled = true;
		game.Debris:AddItem(newMuzzleLight, 1/15);
	end
end;


-- !outline: function CreateTracer(bulletOrigin, targetPoint, camera, color)
function WeaponsMechanics.CreateTracer(bulletOrigin, targetPoint, camera, color, suppressed)
	
	if RunService:IsClient() then
		modData = getModData();
		if modData:GetSetting("DisableBulletTracers") == 1 then return end;
	end

	local originPoint = bulletOrigin.WorldPosition;
	
	local displace = (targetPoint-originPoint);
	local shotDir = displace.Unit;
	local shotDist = displace.Magnitude;
	
	local tracerPart = Debugger:PointPart(targetPoint);
	tracerPart.Name = "BulletTracer";
	tracerPart.Transparency = 1;
	tracerPart.Parent = workspace.CurrentCamera;
	
	local attPointB = Instance.new("Attachment");
	attPointB.Name = "Back";
	attPointB.Parent = tracerPart;
	attPointB.WorldPosition = originPoint;

	local attPointF = Instance.new("Attachment");
	attPointF.Name = "Front";
	attPointF.Parent = tracerPart;
	attPointF.WorldPosition = originPoint;
	
	game.Debris:AddItem(tracerPart, 2);
	
	local newTracer = tracerEffect:Clone();
	newTracer.Attachment0 = attPointB;
	newTracer.Attachment1 = attPointF;
	
	local colorA = color or Color3.fromRGB(255, 89, 0);
	local colorbH, _colorbS, colorbV = colorA:ToHSV();
	newTracer.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHSV(colorbH, 255/255, colorbV)),
		ColorSequenceKeypoint.new(0.3, Color3.fromHSV(colorbH, 200/255, colorbV)),
		ColorSequenceKeypoint.new(0.6, Color3.fromHSV(colorbH, 100/255, colorbV)),
		ColorSequenceKeypoint.new(1, Color3.fromHSV(colorbH, 50/255, colorbV))
	});
	local tracerTransparency = suppressed and 0.5 or 0;
	newTracer.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.1, tracerTransparency),
		NumberSequenceKeypoint.new(0.8, tracerTransparency),
		NumberSequenceKeypoint.new(1, 1)
	})
	newTracer.Parent = tracerPart;
	
	local hitscanSpeed = 80;
	local tracerLength = 4;
	
	local delayTime = 0.1 * math.clamp(tracerLength/hitscanSpeed, 1, 20);
	local travelTime = 0.1 * math.clamp(shotDist/hitscanSpeed, 1, 20);
	
	local endPoint = targetPoint-(shotDir*math.min(tracerLength,shotDist));
	
	local tracerTweenB = TweenService:Create(attPointB, 
		TweenInfo.new(travelTime, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, delayTime), 
		{WorldPosition=endPoint;}
	);
	local tracerTweenF = TweenService:Create(attPointF, 
		TweenInfo.new(travelTime),
		{WorldPosition=targetPoint;}
	);
	
	tracerTweenF.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed or state == Enum.PlaybackState.Cancelled then
			tracerPart:Destroy();
		end
	end)
	tracerTweenB:Play();
	tracerTweenF:Play();
end;


-- !outline: function BulletHitSound(param)
function WeaponsMechanics.BulletHitSound(param)
	local modAudio = require(game.ReplicatedStorage.Library.Audio);
	
	local basePart = param.BasePart;
	local humanoid = param.Humanoid;

	if basePart:GetAttribute("IsLiquid") == true then
		return;
	end
	
	local index = param.Index or 0;
	
	local armor = humanoid and humanoid:GetAttribute("Armor") or 0;
	if armor > 0 then
		modAudio.Play(("ArmorHit"..math.random(1,4)), nil, false, 1/((index+1)*0.9));
		
	elseif (basePart.Name == "Head" or basePart:GetAttribute("IsHead") == true) then
		local hitSoundRoll = (random:NextNumber(0,1) == 1 and "BulletHeadImpact" or "BulletHeadImpact2");
		modAudio.Play(hitSoundRoll, nil, false, 1/((index+1)*0.9));
	else
		local hitSoundRoll = (random:NextNumber(0,1) == 1 and "BulletBodyImpact" or "BulletBodyImpact2");
		modAudio.Play(hitSoundRoll, nil, false, 1/((index+1)*0.9));
	end
end


local casualRandom = modPseudoRandom.new();
-- !outline: function DamageModification(player, weaponModule, shotCache)
function WeaponsMechanics.DamageModification(weaponModule, shotCache, player: Player?)
	local modAudio = require(game.ReplicatedStorage.Library.Audio);
	--==
	local classPlayer = player and shared.modPlayers.Get(player) or nil;

	local configurations = weaponModule.Configurations;
	--local properties = weaponModule.Properties;
	
	local preModDamage = configurations.PreModDamage;
	local damage = configurations.Damage;

	-- extra
	local ammo = shotCache.Ammo;

	local weaponId = shotCache.WeaponId;
	local weaponModel = shotCache.WeaponModel;
	
	
	if configurations.DamageRev and ammo then
		local multi = configurations.DamageRev;
		local add = (preModDamage * multi);
		if (ammo+1) ~= configurations.AmmoLimit then
			damage = damage + (add * math.clamp(1-(ammo/configurations.AmmoLimit), 0, 1));
		end
	end
	
	
	local critChance = configurations.CritChance or 0;
	
	if classPlayer and classPlayer.Properties and classPlayer.Properties.CritBoost then
		critChance = critChance + (classPlayer.Properties.CritBoost.Amount/100);
	end
	
	local critProcs = shotCache.CritProcs or 0;
	local casualRandom = shotCache.CasualRandom or casualRandom;
	if critChance > 0 then
		if shotCache.Index == 1 then
			if configurations.SlugRounds and critProcs > 0 then
				critChance = 0;
			end

			if casualRandom and casualRandom:FairCrit(weaponId or "", critChance) then
				critProcs = critProcs +1;
				shotCache.CritProced = true;
				
				local multi = configurations.CritMulti or 1.5;
				local add = (preModDamage * multi);

				damage = damage + add;
				shotCache.CritOccured = "Crit";

				if weaponModel then
					local critSound = modAudio.Play("CritHit0"..random:NextInteger(1, 2) , weaponModel.PrimaryPart);
					critSound.PlaybackSpeed = random:NextNumber(0.8, 1.2);
					critSound.Volume = 3;
				end
			end
			
		elseif shotCache.CritProced == true then
			local multi = configurations.CritMulti or 1.5;
			local add = (preModDamage * multi);

			damage = damage + add;
			shotCache.CritOccured = "Crit";
			
		end
	end
	
	
	local hitPart = shotCache.HitPart;
	if configurations.HeadshotMultiplier and configurations.HeadshotMultiplier > 0 and hitPart then
		if (hitPart.Name == "Head" or hitPart:GetAttribute("IsHead") == true) then
			local add = preModDamage * configurations.HeadshotMultiplier;
			damage = damage + add;
		end
	end
	
	
	local focusCharge = shotCache.FocusCharge;
	if configurations.FocusDuration > 0 and focusCharge and focusCharge >0 then
		local charge = math.clamp(focusCharge, 0, 1);

		local chargeDmgPercent = configurations.ChargeDamagePercent or 0.05;

		local addDmg = ((preModDamage * chargeDmgPercent) * charge);
		damage = damage + addDmg;
	end
	
	if classPlayer and classPlayer.Properties and classPlayer.Properties.FrostivusSpirit then
		damage = damage + math.clamp(classPlayer.Properties.FrostivusSpirit.Amount, 0, 10000);
	end
	
	return damage;
end

return WeaponsMechanics;