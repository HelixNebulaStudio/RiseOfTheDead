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
	local modWeatherLibrary = require(game.ReplicatedStorage.Library.WeatherLibrary);

	local modTables = require(game.ReplicatedStorage.Library.Util.Tables);

	local particlesFolder = game.ReplicatedStorage.Particles;
	--== Camera Handler
	local camera = workspace.CurrentCamera;

	--MARK: CameraParticles
	local cameraParticlePart = Instance.new("Part");
	cameraParticlePart.Name = "CameraParticlePart";
	cameraParticlePart.Anchored = true;
	cameraParticlePart.CanCollide = false;
	cameraParticlePart.CanQuery = false;
	cameraParticlePart.Size = Vector3.new(200, 0, 200);
	cameraParticlePart.Transparency = 1;
	cameraParticlePart.Parent = camera;
	
	RunService.Heartbeat:Connect(function()
		cameraParticlePart.CFrame = CFrame.new(camera.CFrame.X, camera.CFrame.Y+100, camera.CFrame.Z);
	end)

	local CameraClass = {};
	CameraClass.__index = CameraClass;
	CameraClass.PreviousLayerId = nil;

	-- Camera priority level
	-- 1 Character
	-- 2 Cutscene
	-- 3 Freecam

	CameraClass.RenderLayers = modLayeredVariable.new({});
	
	local RenderLayer = {
		FieldOfView = 70;
		CameraType = Enum.CameraType.Scriptable;
	};
	RenderLayer.__index = RenderLayer;
	
	function CameraClass:Bind(layerId, bindInput, priority, expire)
		setmetatable(bindInput, RenderLayer);
		CameraClass.RenderLayers:Set(layerId, bindInput, priority, expire);
	end
	
	function CameraClass:Unbind(layerId)
		CameraClass.RenderLayers:Remove(layerId);
	end
	
	local totalDelta = 0;
	RunService:BindToRenderStep("CameraClass", Enum.RenderPriority.Camera.Value-1, function(delta)
		local layer = CameraClass.RenderLayers:GetTable();
		local activeRenderLayer = layer.Value;
		
		if layer.Id ~= CameraClass.PreviousLayerId then
			CameraClass.PreviousLayerId = layer.Id;
			
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
	
	

	local function setFogAmbient()
		local _, _, v = game.Lighting.OutdoorAmbient:ToHSV();
		CameraClass.AtmosphereColor = Color3.fromHSV(129/255, 43/255, math.min(227/255, v));
	end
	setFogAmbient();
	game.Lighting:GetPropertyChangedSignal("OutdoorAmbient"):Connect(setFogAmbient)


	--== MARK: CameraColorCorrection
	local ccName = "ClientCameraColorCorrection";
	local colorCorrection: ColorCorrectionEffect = camera:FindFirstChild(ccName);
	if colorCorrection == nil then 
		colorCorrection = Instance.new("ColorCorrectionEffect");
		colorCorrection.Name = ccName;
		colorCorrection.Parent = camera;
	end;

	CameraClass.Brightness = modLayeredVariable.new(0);
	CameraClass.Contrast = modLayeredVariable.new(0);
	CameraClass.Saturation = modLayeredVariable.new(0.2);
	CameraClass.TintColor = modLayeredVariable.new(Color3.fromRGB(255, 255, 255)); --255, 238, 230
	

	--== MARK: CameraEffectSystem
	CameraClass.EffectsPriority = {
		Sky=1;
		Weather=3;
		Environment=6;
		Ability=9;
	}
	CameraClass.Effects = modLayeredVariable.new();

	local atmosName = "ClientCameraAtmosphere";
	local atmosphere: Atmosphere = Lighting:FindFirstChild(atmosName);
	if atmosphere == nil then 
		atmosphere = Instance.new("Atmosphere");
		atmosphere.Name = atmosName;
		atmosphere.Parent = script;
	end;
	
	local defaultAtmosphere: Atmosphere = game.Lighting:FindFirstChild("DefaultAtmosphere");
	if defaultAtmosphere then
		CameraClass.Effects:Set("sky", {
			Atmosphere = {
				Density=defaultAtmosphere.Density;
				Offset=defaultAtmosphere.Offset;
				Color=defaultAtmosphere.Color;
				Decay=defaultAtmosphere.Decay;
				Glare=defaultAtmosphere.Glare;
				Haze=defaultAtmosphere.Haze;
			};
		}, CameraClass.EffectsPriority.Sky);
		game.Debris:AddItem(defaultAtmosphere, 0);
	end

	local previousWeather = nil;
	local logDebounce = tick();
	RunService.RenderStepped:Connect(function(delta)
		colorCorrection.Brightness = CameraClass.Brightness:Get();
		colorCorrection.Contrast = CameraClass.Contrast:Get();
		colorCorrection.Saturation = CameraClass.Saturation:Get();
		colorCorrection.TintColor = CameraClass.TintColor:Get();

		local cameraEffects = CameraClass.Effects;

		-- MARK: WeatherEffects;
		local activeWeather = modWeatherService:GetActive();
		local weatherId = activeWeather and activeWeather.Id;

		local weatherLib = weatherId and modWeatherLibrary:Find(weatherId) or nil;
		if weatherLib and weatherLib.CameraEffect then
			local weatherEffect = cameraEffects:Find("weather");
			local weatherEffectValue = weatherEffect and weatherEffect.Value or {};
			
			if weatherEffectValue.Id ~= weatherId then
				previousWeather = modTables.DeepClone(weatherEffectValue);
				if previousWeather then previousWeather.EndTick = tick() end;
			end

			weatherEffectValue.Id = weatherId;
			for k, v in pairs(weatherLib.CameraEffect) do
				weatherEffectValue[k] = v;
			end

			if weatherEffect == nil then
				cameraEffects:Set("weather", weatherEffectValue, CameraClass.EffectsPriority.Weather);
			end

		else
			local weatherEffect = cameraEffects:Find("weather");
			if weatherEffect and weatherEffect.Value then
				previousWeather = modTables.DeepClone(weatherEffect and weatherEffect.Value);
				if previousWeather then previousWeather.EndTick = tick() end;
			end

			cameraEffects:Remove("weather");

		end

		-- MARK: CameraEffects
		local activeEffect = cameraEffects:Get();

		if tick()-logDebounce >= 5 then
			logDebounce = tick();
			Debugger:StudioWarn("ActiveEffect",activeEffect,"\nPreviousWeather",previousWeather);
		end

		if activeEffect and activeEffect.Atmosphere then
			local effectAtmosphere = activeEffect.Atmosphere;
			
			atmosphere.Density = effectAtmosphere.Density or atmosphere.Density;
			atmosphere.Offset = effectAtmosphere.Offset or atmosphere.Offset;

			atmosphere.Color = (effectAtmosphere.UseAmbientColor and CameraClass.AtmosphereColor) or effectAtmosphere.Color or atmosphere.Color;
			atmosphere.Decay = effectAtmosphere.Decay or atmosphere.Decay;
			atmosphere.Glare = effectAtmosphere.Glare or atmosphere.Glare;
			atmosphere.Haze = effectAtmosphere.Haze or atmosphere.Haze;

			atmosphere.Parent = Lighting;
		else
			atmosphere.Parent = script;

		end

		local fogColor = Lighting:GetAttribute("FogColor");
		local fogStart = Lighting:GetAttribute("FogStart");
		local fogEnd = Lighting:GetAttribute("FogEnd");
		if activeEffect and activeEffect.Fog then
			local effectFog = activeEffect.Fog;

			fogColor = effectFog.Color or fogColor;
			fogStart = effectFog.Start or fogStart;
			fogEnd = effectFog.End or fogEnd;
		end

		Lighting.FogColor = fogColor;
		Lighting.FogStart = fogStart;
		Lighting.FogEnd = fogEnd;

		if activeEffect and activeEffect.EnableScreenRain then
			local weatherParticleName = "Weather"..activeEffect.EnableScreenRain;
			if modScreenRain.RainParticle == nil or modScreenRain.RainParticle.Name ~= weatherParticleName then
				if modScreenRain.RainParticle then
					game.Debris:AddItem(modScreenRain.RainParticle, 0);
				end
				local new = particlesFolder:WaitForChild(weatherParticleName):Clone();
				new.Parent = cameraParticlePart;
				modScreenRain.RainParticle = new;
			end
			modScreenRain:Enable();
			
			if activeEffect.EnableScreenRain == "Rain" then
				modScreenRain.CanCreateDroplets = true;
			else
				modScreenRain.CanCreateDroplets = false;
			end
			
		else
			modScreenRain:Disable();

		end

		if modScreenRain.RainParticle then
			if modData:GetSetting("DisableWeatherParticles") ~= 1 then
				modScreenRain.RainParticle.Enabled = modScreenRain.RainVisible;
			else
				modScreenRain.RainParticle.Enabled = false;
			end
		end
	end)

	function CameraClass:SetFog(fogData: {FogColor: Color3?; FogStart: number?; FogEnd: number?}, id, priority, expireDuration)
		CameraClass.Effects:Set(id, {
			Fog=fogData;
		}, priority, expireDuration);
	end
	
	function CameraClass:SetAtmosphere(atmo: Atmosphere, id, priority, expireDuration)
		local atmosphereData = {
			Density=atmo.Density;
			Offset=atmo.Offset;
			Color=atmo.Color;
			Decay=atmo.Decay;
			Glare=atmo.Glare;
			Haze=atmo.Haze;
		};

		CameraClass.Effects:Set(id, {
			Atmosphere=atmosphereData;
		}, priority, expireDuration);
	end
	
	function CameraClass:ClearAtmosphere(id)
		CameraClass.Effects:Remove(id);
	end
	

	
	function CameraClass:RefreshGraphics()
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
	
	modData.CameraClass = CameraClass;
	
	--== MARK: Graphics Chunks
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
						Debugger:StudioWarn("Hide small instance (", smallObject,")");
					end

				end
			end
		end
		
	end);
	
	return CameraClass;
end