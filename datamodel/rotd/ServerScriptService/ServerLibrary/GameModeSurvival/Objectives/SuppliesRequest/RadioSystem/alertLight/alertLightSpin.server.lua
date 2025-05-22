local TweenService = game:GetService("TweenService");

local lightPart = script.Parent:WaitForChild("alertLight3");
local lightPart2 = script.Parent:WaitForChild("alertLight2");
local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1);
---

script.Parent:GetAttributeChangedSignal("Active"):Connect(function()
	local active = script.Parent:GetAttribute("Active");
	lightPart:WaitForChild("_lightSource"):WaitForChild("SpotLight").Enabled = active;
	lightPart2:WaitForChild("_lightSource"):WaitForChild("PointLight").Enabled = active;
	
	if active then
		lightPart.Material = Enum.Material.Neon;
		lightPart2.Material = Enum.Material.Neon;
		
	else
		lightPart.Material = Enum.Material.Plastic;
		lightPart2.Material = Enum.Material.Plastic;
		
	end
end)

--local rotY = lightPart.Orientation.Y;
TweenService:Create(lightPart, tweenInfo, {Orientation=Vector3.new(0, 360, -90)}):Play();