local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local random = Random.new();
local TweenService = game:GetService("TweenService");
local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

--== Script;

local reloadAnimation = {
	keyFrameConnection = nil;
}	

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Projectile;
	TriggerMode=Library.TriggerModes.Automatic;
	ReloadMode=Library.ReloadModes.Full;
	
	EquipLoadTime=1.2;
	
	BaseInaccuracy=4;
	FocusInaccuracyReduction=1;
	CrouchInaccuracyReduction=1;
	MovingInaccuracyScale=2;
	
	BulletRange=512;
	-- Weapon Properties;
	MinBaseDamage=2;
	BaseDamage=100;
	
	AmmoLimit=50;
	MaxAmmoLimit=(50*4);
	
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(10);
	
	-- Decorations;
	ShakeCamera=false;
	GeneratesBulletHoles=false;
	GenerateBloodEffect=false;
	GenerateTracers=false;
	GenerateMuzzle=false;

	
	ProjectileId="liquidFlame";
	AdsTrajectory=true;
	
	-- Audio
	PrimaryFireAudio=function(file, state)
		local tween = nil;
		if file ~= nil then
			if state == 1 then
				file.Volume = 0;
				tween = TweenService:Create(file, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Volume=1;});
				tween:Play();
			elseif state == 2 then
				file.Volume = 1;
				tween = TweenService:Create(file, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {Volume=0;});
				tween:Play();
				tween.Completed:Connect(function()
					game.Debris:AddItem(file, 0);
				end)
			end
		end
		return tween;
	end;
	
	-- Animations
	OnMarkerEvent=function(weaponModel, animationId, markerValue)
		if animationId == "Reload" then
			local mainModel = weaponModel.Right;
			
			if markerValue == "Detach gastank" and mainModel then
				mainModel.Magazine.Particle.GasParticle:Emit(10);
				task.wait();
				mainModel.Magazine.Particle.GasParticle:Emit(10);
				task.wait();
				mainModel.Magazine.Particle.GasParticle:Emit(6);
				task.wait();
				mainModel.Magazine.Particle.GasParticle:Emit(4);
			end
		end
	end;

	OnAmmoUpdate = function(weaponModel, modWeaponModule, ammo)
		local configurations = modWeaponModule.Configurations;
		local properties = modWeaponModule.Properties;
		
		local ammoLimit = configurations.AmmoLimit;
		
		local pointerAtt = weaponModel.Pointer.PointerAtt;
		
		local ratio = math.clamp(ammo/ammoLimit, 0, 1);
		pointerAtt.CFrame = CFrame.new(0, 0, -0.049) * CFrame.Angles(0, math.rad((ratio * 180)-90), 0);
	end;
	
	FocusWalkSpeedReduction=0.6;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=600;
	FireRate=(60/600);
	ReloadSpeed=5;
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16608653550;};
	PrimaryFire={Id=16608798136; FocusWeight=1; LoopMarker=true;};
	Reload={Id=16608800776;};
	Load={Id=16608795644;};
	Inspect={Id=16608807141;};
	Sprint={Id=16608804483};
	Empty={Id=16608656414;};
	Unequip={Id=16840084601; Looped=false;};
	
} or { -- Main
	Core={Id=16608653550;};
	PrimaryFire={Id=16608798136; FocusWeight=1; LoopMarker=true;};
	Reload={Id=16608800776;};
	Load={Id=16608795644;};
	Inspect={Id=16608807141;};
	Sprint={Id=16608804483};
	Empty={Id=16608656414;};
	Unequip={Id=16840084601; Looped=false;};
	
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=260131485; Pitch=1; Volume=1; Looped=true;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
	--Reload={Id=6291966821; Pitch=1; Volume=0.6;};
}

Configurations.ItemId = script.Name;
return WeaponProperties.new(Configurations, Properties, Animations, Audio);