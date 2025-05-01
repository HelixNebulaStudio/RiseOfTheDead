local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");
local TweenService = game:GetService("TweenService");

local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local loopActive = false;
CollectionService:GetInstanceAddedSignal("BlacklightLights"):Connect(function()
	if loopActive then return end;
	loopActive = true;
	
	task.spawn(function()
		while loopActive do
			task.wait(0.5);
			
			local blacklightInteractables = CollectionService:GetTagged("BlacklightInteractables");
			for _, interactableModule in pairs(blacklightInteractables) do
				local parentObj = interactableModule.Parent;
				local interactPos = parentObj:IsA("BasePart") and parentObj.Position or parentObj:IsA("Model") and parentObj:GetPivot() or nil;

				if interactPos == nil then continue end;
				local interactObj = require(interactableModule);
				
				local blacklights = CollectionService:GetTagged("BlacklightLights");
				for _, blacklightModel in pairs(blacklights) do
					local lightPos = blacklightModel:GetPivot().Position;
					local dist = math.round((interactPos-lightPos).Magnitude);
					
					if dist <= 16 then
						interactableModule:SetAttribute("LastBlackLightTick", tick());
						if interactableModule:GetAttribute("BlacklightCheckLoop") == nil then
							interactableModule:SetAttribute("BlacklightCheckLoop", true);
							
							if interactObj.InteractableRange ~= 5 then
								interactObj.InteractableRange = 5;
								interactObj:Sync();
							end
								
							local function toggleLabels(v)
								for _, textLabel in pairs(parentObj.BlacklightHint:GetChildren()) do
									if not textLabel:IsA("TextLabel") then continue end;

									textLabel.Text = interactObj.Label;
									TweenService:Create(textLabel, TweenInfo.new(0.33), {TextTransparency = v and 0 or 1;}):Play();
								end
							end
							toggleLabels(true);
							
							
							task.spawn(function()
								while true do
									task.wait(0.5);
									local lastBl = interactableModule:GetAttribute("LastBlackLightTick");
									if lastBl == nil or tick()-lastBl > 1 then
										break;
									end
								end
								
								if interactObj.InteractableRange ~= 0 then
									interactObj.InteractableRange = 0;
									interactObj:Sync();
								end
								toggleLabels(false);
								interactableModule:SetAttribute("BlacklightCheckLoop", nil);
							end)
						end
					end
				end
			end
			
		end
		
	end)
end)

CollectionService:GetInstanceRemovedSignal("BlacklightLights"):Connect(function()
	if #CollectionService:GetTagged("BlacklightLights") <= 0 then
		loopActive = false;
	end
end)


local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="GenericTool";

	Animations={
		Core={Id=4469912045;};
		Use={Id=13631843548;};
	};
	Audio={};
	Configurations={};
	Properties={};
};

function toolPackage.OnActionEvent(handler, packet)
	if packet.ActionIndex ~= 1 then return end;
	local isActive = packet.IsActive;

	local toolModel = handler.Prefabs[1];
	local lightPart = toolModel:FindFirstChild("lightStick");
	if lightPart then
		lightPart.Color = isActive and Color3.fromRGB(81, 32, 230) or Color3.fromRGB(69, 65, 95);
		lightPart.Material = isActive and Enum.Material.Neon or Enum.Material.SmoothPlastic;
		local lights = lightPart._lightPoint:GetChildren();
		for b=1, #lights do
			lights[b].Enabled = isActive;
		end
	end
	
	if isActive then
		CollectionService:AddTag(toolModel, "BlacklightLights");
	else
		CollectionService:RemoveTag(toolModel, "BlacklightLights");
	end;
	
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;