local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Automatic;
	ReloadMode=Library.ReloadModes.Full;
	
	EquipLoadTime=0.4;
	AmmoType="lightammo";
	
	BaseInaccuracy=2;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=1.3;
	
	BulletRange=512;
	BulletEject="PistolBullet";
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.02;
	YRecoil=0.04;
	
	-- Weapon Properties;
	MinBaseDamage=20;
	BaseDamage=290;
	
	AmmoLimit=16;
	MaxAmmoLimit=(16*4);
	
	DamageRev=2; --5
	
	PenatrationStrength=1; -- In studs.
	PenatrationDamageReduction=0.5; -- Damage * PenatrationDamageReduction;
	
	DamageDropoff={
		MinDistance=64;
		MaxDistance=100;
	};
	
	BaseHeadshotMultiplier=0.5;
	-- UI Configurations;
	UISpreadIntensity=5;
	
	-- Body
	RecoilStregth=math.rad(60);
	
	-- Penetration
	Penetration=WeaponProperties.PenetrationTable.Pistol;

	DoCustomLoad = function(weaponModule, storageItem)
		local configurations = weaponModule.Configurations;
		local properties = weaponModule.Properties;

		local itemValues = storageItem.Values;
		
		if itemValues.MA and itemValues.MA <= configurations.MaxAmmoLimit then
			return "CustomLoad";
		end
		return "Load";
	end;
	
	DoCustomReload = function(weaponModule, storageItem, toolObjects)
		local properties = weaponModule.Properties;
		local toolModel = toolObjects.Right.Model;
		
		local magazine2 = toolModel:FindFirstChild("Magazine2");
		if magazine2 and magazine2.Transparency == 1 then
			
			if properties.Ammo > 0 then
				return "TacticalReload";
			end
			return "CustomReload";
		end
		return "Reload";
	end;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=400;
	FireRate=(60/400);
	ReloadSpeed=3;
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16184525174;};
	PrimaryFire={Id=16184527745;};
	Reload={Id=16184528808;};
	TacticalReload={Id=16255200609;};
	Load={Id=16184526771;};
	Inspect={Id=16184526150;};
	Sprint={Id=16184602077};
	Empty={Id=16184556763;};
	Unequip={Id=16838903122};

	CustomReload={Id=16636386784;};
	CustomLoad={Id=16636398550;};
	
} or { -- Main
	Core={Id=16184525174;};
	PrimaryFire={Id=16184527745;};
	Reload={Id=16184528808;};
	TacticalReload={Id=16255200609;};
	Load={Id=16184526771;};
	Inspect={Id=16184526150;};
	Sprint={Id=16184602077};
	Empty={Id=16184556763;};
	Unequip={Id=16838903122};

	CustomReload={Id=16636386784;};
	CustomLoad={Id=16636398550;};
	
};

local Audio={
	Load={Id=169799883; Pitch=1.5; Volume=0.4;};
	PrimaryFire={Id=2920959; Pitch=1.4; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
};

Configurations.ItemId = script.Name;
return WeaponProperties.new(Configurations, Properties, Animations, Audio);