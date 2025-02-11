local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="Throwable";

	Animations={
		Core={Id=7326823684;};
		Load={Id=7326830371;};
		Reload={Id=7326830371;};
		Charge={Id=5075419727;};
		Throw={Id=5075441987};
	};
	Audio={
		ProjectileBounce={Id=5082995723; Pitch=1; Volume=1;};
		Throw={Id=5083063763; Pitch=1; Volume=1;};
	};

	Configurations={
		LoadTime = 2.5;
		
		DamageRatio = 0.1;
		ExplosionRadius = 25;
		MinDamage = 50;
		
		
		Velocity = 200;
		ProjectileBounce = 0;
		ChargeDuration = 0.5;
		VelocityBonus = 20;
		ProjectileAcceleration = Vector3.new(0, -workspace.Gravity, 0);
		
		--== Projectile
		ProjectileId = "explosives";
		ProjectileLifeTime = 2;
		
		ConsumeOnThrow=true;
		ThrowRate = 2.3;
	};
	Properties={
		OnAnimationPlay = function(animId, toolHandler, toolModel)
			if animId == "Load" or animId == "Reload" then
				local fuseParticle = toolModel:WaitForChild("Handle"):WaitForChild("fusePoint"):WaitForChild("fuseParticle");
				local fireParticle = toolModel:WaitForChild("MatchStick"):WaitForChild("firePoint"):WaitForChild("Fire2");
				toolModel.MatchStick.Transparency = 0;
				
				task.delay(1.4, function()
					fireParticle.Enabled = true;
				end)
				task.delay(1.75, function()
					fuseParticle.Enabled = true;
				end)
				task.delay(2, function()
					fireParticle.Enabled = false;
				end)
				task.delay(2.5, function()
					toolModel.MatchStick.Transparency = 1;
					fuseParticle.Enabled = true;
					fireParticle.Enabled = false;
				end)
			end
		end;
	};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage.Class);
end

return toolPackage;