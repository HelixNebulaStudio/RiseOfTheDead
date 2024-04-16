local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local modRichFormatter = require(game.ReplicatedStorage.Library.UI.RichFormatter);
--
local colorBoolText = modRichFormatter.ColorBoolText;
local colorStringText = modRichFormatter.ColorStringText;
local colorNumberText = modRichFormatter.ColorNumberText;

local PlaceholderIcon = "rbxassetid://16029038219";

local ModsLibrary = {List={}; Library={};};
ModsLibrary.EffectTrigger = {
	Passive=0;
	Activate=1;
	Trigger=2;
};

ModsLibrary.ScalingStyle = {
	Linear=0;
	NaturalCurve=1;
};

function ModsLibrary.Linear(base, max, level, maxlevel)
	level = level or 0;
	if base > max then -- base=8, max=2
		local scale = base-max;
		return base - (math.clamp(level/maxlevel, 0, 1) * scale);
		
	else
		local scale = max-base;
		return base + (math.clamp(level/maxlevel, 0, 1) * scale);
		
	end
end

function ModsLibrary.NaturalInterpolate(base, max, level, maxlevel, rate)
	level = level or 0;
	local scale = math.clamp(level/maxlevel, 0, 1)^(rate or 2.5);
	return (base + (max-base)*scale);
end


function ModsLibrary.GetLayer(upgradeKey, packet)
	local modStorageItem = packet.ModStorageItem;
	
	local modLib = ModsLibrary.Get(modStorageItem.ItemId);
	local values = modStorageItem.Values;
	
	local layerPacket = {};
	
	local upgradeInfo = nil;
	for a=1, #modLib.Upgrades do
		if modLib.Upgrades[a].DataTag == upgradeKey then
			upgradeInfo = modLib.Upgrades[a];
			break;
		end
	end
	
	if upgradeInfo == nil then
		error("Unknown upgradeKey ("..upgradeKey..") for ("..modStorageItem.ItemId..")");
	end
	
	local modTier = values.Tier or modLib.BaseTier;
	--local tierDiff = packet.ItemTier > modTier and (packet.ItemTier-modTier) or 0;
	local tierDiff = packet.ItemTier < modTier and (modTier-packet.ItemTier) or 0;

	layerPacket.MaxLevel = math.max(upgradeInfo.MaxLevel-tierDiff, 0);
	layerPacket.Level = math.clamp((values[upgradeKey] or 0), 0, layerPacket.MaxLevel);
	
	local activeLevel = layerPacket.Level;
	
	if upgradeInfo.SliderTag then
		layerPacket.SliderLevel = math.clamp(values[upgradeInfo.SliderTag] or layerPacket.Level, 0, layerPacket.Level);
		activeLevel = layerPacket.SliderLevel;
	end
	
	
	if upgradeInfo.Scaling == ModsLibrary.ScalingStyle.Linear then
		layerPacket.Value = ModsLibrary.Linear(
			upgradeInfo.BaseValue, 
			upgradeInfo.MaxValue,
			activeLevel,
			upgradeInfo.MaxLevel
		);
		
	elseif upgradeInfo.Scaling == ModsLibrary.ScalingStyle.NaturalCurve then
		layerPacket.Value = ModsLibrary.NaturalInterpolate(
			upgradeInfo.BaseValue, 
			upgradeInfo.MaxValue, 
			activeLevel, 
			upgradeInfo.MaxLevel, 
			upgradeInfo.Rate
		);
		
	end
	
	if packet.TweakStat and upgradeInfo.TweakBonus then
		local tweakPercent = math.abs(packet.TweakStat/100);
		
		layerPacket.TweakValue = upgradeInfo.TweakBonus * tweakPercent;
	end
	
	layerPacket.UpgradeInfo = upgradeInfo;
	
	return layerPacket;
end


local Lib = modItemsLibrary.Library;
local function new(b, d)
	b.__index=b;
	modItemsLibrary:Add(setmetatable(d, b));
end;

local modBase = {
	Type = modItemsLibrary.Types.Mod;
	Tradable = modItemsLibrary.Tradable.PremiumOnly;
	NonPremiumTax = 500;
};

local order = 0;
function Add(data)
	if ModsLibrary.Library[data.Id] ~= nil then error("ModulesLibrary>>  Add Id alerady exist for ("..data.Name..")("..data.Id..")"); end;
	if data.Module == nil then error("ModulesLibrary>> Mod ("..data.Name..")("..data.Id..") does not have module attached."); end;
	local description = data.Description or data.Desc;
	
	order = order+1;
	ModsLibrary.List[data.Name] = {
		Id=data.Id;
		Name=data.Name;
		Desc=data.ModDesc or data.Desc;
		--Description=description;
		BaseTier=data.BaseTier or 1;
		Tier=data.BaseTier or 1;
		Icon=data.Icon or "rbxassetid://2635316236";
		Stackable=data.Stackable or false;
		Upgrades=data.Upgrades;
		Type=data.Type;
		Order=order;
		EffectTrigger=data.EffectTrigger;
		Module=data.Module;
		Category=data.Category or "Miscellaneous";
		Layer=data.Layer or 1;

		Element=data.Element;
		Color=data.Color or nil;
		
		ActivationDuration = data.ActivationDuration;
		CooldownDuration = data.CooldownDuration;
		
		GetModule = function(self)
			return self.Module and require(self.Module) or nil;
		end;
	}
	ModsLibrary.Library[data.Id] = ModsLibrary.List[data.Name];
	
	description = description.."\n\n<b>Compatibility:</b> ";
	for a=1, #data.Type do
		description = description..colorStringText(data.Type[a])
		if a ~= #data.Type then
			description = description..", ";
		else
			description = description.."";
		end
	end
	description = description.."\n\n<b>EffectTrigger:</b> "..(data.EffectTrigger == ModsLibrary.EffectTrigger.Passive and colorStringText("Passive") 
		or data.EffectTrigger == ModsLibrary.EffectTrigger.Activate and colorStringText("Activate") or colorStringText("Unknown"));
	
	local stackable = "";
	if typeof(data.Stackable) == "boolean" then
		stackable = colorBoolText(data.Stackable);
	elseif typeof(data.Stackable) == "table" then
		for sKey, sbool in pairs(data.Stackable) do
			stackable = stackable.."\n    - "..colorStringText(sKey)..": ".. colorBoolText(sbool);
		end
	end
	description = description.."\n<b>Mod Stackable:</b> ".. stackable;
	

	new(modBase, {
		Id=data.Id; 
		Name=data.Name; 
		Icon=data.Icon; 
		Description=description;
		Tier=data.Tier;
		Tags = {data.Category};
			--(data.Category == "Rare Mods" and modItemsLibrary.Tradable.PremiumOnly or modItemsLibrary.Tradable.Nontradable);
	});
end

function ModsLibrary.Get(nameOrId)
	return ModsLibrary.List[nameOrId] or ModsLibrary.Library[nameOrId];
end

--== Mod Descriptions;
local Descriptions={
	Damage="Add an additional $Damage of premod damage.";
	FireRate="Increase Fire Rate by $Fire Rate.";
	FireRateRpm="Increase Fire Rate by an additional $Fire Rate Rpm.";
	ReloadSpeed="Decrease Reload Time by $Reload Time.";
	AmmoCap="Increase Ammo Capacity by an additional $Ammo Capacity of the Magazine Size.";
	AmmoMag="Increase Magazine size by $Magazine bullets.";
	HyperDamage="Add an additional $Damage of premod damage and increase Fire Rate by an additional $Fire Rate Rpm.";
	DamageRev="Damage revs up for every shot you have left in your magazine. The last bullet in the magazine will do an additional $Multiplier% damage.";
};

