local parent = script.Parent;
local parts = {};

for _, obj in pairs(parent:GetDescendants()) do
	if not obj:IsA("BasePart") then continue end;
	table.insert(parts, obj);
end

parent:GetAttributeChangedSignal("Color"):Connect(function()
	for a=1, #parts do
		parts[a].Color = parent:GetAttribute("Color") or Color3.fromRGB(128, 183, 255);
	end
end)