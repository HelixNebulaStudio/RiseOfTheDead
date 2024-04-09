local FireEffect = {};
FireEffect.__index = FireEffect;

local RunService = game:GetService("RunService");

local fireTemplate = script:WaitForChild("Fire");
local lightTemplate = script:WaitForChild("PointLight");
--==

function FireEffect.new()
	local newAtt = Instance.new("Attachment");
	newAtt.Name = "FireEffect";
	
	local newFire = fireTemplate:Clone();
	newFire.Parent = newAtt;
	local newLight = lightTemplate:Clone();
	newLight.Parent = newAtt;
	
	spawn(function()
		repeat
			newLight.Brightness = math.random(10, 15)/10;
			wait(math.random(5, 30)/10);
		until not newAtt:IsDescendantOf(workspace);
	end)
	
	return newAtt;
end

return FireEffect;