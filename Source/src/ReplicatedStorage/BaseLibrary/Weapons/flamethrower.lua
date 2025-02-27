local modWeaponAttributes = require(game.ReplicatedStorage.Library.Weapons.WeaponAttributes);
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Pyrotechnic";
	Tier=1;

	Animations={
		Core={Id=139960063874729;};
		PrimaryFire={Id=111594127198663; FocusWeight=1; LoopMarker=true;};
		Reload={Id=95479337670641;};
		Load={Id=77555855180377;};
		Inspect={Id=110730144530496;};
		Sprint={Id=76041028625264};
		Empty={Id=88047448709872;};
		Unequip={Id=119216181015801; Looped=false;};
		Idle={Id=98551069245377};
	};

	Audio={
		Load={Id=169799883; Pitch=1.2; Volume=0.4;};
		PrimaryFire={Id=260131485; Pitch=1; Volume=1; Looped=true;};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
		SafetyFlip={Id="SafetyFlip"; Preload=true;};
		OpenMagTop2={Id="OpenMagTop2"; Preload=true;};
		FlamethrowerMagOut={Id="FlamethrowerMagOut"; Preload=true;};
		FlamethrowerMagOut2={Id="FlamethrowerMagOut2"; Preload=true;};
		FlamethrowerGas={Id="FlamethrowerGas"; Preload=true;};
		FlamethrowerMagIn1={Id="FlamethrowerMagIn1"; Preload=true;};
		FlamethrowerMagIn2={Id="FlamethrowerMagIn2"; Preload=true;};
		CloseMagTop={Id="CloseMagTop"; Preload=true;};
	};

	Configurations={
		-- Mechanics
		BulletMode=modWeaponAttributes.BulletModes.Projectile;
		TriggerMode=modWeaponAttributes.TriggerModes.Automatic;
		ReloadMode=modWeaponAttributes.ReloadModes.Full;
		
		AmmoType="lightammo";

		BulletEject="PistolBullet";
		BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);
		
		-- Stats
		Damage=2;
		PotentialDamage=100;
		
		MagazineSize=50;
		AmmoCapacity=(50*4);
	
		Rpm=600;
		ReloadTime=5;
		Multishot=1;
<<<<<<< HEAD

		HeadshotMultiplier=0.5;
		EquipLoadTime=1.2;

		StandInaccuracy=4;
		FocusInaccuracyReduction=1;
		CrouchInaccuracyReduction=1;
		MovingInaccuracyScale=2;

		-- Focus
		FocusWalkSpeedReduction=0.6;

		-- Projectile
		ProjectileId="liquidFlame";

=======

		HeadshotMultiplier=0.5;
		EquipLoadTime=1.2;

		StandInaccuracy=4;
		FocusInaccuracyReduction=1;
		CrouchInaccuracyReduction=1;
		MovingInaccuracyScale=2;

		-- Focus
		FocusWalkSpeedReduction=0.6;

		-- Projectile
		ProjectileId="liquidFlame";

>>>>>>> b7050963ccc669ec5ee00093af9741966adc936a
		-- Recoil
		XRecoil=0.01;
		YRecoil=0.02;
		-- Dropoff
		DamageDropoff={
			MinDistance=100;
			MaxDistance=200;
		};
		-- UI
		UISpreadIntensity=4;
		-- Body
		RecoilStregth=math.rad(10);
		-- Penetration
		Penetration=modWeaponAttributes.PenetrationTable.Pistol;
		-- Physics
		KillImpulseForce=5;
		-- Effects
		GeneratesBulletHoles=false;
		GenerateBloodEffect=false;
		GenerateTracers=false;
		GenerateMuzzle=false;
	};

<<<<<<< HEAD
	Properties={
		PrimaryFireAudio=function(file, state)
			local TweenService = game:GetService("TweenService");

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
	
		OnAmmoUpdate = function(weaponModel, equipmentClass, ammo)
			local configurations = equipmentClass.Configurations;
			local properties = equipmentClass.Properties;
			
			local magSize = configurations.MagazineSize;
			
			local pointerAtt = weaponModel.Pointer.PointerAtt;
			
			local ratio = math.clamp(ammo/magSize, 0, 1);
			pointerAtt.CFrame = CFrame.new(0, 0, -0.049) * CFrame.Angles(0, math.rad((ratio * 180)-90), 0);
		end;
	};
};

=======
	Properties={};
};

function toolPackage.OnPrimaryFireAudio(handler: ToolHandlerInstance, sound: Sound, state)
	local TweenService = game:GetService("TweenService");

	local tween = nil;
	if sound ~= nil then
		if state == 1 then
			sound.Volume = 0;
			tween = TweenService:Create(sound, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Volume=1;});
			tween:Play();
		elseif state == 2 then
			sound.Volume = 1;
			tween = TweenService:Create(sound, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {Volume=0;});
			tween:Play();
			tween.Completed:Connect(function()
				game.Debris:AddItem(sound, 0);
			end)
		end
	end

	return tween;
end

function toolPackage.OnMarkerEvent(handler: ToolHandlerInstance, animationId: string, markerValue)
	local weaponModel = handler.Prefabs[1];

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
end

function toolPackage.OnAmmoUpdate(handler: ToolHandlerInstance)
	local weaponModel = handler.Prefabs[1];
	local equipmentClass = handler.EquipmentClass;

	local configurations = equipmentClass.Configurations;
	local properties = equipmentClass.Properties;
	
	local magSize = configurations.MagazineSize;
	
	local pointerAtt = weaponModel.Pointer.PointerAtt;
	
	local ratio = math.clamp(properties.Ammo/magSize, 0, 1);
	pointerAtt.CFrame = CFrame.new(0, 0, -0.049) * CFrame.Angles(0, math.rad((ratio * 180)-90), 0);
end


>>>>>>> b7050963ccc669ec5ee00093af9741966adc936a
function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage.Class, toolPackage.Configurations, toolPackage.Properties);
end

return toolPackage;