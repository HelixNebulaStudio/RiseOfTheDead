local Flashlight = {}

local character = script.Parent.Parent;
local rootPart = character:WaitForChild("HumanoidRootPart");

local flashLightTemplate = script:WaitForChild("FlashLight");
local spotLightTemplate = script:WaitForChild("SpotLight");

local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

function Flashlight:Attachment()
	local CameraAttachment = Instance.new("Attachment");
	CameraAttachment.Name = "CameraLight";
	CameraAttachment.Parent = rootPart;
	local newFlashlight = flashLightTemplate:Clone();
	local newSpotlight = spotLightTemplate:Clone();
	newFlashlight.Parent = CameraAttachment;
	newSpotlight.Parent = CameraAttachment;
	
	if modConfigurations.DisableDefaultFlashlight == true then
		newFlashlight.Enabled = false;
		newSpotlight.Enabled = false;
	end
	return CameraAttachment;
end

function Flashlight:Update(cframe)
	local attachment = rootPart:FindFirstChild("CameraLight") or self.Attachment();
	attachment.WorldCFrame = cframe;
end

function Flashlight:Destroy()
	game.Debris:AddItem(rootPart:FindFirstChild("CameraLight"), 0);
end

return Flashlight;
