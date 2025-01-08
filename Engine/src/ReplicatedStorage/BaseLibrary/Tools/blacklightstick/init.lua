local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");
local TweenService = game:GetService("TweenService");

--==
local toolPackage = {
	Type="RoleplayTool";
	Animations={
		Core={Id=4469912045;};
		Use={Id=13631843548;};
	};
};


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
				
				--local closestDist, closestBlacklight = math.huge, nil;
				
				--local blacklights = CollectionService:GetTagged("BlacklightLights");
				--for _, blacklightModel in pairs(blacklights) do
				--	local lightPos = blacklightModel:GetPivot().Position;
				--	local dist = math.round((targetPos-lightPos).Magnitude);
					
				--	if dist < closestDist then
				--		closestDist = dist;
				--		closestBlacklight = blacklightModel;
				--	end
				--end
				
				--local isVisible = closestDist <= 16;
				
				--local interactObj = require(interactableModule);
				--if isVisible then
				--	if interactObj.InteractableRange ~= 5 then
				--		interactObj.InteractableRange = 5;
				--		interactObj:Sync();
				--	end
				--else
				--	if interactObj.InteractableRange ~= 0 then
				--		interactObj.InteractableRange = 0;
				--		interactObj:Sync();
				--	end
				--end
				
				--for _, textLabel in pairs(parentObj.BlacklightHint:GetChildren()) do
				--	if not textLabel:IsA("TextLabel") then continue end;
					
				--	textLabel.Text = interactObj.Label;
					
				--	local isShown: boolean = textLabel:GetAttribute("IsShown");
				--	if (isShown and isVisible) or (not isShown and not isVisible) then continue; end
				--	textLabel:SetAttribute("IsShown", isVisible);
					
				--	TweenService:Create(textLabel, TweenInfo.new(0.33), {TextTransparency = (isVisible and 0 or 1);}):Play();
				--end
			end
			
		end
		
	end)
end)

CollectionService:GetInstanceRemovedSignal("BlacklightLights"):Connect(function()
	if #CollectionService:GetTagged("BlacklightLights") <= 0 then
		loopActive = false;
	end
end)

function toolPackage.NewToolLib(handler)
	local Tool = {};
	Tool.IsActive = false;
	--Tool.UseViewmodel = false;

	function Tool:OnPrimaryFire(isActive)
		local toolModel;
		for a=1, #self.Prefabs do
			local prefab = self.Prefabs[a];
			toolModel = prefab;

			local lightPart = prefab:FindFirstChild("lightStick");
			if lightPart then
				lightPart.Color = isActive and Color3.fromRGB(81, 32, 230) or Color3.fromRGB(69, 65, 95);
				lightPart.Material = isActive and Enum.Material.Neon or Enum.Material.SmoothPlastic;
				local lights = lightPart._lightPoint:GetChildren();
				for b=1, #lights do
					lights[b].Enabled = isActive;
				end
			end
		end
		
		if isActive then
			CollectionService:AddTag(toolModel, "BlacklightLights");
		else
			CollectionService:RemoveTag(toolModel, "BlacklightLights");
		end;
		
	end
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return Tool;
end

return toolPackage;