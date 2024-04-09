return function()
	local Tool = {};
	Tool.IsActive = false;
	Tool.UseViewmodel = false;
	Tool.CustomViewModel = CFrame.new(-0.24, -0.95, 0);
	Tool.UseFOV = 25;
	
	return Tool;
end;