local GenericDescs={
	Damage="Adds <b>Damage</b> based on <b>Premod Damage</b>.";
	FireRateRpm="Adds <b>Rpm</b> to <b>Fire Rate</b>.";
	ReloadSpeed="Reduce <b>Reload Time</b> by a percentage.";
	AmmoCap="Adds <b>Magazine Size</b> to <b>Ammo Capacity</b>.";
	AmmoMag="Adds bullets to <b>Magazine Size</b>.";
	HappyAuto="Adds <b>Magazine Size</b> to <b>Ammo Capacity</b> and switch <b>TriggerMode</b> from <b>Semi-automatic</b> to <b>Full-automatic</b>.";
	
	Skullcracker="Adds multiplier to <b>Headshot Multiplier</b>.";
	Calibre="Shift your weapon's <b>Fire Rate</b> in proportional from <b>DPS</b> towards <b>Damage</b>.";
	CritMulti="Adds multiplier to <b>Crit Multiplier</b> for weapons with existing <b>Crit Chance</b>.";
	
	ShotSplitter="Splits a shot into two by settings <b>Multishot</b> to 2. <b>Damage</b> will be re-scaled to the new ratio and adds <b>Rpm</b> to <b>Fire Rate</b>.";
	Deadeye="Increases aim-down accuracy and recoil control and adds <b>Damage</b> based on <b>Premod Damage</b>.";
	
	RapidFire="Revs up the longer you fire towards max fire rate. Upgrading decreases the rev up time.";
}

--==
local GenericUpgrades = {
	AmmoCapacity={DataTag="AC"; Name="Ammo Capacity"; Syntax="Upgrade Ammo Capacity"; MaxLevel=10; BaseCost=5; MaxCost=50; BaseValue=0.3; MaxValue=3; TweakBonus=1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1;};
}

--== Pistol Mods 1-49;
Add{
	Id="pistoldamagemod";
	Name="Pistol Damage";
	Desc=GenericDescs.Damage;
	Icon="http://www.roblox.com/asset/?id=3817463645";
	BaseTier=1;
	Tier=1;
	Upgrades={	
		{DataTag="D"; Name="Damage"; Syntax="Upgrade Damage"; MaxLevel=10; BaseCost=5; MaxCost=100; BaseValue=0.05; MaxValue=0.5; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1.5;};
	};
	Stackable=true;
	Type={"Pistol"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.Damage;
	Category="Damage Mods";
}

Add{
	Id="pistolfireratemod";
	Name="Pistol Fire Rate";
	Desc=GenericDescs.FireRateRpm;
	Icon="http://www.roblox.com/asset/?id=3817464059";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="FR"; Name="Rpm"; Syntax="Upgrade Fire Rate"; ValueType="Normal"; MaxLevel=10; BaseCost=6; MaxCost=60; BaseValue=10; MaxValue=100; TweakBonus=10; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1.5;};
	};
	Stackable=true;
	Type={"Pistol"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.FireRateRpm;
	Category="Fire Rate Mods";
}

Add{
	Id="pistolreloadspeedmod";
	Name="Pistol Reload Speed";
	Desc=GenericDescs.ReloadSpeed;
	Icon="http://www.roblox.com/asset/?id=3817464922";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="RT"; Name="Reload Speed"; Syntax="Upgrade Reload Speed"; MaxLevel=10; BaseCost=4; MaxCost=50; BaseValue=0.05; MaxValue=0.75; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=false;
	Type={"Pistol"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.ReloadSpeed;
	Category="Reload Speed Mods";
}

Add{
	Id="pistolammocapmod";
	Name="Pistol Ammo Capacity";
	Desc=GenericDescs.AmmoCap;
	Icon="http://www.roblox.com/asset/?id=3817465261";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="AC"; Name="Ammo Capacity"; Syntax="Upgrade Ammo Capacity"; MaxLevel=10; BaseCost=5; MaxCost=50; BaseValue=0.3; MaxValue=3; TweakBonus=1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1;};
	};
	Stackable=true;
	Type={"Pistol"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.AmmoCapacity;
	Category="Ammo Capacity Mods";
}

Add{
	Id="pistolammomagmod";
	Name="Pistol Magazine";
	Desc=GenericDescs.AmmoMag;
	Icon="rbxassetid://3551129663";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="M"; Name="Magazine Size"; Syntax="Upgrade Magazine Size"; ValueType="Normal"; ValueDp=0; MaxLevel=9; BaseCost=3; MaxCost=30; BaseValue=1; MaxValue=10; TweakBonus=10; Scaling=ModsLibrary.ScalingStyle.Linear;};
	};
	Stackable=true;
	Type={"Pistol"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.AmmoMag;
	Category="Rare Mods";
	Layer=0;
}

Add{
	Id="pistolautomod";
	Name="Pistol Automatic Trigger";
	Desc="Switch <b>TriggerMode</b> from <b>Semi-automatic</b> to <b>Full-automatic</b>.";
	Icon="rbxassetid://4523393772";
	BaseTier=1;
	Tier=1;
	Upgrades={};
	Stackable=false;
	Type={"Pistol"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.AutomaticTrigger;
	Category="Rare Mods";
}

Add{
	Id="pistolhappyautomod";
	Name="Pistol Happy Trigger";
	Desc=GenericDescs.HappyAuto;
	Icon="rbxassetid://4573247953";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="AC"; Name="Ammo Capacity"; Syntax="Upgrade Ammo Capacity"; MaxLevel=6; BaseCost=6; MaxCost=60; BaseValue=0.3; MaxValue=2; TweakBonus=1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1;};
	};
	Stackable=true;
	Type={"Pistol"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.HappyTrigger;
	Category="Rare Mods";
}

--== Submachine Gun Mods 50-99;
Add{
	Id="subdamagemod";
	Name="Submachine Gun Damage";
	Desc=GenericDescs.Damage;
	Icon="http://www.roblox.com/asset/?id=3817878750";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="D"; Name="Damage"; Syntax="Upgrade Damage"; MaxLevel=10; BaseCost=5; MaxCost=100; BaseValue=0.05; MaxValue=0.5; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=true;
	Type={"Submachine gun"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.Damage;
	Category="Damage Mods";
}

Add{
	Id="subfireratemod";
	Name="Submachine Gun Fire Rate";
	Desc=GenericDescs.FireRateRpm;
	Icon="http://www.roblox.com/asset/?id=3817879408";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="FR"; Name="Fire Rate"; Syntax="Upgrade Fire Rate"; ValueType="Normal"; MaxLevel=10; BaseCost=8; MaxCost=80; BaseValue=10; MaxValue=200; TweakBonus=10; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1.5;};
	};
	Stackable=true;
	Type={"Submachine gun"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.FireRateRpm;
	Category="Fire Rate Mods";
}

Add{
	Id="subreloadspeedmod";
	Name="Submachine Gun Reload Speed";
	Desc=GenericDescs.ReloadSpeed;
	Icon="http://www.roblox.com/asset/?id=3817880334";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="RT"; Name="Reload Time"; Syntax="Upgrade Reload Speed"; MaxLevel=10; BaseCost=4; MaxCost=40; BaseValue=0.05; MaxValue=0.8; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=false;
	Type={"Submachine gun"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.ReloadSpeed;
	Category="Reload Speed Mods";
}

Add{
	Id="subammocapmod";
	Name="Submachine Gun Ammo Capacity";
	Desc=GenericDescs.AmmoCap;
	Icon="http://www.roblox.com/asset/?id=3817881866";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="AC"; Name="Ammo Capacity"; Syntax="Upgrade Ammo Capacity"; MaxLevel=10; BaseCost=5; MaxCost=50; BaseValue=0.6; MaxValue=5; TweakBonus=1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1;};
	};
	Stackable=true;
	Type={"Submachine gun"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.AmmoCapacity;
	Category="Ammo Capacity Mods";
}

