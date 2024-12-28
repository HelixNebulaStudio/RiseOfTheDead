local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
---
local Settings = {};

local RunService = game:GetService("RunService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local modConfigInterface = require(game.ReplicatedStorage.Library.UI.ConfigInterface);

Settings.OnChanged = modEventSignal.new("SettingsOnChanged");

function Settings.Fix(player, key, value)
	if Settings[key] then
		return Settings[key](value, player);
	end
	return value;
end

function Settings.Add(key, func)
	Settings[key] = func;
end

function Settings.Set(player, key, value)
	if RunService:IsServer() then return end;

	local modData = require(player:WaitForChild("DataModule"));
	
	local oldVal = Settings[key];
	local newVal = Settings.Fix(player, key, value);
	modData.Settings[key] = newVal;
	
	if modData.Profile and modData.Profile.Settings then
		modData.Profile.Settings[key] = modData.Settings[key];
	end
	modData:SetSetting(key, newVal);
	
	if oldVal ~= newVal then
		Settings.OnChanged:Fire(key);
	end
	
	return newVal;
end

function Settings.UpdateAutoPickup(pickupCache, config)
	table.clear(pickupCache);

	local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
	local itemsList = modItemsLibrary.Library:GetIndexList();
	for _, itemLib in pairs(itemsList) do
		local itemId = itemLib.Id;

		for _, listItem in pairs(config) do
			local mode = listItem.Mode;
			local keyword = listItem.Keyword;
			local isKeyword = keyword:sub(1,1) == "*";

			if mode == 1 then
				if isKeyword then
					keyword = string.gsub(keyword, "*", ""):lower();

					local hasMatch = false;

					if string.match(string.lower(itemLib.Id), keyword) then
						hasMatch = true;
					end
					for _, tag in pairs(itemLib.Tags) do
						if string.match(string.lower(tag), keyword) then
							hasMatch = true;
							break;
						end
					end

					if hasMatch then
						pickupCache[itemId] = true;
					end

				else
					if itemLib.Id == keyword then
						pickupCache[itemId] = true;

					end
				end
			end

		end

	end
end

local function booleanOrNil(value)
	if value == nil then return nil end;
	if value == true or value == 1 then return 1; end
	return 0;
end

--==Keybinds;
local function keyCheck(key)
	return modKeyBindsHandler:KeyCheck(key)
end
local function ignoreMouseKeys(key)
	if key == "MouseButton1" or key == "MouseButton2" or key == "MouseButton3" then
		return nil;
	end
	return key;
end
local function numOrNil(value)
	if value == nil then return nil end;
	return tonumber(value);
end

Settings.Add("HideHotkey", booleanOrNil)

Settings.Add("KeySprint", keyCheck);
Settings.Add("KeyCrouch", keyCheck);
Settings.Add("KeyJump", keyCheck);
Settings.Add("KeyWalk", keyCheck);
Settings.Add("KeyCamSide", keyCheck);
Settings.Add("KeyInteract", keyCheck);

Settings.Add("KeyReload", keyCheck);
Settings.Add("KeyInspect", keyCheck);

Settings.Add("KeyToggleSpecial", keyCheck);
Settings.Add("KeyTogglePat", keyCheck);


Settings.Add("KeyWindowInventory", ignoreMouseKeys(keyCheck));
Settings.Add("KeyWindowFactionsMenu", ignoreMouseKeys(keyCheck));
Settings.Add("KeyWindowMissions", ignoreMouseKeys(keyCheck));
Settings.Add("KeyWindowSocialMenu", ignoreMouseKeys(keyCheck));
Settings.Add("KeyWindowEmotes", ignoreMouseKeys(keyCheck));
Settings.Add("KeyWindowMasteryMenu", ignoreMouseKeys(keyCheck));
Settings.Add("KeyWindowWorkbench", ignoreMouseKeys(keyCheck));
Settings.Add("KeyWindowMapMenu", ignoreMouseKeys(keyCheck));
Settings.Add("KeyHideHud", ignoreMouseKeys(keyCheck));

--== Gameplay;

Settings.Add("ZoomLevel", function(value)
	return math.clamp(math.floor(value), 2, 20);
end)

Settings.Add("ShowScrollbars", booleanOrNil)
Settings.Add("Notifications", function(value)
	if value then
		if value == 1 then
			return 1;
		elseif value == 2 then
			return 2;
		end
	end
	return nil;
end)
Settings.Add("CombineHealthbars", booleanOrNil)
Settings.Add("ToggleCrouch", booleanOrNil)
Settings.Add("CompactInterface", function(value)
	if value then
		if value == true or value == 1 then
			return 1;
		elseif value == 2 then
			return 2;
		end
	end
	return nil;
end)
Settings.Add("DisableAccessoryHud", booleanOrNil)
Settings.Add("DisableDamageIndicator", booleanOrNil)
Settings.Add("SlideCameraLock", booleanOrNil)

--== Social;
Settings.Add("InviteFriendsOnly", booleanOrNil)
Settings.Add("HideLevelIcon", booleanOrNil)
Settings.Add("HidePlayerTitle", booleanOrNil)
Settings.Add("CinematicMode", booleanOrNil)

Settings.Add("HideIconLevels", booleanOrNil)
Settings.Add("AchievementTitleLevels", booleanOrNil)


Settings.Add("Nickname", function(value, player)
	if type(value) ~= "string" then value = tostring(value) end;
	if #value > 20 then value = value:sub(1,20) end;
	if value == nil or value == player.Name then return nil end;
	if modGlobalVars.IsCreator(player) then return value end;
	
	local resultValue;
	if RunService:IsServer() then
		resultValue = shared.modAntiCheatService:Filter(value, player, true, false);
	else
		resultValue = value;
	end
	return resultValue;
end)

Settings.Add("TradeFriendsOnly", booleanOrNil)
Settings.Add("DisabledTravelRequests", booleanOrNil)

--MARK: Graphics;
Settings.Add("DamageBubble", booleanOrNil)
Settings.Add("BloodParticle", booleanOrNil)

Settings.Add("DisableDeathRagdoll", booleanOrNil)
Settings.Add("MaxDeadbodies", function(v)
	return v and tonumber(v) and math.clamp(tonumber(v) :: number, 0, 64) or nil;
end)
Settings.Add("DeadbodyDespawnTimer", function(v)
	return v and tonumber(v) and math.clamp(tonumber(v) :: number, 1, 61) or nil;
end)

Settings.Add("ObjMats", booleanOrNil)

Settings.Add("FilterColors", booleanOrNil)
Settings.Add("FilterSunRays", booleanOrNil)

Settings.Add("HideFarSmallObjects", booleanOrNil)
Settings.Add("LessDetail", booleanOrNil)

Settings.Add("DisableBulletTracers", booleanOrNil)
Settings.Add("LimitParticles", booleanOrNil)
Settings.Add("ReduceMaxDebris", booleanOrNil)
Settings.Add("GlobalShadows", booleanOrNil)
Settings.Add("DisableSmallShadows", booleanOrNil)
Settings.Add("DisableParticle3D", booleanOrNil)
Settings.Add("DisableWeatherParticles", booleanOrNil)

Settings.Add("TextureStepBuffer", numOrNil)
Settings.Add("MotionStepBuffer", numOrNil)

--==
Settings.Add("UseOldZombies", booleanOrNil);

--== Audio;
local function volumeCheck(v)
	return v and tonumber(v) and math.clamp(tonumber(v) :: number, 0, 100) or nil;
end
Settings.Add("SndAmbient", volumeCheck);
Settings.Add("SndBackgroundMusic", volumeCheck);
Settings.Add("SndInstrumentMusic", volumeCheck);
Settings.Add("SndEffects", volumeCheck);
Settings.Add("SndNPC", volumeCheck);
Settings.Add("SndUIEffects", volumeCheck);
Settings.Add("SndWeaponEffects", volumeCheck);
Settings.Add("SndZombies", volumeCheck);
Settings.Add("SndWeather", volumeCheck);

--== Menus;
local function numCheck(v)
	return tonumber(v);
end
Settings.Add("HideTabCore", numCheck);
Settings.Add("HideTabSide", numCheck);
Settings.Add("HideTabSecret", numCheck);
Settings.Add("HideTabDaily", numCheck);
Settings.Add("HideTabPremium", numCheck);
Settings.Add("HideTabEvent", numCheck);


--== PlayerClothing;

Settings.Add("ToggleClothing", function(t, player)
	local appearFolder = player:FindFirstChild("Appearance");
	if appearFolder then
		for k, v in pairs(t) do
			local found = false;
			for _, asset in pairs(appearFolder:GetChildren()) do
				if asset:GetAttribute("AssetId") == k then
					found = true;
					break;
				end
			end
			if not found then
				t[k] = nil;
			end
		end
	end
	
	for k, v in pairs(t) do
		if v == false then
			t[k] = false;
		else
			t[k] = nil;
		end
	end
	return t;
end);


Settings.Add("AutoPickupMode", function(v)
	return tonumber(v);
end);
Settings.Add("AutoPickupConfig", function(t)
	local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
	
	t = t or {};
	
	for a=#t, 1, -1 do
		local listItem = t[a];
		local keyword = listItem.Keyword;
		--local listType = listItem.Mode;

		local isSearchWord = keyword:sub(1,1) == "*";
		if isSearchWord then
			
		else
			if modItemsLibrary:Find(keyword) == nil then
				table.remove(t, a);
			end
			
		end
	end
	table.sort(t, function(a, b)
		return a.Keyword < b.Keyword;
	end);
	
	return t;
end);

--== SettingsMenu

local baseConfigInterface = modConfigInterface.new();

baseConfigInterface:Add("Left", "CategoryTitle", {Properties={Text="Gameplay";}; });
baseConfigInterface:Add("Left", "CategoryOption", {Properties={Text="General";}; ButtonLink="GameplayGeneral";});
baseConfigInterface:Add("Left", "CategoryOption", {Properties={Text="Auto Pickup";}; ButtonLink="GameplayAutoPickup"; });

baseConfigInterface:Add("Left", "CategoryTitle", {Properties={Text="Controls";}; });
baseConfigInterface:Add("Left", "CategoryOption", {Properties={Text="Keybinds";}; ButtonLink="ControlsKeybinds"});

baseConfigInterface:Add("Left", "CategoryTitle", {Properties={Text="Social";}; });
baseConfigInterface:Add("Left", "CategoryOption", {Properties={Text="Requests";}; ButtonLink="SocialsRequests"});
baseConfigInterface:Add("Left", "CategoryOption", {Properties={Text="Roleplay";}; ButtonLink="SocialsRoleplay"});

baseConfigInterface:Add("Left", "CategoryTitle", {Properties={Text="Visuals";}; });
baseConfigInterface:Add("Left", "CategoryOption", {Properties={Text="Interface";}; ButtonLink="VisualsInterface" });
baseConfigInterface:Add("Left", "CategoryOption", {Properties={Text="Graphics";}; ButtonLink="VisualsGraphics" });

baseConfigInterface:Add("Left", "CategoryTitle", {Properties={Text="Audio";}; });
baseConfigInterface:Add("Left", "CategoryOption", {Properties={Text="Sound Effects";}; ButtonLink="AudioSoundeffects" });
baseConfigInterface:Add("Left", "CategoryOption", {Properties={Text="Music & Ambience";}; ButtonLink="AudioMusic" });

baseConfigInterface:Add("Left", "CategoryTitle", {Properties={Text="Data";}; });
baseConfigInterface:Add("Left", "CategoryOption", {Properties={Text="Reset";}; ButtonLink="DataReset" });

-- MARK: GameplayGeneral;
baseConfigInterface:Add("Right", "Page", {Id="GameplayGeneral"; ClickOnRender=true;});
baseConfigInterface:Add("GameplayGeneral", "ToggleOption", {
	TitleProperties={Text="Toggle Focus Mode";};
	DescProperties={Text="Switch between hold aimming or toggle aimming.";};
	Config={
		SettingsKey="ToggleAimMode"; 
		Type="Toggle;Hold;Toggle";
	};
});
baseConfigInterface:Add("GameplayGeneral", "ToggleOption", {
	TitleProperties={Text="Toggle Crouch";};
	DescProperties={Text="Switch between hold crouching or toggle crouching.";};
	Config={
		SettingsKey="ToggleCrouch"; 
		Type="Toggle;Hold;Toggle";
	};
});
baseConfigInterface:Add("GameplayGeneral", "ToggleOption", {
	TitleProperties={Text="Slide Camera Lock";};
	DescProperties={Text="Lock sliding direction to camera.";};
	Config={
		SettingsKey="SlideCameraLock"; 
		Type="Toggle;Off;Lock";
	};
});



-- MARK: GameplayAutoPickup;
baseConfigInterface:Add("Right", "Page", {Id="GameplayAutoPickup";
	Config={
		Type="AutoPickup";
	};	
});
baseConfigInterface:Add("GameplayAutoPickup", "ToggleOption", {
	TitleProperties={Text="Auto Pickup Mode";};
	DescProperties={Text="Default picks up basic items. Custom uses the list below. Disable does not pick up any items.";};
	Config={
		SettingsKey="AutoPickupMode"; 
		Type="Toggle;Default;Custom;Disabled";
	};
});

-- MARK: ControlsKeybinds;
baseConfigInterface:Add("Right", "Page", {Id="ControlsKeybinds";
	Config={
		Type="Keybinds";
	};	
});


-- MARK: SocialsPublic;
baseConfigInterface:Add("Right", "Page", {Id="SocialsRequests";});
baseConfigInterface:Add("SocialsRequests", "ToggleOption", {
	TitleProperties={Text="Travel Request";};
	DescProperties={Text="Allow anyone to send you travel requests.";};
	Config={
		SettingsKey="DisabledTravelRequests"; 
		Type="Toggle";
	};
});
baseConfigInterface:Add("SocialsRequests", "ToggleOption", {
	TitleProperties={Text="Squad Requests";};
	DescProperties={Text="Who can invite you to squad.";};
	Config={
		SettingsKey="InviteFriendsOnly"; 
		Type="Toggle;Anyone;Friends";
	};
});
baseConfigInterface:Add("SocialsRequests", "ToggleOption", {
	TitleProperties={Text="Trade Requests";};
	DescProperties={Text="Who can invite you to trade.";};
	Config={
		SettingsKey="TradeFriendsOnly"; 
		Type="Toggle;Anyone;Friends";
	};
});
-- SocialsRoleplay;
baseConfigInterface:Add("Right", "Page", {Id="SocialsRoleplay";});
baseConfigInterface:Add("SocialsRoleplay", "ToggleOption", {
	TitleProperties={Text="Level Icon";};
	DescProperties={Text="Show your level icon.";};
	Config={
		SettingsKey="HideLevelIcon"; 
		Type="Toggle";
	};
});
baseConfigInterface:Add("SocialsRoleplay", "ToggleOption", {
	TitleProperties={Text="Player Title";};
	DescProperties={Text="Show your character name.";};
	Config={
		SettingsKey="HidePlayerTitle"; 
		Type="Toggle";
	};
});
baseConfigInterface:Add("SocialsRoleplay", "ToggleOption", {
	TitleProperties={Text="Achievement Title Levels";};
	DescProperties={Text="Adds achievement level to player title.";};
	Config={
		SettingsKey="AchievementTitleLevels";
		Type="Toggle";
	};
});
baseConfigInterface:Add("SocialsRoleplay", "InputOption", {
	TitleProperties={Text="Character Name";};
	DescProperties={Text="Set your character name.";};
	Config={
		SettingsKey="Nickname"; 
		Type="Name";
	};
});


-- MARK: VisualsInterface;
baseConfigInterface:Add("Right", "Page", {Id="VisualsInterface";});
baseConfigInterface:Add("VisualsInterface", "ToggleOption", {
	TitleProperties={Text="Compact Interface";};
	DescProperties={Text="Compact interface makes menus and windows more compact for smaller screens.";};
	Config={
		SettingsKey="CompactInterface"; 
		Type="Toggle;Automatic;Enabled;Disabled";
	};
});
baseConfigInterface:Add("VisualsInterface", "ToggleOption", {
	TitleProperties={Text="Notifications";};
	DescProperties={Text="Switch between where notifications are displayed.";};
	Config={
		SettingsKey="Notifications"; 
		Type="Toggle;Normal;Chat;Disabled";
	};
});
baseConfigInterface:Add("VisualsInterface", "ToggleOption", {
	TitleProperties={Text="Damage Bubbles";};
	DescProperties={Text="Damage, healing or status bubbles that shows up in 3D space.";};
	Config={
		SettingsKey="DamageBubble";
		Type="Toggle";
	};
});
baseConfigInterface:Add("VisualsInterface", "ToggleOption", {
	TitleProperties={Text="Hotkey Hints";};
	DescProperties={Text="Hotkey hints for top menu bar.";};
	Config={
		SettingsKey="HideHotkey";
		Type="Toggle";
	};
});
baseConfigInterface:Add("VisualsInterface", "ToggleOption", {
	TitleProperties={Text="Accessory Hud";};
	DescProperties={Text="Show/hide huds of accessories such as watches.";};
	Config={
		SettingsKey="DisableAccessoryHud";
		Type="Toggle";
	};
});
baseConfigInterface:Add("VisualsInterface", "ToggleOption", {
	TitleProperties={Text="Scrollbars";};
	DescProperties={Text="Show/hide scrollsbars on interfaces.";};
	Config={
		SettingsKey="ShowScrollbars";
		Type="Toggle";
	};
});
baseConfigInterface:Add("VisualsInterface", "ToggleOption", {
	TitleProperties={Text="Cinematic Mode";};
	DescProperties={Text="For a more cinematic experience. Hides damage bubbles, notifications, health bars, etc..";};
	Config={
		SettingsKey="CinematicMode";
		Type="Toggle;Disabled;Enabled";
	};
});
baseConfigInterface:Add("VisualsInterface", "ToggleOption", {
	TitleProperties={Text="Directional Damage Indicators";};
	DescProperties={Text="Hud indicators which shows the magnitude and direction when taking damage.";};
	Config={
		SettingsKey="DisableDamageIndicator";
		Type="Toggle;Enabled;Disabled";
	};
});

-- MARK: VisualsGraphics;
baseConfigInterface:Add("Right", "Page", {Id="VisualsGraphics";});
baseConfigInterface:Add("VisualsGraphics", "ToggleOption", {
	TitleProperties={Text="Blood Particles";};
	DescProperties={Text="Hides blood splatter when shooting enemies.";};
	Config={
		SettingsKey="BloodParticle";
		Type="Toggle";
	};
});

baseConfigInterface:Add("VisualsGraphics", "SliderOption", {
	TitleProperties={Text="Maximum Deadbodies";};
	DescProperties={Text="Limit the number of dead bodies.";};
	Config={
		SettingsKey="MaxDeadbodies";
		RangeInfo={Min=0; Max=64; Default=16; ValueType="Flat"};
	};
});
baseConfigInterface:Add("VisualsGraphics", "SliderOption", {
	TitleProperties={Text="Deadbody Despawn Timer";};
	DescProperties={Text="The time until dead bodies are despawned.";};
	Config={
		SettingsKey="DeadbodyDespawnTimer";
		RangeInfo={Min=1; Max=61; Default=16; ValueType="Flat";
			DisplayValueFunc=function(v)
				if v == 61 then
					if modBranchConfigs.CurrentBranch.Name == "Dev" then
						return "Disabled";
					end
					return "60s";
				else
					return v.."s";
				end
			end;
		};
	};
});


baseConfigInterface:Add("VisualsGraphics", "ToggleOption", {
	TitleProperties={Text="Enemy Ragdoll";};
	DescProperties={Text="Enemies ragdolls during death or stun.";};
	Config={
		SettingsKey="DisableDeathRagdoll";
		Type="Toggle";
	};
});
baseConfigInterface:Add("VisualsGraphics", "ToggleOption", {
	TitleProperties={Text="Sun Rays";};
	DescProperties={Text="Add sun rays from sun light with filters.";};
	Config={
		SettingsKey="FilterSunRays";
		Type="Toggle";
		RefreshGraphics=true;
	};
});

baseConfigInterface:Add("VisualsGraphics", "ToggleOption", {
	TitleProperties={Text="Disable Bullet Tracers";};
	DescProperties={Text="Disabling the trails that visualizes hitscan bullets.";};
	Config={
		SettingsKey="DisableBulletTracers";
		Type="Toggle;Disabled;Enabled";
	};
});
baseConfigInterface:Add("VisualsGraphics", "ToggleOption", {
	TitleProperties={Text="Limit Particles";};
	DescProperties={Text="Hides or limits unimportant particles.";};
	Config={
		SettingsKey="LimitParticles";
		Type="Toggle;Disabled;Enabled";
	};
});
baseConfigInterface:Add("VisualsGraphics", "ToggleOption", {
	TitleProperties={Text="Reduce Max Debris";};
	DescProperties={Text="Limits total debris count to 100.";};
	Config={
		SettingsKey="ReduceMaxDebris";
		Type="Toggle;Disabled;Enabled";
	};
});

baseConfigInterface:Add("VisualsGraphics", "ToggleOption", {
	TitleProperties={Text="Object Materials";};
	DescProperties={Text="Disabling will set all object materials to smooth plastic for better performance.";};
	Config={
		SettingsKey="ObjMats";
		Type="Toggle";
		RefreshGraphics=true;
	};
});
baseConfigInterface:Add("VisualsGraphics", "ToggleOption", {
	TitleProperties={Text="Small Shadows";};
	DescProperties={Text="Shadows of objects smaller than 5x5x5. <b>Enabling requires rejoining.</b>";};
	Config={
		SettingsKey="DisableSmallShadows";
		Type="Toggle";
		RefreshGraphics=true;
	};
});
baseConfigInterface:Add("VisualsGraphics", "ToggleOption", {
	TitleProperties={Text="Extra Detail";};
	DescProperties={Text="Disabling will delete decorative props and assets from the world. <b>Enabling requires rejoining.</b>";};
	Config={
		SettingsKey="LessDetail";
		Type="Toggle";
		RefreshGraphics=true;
	};
});
baseConfigInterface:Add("VisualsGraphics", "ToggleOption", {
	TitleProperties={Text="Global Shadows";};
	DescProperties={Text="Cast shadows from the sun.";};
	Config={
		SettingsKey="GlobalShadows";
		Type="Toggle";
		RefreshGraphics=true;
	};
});
baseConfigInterface:Add("VisualsGraphics", "ToggleOption", {
	TitleProperties={Text="3D Particles";};
	DescProperties={Text="Particles that interact with the environment such as metal sparks, bullet shells, flesh chunks, etc..";};
	Config={
		SettingsKey="DisableParticle3D";
		Type="Toggle";
	};
});
baseConfigInterface:Add("VisualsGraphics", "ToggleOption", {
	TitleProperties={Text="Weather Particles";};
	DescProperties={Text="Particles of rain or snow.";};
	Config={
		SettingsKey="DisableWeatherParticles";
		Type="Toggle";
	};
});
baseConfigInterface:Add("VisualsGraphics", "ToggleOption", {
	TitleProperties={Text="Use Zombie 1.0 Skin & Face";};
	DescProperties={Text="Use Zombie 1.0's skin tone & face. Only shows for new spawns. (Model, clothing & animations aren't compatible)";};
	Config={
		SettingsKey="UseOldZombies";
		Type="Toggle;Disabled;Enabled";
	};
});

baseConfigInterface:Add("VisualsGraphics", "SliderOption", {
	TitleProperties={Text="Texture Animations Step Buffer";};
	DescProperties={Text="Skip steps on scripted texture animations on crates and skins. Increase = more performance. Decrease = smoother animation.";};
	Config={
		SettingsKey="TextureStepBuffer";
		RefreshGraphics=true;
		RangeInfo={Min=1; Max=8; Default=2; ValueType="Flat";
			DisplayValueFunc=function(v)
				if v >= 8 then
					return "Disabled Texture Animations"
				end
				return `Every {math.clamp(v, 1, 8)} step`;
			end;
		};
	};
});
baseConfigInterface:Add("VisualsGraphics", "SliderOption", {
	TitleProperties={Text="Joints Motion Step Buffer";};
	DescProperties={Text="Skip steps on scripted motion of character joints. Increase = more performance. Decrease = smoother motion.";};
	Config={
		SettingsKey="MotionStepBuffer"; 
		RangeInfo={Min=1; Max=6; Default=1; ValueType="Flat";
			DisplayValueFunc=function(v)
				return `Every {math.clamp(v, 1, 6)} step`;
			end;
		};
	};
});

-- MARK: AudioSoundeffects;
baseConfigInterface:Add("Right", "Page", {Id="AudioSoundeffects";});
baseConfigInterface:Add("AudioSoundeffects", "SliderOption", {
	TitleProperties={Text="Effects";};
	DescProperties={Text="General sound effects from tools to explosions.";};
	Config={SoundGroupKey="Effects"; Type="SoundGroup"};
});
baseConfigInterface:Add("AudioSoundeffects", "SliderOption", {
	TitleProperties={Text="Weapon Effects";};
	DescProperties={Text="Weapons sounds.";};
	Config={SoundGroupKey="WeaponEffects"; Type="SoundGroup"};
});
baseConfigInterface:Add("AudioSoundeffects", "SliderOption", {
	TitleProperties={Text="NPC";};
	DescProperties={Text="Npc noises such as Carlos's flute music.";};
	Config={SoundGroupKey="NPC"; Type="SoundGroup"};
});
baseConfigInterface:Add("AudioSoundeffects", "SliderOption", {
	TitleProperties={Text="UIEffects";};
	DescProperties={Text="User interface sounds.";};
	Config={SoundGroupKey="UIEffects"; Type="SoundGroup"};
});
baseConfigInterface:Add("AudioSoundeffects", "SliderOption", {
	TitleProperties={Text="Zombies";};
	DescProperties={Text="Zombie noises.";};
	Config={SoundGroupKey="Zombies"; Type="SoundGroup"};
});
baseConfigInterface:Add("AudioSoundeffects", "SliderOption", {
	TitleProperties={Text="Weather";};
	DescProperties={Text="Weather sounds.";};
	Config={SoundGroupKey="Weather"; Type="SoundGroup"};
});

-- AudioMusic;
baseConfigInterface:Add("Right", "Page", {Id="AudioMusic";});
baseConfigInterface:Add("AudioMusic", "SliderOption", {
	TitleProperties={Text="Ambient";};
	DescProperties={Text="Ambient noise such as wind and ocean sounds.";};
	Config={SoundGroupKey="Ambient"; Type="SoundGroup"};
});
baseConfigInterface:Add("AudioMusic", "SliderOption", {
	TitleProperties={Text="Background Music";};
	DescProperties={Text="Any kind of music All boss, raids, survival, etc.. music.";};
	Config={SoundGroupKey="BackgroundMusic"; Type="SoundGroup"};
});
baseConfigInterface:Add("AudioMusic", "SliderOption", {
	TitleProperties={Text="Instrument Music";};
	DescProperties={Text="Sounds from instruments such as boombox, flute, etc..";};
	Config={SoundGroupKey="InstrumentMusic"; Type="SoundGroup"};
});

-- DataReset;
baseConfigInterface:Add("Right", "Page", {Id="DataReset";
	Config={
		Type="DataReset";
	};		
});


Settings.DefaultConfigInterface = baseConfigInterface;

Settings.Checks = {
	KeyCheck = keyCheck;
	IgnoreMouseKeys = ignoreMouseKeys;
}

local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetModule(script.Name);
if moddedSelf then moddedSelf:Init(Settings); end


return Settings;