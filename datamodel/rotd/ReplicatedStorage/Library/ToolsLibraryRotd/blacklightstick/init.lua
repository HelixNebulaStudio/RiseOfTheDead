local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");
local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");

local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
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

function toolPackage.ActionEvent(handler, packet)
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


function toolPackage.init()
	if RunService:IsClient() then return end;
	
	task.spawn(function()
		repeat task.wait(1) until shared.EngineIgnited == true;
		local templateBlackLightSurfaceGui = script:WaitForChild("BlacklightHint");

		local blacklightHintLabel = {
			"*Hmm.. There seems to be a message here..*";
			"*You notice a slight color difference here..*";
			"*You notice a faint glow here..*";
		};
		local function loadBlacklightInteractable(interactConfig: Configuration)
			if not workspace:IsAncestorOf(interactConfig) then return end;
			if interactConfig:GetAttribute("Blacklight") ~= true then return end;

			local interactable: InteractableInstance = modInteractables.getOrNew(interactConfig);
			if interactable == nil then return end;

			if interactConfig:HasTag("BlacklightInteractables") then return end;
			interactConfig:AddTag("BlacklightInteractables");

			local faceEnum = Enum.NormalId.Right;
			if interactConfig:GetAttribute("BlacklightFace") then
				faceEnum = Enum.NormalId:FromName(interactConfig:GetAttribute("BlacklightFace") :: string);
			end

			local interactPart = interactable.Part;

			local newBlacklightGui = interactPart:FindFirstChild(templateBlackLightSurfaceGui.Name);
			if newBlacklightGui == nil then
				newBlacklightGui = templateBlackLightSurfaceGui:Clone();
			end
			newBlacklightGui.Parent = interactPart;
			newBlacklightGui.Adornee = interactPart;
			newBlacklightGui.Face = faceEnum;

			local textLabel = newBlacklightGui:WaitForChild("TextLabel");
			textLabel.Text = interactable.Values.BlacklightText or "";
			textLabel.TextTransparency = 1;

			interactable.InteractableRange = 5;
			interactable.Values.BlacklightTextVisible = false;
			interactConfig:SetAttribute("Text", blacklightHintLabel[math.random(1, #blacklightHintLabel)]);

			interactable.Values.OnChanged:Connect(function(k, nv, ov)
				if k == "BlacklightTextVisible" then
					if nv == true then
						interactConfig:SetAttribute("Text", interactable.Values.BlacklightText or "");
						TweenService:Create(textLabel, TweenInfo.new(0.33), {
							TextTransparency = 0;
						}):Play();
					else
						interactConfig:SetAttribute("Text", blacklightHintLabel[math.random(1, #blacklightHintLabel)]);
						TweenService:Create(textLabel, TweenInfo.new(0.66), {
							TextTransparency = 1;
						}):Play();
					end
				end
			end)

		end

		CollectionService:GetInstanceAddedSignal("Interactable"):Connect(loadBlacklightInteractable);

		local loopActive = false;
		CollectionService:GetInstanceAddedSignal("BlacklightLights"):Connect(function()
			if loopActive then return end;
			loopActive = true;
			
			task.spawn(function()
				while loopActive do
					task.wait(0.5);
					
					local blacklightInteractables = CollectionService:GetTagged("BlacklightInteractables");
					for _, interactConfig: Configuration in pairs(blacklightInteractables) do
						local interactable: InteractableInstance = modInteractables.getOrNew(interactConfig);
						if interactable == nil then continue end;

						local interactPart = interactable.Part;
						local interactPoint = interactable.Point;

						local blacklights = CollectionService:GetTagged("BlacklightLights");
						for _, blacklightModel in pairs(blacklights) do
							local lightPos = blacklightModel:GetPivot().Position;
							local dist = math.round((interactPoint-lightPos).Magnitude);
							
							if dist > 16 then continue end;

							interactConfig:SetAttribute("LastBlackLightTick", tick());
							if interactConfig:GetAttribute("BlacklightCheckLoop") then continue end;
							interactConfig:SetAttribute("BlacklightCheckLoop", true);
								
							interactable.Values.BlacklightTextVisible = true;
							
							task.spawn(function()
								while true do
									task.wait(0.5);
									local lastBl = interactConfig:GetAttribute("LastBlackLightTick");
									if lastBl == nil or tick()-lastBl > 1 then
										break;
									end
								end
								
								interactable.Values.BlacklightTextVisible = false;
								interactConfig:SetAttribute("BlacklightCheckLoop", nil);
							end)

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

		for _, obj in pairs(workspace.Interactables:GetDescendants()) do
			if obj.Name ~= "Interactable" or not obj:IsA("Configuration") then continue end; 
			loadBlacklightInteractable(obj);
		end
	end)
end


return toolPackage;