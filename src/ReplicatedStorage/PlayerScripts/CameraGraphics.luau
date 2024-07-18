local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local Lighting = game:GetService("Lighting");
local CollectionService = game:GetService("CollectionService");
local TweenService = game:GetService("TweenService");

local camera = workspace.CurrentCamera;
local localplayer = game.Players.LocalPlayer;
local modData = require(localplayer:WaitForChild("DataModule") :: ModuleScript);

local modVoxelSpace = require(game.ReplicatedStorage.Library.VoxelSpace);
local modTextureAnimations = require(game.ReplicatedStorage.Library.TextureAnimations);
local modLayeredVariable = require(game.ReplicatedStorage.Library.LayeredVariable);
local modWeatherService = require(game.ReplicatedStorage.Library.WeatherService);
local modWeatherLibrary = require(game.ReplicatedStorage.Library.WeatherLibrary);
local modScreenRain = require(game.ReplicatedStorage.Library.ScreenRain);

local modMath = require(game.ReplicatedStorage.Library.Util.Math)
local modRaycastUtil = require(game.ReplicatedStorage.Library.Util.RaycastUtil);
local modTables = require(game.ReplicatedStorage.Library.Util.Tables);

local particlesFolder = game.ReplicatedStorage:WaitForChild("Particles");

local CameraClass = {};
CameraClass.__index = CameraClass;
CameraClass.__init = true;
--==

