return function()
	local Tool = {};
	Tool.IsActive = false;
	
	function Tool:OnPrimaryFire(isActive)
		for a=1, #self.Prefabs do
			local prefab = self.Prefabs[a];
			local outletHoles = prefab:FindFirstChild("outletHoles");
			local waterParticle = outletHoles and outletHoles:FindFirstChild("waterParticle");
			if waterParticle then
				waterParticle.Enabled = isActive;
			end
		end
	end
	
	return Tool;
end;