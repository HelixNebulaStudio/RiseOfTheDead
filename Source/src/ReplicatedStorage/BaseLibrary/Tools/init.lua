local Tools = {};
Tools.__index = Tools;
--== Script;
function Tools:Init(super)
	for _, m in pairs(script:GetChildren()) do
		if m.Name == "TemplateToolPackage" then continue end;
		super:LoadToolModule(m);
	end
	script.ChildAdded:Connect(function(m) 
		super:LoadToolModule(m);
	end);
end

return Tools;