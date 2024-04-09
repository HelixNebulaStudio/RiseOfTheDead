local ClothingLibrary = {};
ClothingLibrary.__index = ClothingLibrary;

local RunService = game:GetService("RunService");

--== Script;
function ClothingLibrary:Init(super)
	for _, m in pairs(script:GetChildren()) do
		super.LoadToolModule(m);
	end
	script.ChildAdded:Connect(super.LoadToolModule);
end

return ClothingLibrary;
