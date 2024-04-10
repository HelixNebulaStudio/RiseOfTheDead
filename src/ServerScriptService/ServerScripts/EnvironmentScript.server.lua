--== Initialize;
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
repeat task.wait() until shared.MasterScriptInit == true;

local dayOfYearSet = nil;
--== Configuration;
local LightingConfigurations = {
	OutdoorAmbient = Color3.fromRGB(35, 41, 49);
	NightOutdoorAmbient = Color3.fromRGB(25, 28, 34);
	DayOutdoorAmbient = Color3.fromRGB(223, 234, 240);
	
	Properties = {
		BaseBrightness = 2.5;
		FogRange = 1000;
	};
};

local SeasonsConfigurations = {
	{
		Name="Spring"; 
		Start=60; 
		End=151; 	
		Temperature=24;	TempMin=22; TempMax=26;	
		Brightness=2.5; 
		
		FogRange=400;
		FogChance=1.2;
	};
	{Name="Summer"; 
		Start=152; 
		End=243; 
		
		Temperature=27;	TempMin=24; TempMax=30;	
		
		Brightness=3;
		
		FogRange=500;
		FogChance=1.8;
	};
	{
		Name="Autumn"; 
		Start=244; 
		End=334; 
		
		Temperature=22;	TempMin=20; TempMax=24;	
		
		Brightness=2.5; 
		
		FogRange=300;
		FogChance=1.2;
	};
	{
		Name="Winter"; RangeLoop=true; 
		Temperature=19;	TempMin=16; TempMax=22;	
		
		Brightness=2; 
		
		FogRange=100;
		FogChance=1.1;
		
		WinterMap=true;
	};
}

workspace:SetAttribute("GlobalTemperature", 15);
workspace:SetAttribute("DayOfYear", (tonumber(os.date("%j")) :: number) -1);
-- Variables;
local TweenService = game:GetService("TweenService");
local CollectionService = game:GetService("CollectionService");
local Lighting = game.Lighting;


local modConfigurations = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("Configurations"));
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modInteractable = require(game.ReplicatedStorage.Library.Interactables);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modWorldClipsHandler = require(game.ReplicatedStorage.Library.WorldClipsHandler);

local folderClips = workspace:WaitForChild("Clips");
local folderInteractables = workspace:WaitForChild("Interactables");
local folderDebris = workspace:WaitForChild("Debris");
local folderMapEvent = game.ServerStorage:FindFirstChild("MapEvents");
if folderMapEvent == nil then
	folderMapEvent = Instance.new("Folder");
	folderMapEvent.Parent = game.ServerStorage;
end

local templateInteractableType = script:WaitForChild("InteractableType");

local filterBlur = script:WaitForChild("Blur");
local filterSunRays = script:WaitForChild("SunRays");

local configFolder = game.Lighting:FindFirstChild("Configuration");
if configFolder then
	for _, obj in pairs(configFolder:GetChildren()) do
		LightingConfigurations[obj.Name] = obj.Value;
		obj:GetPropertyChangedSignal("Value"):Connect(function()
			LightingConfigurations[obj.Name] = obj.Value;
		end)
	end
end
-- Script;
Lighting.GlobalShadows = true;
--Lighting.GeographicLatitude = 70;
--Lighting.OutdoorAmbient = LightingConfigurations.OutdoorAmbient;
--Lighting.Ambient = Color3.fromRGB(10, 10, 10);
--Lighting.Brightness = 0;
--Lighting.ClockTime = 3.1;
--Lighting.FogColor = Color3.fromRGB(0, 0, 0);
--Lighting.FogEnd = 400;
--Lighting.FogStart = 40;

Lighting.EnvironmentDiffuseScale = 1;
Lighting.EnvironmentSpecularScale = 0.5;

game.SoundService.RespectFilteringEnabled = true;
game.StarterPlayer.EnableMouseLockOption = false;
--game.StarterPlayer.DevComputerMovementMode = Enum.DevComputerMovementMode.KeyboardMouse;
--game.StarterPlayer.DevComputerCameraMovementMode = Enum.DevComputerCameraMovementMode.Classic;

local isNight: boolean;
if game.Lighting:FindFirstChild("PlaceholderSky") then
	game.Lighting.PlaceholderSky:Destroy();
end
if game.Lighting:FindFirstChildWhichIsA("Sky") == nil then
	script.Sky:Clone().Parent = game.Lighting;
end

for _, obj in pairs(workspace:GetChildren()) do
	if obj:IsA("SpawnLocation") then
		CollectionService:AddTag(obj, "SpawnLocation");
	end
end

modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
	local osTime = workspace:GetAttribute("SetOsTime") or modBranchConfigs.WorldInfo.TimeCycleEnabled and modSyncTime.GetTime() or 0;
	
	if osTime then
		local dayLapseDuration = modConfigurations.DayLapseDuration;
		local hourClock = math.fmod(osTime, dayLapseDuration)/dayLapseDuration*24;
		modSyncTime.IsDay = hourClock > 6 and hourClock < 18;
		
		local range = (hourClock >= 6 and hourClock < 12 and (hourClock-6)/6 or hourClock >= 12 and hourClock < 18 and 1-(hourClock-12)/6 or 0);
		range = range^(1/4);
		-- range = [0,1];
		
		filterSunRays.Intensity = 0.05+(0.15*range);
		
		if hourClock <= 0.1 then
			Lighting.ClockTime = hourClock;
		end
		
		local newOutDoorAmbient = LightingConfigurations.NightOutdoorAmbient:Lerp(LightingConfigurations.DayOutdoorAmbient, range);
		TweenService:Create(Lighting, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
			ClockTime = hourClock;
			ExposureCompensation = -1+(0.1*range);
			Brightness = LightingConfigurations.Properties.BaseBrightness*range;
			FogEnd = 400+(LightingConfigurations.Properties.FogRange * range);
			FogStart = 40+(160*range);
			OutdoorAmbient = newOutDoorAmbient;
			FogColor = Color3.fromRGB(0, 0, 0):Lerp(Color3.fromRGB(255, 255, 255), range);
		}):Play();
		
		Lighting:SetAttribute("OutdoorAmbient", newOutDoorAmbient);
		
		if modSyncTime.IsDay and isNight ~= false then
			isNight = false;
			modOnGameEvents:Fire("OnDayTimeStart");

		elseif not modSyncTime.IsDay and isNight == false then
			isNight = true;
			modOnGameEvents:Fire("OnNightTimeStart");

		end
	end
	
	local dayOfYear = tonumber(os.date("%j")) or 1;
	if workspace:GetAttribute("DayOfYear") ~= dayOfYear then
		workspace:SetAttribute("DayOfYear", dayOfYearSet or dayOfYear);
		
		local seasonInfo;
		
		for a=1, #SeasonsConfigurations do
			local s = SeasonsConfigurations[a];
			
			if s.RangeLoop then
				seasonInfo = s;
				break;
			elseif s.Start <= dayOfYear and dayOfYear <= s.End then
				seasonInfo = s;
				break;
			end
		end
		
		if seasonInfo then
			local dailyNoise = math.abs(math.noise(dayOfYear/2+0.1, 0.1, 0.1)+0.5);
			workspace:SetAttribute("Season", seasonInfo.Name);
			LightingConfigurations.Properties.BaseBrightness = seasonInfo.Brightness or 2.5;
			
			local todaysFog = math.clamp(seasonInfo.FogChance * (dailyNoise ^(1/4)), 0, 1);
			local fogginess = (1000-(seasonInfo.FogRange or 1000))*todaysFog;
			
			LightingConfigurations.Properties.FogRange = seasonInfo.FogRange + fogginess;
			workspace:SetAttribute("Fogginess", fogginess);
			
			local todaysTemp = math.clamp(math.floor((dailyNoise-0.5) *10), -seasonInfo.TempMin, seasonInfo.TempMax);
			workspace:SetAttribute("GlobalTemperature", math.clamp(seasonInfo.Temperature + todaysTemp, 11, 39));
			
			-- Map Decorations
			if seasonInfo.WinterMap then
				if folderDebris:FindFirstChild("WinterEvent") == nil then
					local new = folderMapEvent:FindFirstChild("WinterEvent") and folderMapEvent.WinterEvent:Clone() or nil;
					if new then
						new.Parent = folderDebris;
					end
				end
				
			else
				if folderDebris:FindFirstChild("WinterEvent") then
					game.Debris:AddItem(folderDebris.WinterEvent, 0);
				end
				
			end
			
		end
	end
end)

local function loadClipping(object)
	if object:IsA("BasePart") then
		
		--if object.Name ~= "_Void" then
		--	object.Transparency = 1;
		--end
		
		if modWorldClipsHandler:LoadClip(object) then
			
		elseif object.Name == "_Clip" then
			object.Transparency = 1;
			
		elseif object.Name == "_enemyClip" then
			object.Transparency = 1;
			object.CollisionGroup = "EnemyClips";
			
		elseif object.Name == "_lightClip" then
			object.Transparency = 1;
			object.CanCollide = false;
			
		elseif object.Name == "_playerClip" then
			object.Transparency = 1;
			object.CollisionGroup = "PlayerClips";
			object.CanCollide = false;
			
		end
	end
end

local playerClips = folderClips and folderClips:GetDescendants() or {};

for a=1, #playerClips do 
	loadClipping(playerClips[a]);
end;

