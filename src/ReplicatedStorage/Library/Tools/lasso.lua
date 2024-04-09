return function()
	local Tool = {};
	Tool.IsActive = false;

	function Tool:OnPrimaryFire(isActive)
		self.IsActive = isActive;
		
		local prefab = self.Prefabs[1];
		
		if prefab then
			local rope = prefab:FindFirstChild("rope");
			if rope then
				rope.Transparency = self.IsActive and 0 or 1;
			end
			local ropeCoil = prefab:FindFirstChild("ropeCoil");
			if ropeCoil then
				ropeCoil.Transparency = self.IsActive and 1 or 0;
			end
		end
	end
	
	return Tool;
end;