function CameraClass:Init()
	if CameraClass.__init == nil then return end;
	CameraClass.__init = nil;
	
	--== Camera Handler
	--MARK: CameraParticles
	local cameraParticlePart = Instance.new("Part");
	cameraParticlePart.Name = "CameraParticlePart";
	cameraParticlePart.Anchored = true;
	cameraParticlePart.CanCollide = false;
	cameraParticlePart.CanQuery = false;
	cameraParticlePart.Size = Vector3.new(100, 0, 100);
	cameraParticlePart.Transparency = 1;
	cameraParticlePart.Parent = camera;
	
	RunService.Heartbeat:Connect(function()
		local pos = camera.CFrame.Position + camera.CFrame.LookVector * 40;
		cameraParticlePart.CFrame = CFrame.new(pos.X, pos.Y+30, pos.Z);
	end)

	CameraClass.PreviousLayerId = nil;
	CameraClass.IsIndoors = false;

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
			
			Debugger:StudioLog("CameraLayer changed", layer.Id);
		end
		
		if camera.CameraType ~= activeRenderLayer.CameraType then
			camera.CameraType = activeRenderLayer.CameraType or Enum.CameraType.Scriptable;
		end
		
		if activeRenderLayer.RenderStepped then
			activeRenderLayer.RenderStepped(camera, delta, totalDelta);
			totalDelta = totalDelta + delta;
		end
	end)
	
	--==

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
	
	--== MARK: Sky
	local sky: Sky = Lighting:FindFirstChildWhichIsA("Sky");
	
	--== MARK: CameraSunRays
	local srName = "ClientCameraSunRays";
	local sunRays: SunRaysEffect = Lighting:FindFirstChild(srName);
	if sunRays == nil then
		sunRays = Instance.new("SunRaysEffect");
		sunRays.Name = srName;
		sunRays.Parent = Lighting;
	end


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
		atmosphere.Density = 0;
		atmosphere.Offset = 0;
		atmosphere.Haze = 0;
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

	local screenParticles = {};
	CameraClass.ScreenParticles = screenParticles;

	local previousWeather = nil;
	local ceilingCheck = tick();
	RunService.RenderStepped:Connect(function(delta)
		if sky == nil then
			sky = Lighting:FindFirstChildWhichIsA("Sky");
		end
		
		local rootPart = localplayer and localplayer.Character and localplayer.Character.PrimaryPart;

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

		local tweenRatio = previousWeather and previousWeather.EndTick and math.clamp((tick()-previousWeather.EndTick)/(weatherLib and weatherLib.FadeTime or 0.1), 0, 1) or 1;

		local densityDecay = 0.2;
		-- MARK: CameraEffects
		local activeEffect = cameraEffects:Get();

		if activeEffect and activeEffect.Atmosphere then
			local effectAtmosphere = activeEffect.Atmosphere;
			local previousAtmosphere = previousWeather and previousWeather.Atmosphere or {};

			local density = (CameraClass.IsIndoors and effectAtmosphere.DensityIndoors) or effectAtmosphere.Density or atmosphere.Density;
			atmosphere.Density = modMath.DeltaLerp(atmosphere.Density, density, densityDecay, delta);

			local offset = effectAtmosphere.Offset or atmosphere.Offset;
			atmosphere.Offset = modMath.DeltaLerp(atmosphere.Offset, offset, densityDecay, delta);

			local color = (effectAtmosphere.UseAmbientColor and CameraClass.AtmosphereColor) or effectAtmosphere.Color or atmosphere.Color;
			atmosphere.Color = (previousAtmosphere.Color or color):Lerp(color, tweenRatio);

			local decay = effectAtmosphere.Decay or atmosphere.Decay;
			atmosphere.Decay = (previousAtmosphere.Decay or decay):Lerp(decay, tweenRatio);

			local glaze = effectAtmosphere.Glare or atmosphere.Glare;
			atmosphere.Glare = modMath.Lerp(previousAtmosphere.Glare or glaze, glaze, tweenRatio);

			local haze = effectAtmosphere.Haze or atmosphere.Haze;
			atmosphere.Haze = modMath.Lerp(previousAtmosphere.Haze or 0, haze, tweenRatio);

			atmosphere.Parent = Lighting;
			
		elseif activeEffect and activeEffect.Fog then
			atmosphere.Parent = script;
			
		else
			if atmosphere.Density > 0.1 then
				atmosphere.Parent = Lighting;
				atmosphere.Density = modMath.DeltaLerp(atmosphere.Density, 0, densityDecay, delta);
				atmosphere.Offset = modMath.DeltaLerp(atmosphere.Offset, 0, densityDecay, delta);
				atmosphere.Glare = modMath.DeltaLerp(atmosphere.Glare, 0, densityDecay, delta);
				atmosphere.Haze = modMath.DeltaLerp(atmosphere.Haze, 0, densityDecay+0.5, delta);

			else
				atmosphere.Parent = script;

			end
			
		end


		local noAtmosphere = atmosphere.Parent == script;
		local scale = modMath.MapNum(atmosphere.Haze, 1, 2.5, 1, 0);
		sky.SunAngularSize = modMath.Lerp(sky.SunAngularSize, math.clamp(scale, 0, 1) * (noAtmosphere and 32 or 22), 0.1);
		sky.MoonAngularSize = modMath.Lerp(sky.MoonAngularSize, math.clamp(scale, 0, 1) * 11, 0.1);

		
		local fogColor = Lighting:GetAttribute("FogColor");
		local fogStart = Lighting:GetAttribute("FogStart");
		local fogEnd = Lighting:GetAttribute("FogEnd");
		if activeEffect and activeEffect.Fog then
			local effectFog = activeEffect.Fog;

			fogColor = effectFog.Color or fogColor;
			fogStart = effectFog.Start or fogStart;
			fogEnd = effectFog.End or fogEnd;
		end

		Lighting.FogColor = Lighting.FogColor:Lerp(fogColor, 0.1);
		Lighting.FogStart = modMath.DeltaLerp(Lighting.FogStart, fogStart, 25, delta);
		Lighting.FogEnd = modMath.DeltaLerp(Lighting.FogEnd, fogEnd, 25, delta);


		local sunRayIntensity = Lighting:GetAttribute("SunRaysIntensity");
		sunRays.Intensity = modMath.Lerp(sunRayIntensity or 0.1, activeEffect and activeEffect.SunRaysIntensity or sunRayIntensity, tweenRatio);

		local isIndoors = CameraClass.IsIndoors;

		if tick()-ceilingCheck > 0.2 and camera then
			ceilingCheck = tick();
			isIndoors = modRaycastUtil.GetCeiling(camera.CFrame.Position, 256) ~= nil;
		end
		
		local modCharacter = localplayer.Character and modData:GetModCharacter() or nil;
		if modCharacter and modCharacter.CharacterProperties and modCharacter.CharacterProperties.CamUnderwater then
			isIndoors = true;
		end
		CameraClass.IsIndoors = isIndoors;

		local weatherParticlesEnabled = modData:GetSetting("DisableWeatherParticles") ~= 1;
		local existParticle = {};
		if activeEffect and activeEffect.ScreenParticles and weatherParticlesEnabled then
			for a=1, #activeEffect.ScreenParticles do
				local particleData = activeEffect.ScreenParticles[a];
				
				if screenParticles[particleData.Id] == nil then
					local new: ParticleEmitter = particlesFolder:FindFirstChild(particleData.Id):Clone();
					local defaultRate = new.Rate;
					new.Rate = 0;
					new.Parent = cameraParticlePart;
					screenParticles[particleData.Id] = new;

					TweenService:Create(new, TweenInfo.new(5), {Rate = defaultRate}):Play();

				else
					local particle = screenParticles[particleData.Id];
					
					if particle:GetAttribute("OutdoorsOnly") then
						particle.Enabled = not isIndoors;
					end

				end

				existParticle[particleData.Id] = true;
			end
		end
		for k, particle in pairs(screenParticles) do
			if existParticle[k] then continue end;

			if not weatherParticlesEnabled then
				particle:Destroy();
			else
				Debugger.Expire(particle, 3);
				TweenService:Create(particle, TweenInfo.new(3), {Rate = 0}):Play();
			end
			screenParticles[k] = nil;
		end


		if activeEffect and activeEffect.EnableScreenRain and not isIndoors and weatherParticlesEnabled then
			modScreenRain:Enable({
				Rate = activeEffect.ScreenRainRate or 5;
			});
		else
			modScreenRain:Disable();
		end

		local weatherSounds = CollectionService:GetTagged("WeatherSound");
		for a=1, #weatherSounds do
			local sound = weatherSounds[a];
			local eq = sound:FindFirstChild("EqualizerSoundEffect");
			if eq then
				eq.Enabled = isIndoors;
			end
			
            if sound:GetAttribute("Lightning") then
				if sound.IsPlaying and sound.PlaybackLoudness > 250 then
					task.spawn(function()
						Lighting.Brightness = math.random(14, 20);
						task.wait(math.random(200,300)/1000);
						Lighting.Brightness = Lighting:GetAttribute("Brightness") or 0;
					end)
				end
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
		if sunRays then
			sunRays.Enabled = modData:GetSetting("FilterSunRays") ~= 1;
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


	--== MARK: Graphical Chunks
	local overlapParam = OverlapParams.new();
	overlapParam.FilterDescendantsInstances = {workspace.Environment;};
	overlapParam.FilterType = Enum.RaycastFilterType.Include;
	overlapParam.MaxParts = 64;

	local lastInteractableScan = tick();
	RunService.Heartbeat:Connect(function()
		if tick()-lastInteractableScan < 2 then return end;
		lastInteractableScan = tick();
		
		local disableSmallShadows = modData:GetSetting("DisableSmallShadows") == 1;
		local disableObjMat = modData:GetSetting("ObjMats") == 1;

		if disableSmallShadows == false and disableObjMat == false then return end;

		local cameraPos = camera.CFrame;
		local hitList = workspace:GetPartBoundsInBox(cameraPos, Vector3.new(50, 50, 50), overlapParam);
		
		for a=1, #hitList do
			local object = hitList[a] :: BasePart;

			local isSmallObj = object.Size.X <= 5 and object.Size.Y <= 5 and object.Size.Z <= 5;
			if disableSmallShadows and isSmallObj and object.CastShadow then
				object.CastShadow = false;
			end
			if disableObjMat then
				object.Material = Enum.Material.SmoothPlastic;
			end
		end
	end)

end

return CameraClass;