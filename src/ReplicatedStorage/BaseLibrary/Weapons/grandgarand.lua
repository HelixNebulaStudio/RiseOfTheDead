local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local modAudio = require(game.ReplicatedStorage.Library.Audio);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Hitscan;
	TriggerMode=WeaponsAttributes.TriggerModes.Semi;
	ReloadMode=WeaponsAttributes.ReloadModes.Full;
	WeaponType=WeaponsAttributes.WeaponType.Sniper;
	
	EquipLoadTime=1.5;
	
	AmmoType="sniperammo";
	
	BaseInaccuracy=2.2;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.5;
	MovingInaccuracyScale=8;
	
	BulletRange=512;
	BulletEject="SniperBullet";
	BulletEjectDelayTime=0.2;
	BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.1;
	YRecoil=0.6;
	
	-- Weapon Properties;
	MinBaseDamage=580;
	BaseDamage=19680;
	
	AmmoLimit=6;
	MaxAmmoLimit=(6*3);
	
	DamageDropoff={
		MinDistance=256;
	};
	
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Gimmick
	BulletRicochet="Modifier";
	BulletRicochetCount=2;
	BulletRicochetDistance=64;

	-- Body
	RecoilStregth=math.rad(90);

	UseScopeGui=true;
	KeepScopedWhenFiring=true;
	
	-- Sniper
	BaseFocusDuration=3;
	FocusDuration=3;
	FocusWalkSpeedReduction=0.65;
	ChargeDamagePercent=0.2;
	
	Penetration={
		[Enum.Material.Glass]=1;
		[Enum.Material.Wood]=1;
		[Enum.Material.WoodPlanks]=1;
		["Others"]=0.5;
	};
	KillImpulseForce=40;

	OnEquip=function()
		local modAudio = require(game.ReplicatedStorage.Library.Audio);
		modAudio.Preload("GarandPing", 5);
	end;

	OnReload=function(mainWeaponModel, modWeaponModule)
		local properties = modWeaponModule.Properties;
		if properties.Ammo <= 0 then return end;

		local magazinePart = mainWeaponModel:FindFirstChild("Magazine");
		local caseOutPoint = mainWeaponModel:FindFirstChild("CaseOut", true);
		if magazinePart and caseOutPoint then
			local newEject = magazinePart:Clone();
			newEject:ClearAllChildren();
			game.Debris:AddItem(newEject, 5);

			newEject.CFrame = caseOutPoint.WorldCFrame * CFrame.Angles(0, math.rad(math.random(0, 360)), math.rad(math.random(-35, 35)));
			newEject.Parent = workspace.Debris;

			newEject:ApplyImpulse(caseOutPoint.WorldCFrame.RightVector * 0.5);
		end
	end;

	OnPrimaryFire=function(mainWeaponModel, modWeaponModule)
		local properties = modWeaponModule.Properties;
		if properties.Ammo > 0 then return end;

		modAudio.Play("GarandPing", mainWeaponModel.PrimaryPart);

		local magazinePart = mainWeaponModel:FindFirstChild("Magazine");
		local caseOutPoint = mainWeaponModel:FindFirstChild("CaseOut", true);
		if magazinePart and caseOutPoint then
			local newEject = magazinePart:Clone();
			newEject:ClearAllChildren();
			game.Debris:AddItem(newEject, 5);

			newEject.CFrame = caseOutPoint.WorldCFrame * CFrame.Angles(0, math.rad(math.random(0, 360)), math.rad(math.random(-35, 35)));
			newEject.Parent = workspace.Debris;

			newEject:ApplyImpulse(caseOutPoint.WorldCFrame.RightVector * 0.5);
		end
	end;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=250;
	FireRate=(60/250);
	ReloadSpeed=2.8;
}

local Animations={
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

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=988205199; Pitch=1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
}

local toolPackage = {
	ItemId=script.Name;
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Sniper";
	Tier=2;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;