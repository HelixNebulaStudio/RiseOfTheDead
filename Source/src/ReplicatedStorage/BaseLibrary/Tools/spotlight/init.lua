local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="GenericTool";

	Animations={
		Core={Id=4706387367; IdSwim=14120032381;};
	};
	Audio={};
	Configurations={
		UseViewmodel = false;
	};
	Properties={};
};

function toolPackage.OnActionEvent(handler, packet)
	local isActive = packet.IsActive;
	local prefab = handler.Prefabs[1];
			
	local light = prefab:FindFirstChild("_lightSource");
	if light then
		light.Color = isActive and Color3.fromRGB(211, 190, 150) or Color3.fromRGB(100, 100, 100);
		light.Material = isActive and Enum.Material.Neon or Enum.Material.SmoothPlastic;
		local lights = light._lightPoint:GetChildren();
		for b=1, #lights do
			lights[b].Enabled = isActive;
		end
	end
end

local animUpdateTick = tick();
function toolPackage.OnRenderStep(handler, delta)
	if tick()-animUpdateTick > 0.5 then
		animUpdateTick = tick();
		
		local modData = require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
		local modCharacter = modData:GetModCharacter();

		local characterProperties = modCharacter.CharacterProperties;

		local toolAnimator = handler.ToolAnimator;

		if characterProperties.IsSwimming and characterProperties.IsMoving 
		and characterProperties.ThirdPersonCamera and not characterProperties.IsFocused then
			toolAnimator:SetState("Swim");
		else
			toolAnimator:SetState("");
		end
		toolAnimator:Play("Core");

	end
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage.Class, toolPackage.Configurations, toolPackage.Properties);
end

return toolPackage;