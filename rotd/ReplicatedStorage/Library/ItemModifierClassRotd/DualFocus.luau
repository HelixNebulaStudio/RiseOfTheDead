local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local localPlayer = game.Players.LocalPlayer;

local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);


local modifierPackage = {
	Name = "Dual Focus";
	
	Tags = {};
	Binds = {};
};
--==

if RunService:IsClient() then

	function modifierPackage.Binds.WeaponRenderStepped(modifier: ItemModifierInstance, ...)
		if modifier.Enabled == false then return end;

		local toolHandler: ToolHandlerInstance, toolStatusHud: anydict = ...;

		local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
		local camera = workspace.CurrentCamera;

		local equipmentClass: EquipmentClass? = modifier.EquipmentClass;
		assert(equipmentClass, `Missing equipment class: {modifier}`);

		local configurations = equipmentClass.Configurations;
		local properties = equipmentClass.Properties;

		local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);

		local modCharacter = modData:GetModCharacter();
		local mouseProperties = modCharacter.MouseProperties;
		local characterProperties = modCharacter.CharacterProperties;

		local character = playerClass.Character;
		local rootPart = playerClass.RootPart;

		--MARK: Lock
		if characterProperties.IsFocused then
			local entitiesList = {};

			local hvpSize = camera.ViewportSize/2;
			local hvpMag = hvpSize.Magnitude;
			local rpPos = rootPart.Position;
			for _, model in ipairs( CollectionService:GetTagged("TargetableEntities") ) do
				local humanoid = model:FindFirstChildWhichIsA("Humanoid");
				if humanoid == nil or humanoid.Health <= 0 then continue end;
				if model:GetAttribute("Detectable") == false then continue end;

				local tarPos = model:GetPivot().Position;

				local dist = modVector.DistanceSqrd(tarPos, rpPos);
				if dist >= 4096 then continue end; -- 64units;

				local screenPoint, onScreen = camera:WorldToViewportPoint(tarPos);
				if not onScreen then continue end;

				local sPointMag = (Vector2.new(screenPoint.X, screenPoint.Y) - hvpSize).Magnitude/hvpMag;

				local dualFocusRayParams = RaycastParams.new();
				dualFocusRayParams.IncludeInstances = {workspace.Environment; workspace.Terrain; model};

				local camFocus = mouseProperties.Focus;
				local camDir = (tarPos - camFocus.Position).Unit;
				local rayResult = workspace:Raycast(camFocus.Position, camDir * 64, dualFocusRayParams);
				
				if rayResult == nil then continue end;
				if not model:IsAncestorOf(rayResult.Instance) then continue end;

				table.insert(entitiesList, {
					Model = model;
					Dist = (dist) * (sPointMag^2);
				});
			end

			table.sort(entitiesList, function(a, b)
				return a.Dist < b.Dist;
			end)

			local upperTorso = character:FindFirstChild("UpperTorso");
			local uTLookVec = upperTorso.CFrame.LookVector;

			local chosenLTarget = entitiesList[1] and entitiesList[1].Model;
			local toolModelL = toolHandler.Prefabs[2];

			if toolModelL and chosenLTarget then
				local oCf = upperTorso.CFrame * CFrame.new(-1.2, 0.702, 0.061);
				local tCf = chosenLTarget:GetPivot();
				local dir = (tCf.Position - oCf.Position).Unit;

				local wLShoulderCf = CFrame.lookAlong(oCf.Position, dir);
				properties.CustomLeftShoulderC0 = upperTorso.CFrame:ToObjectSpace(wLShoulderCf);

				--Debugger.Expire(Debugger:Ray(Ray.new(oCf.Position, dir * 3)), 0.1);

			else
				properties.CustomLeftShoulderC0 = nil;
				chosenLTarget = nil;
			end

			local chosenRTarget = entitiesList[2] and entitiesList[2].Model;
			if chosenRTarget == nil then chosenRTarget = chosenLTarget end;
			local toolModelR = toolHandler.Prefabs[1];

			if toolModelR and chosenRTarget then
				local oCf = upperTorso.CFrame * CFrame.new(1.2, 0.702, 0.061);
				local tCf = chosenRTarget:GetPivot();
				local dir = (tCf.Position - oCf.Position).Unit;

				local dirDot = dir:Dot(uTLookVec);
				if dirDot > 0 then
					local wRShoulderCf = CFrame.lookAlong(oCf.Position, dir);
					properties.CustomRightShoulderC0 = upperTorso.CFrame:ToObjectSpace(wRShoulderCf);
				else
					properties.CustomRightShoulderC0 = nil;
					chosenRTarget = nil;
				end
				--Debugger.Expire(Debugger:Ray(Ray.new(oCf.Position, dir * 3)), 0.1);

			else
				properties.CustomRightShoulderC0 = nil;
				chosenRTarget = nil;
			end

			properties.DualSightTargetL = chosenLTarget;
			properties.DualSightTargetR = chosenRTarget;

			local lookTarg = chosenLTarget or chosenRTarget;
			if lookTarg then
				local oCf = upperTorso.CFrame * CFrame.new(-0, 1, 0.061);
				local tCf = lookTarg:GetPivot();
				local dir = (tCf.Position - oCf.Position).Unit;

				local dirDot = dir:Dot(uTLookVec);
				if dirDot > 0.2 then
					local wNeckCf = CFrame.lookAlong(oCf.Position, dir);
					properties.CustomNeckC0 = upperTorso.CFrame:ToObjectSpace(wNeckCf);
				else
					properties.CustomNeckC0 = nil;
				end
			else
				properties.CustomNeckC0 = nil;
			end

		else
			properties.CustomNeckC0 = nil;
			properties.CustomLeftShoulderC0 = nil;
			properties.CustomRightShoulderC0 = nil;
			properties.DualSightTargetL = nil;
			properties.DualSightTargetR = nil;
			
		end


		--MARK: UseCustomCrosshair
		if characterProperties.IsFocused then
			local window: InterfaceWindow = modClientGuis.getWindow("WeaponWindow");
			local windowBinds = window and window.Binds;

			if windowBinds then
				local crosshairTemplate = windowBinds.CrosshairFrame;
				crosshairTemplate.Visible = false;

				if windowBinds.CrosshairFrameL == nil then
					local chFrameL = crosshairTemplate:Clone();
					chFrameL.Parent = crosshairTemplate.Parent;
					windowBinds.CrosshairFrameL = chFrameL;

					chFrameL:WaitForChild("ReloadIcon").Visible = false;
					chFrameL:WaitForChild("FocusBonusLabel").Visible = false;
					chFrameL:WaitForChild("CrosshairN").Position = UDim2.new(0.5, 0, 0.5, -5);
					chFrameL:WaitForChild("CrosshairS").Position = UDim2.new(0.5, 0, 0.5, 5);
					chFrameL:WaitForChild("CrosshairW").Position = UDim2.new(0.5, -5, 0.5, 0);
					chFrameL:WaitForChild("CrosshairE").Position = UDim2.new(0.5, 5, 0.5, 0);
				end
				if windowBinds.CrosshairFrameL then
					windowBinds.CrosshairFrameL.Visible = true;

					if properties.DualSightTargetL then
						local tModel = properties.DualSightTargetL;
						local rtPos = tModel:GetPivot().Position;
						local headPos = tModel:FindFirstChild("Head") and tModel.Head:IsA("BasePart") and tModel.Head.Position or rtPos;
						local tPos = (rtPos + headPos)/2;

						local screenPoint, onScreen = camera:WorldToViewportPoint(tPos);
						windowBinds.CrosshairFrameL.Position = UDim2.new(0, screenPoint.X + mouseProperties.XAngOffset, 0, screenPoint.Y + mouseProperties.YAngOffset);
					
					else
						windowBinds.CrosshairFrameL.Position = UDim2.new(0.5, 0, 0.5, 0);
					end
				end

				if windowBinds.CrosshairFrameR == nil then
					local chFrameR = crosshairTemplate:Clone();
					chFrameR.Parent = crosshairTemplate.Parent;
					windowBinds.CrosshairFrameR = chFrameR;

					chFrameR:WaitForChild("ReloadIcon").Visible = false;
					chFrameR:WaitForChild("FocusBonusLabel").Visible = false;
					chFrameR:WaitForChild("CrosshairN").Position = UDim2.new(0.5, 0, 0.5, -5);
					chFrameR:WaitForChild("CrosshairS").Position = UDim2.new(0.5, 0, 0.5, 5);
					chFrameR:WaitForChild("CrosshairW").Position = UDim2.new(0.5, -5, 0.5, 0);
					chFrameR:WaitForChild("CrosshairE").Position = UDim2.new(0.5, 5, 0.5, 0);
				end
				if windowBinds.CrosshairFrameR then
					windowBinds.CrosshairFrameR.Visible = true;

					if properties.DualSightTargetR then
						
						local tModel = properties.DualSightTargetR;
						local rtPos = tModel:GetPivot().Position;
						local headPos = tModel:FindFirstChild("Head") and tModel.Head:IsA("BasePart") and tModel.Head.Position or rtPos;
						local tPos = (rtPos + headPos)/2;

						local screenPoint, onScreen = camera:WorldToViewportPoint(tPos);
						windowBinds.CrosshairFrameR.Position = UDim2.new(0, screenPoint.X + mouseProperties.XAngOffset, 0, screenPoint.Y + mouseProperties.YAngOffset);
					else
						windowBinds.CrosshairFrameR.Position = UDim2.new(0.5, 0, 0.5, 0);
					end
				end
			end

			properties.UseCustomCrosshair = true;

		else
			properties.UseCustomCrosshair = false;

		end

	end

end

return modifierPackage;