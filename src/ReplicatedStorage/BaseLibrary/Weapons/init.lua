local Weapons = {};
Weapons.__index = Weapons;
--==

function Weapons:Init(super)
	for _, m in pairs(script:GetChildren()) do
		if m.Name == "Template" then continue end;
		super:LoadToolModule(m);
	end
	script.ChildAdded:Connect(function(m) 
		super:LoadToolModule(m);
	end);
end

return Weapons;