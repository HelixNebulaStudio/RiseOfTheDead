local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Hitscan;
	TriggerMode=WeaponsAttributes.TriggerModes.Automatic;
	ReloadMode=WeaponsAttributes.ReloadModes.Full;
	
	EquipLoadTime=0.4;
	AmmoType="lightammo";
	
	BaseInaccuracy=2;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=1.3;
	
	BulletRange=512;
	BulletEject="PistolBullet";
	BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);

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

	DoSpecialLoad = function(weaponModule, storageItem)
		local configurations = weaponModule.Configurations;
		local properties = weaponModule.Properties;

		local itemValues = storageItem.Values;
		
		if itemValues.MA and itemValues.MA <= configurations.MaxAmmoLimit then
			return "SpecialLoad";
		end
		return "Load";
	end;
	
	DoSpecialReload = function(weaponModule, storageItem, toolObjects)
		local properties = weaponModule.Properties;
		local toolModel = toolObjects.Right.Model;
		
		local magazine2 = toolModel:FindFirstChild("Magazine2");
		if magazine2 and magazine2.Transparency == 1 then
			
			if properties.Ammo > 0 then
				return "TacticalReload";
			end
			return "SpecialLoad";
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

local Animations={
	Core={Id=74139870889569;};
	PrimaryFire={Id=101753791713642;};
	Reload={Id=76704583558755;};
	TacticalReload={Id=110960139338373;};
	Load={Id=71780611626513;};
	Inspect={Id=95711599651337;};
	Sprint={Id=98761523775318};
	Empty={Id=82796095029912;};
	Unequip={Id=127466609333739};
	Idle={Id=74318408349078;};

	SpecialReload={Id=134203123804957;};
	SpecialLoad={Id=93932634098637;};
};

local Audio={
	Load={Id=169799883; Pitch=1.5; Volume=0.4;};
	PrimaryFire={Id=2920959; Pitch=1.4; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
};

local toolPackage = {
	ItemId="cz75";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Pistol";
	Tier=1;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;