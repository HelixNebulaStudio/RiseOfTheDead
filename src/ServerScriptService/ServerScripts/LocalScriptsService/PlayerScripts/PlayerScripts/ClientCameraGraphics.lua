local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
return function()
	local localplayer = game.Players.LocalPlayer;
	
	local RunService = game:GetService("RunService");
	local Lighting = game:GetService("Lighting");
	
	local modData = require(localplayer:WaitForChild("DataModule") :: ModuleScript);

	local modVoxelSpace = require(game.ReplicatedStorage.Library.VoxelSpace);
	local modTextureAnimations = require(game.ReplicatedStorage.Library.TextureAnimations);
	local modLayeredVariable = require(game.ReplicatedStorage.Library.LayeredVariable);
	local modWeatherService = require(game.ReplicatedStorage.Library.WeatherService);
	local modScreenRain = require(game.ReplicatedStorage.Library.ScreenRain);

	--== Camera Handler
	local camera = workspace.CurrentCamera;

	local CameraHandler = {};
	CameraHandler.__index = CameraHandler;
	CameraHandler.PreviousLayerId = nil;

	-- Camera priority level
	-- 1 Character
	-- 2 Cutscene
	-- 3 Freecam

	CameraHandler.RenderLayers = modLayeredVariable.new({});
	
	local RenderLayer = {
		FieldOfView = 70;
		CameraType = Enum.CameraType.Scriptable;
	};
	RenderLayer.__index = RenderLayer;
	
	function CameraHandler:Bind(layerId, bindInput, priority, expire)
		setmetatable(bindInput, RenderLayer);
		CameraHandler.RenderLayers:Set(layerId, bindInput, priority, expire);
	end
	
	function CameraHandler:Unbind(layerId)
		CameraHandler.RenderLayers:Remove(layerId);
	end
	
	local totalDelta = 0;
	RunService:BindToRenderStep("CameraHandler", Enum.RenderPriority.Camera.Value-1, function(delta)
		local layer = CameraHandler.RenderLayers:GetTable();
		local activeRenderLayer = layer.Value;
		
		if layer.Id ~= CameraHandler.PreviousLayerId then
			CameraHandler.PreviousLayerId = layer.Id;
			
			Debugger:Log("CameraLayer changed", layer.Id);
		end
		
		if camera.CameraType ~= activeRenderLayer.CameraType then
			camera.CameraType = activeRenderLayer.CameraType or Enum.CameraType.Scriptable;
		end
		
		if activeRenderLayer.RenderStepped then
			activeRenderLayer.RenderStepped(camera, delta, totalDelta);
			totalDelta = totalDelta + delta;
		end
	end)
	
	modData.CameraHandler = CameraHandler;
	
	--== CameraEffects
	local CameraEffects = {
		Atmosphere = nil;
		Fog = nil;
	};
	CameraEffects.__index = CameraEffects;

	modData.CameraEffects = CameraEffects;
	
	--== CameraColorCorrection
	local ccName = "ClientCameraColorCorrection";
	local colorCorrection: ColorCorrectionEffect = camera:FindFirstChild(ccName);
	if colorCorrection == nil then 
		colorCorrection = Instance.new("ColorCorrectionEffect");
		colorCorrection.Name = ccName;
		colorCorrection.Parent = camera;
	end;

	CameraEffects.Brightness = modLayeredVariable.new(0);
	CameraEffects.Contrast = modLayeredVariable.new(0);
	CameraEffects.Saturation = modLayeredVariable.new(0.2);
	CameraEffects.TintColor = modLayeredVariable.new(Color3.fromRGB(255, 255, 255)); --255, 238, 230
	--== MARK: CameraColorCorrection
	
	--== MARK: CameraFog
	local camFog = CameraEffects.Fog;
	if camFog == nil then
		CameraEffects.Fog = {};
		camFog = CameraEffects.Fog;
	end

	camFog.Enabled = modLayeredVariable.new(false);
	camFog.FogColor = modLayeredVariable.new(nil);
	camFog.FogStart = modLayeredVariable.new(nil);
	camFog.FogEnd = modLayeredVariable.new(nil);
	
	function CameraEffects:SetFog(fogData: {FogColor: Color3?; FogStart: number?; FogEnd: number?}, id, priority, expireDuration)
		camFog.Enabled:Set(id, true, priority, expireDuration);
		
		if fogData.FogColor then
			camFog.FogColor:Set(id, fogData.FogColor, priority, expireDuration);
		end
		if fogData.FogStart then
			camFog.FogStart:Set(id, fogData.FogStart, priority, expireDuration);
		end
		if fogData.FogEnd then
			camFog.FogEnd:Set(id, fogData.FogEnd, priority, expireDuration);
		end
	end
	--== CameraFog

	--== MARK: CameraAtmosphere
	local atmosName = "ClientCameraAtmosphere";
	local atmosphere: Atmosphere = Lighting:FindFirstChild(atmosName);
	if atmosphere == nil then 
		atmosphere = Instance.new("Atmosphere");
		atmosphere.Name = atmosName;
		atmosphere.Parent = script;
	end;
	
	local camAtmosphere = CameraEffects.Atmosphere;
	if camAtmosphere == nil then
		CameraEffects.Atmosphere = {};
		camAtmosphere = CameraEffects.Atmosphere;
	end
	
	local defaultAtmosphere: Atmosphere = game.Lighting:FindFirstChild("DefaultAtmosphere");
	
	camAtmosphere.Enabled = modLayeredVariable.new(defaultAtmosphere and true or false);
	camAtmosphere.Density = modLayeredVariable.new(defaultAtmosphere and defaultAtmosphere.Density or 0.395);
	camAtmosphere.Offset = modLayeredVariable.new(defaultAtmosphere and defaultAtmosphere.Offset or 0);

	camAtmosphere.Color = modLayeredVariable.new(defaultAtmosphere and defaultAtmosphere.Color or Color3.fromRGB(199, 170, 107));
	camAtmosphere.Decay = modLayeredVariable.new(defaultAtmosphere and defaultAtmosphere.Decay or Color3.fromRGB(92, 60, 13));
	camAtmosphere.Glare = modLayeredVariable.new(defaultAtmosphere and defaultAtmosphere.Glare or 0);
	camAtmosphere.Haze = modLayeredVariable.new(defaultAtmosphere and defaultAtmosphere.Haze or 0);
	
	function CameraEffects:SetAtmosphere(atmo: Atmosphere, id, priority, expireDuration)
		camAtmosphere.Enabled:Set(id, true, priority, expireDuration);
		
		camAtmosphere.Density:Set(id, atmo.Density, priority, expireDuration);
		camAtmosphere.Offset:Set(id, atmo.Offset, priority, expireDuration);

		camAtmosphere.Color:Set(id, atmo.Color, priority, expireDuration);
		camAtmosphere.Decay:Set(id, atmo.Decay, priority, expireDuration);
		camAtmosphere.Glare:Set(id, atmo.Glare, priority, expireDuration);
		camAtmosphere.Haze:Set(id, atmo.Haze, priority, expireDuration);
	end
	
	function CameraEffects:ClearAtmosphere(id)
		camAtmosphere.Enabled:Remove(id);

		camAtmosphere.Density:Remove(id);
		camAtmosphere.Offset:Remove(id);

		camAtmosphere.Color:Remove(id);
		camAtmosphere.Decay:Remove(id);
		camAtmosphere.Glare:Remove(id);
		camAtmosphere.Haze:Remove(id);
	end
	
	local serverAtmosphere;
	game.ReplicatedStorage.ChildAdded:Connect(function(child)
		if child:IsA("Atmosphere") and child.Name == "ServerAtmosphere" then
			serverAtmosphere = child;
		else
			task.wait();
			serverAtmosphere = game.ReplicatedStorage:FindFirstChild("ServerAtmosphere");
		end
	end)
	game.ReplicatedStorage.ChildRemoved:Connect(function(child)
		if child == serverAtmosphere then
			serverAtmosphere = nil;
		end
	end)
	
	--==

	local skipRender = tick();
	RunService.RenderStepped:Connect(function(delta)
		local renderTick = tick();
		if skipRender > renderTick then
			return;
		end
		if modData:IsMobile() then
			skipRender = renderTick + (delta*2);
		end

		colorCorrection.Brightness = CameraEffects.Brightness:Get();
		colorCorrection.Contrast = CameraEffects.Contrast:Get();
		colorCorrection.Saturation = CameraEffects.Saturation:Get();
		colorCorrection.TintColor = CameraEffects.TintColor:Get();
		
		local camFogEnabled = camFog.Enabled:Get();
		if camFogEnabled then
			Lighting.FogColor = camFog.FogColor:Get() or Lighting:GetAttribute("FogColor");
			Lighting.FogStart = camFog.FogStart:Get() or Lighting:GetAttribute("FogStart");
			Lighting.FogEnd = camFog.FogEnd:Get() or Lighting:GetAttribute("FogEnd");

		else
			Lighting.FogColor = Lighting:GetAttribute("FogColor");
			Lighting.FogStart = Lighting:GetAttribute("FogStart");
			Lighting.FogEnd = Lighting:GetAttribute("FogEnd");

		end

		local atmosphereEnabledTable = camAtmosphere.Enabled:GetTable();
		local atmosphereEnabled = atmosphereEnabledTable.Value;
		
		if serverAtmosphere and serverAtmosphere.Parent == game.ReplicatedStorage and atmosphereEnabledTable.Order <= 1 then
			atmosphere.Density = serverAtmosphere.Density;
			atmosphere.Offset = serverAtmosphere.Offset;

			atmosphere.Color = serverAtmosphere.Color;
			atmosphere.Decay = serverAtmosphere.Decay;
			atmosphere.Glare = serverAtmosphere.Glare;
			atmosphere.Haze = serverAtmosphere.Haze;
			atmosphereEnabled = true;
			
		elseif atmosphereEnabled == true then
			atmosphere.Density = camAtmosphere.Density:Get();
			atmosphere.Offset = camAtmosphere.Offset:Get();

			atmosphere.Color = camAtmosphere.Color:Get();
			atmosphere.Decay = camAtmosphere.Decay:Get();
			atmosphere.Glare = camAtmosphere.Glare:Get();
			atmosphere.Haze = camAtmosphere.Haze:Get();
			
		end
		
		if atmosphere.Parent == nil then
			atmosphere = Instance.new("Atmosphere");
			atmosphere.Parent = script;
			atmosphere.Name = atmosName;
		end
		
		if atmosphereEnabled == true and atmosphere.Parent ~= Lighting then
			atmosphere.Parent = Lighting;
			
		elseif atmosphereEnabled == false and atmosphere.Parent ~= script then
			atmosphere.Parent = script;
			
		end
	end)
	
	function CameraEffects:RefreshGraphics()
		if game.Lighting:FindFirstChild("SunRays") then
			game.Lighting.SunRays.Enabled = modData:GetSetting("FilterSunRays") ~= 1;
		end

		if modData:GetSetting("GlobalShadows") == nil then
			game.Lighting.GlobalShadows = true;
		else
			game.Lighting.GlobalShadows = false;
		end

		if modData:GetSetting("LessDetail") == 1 then
			task.spawn(function()
				if workspace:FindFirstChild("Environment") and workspace.Environment:FindFirstChild("ExtraDetail") then
					for _, obj in pairs(workspace.Environment.ExtraDetail:GetChildren()) do
						obj:Destroy();
						RunService.Heartbeat:Wait();
					end
				end
			end)
		end
		
		modTextureAnimations.Update();
	end
	
	local graphicsChunks = modVoxelSpace.new();
	
	local overlapParam = OverlapParams.new();
	overlapParam.FilterDescendantsInstances = {workspace.Environment; workspace.Interactables};
	overlapParam.FilterType = Enum.RaycastFilterType.Include;
	overlapParam.MaxParts = 128;
	
	local voxelSize = 64;
	
	local function handleInteractable(basePart: BasePart)
		local rootBase = basePart;
		local interactModule = rootBase:FindFirstChild("Interactable");
		while interactModule == nil do
			rootBase = rootBase.Parent;
			interactModule = rootBase:FindFirstChild("Interactable");
			if workspace.Interactables:IsAncestorOf(rootBase) == false then
				return;
			end
			if interactModule then break; end;
		end
		if interactModule == nil or not interactModule:IsA("ModuleScript") then return end;
		local modCharacter = modData:GetModCharacter();
		if modCharacter == nil then return end;

		local interactData = require(interactModule);
		if interactData and interactData.Trigger then
			
			local dataMeta = getmetatable(interactData);
			dataMeta.CharacterModule = modCharacter;
			dataMeta.Humanoid = modCharacter.Humanoid;
			dataMeta.RootPart = modCharacter.RootPart;

			interactData.Script = interactModule;
			if rootBase:IsA("Model") then
				interactData.Object = rootBase.PrimaryPart;
			else
				interactData.Object = rootBase;
			end
			
			if interactData.FirstTrigger == nil then
				interactData.FirstTrigger = tick();
				interactData:Trigger();
			end
		end
	end

	local lastScan = tick();
	RunService.Heartbeat:Connect(function()
		if tick()-lastScan < 5 then return end;
		lastScan = tick();
		
		local hitList = workspace:GetPartBoundsInRadius(camera.CFrame.Position, 64, overlapParam);
		
		for a=1, #hitList do
			local object = hitList[a];
			
			if workspace.Interactables:IsAncestorOf(object) and localplayer.Character then
				task.spawn(function()
					handleInteractable(object);
				end)
				continue;
			end
			
			local isSmallObj = object.Size.X <= 5 and object.Size.Y <= 5 and object.Size.Z <= 5;
			if modData:GetSetting("DisableSmallShadows") == 1 and isSmallObj then
				object.CastShadow = false;
			end
			if modData:GetSetting("ObjMats") == 1 then
				object.Material = Enum.Material.SmoothPlastic;
			end
			
			if modData:GetSetting("HideFarSmallObjects") ~= 1 or object.Anchored ~= true then continue end;
			
			local isDynamicPlatform = false;
			local parCheck = object.Parent;
			while workspace:IsAncestorOf(parCheck) do
				if parCheck:GetAttribute("DynamicPlatform") == true then
					isDynamicPlatform = true;
					break;
				else
					parCheck = parCheck.Parent;
				end
			end
			if isDynamicPlatform then continue end;
			
			--== Small Model;
			local smallObject = nil;
			
			for a=1, 5 do
				local parentModel = smallObject or object.Parent;
				if parentModel:IsA("Model") then
					local parentSize = parentModel:GetExtentsSize();
					if parentSize.X <= 5 and parentSize.Y <= 5 and parentSize.Z <= 5 then
						smallObject = parentModel;
					else
						break;
					end
				else
					break;
				end
				if smallObject == nil then
					break;
				end
			end
			
			
			local objectPos = smallObject and smallObject:GetPivot().Position or object.Position;
			if smallObject == nil then
				smallObject = object;

				if object.Size.X > 5 or object.Size.Y > 5 or object.Size.Z > 5 then
					continue
				end
			end
			
			local voxelPos = modVoxelSpace:GetVoxelPosition(objectPos/voxelSize);
			local voxelPoint = graphicsChunks:GetOrDefault(voxelPos, {Groups={};});

			local chunkObject = voxelPoint.Value;
			local _groupsList = chunkObject.Groups;
			
			if chunkObject.Groups[smallObject] == nil then
				chunkObject.Groups[smallObject] = {};
				
				smallObject.Destroying:Connect(function()
					chunkObject.Groups[smallObject] = nil;
				end)
			end
			local chunkObjGroup = chunkObject.Groups[smallObject];
			chunkObjGroup.Parent = smallObject.Parent;
		end
	end)
	
	
	local lastUpdateChunks = tick();
	RunService.Heartbeat:Connect(function()
		if tick()-lastUpdateChunks < 1 then return end;
		lastUpdateChunks = tick();

		if modData:GetSetting("HideFarSmallObjects") ~= 1 then return end;

		local camVoxelPos = modVoxelSpace:GetVoxelPosition(camera.CFrame.Position/voxelSize);
		
		local regionPoints = graphicsChunks:GetVoxelPointsInRadius(camVoxelPos, 3);
		for a=1, #regionPoints do
			local voxelPoint = regionPoints[a];
			
			local chunkObject = voxelPoint and voxelPoint.Value or nil;
			if chunkObject then
				local voxelCost = graphicsChunks:GetCost(voxelPoint, {Position=camVoxelPos;})
				local inRange = voxelCost <= 15;
				
				if inRange then
					-- Show chunk;
					for smallObject, prefabData in pairs(chunkObject.Groups) do
						if prefabData == nil then continue end;

						if RunService:IsStudio() then
							smallObject.Parent = prefabData.Parent;

						else
							pcall(function() 
								smallObject.Parent = prefabData.Parent;
							end)

						end
					end

				else
					for smallObject, prefabData in pairs(chunkObject.Groups) do
						if prefabData == nil then continue end;

						smallObject.Parent = nil;
						if RunService:IsStudio() then
							Debugger:Warn("Hide instance (", smallObject,")");
						end
					end

				end
			end
		end
		
	end);
	
	return CameraEffects;
end