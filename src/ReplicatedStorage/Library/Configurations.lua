local ChangeHooks = {};
local ConfigurationsMeta = {};
ConfigurationsMeta.__index = ConfigurationsMeta;
local Configurations = setmetatable({}, ConfigurationsMeta);

local RunService = game:GetService("RunService");
local functionHookedYield = script:WaitForChild("FunctionHooked");

ConfigurationsMeta.Set = function(key, value)
	local oldValue = Configurations[key];
	Configurations[key] = value;
		
	if ChangeHooks[key] then
		ChangeHooks[key](oldValue, value);
	end;
end

ConfigurationsMeta.OnChanged = function(key, func)
	ChangeHooks[key] = func;
end

--== Client;
Configurations.Set("VersionLabelSide", "Right");
Configurations.Set("CompactInterface", false);
Configurations.Set("AutoOpenBlinds", true);
Configurations.Set("DisableHotbar", true);
Configurations.Set("DisableWeaponInterface", true);
Configurations.Set("DisableInventory", true);
Configurations.Set("DisableHealthbar", true);
Configurations.Set("DisableFactionsMenu", true);
Configurations.Set("DisableFaction", true);
Configurations.Set("DisableMissions", true);
Configurations.Set("DisablePinnedMission", true);
Configurations.Set("DisableWorkbench", true);
Configurations.Set("DisableReportMenu", true);
Configurations.Set("DisableMasteryMenu", true);
Configurations.Set("DisableExperiencebar", true);
Configurations.Set("DisableGeneralStats", true);
Configurations.Set("DisableSquadInterface", true);
Configurations.Set("DisableCutsceneNext", true);
Configurations.Set("DisableSocialMenu", true);
Configurations.Set("DisableEmotes", true);
Configurations.Set("DisableMapMenu", true);
Configurations.Set("DisableSettingsMenu", true);
Configurations.Set("CanQuickEquip", false);
Configurations.Set("DisableWaypointers", true);
Configurations.Set("DisableMajorNotifications", true);
Configurations.Set("DisableDialogue", true);
Configurations.Set("DisableInfoBubbles", true);
Configurations.Set("DisableHotKeyLabels", false);
Configurations.Set("DisableGoldMenu", true);
Configurations.Set("DisableStatusHud", true);
Configurations.Set("NotificationViewPos", 1);
Configurations.Set("AutoMarkEnemies", false);
Configurations.Set("DisableDefaultFlashlight", false);
Configurations.Set("SpectateEnabled", false);
Configurations.Set("Disable3DSkybox", false);
Configurations.Set("DisableRbxEmotes", true);
Configurations.Set("DisableSafehomeMenu", true);
Configurations.Set("RecoilScaler", 0.3);
Configurations.Set("AllowFreecam", false);
Configurations.Set("AllowUnstuck", true);
Configurations.Set("DisableUpdateLogs", true);
Configurations.Set("BaseWoundedDuration", 0);
Configurations.Set("KnockoutOnDeath", 0);
Configurations.Set("VelocityTriggerRagdoll", false);
Configurations.Set("DisableMapItems", true);
Configurations.Set("DisableHurtInterface", false);

Configurations.Set("IgnoreModCompatibility", false);

--== Server;
Configurations.Set("DisableItemDrops", true);
Configurations.Set("DisableExperienceGain", true);
Configurations.Set("DisableLeaderboard", false);
--Configurations.Set("AutoRespawnLength", 5);
--Configurations.Set("AutoSpawning", true);
Configurations.Set("RemoveForceFieldOnWeaponFire", false);
Configurations.Set("ShowNameDisplays", true);
Configurations.Set("TargetableEntities", {
	Zombie=1;
	Bandit=0.8;
	Cultist=0.7;
	Rat=0.5;
});
Configurations.Set("InfTargeting", false);
Configurations.Set("PvpMode", false);
Configurations.Set("DisableGearMods", false);
Configurations.Set("DisableNonMockEquip", false);
Configurations.Set("DisableMasterySkills", false);
Configurations.Set("DisableWorldAd", false);

Configurations.Set("DayLapseDuration", 1200);
Configurations.Set("DisableWeatherCycle", false);
Configurations.Set("SpawnProtectionTimer", 10);
Configurations.Set("ExpireDeployables", false);

Configurations.Set("NpcThinkCycle", 15);
Configurations.Set("WithererSpawnLogic", false);
Configurations.Set("NaturalSpawnLimit", 999);

Configurations.Set("SkyPhaseColor", {
	Night = Color3.fromRGB(25, 28, 34);

	DawnStart = Color3.fromRGB(58, 25, 31);
	DawnPeak = Color3.fromRGB(104, 30, 52);
	DawnEnd = Color3.fromRGB(154, 105, 124);

	Day = Color3.fromRGB(223, 234, 240);

	DuskStart = Color3.fromRGB(166, 157, 153);
	DuskPeak = Color3.fromRGB(121, 69, 31);
	DuskEnd = Color3.fromRGB(77, 50, 38);
});
Configurations.Set("FogRange", {
	Start = 40;
	End = 400;
});

--== Events;
local Months = {"January"; "Feburary"; "March"; "April"; "May"; "June"; "July"; "August"; "September"; "October"; "November"; "December";};
local SpecialEventsTable = {
	NewYear = {Month="January";};
	AprilFools = {Month="April"; DaysBefore=7;}; -- First week of April;
	Easter = {Month="April"; DaysAfter=8;}; -- Second week of April;
	Halloween = {Month="October"; DaysAfter=8;}; -- second week of October;
	Christmas = {Month="December"};
};
local SpecialEvents = {};

for eventId, dateTable in pairs(SpecialEventsTable) do
	local isActive = false;
	if dateTable.Month and os.date("%B") == dateTable.Month then
		if dateTable.DaysBefore then
			isActive = tonumber(os.date("%d")) <= dateTable.DaysBefore;
		elseif dateTable.DaysAfter then
			isActive = tonumber(os.date("%d")) >= dateTable.DaysAfter;
		else
			isActive = true;
		end
	end
	
	if workspace:GetAttribute(eventId) == true then
		isActive = true;
	end

	SpecialEvents[eventId] = isActive;
end

SpecialEvents.Halloween = true;

Configurations.Set("SpecialEvent", SpecialEvents);

return Configurations;