Add{
	Id="subskullcrackmod";
	Name="Submachine Gun Skullcracker";
	Desc=GenericDescs.Skullcracker;
	Icon="http://www.roblox.com/asset/?id=4824432272";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="HSM"; Name="Headshot Multiplier"; Syntax="Upgrade Headshot Multiplier"; ValueType="Normal"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=0.05; MaxValue=3; TweakBonus=2; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=false;
	Type={"Submachine gun"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.Skullcracker;
	Category="Rare Mods";
}

Add{
	Id="subdmgcalibremod";
	Name="Submachine Gun Damage Calibre";
	Desc=GenericDescs.Calibre;
	Icon="http://www.roblox.com/asset/?id=4877050094";
	BaseTier=2;
	Tier=2;
	Upgrades={
		{DataTag="DS"; SliderTag="DSS"; Name="Scaler"; Prefix=""; Syntax="Upgrade Damage Scaler"; MaxLevel=10; BaseCost=7; MaxCost=70; BaseValue=-0.6; MaxValue=0.6; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1;};
	};
	Stackable=false;
	Type={"Submachine gun"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.DamageCalibre;
	Category="Rare Mods";
	--Layer=98;
}

Add{
	Id="smgcritmultimod";
	Name="Submachine Gun Crit Multiplier";
	Desc=GenericDescs.CritMulti;
	Icon="http://www.roblox.com/asset/?id=8536222528";
	BaseTier=4;
	Tier=4;
	Upgrades={
		{DataTag="M"; Name="Multiplier"; Syntax="Upgrade Multiplier"; MaxLevel=10; BaseCost=8; MaxCost=80; BaseValue=0.3; MaxValue=3; TweakBonus=0.5; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=false;
	Type={"Submachine gun"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.CritMulti;
	Category="Rare Mods";
}

Add{
	Id="smgshotsplittermod";
	Name="Submachine Gun Shot Splitter";
	Desc=GenericDescs.ShotSplitter;
	Icon="http://www.roblox.com/asset/?id=8536570855";
	BaseTier=4;
	Tier=4;
	Upgrades={
		{DataTag="D"; Name="Damage"; Syntax="Upgrade Split Damage"; MaxLevel=10; BaseCost=8; MaxCost=80; BaseValue=0.35; MaxValue=0.7; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
		{DataTag="FR"; Name="Fire Rate"; Syntax="Upgrade Fire Rate"; ValueType="Normal"; MaxLevel=10; BaseCost=8; MaxCost=80; BaseValue=5; MaxValue=75; TweakBonus=10; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1.1;};
	};
	Stackable=false;
	Type={"Submachine gun"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.ShotSplitter;
	Category="Rare Mods";
	--Layer=90;
}

Add{
	Id="smgdeadeyemod";
	Name="Submachine Gun Deadeye";
	Desc=GenericDescs.Deadeye;
	Icon="rbxassetid://10418909211";
	BaseTier=4;
	Tier=4;
	Upgrades={
		{DataTag="D"; Name="Damage"; Syntax="Upgrade Damage"; MaxLevel=10; BaseCost=5; MaxCost=100; BaseValue=0.05; MaxValue=0.4; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1.5;}; -- from 8;
		{DataTag="A"; Name="Accuracy"; Syntax="Upgrade Accuracy"; MaxLevel=10; BaseCost=5; MaxCost=50; BaseValue=0.05; MaxValue=0.4; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=true;
	Type={"Submachine gun"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.Deadeye;
	Category="Rare Mods";
}


--== Submachine Gun Mods 100-149;
Add{
	Id="shotgundamagemod";
	Name="Shotgun Damage";
	Desc=GenericDescs.Damage;
	Icon="http://www.roblox.com/asset/?id=3817953044";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="D"; Name="Damage"; Syntax="Upgrade Damage"; MaxLevel=10; BaseCost=5; MaxCost=100; BaseValue=0.05; MaxValue=0.3; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=true;
	Type={"Shotgun"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.Damage;
	Category="Damage Mods";
}

Add{
	Id="shotgunfireratemod";
	Name="Shotgun Fire Rate";
	Desc=GenericDescs.FireRateRpm;
	Icon="http://www.roblox.com/asset/?id=3817953548";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="FR"; Name="Fire Rate"; Syntax="Upgrade Fire Rate"; ValueType="Normal"; MaxLevel=10; BaseCost=8; MaxCost=80; BaseValue=10; MaxValue=100; TweakBonus=10; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1.5;};
	};
	Stackable=true;
	Type={"Shotgun"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.FireRateRpm;
	Category="Fire Rate Mods";
}

Add{
	Id="shotgunreloadspeedmod";
	Name="Shotgun Reload Speed";
	Desc=GenericDescs.ReloadSpeed;
	Icon="http://www.roblox.com/asset/?id=3817954242";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="RT"; Name="Reload Time"; Syntax="Upgrade Reload Speed"; MaxLevel=10; BaseCost=4; MaxCost=40; BaseValue=0.05; MaxValue=0.5; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=false;
	Type={"Shotgun"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.ReloadSpeed;
	Category="Reload Speed Mods";
}

Add{
	Id="shotgunammocapmod";
	Name="Shotgun Ammo Capacity";
	Desc=GenericDescs.AmmoCap;
	Icon="http://www.roblox.com/asset/?id=3817953877";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="AC"; Name="Ammo Capacity"; Syntax="Upgrade Ammo Capacity"; MaxLevel=10; BaseCost=5; MaxCost=50; BaseValue=0.3; MaxValue=4; TweakBonus=1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1;};
	};
	Stackable=true;
	Type={"Shotgun"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.AmmoCapacity;
	Category="Ammo Capacity Mods";
}

Add{
	Id="shotgunautomod";
	Name="Shotgun Automatic Trigger";
	Desc="Switch <b>TriggerMode</b> from <b>Semi-automatic</b> to <b>Full-automatic</b>.";
	Icon="rbxassetid://4523393970";
	BaseTier=2;
	Tier=2;
	Upgrades={
		
	};
	Stackable=false;
	Type={"Shotgun"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.AutomaticTrigger;
	Category="Rare Mods";
}

Add{
	Id="shotgunhappyautomod";
	Name="Shotgun Happy Trigger";
	Desc=GenericDescs.HappyAuto;
	Icon="http://www.roblox.com/asset/?id=8574475833";
	BaseTier=2;
	Tier=2;
	Upgrades={
		{DataTag="AC"; Name="Ammo Capacity"; Syntax="Upgrade Ammo Capacity"; MaxLevel=6; BaseCost=6; MaxCost=60; BaseValue=0.3; MaxValue=1; TweakBonus=1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1;};
	};
	Stackable=true;
	Type={"Shotgun"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.HappyTrigger;
	Category="Rare Mods";
}

Add{
	Id="shotgunslugmod";
	Name="Shotgun Slug Rounds";
	Desc="Increases accuracy by 80% and set multishot to 3 plus an additional <b>Piercing</b>. <b>Damage</b> is rescaled to (Base max multishot)/3.";
	Icon="http://www.roblox.com/asset/?id=5045673615";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="P"; Name="Piercing"; Syntax="Add Piercing"; ValueType="Normal"; MaxLevel=1; BaseCost=20; MaxCost=20; BaseValue=0; MaxValue=1; TweakBonus=1; Scaling=ModsLibrary.ScalingStyle.Linear;};
	};
	Stackable=false;
	Type={"Shotgun"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.SlugRounds;
	Category="Rare Mods";
	Layer=99;
}

Add{
	Id="shotgundualshellmod";
	Name="Shotgun Dual Shell";
	Desc="Reloads two shell each time and decreases <b>Reload Time</b>.";
	Icon="rbxassetid://10415756787";
	BaseTier=2;
	Tier=2;
	Upgrades={
		{DataTag="RT"; Name="Reload Time"; Syntax="Upgrade Reload Speed"; MaxLevel=10; BaseCost=6; MaxCost=60; BaseValue=0.05; MaxValue=0.35; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=true;
	Type={"Shotgun"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.DualShell;
	Category="Rare Mods";
}

Add{
	Id="shotgundeadeyemod";
	Name="Shotgun Deadeye";
	Desc=GenericDescs.Deadeye;
	Icon="rbxassetid://10418754859";
	BaseTier=4;
	Tier=4;
	Upgrades={
		{DataTag="D"; Name="Damage"; Syntax="Upgrade Damage"; MaxLevel=10; BaseCost=5; MaxCost=100; BaseValue=0.05; MaxValue=0.2; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
		{DataTag="A"; Name="Accuracy"; Syntax="Upgrade Accuracy"; MaxLevel=10; BaseCost=5; MaxCost=50; BaseValue=0.05; MaxValue=0.9; TweakBonus=0.05; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=true;
	Type={"Shotgun"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.Deadeye;
	Category="Rare Mods";
}

--== Rifle Mods 150 - 199;
Add{
	Id="rifledamagemod";
	Name="Rifle Damage";
	Desc=GenericDescs.Damage;
	Icon="http://www.roblox.com/asset/?id=3817984835";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="D"; Name="Damage"; Syntax="Upgrade Damage"; MaxLevel=10; BaseCost=6; MaxCost=110; BaseValue=0.05; MaxValue=0.3; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=true;
	Type={"Rifle"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.Damage;
	Category="Damage Mods";
}

Add{
	Id="riflefireratemod";
	Name="Rifle Fire Rate";
	Desc=GenericDescs.FireRateRpm;
	Icon="http://www.roblox.com/asset/?id=3817985194";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="FR"; Name="Fire Rate"; Syntax="Upgrade Fire Rate"; ValueType="Normal"; MaxLevel=10; BaseCost=8; MaxCost=80; BaseValue=10; MaxValue=100; TweakBonus=10; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1.5;};
	};
	Stackable=true;
	Type={"Rifle"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.FireRateRpm;
	Category="Fire Rate Mods";
}

Add{
	Id="riflereloadspeedmod";
	Name="Rifle Reload Speed";
	Desc=GenericDescs.ReloadSpeed;
	Icon="http://www.roblox.com/asset/?id=3817985921";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="RT"; Name="Reload Time"; Syntax="Upgrade Reload Speed"; MaxLevel=10; BaseCost=4; MaxCost=40; BaseValue=0.05; MaxValue=0.8; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=false;
	Type={"Rifle"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.ReloadSpeed;
	Category="Reload Speed Mods";
}

Add{
	Id="rifleammocapmod";
	Name="Rifle Ammo Capacity";
	Desc=GenericDescs.AmmoCap;
	Icon="http://www.roblox.com/asset/?id=3817985587";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="AC"; Name="Ammo Capacity"; Syntax="Upgrade Ammo Capacity"; MaxLevel=10; BaseCost=5; MaxCost=50; BaseValue=0.6; MaxValue=5; TweakBonus=1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1;};
	};
	Stackable=true;
	Type={"Rifle"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.AmmoCapacity;
	Category="Ammo Capacity Mods";
}

Add{
	Id="riflehyperdamagemod";
	Name="Rifle Hyper Damage";
	Desc=Descriptions.HyperDamage;
	Icon="http://www.roblox.com/asset/?id=4535696304";
	BaseTier=2;
	Tier=2;
	Upgrades={
		{DataTag="D"; Name="Damage"; Syntax="Upgrade Damage"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=0.05; MaxValue=0.25; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
		{DataTag="FR"; Name="Fire Rate"; Syntax="Upgrade Fire Rate"; ValueType="Normal"; MaxLevel=10; BaseCost=7; MaxCost=70; BaseValue=10; MaxValue=75; TweakBonus=10; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1.5;};
	};
	Stackable=false;
	Type={"Rifle"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.HyperDamage;
	Category="Rare Mods";
}

Add{
	Id="rifledmgcalibremod";
	Name="Rifle Damage Calibre";
	Desc=GenericDescs.Calibre;
	Icon="http://www.roblox.com/asset/?id=4877039158";
	BaseTier=2;
	Tier=2;
	Upgrades={
		{DataTag="DS"; SliderTag="DSS"; Name="Scaler"; Prefix=""; Syntax="Upgrade Damage Scaler"; MaxLevel=10; BaseCost=7; MaxCost=70; BaseValue=-0.5; MaxValue=0.5; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1;};
	};
	Stackable=false;
	Type={"Rifle"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.DamageCalibre;
	Category="Rare Mods";
}

Add{
	Id="rifledmgrevmod";
	Name="Rifle Damage Rev";
	Desc=Descriptions.DamageRev;
	Icon="http://www.roblox.com/asset/?id=6840144110";
	BaseTier=3;
	Tier=3;
	Upgrades={
		{DataTag="M"; Name="Multiplier"; Syntax="Upgrade Multiplier"; MaxLevel=10; BaseCost=15; MaxCost=150; BaseValue=0.1; MaxValue=3; TweakBonus=1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=false;
	Type={"Rifle"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.DamageRev;
	Category="Rare Mods";
}

Add{
	Id="riflecritmultimod";
	Name="Rifle Crit Multiplier";
	Desc=GenericDescs.CritMulti;
	Icon="http://www.roblox.com/asset/?id=7114254004";
	BaseTier=3;
	Tier=3;
	Upgrades={
		{DataTag="M"; Name="Multiplier"; Syntax="Upgrade Multiplier"; MaxLevel=10; BaseCost=8; MaxCost=80; BaseValue=0.3; MaxValue=3; TweakBonus=1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=false;
	Type={"Rifle"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.CritMulti;
	Category="Rare Mods";
}

--== Sniper 200 - 249;
Add{
	Id="sniperdamagemod";
	Name="Sniper Damage";
	Desc=GenericDescs.Damage;
	Icon="http://www.roblox.com/asset/?id=3818018813";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="D"; Name="Damage"; Syntax="Upgrade Damage"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=0.05; MaxValue=0.2; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=true;
	Type={"Sniper"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.Damage;
	Category="Damage Mods";
}

Add{
	Id="sniperfireratemod";
	Name="Sniper Fire Rate";
	Desc=GenericDescs.FireRateRpm;
	Icon="http://www.roblox.com/asset/?id=3818019324";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="FR"; Name="Fire Rate"; Syntax="Upgrade Fire Rate"; ValueType="Normal"; MaxLevel=10; BaseCost=8; MaxCost=80; BaseValue=5; MaxValue=50; TweakBonus=10; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1.5;};
	};
	Stackable=true;
	Type={"Sniper"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.FireRateRpm;
	Category="Fire Rate Mods";
}

Add{
	Id="sniperammocapmod";
	Name="Sniper Ammo Capacity";
	Desc=GenericDescs.AmmoCap;
	Icon="http://www.roblox.com/asset/?id=4483536988";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="AC"; Name="Ammo Capacity"; Syntax="Upgrade Ammo Capacity"; MaxLevel=10; BaseCost=5; MaxCost=50; BaseValue=0.1; MaxValue=2; TweakBonus=1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1;};
	};
	Stackable=true;
	Type={"Sniper"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.AmmoCapacity;
	Category="Ammo Capacity Mods";
}

Add{
	Id="sniperpiercingmod";
	Name="Sniper Piercing Bullets";
	Desc="Adds <b>Piercing</b> to pierce through enemies, every next enemy pierced will do 75% of the damage.";
	Icon="http://www.roblox.com/asset/?id=4523408866";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="PB"; Name="Piercing"; Syntax="Upgrade Piercing"; ValueType="Normal"; MaxLevel=5; BaseCost=10; MaxCost=50; BaseValue=0; MaxValue=5; TweakBonus=1; Scaling=ModsLibrary.ScalingStyle.Linear;};
	};
	Stackable=false;
	Type={"Sniper"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.PiercingBullets;
	Category="Rare Mods";
}

Add{
	Id="sniperskullcrackmod";
	Name="Sniper Skullcracker";
	Desc=GenericDescs.Skullcracker;
	Icon="http://www.roblox.com/asset/?id=4824432451";
	BaseTier=2;
	Tier=2;
	Upgrades={
		{DataTag="HSM"; Name="Headshot Multiplier"; Syntax="Upgrade Headshot Multiplier"; ValueType="Normal"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=0.05; MaxValue=2; TweakBonus=0.5; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=false;
	Type={"Sniper"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.Skullcracker;
	Category="Rare Mods";
}

Add{
	Id="sniperdmgrevmod";
	Name="Sniper Damage Rev";
	Desc=Descriptions.DamageRev;
	Icon="http://www.roblox.com/asset/?id=6840236859";
	BaseTier=2;
	Tier=2;
	Upgrades={
		{DataTag="M"; Name="Multiplier"; Syntax="Upgrade Multiplier"; MaxLevel=10; BaseCost=15; MaxCost=150; BaseValue=0.2; MaxValue=2; TweakBonus=0.5; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=false;
	Type={"Sniper"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.DamageRev;
	Category="Rare Mods";
}

Add{
	Id="sniperfocusrate";
	Name="Focus Rate";
	Desc="Decrease the time to focus by reducing <b>Focus Time</b>.";
	Icon="rbxassetid://4404542465";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="SF"; Name="Focus Rate"; Syntax="Upgrade Focus Rate"; MaxLevel=10; BaseCost=5; MaxCost=30; BaseValue=0.4; MaxValue=0.8; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=false;
	Type={"Sniper"; "Bow"; "Pistol"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.SniperFocusRate;
	Category="Rare Mods";
}

--== Heavy machine gun 250 - 299;
Add{
	Id="hmgdamagemod";
	Name="Heavy Machine Gun Damage";
	Desc=GenericDescs.Damage;
	Icon="http://www.roblox.com/asset/?id=6468998591";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="D"; Name="Damage"; Syntax="Upgrade Damage"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=0.05; MaxValue=0.5; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=true;
	Type={"Heavy machine gun"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.Damage;
	Category="Damage Mods";
}

Add{
	Id="hmgreloadspeedmod";
	Name="Heavy Machine Gun Reload Speed";
	Desc=GenericDescs.ReloadSpeed;
	Icon="http://www.roblox.com/asset/?id=3818054442";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="RT"; Name="Reload Time"; Syntax="Upgrade Reload Speed"; MaxLevel=10; BaseCost=2; MaxCost=20; BaseValue=0.05; MaxValue=0.5; TweakBonus=0.2; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=false;
	Type={"Heavy machine gun"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.ReloadSpeed;
	Category="Reload Speed Mods";
}

Add{
	Id="hmgammocapmod";
	Name="Heavy Machine Gun Ammo Capacity";
	Desc=GenericDescs.AmmoCap;
	Icon="http://www.roblox.com/asset/?id=3818054835";
	BaseTier=1;
	Tier=1;
	Upgrades={
		GenericUpgrades.AmmoCapacity;
	};
	Stackable=true;
	Type={"Heavy machine gun"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.AmmoCapacity;
	Category="Ammo Capacity Mods";
}

Add{
	Id="hmgrapidfiremod";
	Name="Heavy Machine Gun Rapidfire";
	Desc=GenericDescs.RapidFire;
	Icon="http://www.roblox.com/asset/?id=4979262584";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="RFR"; Name="Rev Up Rate"; Syntax="Increase Rate"; MaxLevel=10; BaseCost=12; MaxCost=120; BaseValue=0.1; MaxValue=0.8; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=false;
	Type={"Heavy machine gun"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.RapidFire;
	Category="Rare Mods";
}


--== Pyrotechnic;
Add{
	Id="pyrodamagemod";
	Name="Pyrotechnic Damage";
	Desc=GenericDescs.Damage;
	Icon="http://www.roblox.com/asset/?id=3818084053";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="D"; Name="Damage"; Syntax="Upgrade Damage"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=0; MaxValue=0.3; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=true;
	Type={"Pyrotechnic"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.Damage;
	Category="Damage Mods";
}

Add{
	Id="pyroammocapmod";
	Name="Pyrotechnic Ammo Capacity";
	Desc=GenericDescs.AmmoCap;
	Icon="http://www.roblox.com/asset/?id=4535764993";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="AC"; Name="Ammo Capacity"; Syntax="Upgrade Ammo Capacity"; MaxLevel=10; BaseCost=5; MaxCost=50; BaseValue=0.6; MaxValue=2; TweakBonus=1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1;};
	};
	Stackable=true;
	Type={"Pyrotechnic"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.AmmoCapacity;
	Category="Ammo Capacity Mods";
}

Add{
	Id="pyroeverlastmod";
	Name="Pyrotechnic Everlast";
	Desc="Increase burning duration of lingering flames while increasing ammo cost per shot.";
	Icon="http://www.roblox.com/asset/?id=4938813087";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="BD"; Name="Duration"; Syntax="Increase Duration"; ValueType="Normal"; Suffix="s"; MaxLevel=9; BaseCost=9; MaxCost=90; BaseValue=3; MaxValue=30; TweakBonus=10; Scaling=ModsLibrary.ScalingStyle.Linear;};
	};
	Stackable=true;
	Type={"Pyrotechnic"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.PyroEverlast;
	Category="Rare Mods";
	Layer=99;
}

Add{
	Id="flamethrowerflameburstmod";
	Name="Flamethrower Flame Burst";
	Desc="Converts projectile from liquid flame to gas flame. Increases multi shot to <b>3, x4 impact damage, x0.5 burn tick damage</b>. Burn time last for 25 seconds and can be extended with <b>Everlast</b>.";
	Icon="http://www.roblox.com/asset/?id=14286986692";
	BaseTier=1;
	Tier=1;
	Upgrades={
	};
	Stackable=false;
	Type={"Flamethrower"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.Flameburst;
	Category="Rare Mods";
}

--== Explosive;
Add{
	Id="explosivedamagemod";
	Name="Explosive Damage";
	Desc=GenericDescs.Damage;
	Icon="http://www.roblox.com/asset/?id=3818101661";
	BaseTier=2;
	Tier=2;
	Upgrades={
		{DataTag="D"; Name="Damage"; Syntax="Upgrade Damage"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=0.1; MaxValue=0.2; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=true;
	Type={"Explosive"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.Damage;
	Category="Damage Mods";
}

Add{
	Id="explosiveammocapmod";
	Name="Explosive Ammo Capacity";
	Desc="Adds <b>Ammo Capacity</b> based on <b>Premod Ammo Capacity</b>.";
	Icon="http://www.roblox.com/asset/?id=4535765280";
	BaseTier=2;
	Tier=2;
	Upgrades={
		{DataTag="AC"; Name="Ammo Capacity"; Syntax="Upgrade Ammo Capacity"; MaxLevel=10; BaseCost=5; MaxCost=50; BaseValue=0.3; MaxValue=1.5; TweakBonus=0.5; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1;};
	};
	Stackable=true;
	Type={"Explosive"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.AmmoCapacityPremod;
	Category="Ammo Capacity Mods";
}

Add{
	Id="explosiveradiusmod";
	Name="Explosive Radius";
	Desc="Increase explosion range by adding radius to <b>Explosion Radius</b>.";
	Icon="http://www.roblox.com/asset/?id=6839719422";
	BaseTier=2;
	Tier=2;
	Upgrades={
		{DataTag="R"; Name="Radius"; Syntax="Upgrade Radius"; ValueType="Normal"; MaxLevel=8; BaseCost=9; MaxCost=90; BaseValue=1; MaxValue=9; TweakBonus=5; Scaling=ModsLibrary.ScalingStyle.Linear;};
	};
	Stackable=true;
	Type={"Explosive"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.ExplosiveRadius;
	Category="Rare Mods";
}

Add{
	Id="rocketmanmod";
	Name="Rocketman";
	Desc="While player is in the air, reload time is reduced to zero. Adds <b>Rpm</b> to <b>Fire Rate</b>.";
	Icon="http://www.roblox.com/asset/?id=12505260876";
	BaseTier=3;
	Tier=3;
	Upgrades={
		{DataTag="FR"; Name="Rpm"; Syntax="Upgrade Fire Rate"; ValueType="Normal"; MaxLevel=10; BaseCost=6; MaxCost=60; BaseValue=10; MaxValue=120; TweakBonus=10; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1.5;};
	};
	Stackable=false;
	Type={"Rocket"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.Rocketman;
	Category="Rare Mods";
}

--== Bow;
Add{
	Id="bowdamagemod";
	Name="Bow Damage";
	Desc=GenericDescs.Damage;
	Icon="http://www.roblox.com/asset/?id=5525819158";
	BaseTier=3;
	Tier=3;
	Upgrades={
		{DataTag="D"; Name="Damage"; Syntax="Upgrade Damage"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=0.05; MaxValue=0.2; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1.5;};
	};
	Stackable=true;
	Type={"Bow"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.Damage;
	Category="Damage Mods";
}

Add{
	Id="bowammocapmod";
	Name="Bow Ammo Capacity";
	Desc="Adds <b>Ammo Capacity</b> based on <b>Premod Ammo Capacity</b>.";
	Icon="http://www.roblox.com/asset/?id=5525831865";
	BaseTier=3;
	Tier=3;
	Upgrades={
		{DataTag="AC"; Name="Ammo Capacity"; Syntax="Upgrade Ammo Capacity"; MaxLevel=10; BaseCost=5; MaxCost=50; BaseValue=0.3; MaxValue=1.5; TweakBonus=0.5; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1;};
	};
	Stackable=true;
	Type={"Bow"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.AmmoCapacityPremod;
	Category="Ammo Capacity Mods";
}

Add{
	Id="bowricochetmod";
	Name="Bow Ricochet";
	Desc="Ricochets an arrow to an enemy within <b>Radius</b> on impact.";
	Icon="http://www.roblox.com/asset/?id=5539240457";
	BaseTier=3;
	Tier=3;
	Upgrades={
		{DataTag="R"; Name="Radius"; Syntax="Increase Scan Radius"; ValueType="Normal"; MaxLevel=8; BaseCost=10; MaxCost=100; BaseValue=16; MaxValue=64; TweakBonus=6; Scaling=ModsLibrary.ScalingStyle.Linear;};
	};
	Stackable=false;
	Type={"Bow"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.BowRicochet;
	Category="Rare Mods";
}

--== Bolt mods;
Add{
	Id="bowdeadweightmod";
	Name="Bow Deadweight";
	Desc="Allows projectiles to pierce enemies at the cost of projectile speed. Also adds <b>Damage</b> based on <b>Premod Damage</b>.";
	Icon="http://www.roblox.com/asset/?id=13257333197";
	BaseTier=2;
	Tier=2;
	Upgrades={
		{DataTag="D"; Name="Damage"; Syntax="Upgrade Damage"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=0.03; MaxValue=0.25; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
		{DataTag="W"; Name="Piercing"; Syntax="Increase Piercing"; ValueType="Normal"; MaxLevel=7; BaseCost=10; MaxCost=100; BaseValue=1; MaxValue=8; TweakBonus=1; Scaling=ModsLibrary.ScalingStyle.Linear;};
	};
	Stackable=false;
	Type={"Bow"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.BowDeadweight;
	Category="Rare Mods";
}


--== Launcher mods;
Add{
	Id="launchertriplethreatmod";
	Name="Launcher Triple Threat";
	Desc="Fires 3 projectiles at a time and decrease <b>Reload Time</b>.";
	Icon="http://www.roblox.com/asset/?id=13265424603";
	BaseTier=2;
	Tier=2;
	Upgrades={
		{DataTag="RT"; Name="Reload Time"; Syntax="Upgrade Reload Speed"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=0.05; MaxValue=0.5; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=false;
	Type={"Launcher"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.LauncherTriplethreat;
	Category="Rare Mods";
}


--== Generic Rare mods;
Add{
	Id="ammorecyclermod";
	Name="Ammo Recycler";
	Desc="Chance to recover ammo into reserve if your damage exceeds enemy's max health.";
	Icon="rbxassetid://13787902901";
	BaseTier=2;
	Tier=2;
	Upgrades={
		{DataTag="C"; Name="Chance"; Syntax="Upgrade Chance"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=0.2; MaxValue=0.7; TweakBonus=0.05; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=1;};
	};
	Stackable=false;
	Type={"Sniper"; "Bow"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.AmmoRecycler;
	Category="Rare Mods";
}

--== Elementals Mods 500-599;
Add{
	Id="incendiarymod";
	Name="Incendiary Rounds";
	Desc="Ignites enemies and deal an additional <b>Damage</b> + <b>1% of their current health</b> as fire damage. Burn ticks every 0.5s over the duration.";
	Icon="rbxassetid://3576196270";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="D"; Name="Flat Damage"; Syntax="Upgrade Damage"; ValueType="Normal"; MaxLevel=10; BaseCost=20; MaxCost=200; BaseValue=5; MaxValue=100; TweakBonus=20; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
		{DataTag="T"; Name="Duration"; Syntax="Upgrade Duration"; ValueType="Normal"; Suffix="s"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=5; MaxValue=25; TweakBonus=5; Scaling=ModsLibrary.ScalingStyle.Linear;};
	};
	Stackable=false;
	Type={"Pistol"; "Submachine gun"; "Shotgun"; "Rifle"; "Sniper"; "Heavy machine gun"; "Bow";};
	
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	ActivationDuration=60;
	CooldownDuration=120;
	
	Module=script.FlameMod;
	Category="Elemental Mods";
	
	Element="Fire";
	Color=Color3.fromRGB(131, 0, 0);
}

Add{
	Id="electricmod";
	Name="Electric Charge";
	Desc="Electrocute nearby enemies and deal an additional <b>Damage</b> based on the weapon's <b>Premod Damage</b> as electric damage.";
	Icon="rbxassetid://3576196956";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="D"; Name="Damage"; Syntax="Upgrade Damage Percent"; MaxLevel=10; BaseCost=20; MaxCost=200; BaseValue=0.1; MaxValue=0.75; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
		{DataTag="T"; Name="Targets"; Syntax="Increase Targets"; ValueType="Normal"; MaxLevel=5; BaseCost=10; MaxCost=100; BaseValue=1; MaxValue=6; Scaling=ModsLibrary.ScalingStyle.Linear;};
	};
	Stackable=false;
	Type={"Pistol"; "Submachine gun"; "Shotgun"; "Rifle"; "Sniper"; "Heavy machine gun"; "Bow";};

	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	ActivationDuration=10;
	CooldownDuration=30;

	Module=script.ElectricMod;
	Category="Elemental Mods";

	Element="Electricity";
	Color=Color3.fromRGB(255, 238, 0);
}

--Add{
--	Id="frostmod";
--	Name="Frostbite";
--	Desc="Enemies affected by frostbite dropped below 10% of their health will shatter and die. Slow enemies and applies a stack of frost and every stack adds more slow. On the 5th stack, the enemy will be stunned for the duration, duration may depend on enemies' stun resistance.";
--	Icon="rbxassetid://3576197517";
--	Tier=1;
--	Upgrades={
--		{DataTag="S"; Name="Slow"; Syntax="Increase Slowness"; MaxLevel=10; BaseCost=20; MaxCost=200; BaseValue=0.2; MaxValue=0.9; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
--		{DataTag="T"; Name="Duration"; Syntax="Increase Duration"; ValueType="Normal"; Suffix="s"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=2; MaxValue=30; TweakBonus=10; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
--	};
--	Stackable=false;
--	Type={"Pistol"; "Submachine gun"; "Shotgun"; "Rifle"; "Sniper"; "Heavy machine gun"; "Bow";};
	
--	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
--	ActivationDuration=60;
--	CooldownDuration=30;
	
--	Module=script.FrostMod;
--	Category="Elemental Mods";
--	Layer=199;

--	Element="Ice";
--	Color=Color3.fromRGB(0, 213, 255); 
--}
Add{
	Id="frostmod";
	Name="Frostbite";
	Desc="Continuous firing will <b>Freeze</b> enemies and causes an <b>Ice Blast</b> freezing nearby enemies. <b>Frostbitten</b> enemies will shatter if dropped below a theshold of max health.";
	ModDesc=[[
	Continuous firing at enemies will slow and <b>Freeze</b> them for 5 seconds and causes an <b>Ice Blast</b>.
	
	<b>Ice Blast</b>
		Area of effect explosion that freezes <b>Targets</b> within the <b>Radius</b> and apply <b>Frostbitten</b> to each enemy.
		
	<b>Frostbitten</b>
		Take weapon damage as frost damage twice per second and when enemies dropped below 10% of max health will instantly shatter and die.
	]];
	Icon="rbxassetid://3576197517";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="S"; Name="Radius"; Syntax="Increase Radius"; ValueType="Normal"; MaxLevel=7; BaseCost=10; MaxCost=100; BaseValue=1; MaxValue=15; TweakBonus=8; Scaling=ModsLibrary.ScalingStyle.Linear;};
		{DataTag="T"; Name="Targets"; Syntax="Increase Targets"; ValueType="Normal"; MaxLevel=7; BaseCost=10; MaxCost=100; BaseValue=1; MaxValue=8; TweakBonus=2; Scaling=ModsLibrary.ScalingStyle.Linear;};
	};
	Stackable=false;
	Type={"Pistol"; "Submachine gun"; "Shotgun"; "Rifle"; "Sniper"; "Heavy machine gun"; "Bow";};

	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	ActivationDuration=60;
	CooldownDuration=30;

	Module=script.FrostMod;
	Category="Elemental Mods";
	Layer=199;

	Element="Ice";
	Color=Color3.fromRGB(0, 213, 255); 
}

Add{
	Id="toxicmod";
	Name="Toxic Barrage";
	Desc="Reduce enemies' immunity and regeneration for the duration. If enemies' immunity drops below 0%, additional toxic damage is dealt.";
	Icon="rbxassetid://3576387976";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="R"; Name="Reduction"; Syntax="Increase Reduction"; MaxLevel=10; BaseCost=20; MaxCost=200; BaseValue=0.05; MaxValue=0.75; TweakBonus=0.1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
		{DataTag="T"; Name="Duration"; Syntax="Increase Duration"; ValueType="Normal"; Suffix="s"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=3; MaxValue=30; TweakBonus=10; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=false;
	Type={"Pistol"; "Submachine gun"; "Shotgun"; "Rifle"; "Sniper"; "Heavy machine gun"; "Bow";};
	
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	ActivationDuration=10;
	CooldownDuration=30;
	
	Module=script.ToxicMod;
	Category="Elemental Mods";
	
	Element="Toxic";
	Color=Color3.fromRGB(140, 255, 83); 
}



--== Melee Mods;
--== Edge Melee Mods;
Add{
	Id="edgeddamagemod";
	Name="Edged Melee Damage";
	Desc=GenericDescs.Damage;
	Icon="http://www.roblox.com/asset/?id=4978991305";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="D"; Name="Damage"; Syntax="Upgrade Damage"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=0.1; MaxValue=5; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=true;
	Type={"Edged Melee"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	
	Module=script.MeleeDamage;
	Category="Damage Mods";
};

--== Blunt Melee Mods;
Add{
	Id="bluntdamagemod";
	Name="Blunt Melee Damage";
	Desc=GenericDescs.Damage;
	Icon="http://www.roblox.com/asset/?id=5125066228";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="D"; Name="Damage"; Syntax="Upgrade Damage"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=0.1; MaxValue=5; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=true;
	Type={"Blunt Melee"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.MeleeDamage;
	Category="Damage Mods";
};

Add{
	Id="bluntknockbackmod";
	Name="Blunt Melee Knockback";
	Desc="Add an additional knockback strength.";
	Icon="http://www.roblox.com/asset/?id=5125105974";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="KB"; Name="Knockback"; Syntax="Upgrade Knockback"; MaxLevel=10; BaseCost=6; MaxCost=60; BaseValue=0.1; MaxValue=1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=true;
	Type={"Blunt Melee"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.MeleeKnockback;
	Category="Rare Mods";
};

--== Pointed Melee Mods;
Add{
	Id="pointdamagemod";
	Name="Point Melee Damage";
	Desc=GenericDescs.Damage;
	Icon="http://www.roblox.com/asset/?id=5766679499";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="D"; Name="Damage"; Syntax="Upgrade Damage"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=0.1; MaxValue=5; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=true;
	Type={"Pointed Melee"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.MeleeDamage;
	Category="Damage Mods";
};



--Add{
--	Id="edgedcostmod";
--	Name="Edged Melee Stamina Cost";
--	Desc="";
--	Icon="http://www.roblox.com/asset/?id=4978532013";
--	Tier=1;
--	Upgrades={
--		{DataTag="D"; Name="Damage"; Syntax="Upgrade Damage"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=0.1; MaxValue=5; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
--	};
--	Stackable=true;
--	Type={"Edged Melee"};
--	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
--	Module=script.MeleeDamage;
--	Category="Damage Mods";
--};




--== Clothing Mods;
--== Utility Wear Mods;
Add{
	Id="beltslotsmod";
	Name="Hot Slots";
	Desc="Increase hotbar slots.";
	Icon="http://www.roblox.com/asset/?id=5627217226";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="S"; Name="Slots"; Syntax="Increase Slots"; ValueType="Normal"; MaxLevel=2; BaseCost=5; MaxCost=50; BaseValue=1; MaxValue=3; Scaling=ModsLibrary.ScalingStyle.Linear;};
	};
	Stackable=false;
	Type={"Utility Wear"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.BeltSlots;
	Category="Rare Mods";
}


--== Chest Mods;
Add{
	Id="armorpointsmod";
	Name="Chest Armor Points";
	Desc="Increase max armor points.";
	Icon="rbxassetid://16078917792";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="AP"; Name="Armor Points"; Syntax="Upgrade Armor"; ValueType="Normal"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=10; MaxValue=50; Scaling=ModsLibrary.ScalingStyle.Linear;};
	};
	Stackable={
		["Armor Mods"]=false;
	};
	Type={"Chest"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.ArmorPoints;
	Category="Armor Mods";
}

Add{
	Id="thornmod";
	Name="Chest Thorn Plating";
	Desc="When taking melee damage, attacker takes reflected damage based on a percent of their health. Reflected damage only affects basic enemeis. Minimum reflected damage is 10.";
	Icon="http://www.roblox.com/asset/?id=5720010211";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="R"; Name="Reflected Percent"; Syntax="Upgrade Percent"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=0.1; MaxValue=0.7; TweakBonus=0.05; Scaling=ModsLibrary.ScalingStyle.NaturalCurve; Rate=2;};
	};
	Stackable=false;
	Type={"Chest"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.ThornPlating;
	Category="Rare Mods";
};

Add{
	Id="healthmod";
	Name="Chest Health Points";
	Desc="Increase max health.";
	Icon="rbxassetid://16078919527";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="HP"; Name="Health Points"; Syntax="Increase Health"; ValueType="Normal"; MaxLevel=9; BaseCost=10; MaxCost=100; BaseValue=5; MaxValue=50; Scaling=ModsLibrary.ScalingStyle.Linear;};
	};
	Stackable={
		["Health Mods"]=false;
	};
	Type={"Chest"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.HealthPoints;
	Category="Health Mods";
}

Add{
	Id="nekrosampmod";
	Name="Nekrosis Amplifier";
	Desc="Increase <b>Nekrosis Heal</b> by a percentage to Nekrosis effect and Ziphoning Heal."; 
	Icon="rbxassetid://16045442080";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="A"; Name="Amplifier"; Syntax="Upgrade"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=0.1; MaxValue=1; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;Rate=1.1;};
	};
	Stackable=false;
	Type={"Chest"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.NekrosisAmp;
	Category="Rare Mods";
};

Add{
	Id="pacifistamuletmod";
	Name="Pacifist's Amulet";
	Desc="<b>Pacifists & Warmongers</b>\nWhen equipping healing or food items, you gain temporary armor rate and armor points."; 
	Icon="rbxassetid://16049397225";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="AP"; Name="Armor Points"; Syntax="Upgrade Armor Points"; ValueType="Normal"; Suffix="AP"; MaxLevel=5; BaseCost=10; MaxCost=100; BaseValue=0; MaxValue=100; Scaling=ModsLibrary.ScalingStyle.Linear;};
		{DataTag="AR"; Name="Armor Rate"; Syntax="Upgrade Armor Rate"; ValueType="Normal"; MaxLevel=5; Suffix="ap/s"; BaseCost=10; MaxCost=100; BaseValue=0; MaxValue=10; Scaling=ModsLibrary.ScalingStyle.Linear;};
	};
	Stackable={
		["Armor Mods"]=false;
		["Pacifists & Warmongers"]=false;
	};
	Type={"Chest"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.PacifistAmulet;
	Category="Armor Mods";
};

Add{
	Id="warmongerscalesmod";
	Name="Warmonger's Scales";
	Desc="<b>Pacifists & Warmongers</b>\nFor every percent damaged, temporary increases max health. Heals only if health pool was newly increased.";
	Icon="rbxassetid://16084490297";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="HPK"; Name="Health Per Kill"; Syntax="Increase Health Per Kill"; ValueType="Normal"; MaxLevel=5; BaseCost=10; MaxCost=100; BaseValue=0; MaxValue=10; Scaling=ModsLibrary.ScalingStyle.Linear;};
		{DataTag="HP"; Name="Max Health"; Syntax="Increase Max Health"; ValueType="Normal"; MaxLevel=5; BaseCost=10; MaxCost=100; BaseValue=0; MaxValue=100; Scaling=ModsLibrary.ScalingStyle.Linear;};
	};
	Stackable={
		["Health Mods"]=false;
		["Pacifists & Warmongers"]=false;
	};
	Type={"Chest"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.WarmongerScales;
	Category="Health Mods";
};

Add{
	Id="mendingmod";
	Name="Mending";
	Desc="For every kill, reduce <b>Armor Break</b> duration by time.";
	Icon="rbxassetid://16074211222";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="T"; Name="Time"; Syntax="Increase Time"; ValueType="Normal"; Suffix="s"; MaxLevel=9; BaseCost=10; MaxCost=100; BaseValue=0.1; MaxValue=1; Scaling=ModsLibrary.ScalingStyle.Linear;};
	};
	Stackable=false;
	Type={"Chest"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.Mending;
	Category="Rare Mods";
};

-- DoubleEdged rbxassetid://16049544633

--== Head wear;
Add{
	Id="flinchcushioning";
	Name="Flinch Cushioning";
	Desc="Adds <b>Flinch Protection</b>.";
	Icon="rbxassetid://16487046815";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="F"; Name="Flinch Protection"; Syntax="Upgrade Flinch Protection"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=0.05; MaxValue=0.75; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=false;
	Type={"Head"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.FlinchProtection;
	Category="Rare Mods";
};

--== Gloves

Add{
	Id="gripmod";
	Name="Gloves Grip Resistance";
	Desc="Increase additional melee stamina.";
	Icon="http://www.roblox.com/asset/?id=6557511294";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="GR"; Name="Grip Resistance"; Syntax="Increase Grip Resistance"; ValueType="Normal"; MaxLevel=10; BaseCost=4; MaxCost=40; BaseValue=10; MaxValue=100; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=false;
	Type={"Gloves"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.GripResistance;
	Category="Rare Mods";
}

Add{
	Id="swifthandsmod";
	Name="Swift Hands";
	Desc="Ready up your next attacks swiftly. Enables auto swing when holding down attack button.";
	Icon="http://www.roblox.com/asset/?id=6557618619";
	BaseTier=1;
	Tier=1;
	Upgrades={};
	Stackable=false;
	Type={"Gloves"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.AutoSwing;
	Category="Rare Mods";
}

Add{
	Id="meleefurymod";
	Name="Melee Fury";
	Desc="Every swing increases the attack speed. Buff stacks up to 5 times and lasts for 5 seconds.";
	Icon="http://www.roblox.com/asset/?id=6557976555";
	BaseTier=1;
	Tier=1;
	Upgrades={
		{DataTag="AS"; Name="Attack Speed"; Syntax="Increase Attack Speed"; MaxLevel=10; BaseCost=10; MaxCost=100; BaseValue=0.02; MaxValue=0.07; Scaling=ModsLibrary.ScalingStyle.NaturalCurve;};
	};
	Stackable=false;
	Type={"Gloves"};
	EffectTrigger=ModsLibrary.EffectTrigger.Passive;
	Module=script.MeleeFury;
	Category="Rare Mods";
}

return ModsLibrary;