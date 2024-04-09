local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;

return function()
	local Tool = {};
	Tool.DisableMovement = true;
	Tool.IsActive = false;
	
	function Tool:OnPrimaryFire(isActive)
		for a=1, #self.Prefabs do
			local prefab = self.Prefabs[a];
			
			local food = prefab:FindFirstChild("Food");
			local firePoint = prefab.PrimaryPart:FindFirstChild("FirePoint");
			
			if food then
				for _, obj in pairs(food:GetChildren()) do
					if obj:IsA("BasePart") then
						obj.Transparency = isActive and 0 or 1;
					end
				end
			end
			if firePoint then
				firePoint.FireEffect.Enabled = isActive;
				firePoint.PointLight.Enabled = isActive;
				firePoint.PointLight2.Enabled = isActive;
			end
		end
	end
	
	return Tool;
end;