local function InitInteractable(interactableModule)
	local obj = interactableModule.Parent;
	if obj:IsA("BasePart") then
		obj.Transparency = 1;
	end
	
	for iconType, iconInfo in pairs(modInteractable.TypeIcons) do
		if string.match(obj.Name, iconType) then
			local new = obj:FindFirstChild("InteractableType") or templateInteractableType:Clone();
			local typeIcon = new:WaitForChild("TypeIcon");
			typeIcon.Image = iconInfo.Icon;
			typeIcon.ImageColor3 = iconInfo.Color;
			new.Parent = obj;
			new.Adornee = obj:IsA("BasePart") and obj or obj:IsA("Model") and obj.PrimaryPart;
		end
	end
	
	local _interactObj = require(interactableModule);
end

task.spawn(function()
	task.wait(0.1);
	local interactables = folderInteractables and folderInteractables:GetDescendants() or {};

	for a=1, #interactables do
		if interactables[a]:IsA("ModuleScript") then
			if interactables[a].Parent.Name == "BlacklightMsg" then
				Debugger:Warn("Blacklight ", interactables[a]);
			end
			task.spawn(function()
				if interactables[a].Name == "Interactable" then
					InitInteractable(interactables[a]);

				elseif interactables[a].Name == "Door" then
					require(interactables[a]);

				end
			end);
		end;
	end;
end)

pcall(function()
	local objectPrefabs = game.ReplicatedStorage.Prefabs.Objects;
	objectPrefabs.MissionIcon.CollisionGroup = "Debris";
	objectPrefabs.HealIcon.CollisionGroup = "Debris";
	objectPrefabs.GuideIcon.CollisionGroup = "Debris";
end)

if folderClips then
	folderClips.ChildAdded:Connect(function(child) 
		loadClipping(child);
		for _, obj in pairs(child:GetDescendants()) do
			loadClipping(obj);
		end
	end)
end;
if folderInteractables then 
	folderInteractables.ChildAdded:Connect(function(child)
		local desc = child:GetDescendants();
		for _, obj in pairs(desc) do
			if obj:IsA("ModuleScript") then
				if obj.Name == "Interactable" then
					InitInteractable(obj);
				elseif obj.Name == "Door" then
					require(obj);
				end
			end
		end
	end) 
end;

filterBlur:Clone().Parent = game.Lighting;
filterSunRays:Clone().Parent = game.Lighting;

local function onDebrisChildAdded(child)
	if child:IsA("BasePart") then
		child.CollisionGroup = "Debris";
		
		if child.Name == "SafehouseProtection" then
			local safehouseId = child:GetAttribute("SafehouseId");
			child.Touched:Connect(function(hitPart)
				modOnGameEvents:Fire("OnSafehouseProtection", safehouseId, hitPart);
			end)
		end
		
		local touchEventId = child:GetAttribute("TouchEvent");
		if touchEventId ~= nil then
			child.Touched:Connect(function(hitPart)
				modOnGameEvents:Fire("OnTouchEvent", touchEventId, hitPart);
			end)
		end
	end
	
	local list = child:GetDescendants();
	for a=1, #list do
		if list[a]:IsA("BasePart") then
			list[a].CollisionGroup = "Debris";
		end
	end
end

folderDebris.ChildAdded:Connect(onDebrisChildAdded)
for _, child in pairs(folderDebris:GetChildren()) do
	onDebrisChildAdded(child);
end

for _, obj in pairs(workspace:GetDescendants()) do
	if obj:IsA("Light") and obj.Name ~= "_naturalLight" and obj.Parent.Name ~= "_naturalLight" and obj.Parent.Parent.Name ~= "_naturalLight" then
		
		local lightSrcPart = obj.Parent:IsA("BasePart") and obj.Parent or obj.Parent.Parent:IsA("BasePart") and obj.Parent.Parent or nil;
		
		if lightSrcPart and lightSrcPart:IsA("BasePart") then
			CollectionService:AddTag(lightSrcPart, "LightSourcePart");
			obj:SetAttribute("DefaultEnabled", obj.Enabled);
		end
		
	end
end

task.spawn(function()
	Debugger.AwaitShared("modCommandsLibrary");
	shared.modCommandsLibrary:HookChatCommand("setdayofyear", {
		Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;

		RequiredArgs = 0;
		UsageInfo = "/setdayofyear [day]";
		Description = [[Sets the day of year of this server. Leave empty to reset to actual date of year.]];
		
		Function = function(player, args)
			
			if args[1] == nil then
				dayOfYearSet = nil;
				
			else
				dayOfYearSet = tonumber(args[1]);
				
			end
			workspace:SetAttribute("DayOfYear", dayOfYearSet or tonumber(os.date("%j")) or 1);
			
			shared.Notify(player, "Day of year set to: ".. workspace:GetAttribute("DayOfYear"), "Inform");
			
			return true;
		end;
	});
end)





