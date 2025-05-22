local modWeaponAttributes = shared.require(game.ReplicatedStorage.Library.WeaponsLibrary.WeaponAttributes);
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Sniper";
	Tier=2;

	Animations={
		Core={Id=92774284166204;};
		PrimaryFire={Id=90639355394112;};
		LastFire={Id=125741744776151;};
		Reload={Id=136978537766095;};
		TacticalReload={Id=83864736846733;};
		Load={Id=72775562785125;};
		Inspect={Id=90391006304690;};
		Sprint={Id=137338635814339};
		Empty={Id=132800056779750;};
		Unequip={Id=130105436052579};
		Idle={Id=125156979609191};
	};

	Audio={
		Load={Id=169799883; Pitch=1.2; Volume=0.4;};
		PrimaryFire={Id=988205199; Pitch=1; Volume=1;};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
		GarandPing={Id="GarandPing"; Preload=true;};
	};

	Configurations={
		-- Mechanics
		BulletMode=modWeaponAttributes.BulletModes.Hitscan;
		TriggerMode=modWeaponAttributes.TriggerModes.Semi;
		ReloadMode=modWeaponAttributes.ReloadModes.Full;
		WeaponType=modWeaponAttributes.WeaponType.Sniper;
		
		AmmoType="sniperammo";

		BulletEject="SniperBullet";
		BulletEjectDelayTime=0.2;
		BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);
		
		-- Stats
		Damage=580;
		PotentialDamage=19680;
		
		MagazineSize=6;
		AmmoCapacity=(6*3);
	
		Rpm=250;
		ReloadTime=2.8;
		Multishot=1;

		HeadshotMultiplier=0.5;
		EquipLoadTime=1.5;

		StandInaccuracy=2.2;
		FocusInaccuracyReduction=0.5;
		CrouchInaccuracyReduction=0.5;
		MovingInaccuracyScale=8;

		-- Focus
		FocusDuration=3;
		FocusWalkSpeedReduction=0.65;
		ChargeDamagePercent=0.2;

		-- Recoil
		XRecoil=0.1;
		YRecoil=0.6;
		-- Dropoff
		DamageDropoff={
			MinDistance=256;
		};
		-- UI
		UISpreadIntensity=4;
		UseScopeGui=true;
		KeepScopedWhenFiring=true;
		-- Body
		RecoilStregth=math.rad(90);
		-- Penetration
		Penetration={
			[Enum.Material.Glass]=1;
			[Enum.Material.Wood]=1;
			[Enum.Material.WoodPlanks]=1;
			["Others"]=0.5;
		};
		-- Physics
		KillImpulseForce=40;
	};

	Properties={};
};

function toolPackage.OnReload(handler: ToolHandlerInstance)
	local weaponModel = handler.Prefabs[1];
	local equipmentClass = handler.EquipmentClass;

	local properties = equipmentClass.Properties;
	if properties.Ammo <= 0 then return end;

	local magazinePart = weaponModel:FindFirstChild("Magazine");
	local caseOutPoint = weaponModel:FindFirstChild("CaseOut", true);
	if magazinePart and caseOutPoint then
		local newEject = magazinePart:Clone();
		newEject:ClearAllChildren();
		game.Debris:AddItem(newEject, 5);

		newEject.CFrame = caseOutPoint.WorldCFrame * CFrame.Angles(0, math.rad(math.random(0, 360)), math.rad(math.random(-35, 35)));
		newEject.Parent = workspace.Debris;

		newEject:ApplyImpulse(caseOutPoint.WorldCFrame.RightVector * 0.5);
	end
end

function toolPackage.OnPrimaryFire(handler: ToolHandlerInstance)
	local weaponModel = handler.Prefabs[1];
	local equipmentClass = handler.EquipmentClass;

	local properties = equipmentClass.Properties;
	if properties.Ammo > 0 then return end;

	local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
	modAudio.Play("GarandPing", weaponModel.PrimaryPart);

	local magazinePart = weaponModel:FindFirstChild("Magazine");
	local caseOutPoint = weaponModel:FindFirstChild("CaseOut", true);
	if magazinePart and caseOutPoint then
		local newEject = magazinePart:Clone();
		newEject:ClearAllChildren();
		game.Debris:AddItem(newEject, 5);

		newEject.CFrame = caseOutPoint.WorldCFrame * CFrame.Angles(0, math.rad(math.random(0, 360)), math.rad(math.random(-35, 35)));
		newEject.Parent = workspace.Debris;

		newEject:ApplyImpulse(caseOutPoint.WorldCFrame.RightVector * 0.5);
	end
end

function toolPackage.newClass()
	local equipmentClass = modEquipmentClass.new(toolPackage);
	
	equipmentClass:AddBaseModifier("BulletRicochet", {
		SetValues={
			BulletRicochetCount=2;
			BulletRicochetDistance=64;
		};
	});

	return equipmentClass;
end

return toolPackage;
