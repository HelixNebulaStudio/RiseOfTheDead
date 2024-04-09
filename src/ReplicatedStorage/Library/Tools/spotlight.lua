local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;

return function()
	local Tool = {};
	Tool.IsActive = false;
	Tool.UseViewmodel = false;
	
	function Tool:OnPrimaryFire(isActive)
		for a=1, #self.Prefabs do
			local prefab = self.Prefabs[a];
			
			local light = prefab:FindFirstChild("_lightSource");
			if light then
				light.Color = isActive and Color3.fromRGB(211, 190, 150) or Color3.fromRGB(100, 100, 100);
				light.Material = isActive and Enum.Material.Neon or Enum.Material.SmoothPlastic;
				local lights = light._lightPoint:GetChildren();
				for b=1, #lights do
					lights[b].Enabled = isActive;
				end
			end
		end
	end

	local animUpdateTick = tick();
	function Tool:OnClientToolRender(equipped, delta)
		if tick()-animUpdateTick > 0.5 then
			animUpdateTick = tick();
			
			local characterProperties = equipped.ModCharacter.CharacterProperties;
			local animations = equipped.Animations;
			
			if animations["SwimCore"] then
				if characterProperties.IsSwimming and characterProperties.IsMoving 
					and characterProperties.ThirdPersonCamera and not characterProperties.IsFocused then
					
					if animations["Core"].IsPlaying then
						animations["Core"]:Stop();
						animations["SwimCore"]:Play();
					end
					
				else
					if animations["SwimCore"].IsPlaying then
						animations["Core"]:Play();
						animations["SwimCore"]:Stop();
					end
					
				end
			end
		end
	end
	
	return Tool;
end;