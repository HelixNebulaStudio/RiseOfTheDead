local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

return function()
	local Tool = {};
	
	Tool.LoadTime = 1;
	Tool.UseViewmodel = false;
	Tool.CustomThrowPoint = "MatchStick";
	
	Tool.Configurations = {
		Damage = 10;
		
		Velocity = 100;
		ProjectileBounce = 0;
		VelocityBonus = 40;

		ThrowRate = 1;
		
		--== Projectile
		ProjectileId = "matchStick";
		ProjectileLifeTime = 4;
		ProjectileAcceleration = Vector3.new(0, -workspace.Gravity, 0);
		ProjectileKeepAcceleration = true;
		
		--ShowFocusTraj=false;
		ConsumeOnThrow=true;
	};
	
	Tool.OnLoad = function(modToolHandler, toolModels)
		for a=1, #toolModels do
			local prefab = toolModels[a];
			
			local fire = prefab:FindFirstChild("Fire2", true);
			if fire then
				modAudio.Play("BurnTick"..math.random(1,3), fire.Parent);
				fire.Enabled = true;
			end
		end
	end
	
	Tool.OnThrow = function(modToolHandler, toolModels)
		for a=1, #toolModels do
			local prefab = toolModels[a];

			local fire = prefab:FindFirstChild("Fire2", true);
			if fire then
				fire.Enabled = false;
				fire:Clear();
			end
		end
	end
	
	Tool.OnThrowComplete = function(modToolHandler, toolModels)
		for a=1, #toolModels do
			local prefab = toolModels[a];

			local fire = prefab:FindFirstChild("Fire2", true);
			if fire then
				fire.Enabled = true;
			end
		end
	end
	
	return Tool;
end;