local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

local modRichFormatter = require(game.ReplicatedStorage.Library.UI.RichFormatter);
--
local colorBoolText = modRichFormatter.ColorBoolText;
local colorStringText = modRichFormatter.ColorStringText;

local PlaceholderIcon = "rbxassetid://16029038219";

local ItemModsLibrary = {List={}; Library={};};
ItemModsLibrary.EffectTrigger = {
	Passive=0;
	Activate=1;
	Trigger=2;
};

ItemModsLibrary.ScalingStyle = {
	Linear=0;
	NaturalCurve=1;
};

function ItemModsLibrary.Linear(base, max, level, maxlevel)
	level = level or 0;
	if base > max then -- base=8, max=2
		local scale = base-max;
		return base - (math.clamp(level/maxlevel, 0, 1) * scale);
		
	else
		local scale = max-base;
		return base + (math.clamp(level/maxlevel, 0, 1) * scale);
		
	end
end

function ItemModsLibrary.NaturalInterpolate(base, max, level, maxlevel, rate)
	level = level or 0;
	local scale = math.clamp(level/maxlevel, 0, 1)^(rate or 2.5);
	return (base + (max-base)*scale);
end


function ItemModsLibrary.GetLayer(upgradeKey, packet)
	local modStorageItem = packet.ModStorageItem;
	
	local modLib = ItemModsLibrary.Get(modStorageItem.ItemId);
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
	
	
	if upgradeInfo.Scaling == ItemModsLibrary.ScalingStyle.Linear then
		layerPacket.Value = ItemModsLibrary.Linear(
			upgradeInfo.BaseValue, 
			upgradeInfo.MaxValue,
			activeLevel,
			upgradeInfo.MaxLevel
		);
		
	elseif upgradeInfo.Scaling == ItemModsLibrary.ScalingStyle.NaturalCurve then
		layerPacket.Value = ItemModsLibrary.NaturalInterpolate(
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
function Add(_, data)
	if ItemModsLibrary.Library[data.Id] ~= nil then error("ModulesLibrary>>  Add Id alerady exist for ("..data.Name..")("..data.Id..")"); end;
	if data.Module == nil then error("ModulesLibrary>> Mod ("..data.Name..")("..data.Id..") does not have module attached."); end;
	local description = data.Description or data.Desc;
	
	order = order+1;
	ItemModsLibrary.List[data.Name] = {
		Id=data.Id;
		Name=data.Name;
		Desc=data.Desc or "";
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
	};
	ItemModsLibrary.Library[data.Id] = ItemModsLibrary.List[data.Name];
	
	for k, v in pairs(data) do
		ItemModsLibrary.Library[data.Id][k] = v;
	end
	if data.ModDesc then
		ItemModsLibrary.Library[data.Id].Desc = data.ModDesc;
	end

	if data.Type then
		description = description.."\n\n<b>Compatibility:</b> ";
		for a=1, #data.Type do
			description = description..colorStringText(data.Type[a])
			if a ~= #data.Type then
				description = description..", ";
			else
				description = description.."";
			end
		end
	end

	if data.EffectTrigger then
		description = description.."\n\n<b>EffectTrigger:</b> "..(data.EffectTrigger == ItemModsLibrary.EffectTrigger.Passive and colorStringText("Passive") 
			or data.EffectTrigger == ItemModsLibrary.EffectTrigger.Activate and colorStringText("Activate") or colorStringText("Unknown"));
	end
	
	local stackable = "";
	if typeof(data.Stackable) == "boolean" then
		stackable = colorBoolText(data.Stackable);
	elseif typeof(data.Stackable) == "table" then
		for sKey, sbool in pairs(data.Stackable) do
			stackable = stackable.."\n    - "..colorStringText(sKey)..": ".. colorBoolText(sbool);
		end
	end
	description = description.."\n<b>Mod Stackable:</b> ".. stackable;
	
	local itemMetadata = {
		Id=data.Id; 
		Name=data.Name; 
		Icon=data.Icon; 
		Description=description;
		Tier=data.Tier;
		Tags = {data.Category};
	};

	if data.ItemMetaData then
		for k, v in pairs(data.ItemMetaData) do
			itemMetadata[k] = v;
		end
	end

	new(modBase, itemMetadata);
end

function ItemModsLibrary.Get(nameOrId)
	return ItemModsLibrary.List[nameOrId] or ItemModsLibrary.Library[nameOrId];
end

ItemModsLibrary.Add = Add;

local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetModule(script.Name);
if moddedSelf then moddedSelf:Init(ItemModsLibrary); end

return ItemModsLibrary;