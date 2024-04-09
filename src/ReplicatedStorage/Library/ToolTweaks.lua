local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local ToolTweaks = {};
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modMath = require(game.ReplicatedStorage.Library.Util.Math);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modWorkbenchLibrary = require(game.ReplicatedStorage.Library.WorkbenchLibrary);

if RunService:IsServer() then
	modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
	modPseudoRandom = require(game.ReplicatedStorage.Library.PseudoRandom);
end

ToolTweaks.TierTitles = {
	{"Improved"; "Fine-tuned"; "Special"; "Enhanced"; "Revamped"; "Great"; "Revised"; "Tinkered"; "Efficient"; "Better"; "Finer"; "Upgraded"}; -- Tier 1
	{"Amazing"; "Well-tuned"; "Greater"; "Remarkable"; "Awesome"; "Lucky"}; -- Tier 2
	{"Ultra"; "Outstanding"; "Outrageous"; "Prestigious"; "Incredible"}; -- Tier 3
	{"Mythical"; "Phenomenal"; "Extraordinary"; "Superior";}; -- Tier 4
	{"Legendary"; "Dominating"; "Supreme"}; -- Tier 5
	{"Nekronomical"}; -- Tier 6
}

--==
function ToolTweaks.Generate(player, storageItem)
	local profile = modProfile:Get(player);
	local nextSeed = modPseudoRandom:NextNumber(player, "guntweak", 0, 999999);
	storageItem.Values.Tweak = nextSeed;
end

function ToolTweaks.LoadTrait(itemId, traitId)
	local tweaksReturn = {};
	
	local traitLib = modWorkbenchLibrary.ItemUpgrades[itemId] and modWorkbenchLibrary.ItemUpgrades[itemId].TraitStats;
	if traitLib then
		local random = Random.new(traitId);
		local generateTier = random:NextNumber(0, 1);
		local tier = 1;
		
		if generateTier <= 0.002 then
			tier = 6;
		elseif generateTier <= 0.008 then
			tier = 5;
		elseif generateTier <= 0.032 then
			tier = 4;
		elseif generateTier <= 0.166 then
			tier = 3;
		elseif generateTier <= 0.334 then
			tier = 2;
		end
		
		tweaksReturn.Tier = tier;
		local titlesList = ToolTweaks.TierTitles[tier];
		tweaksReturn.Title = titlesList[random:NextInteger(1, #titlesList)];
		
		local usedTrait = {};
		local picks = {};
		for a=1, tier do
			local traitsPick = {};
			local traitTotalChance = 0;
			for a=1, #traitLib do
				local traitRarity = traitLib[a].Rarity;
				
				if usedTrait[traitLib[a].Stat] == nil then
					table.insert(traitsPick, {Trait=traitLib[a]; Start=traitTotalChance; End=traitTotalChance + traitRarity});
					traitTotalChance = traitTotalChance + traitRarity;
				end	
			end
			
			local roll = random:NextNumber(0, traitTotalChance);
			for a=1, #traitsPick do
				local picked = traitsPick[a]
				if roll >= traitsPick[a].Start and roll < traitsPick[a].End then
					table.insert(picks, picked.Trait);
					usedTrait[picked.Trait.Stat] = true;
					break;
				end
			end
		end
		
		tweaksReturn.Stats = {};
		for a=1, #picks do
			local trait = picks[a];
			
			local rangeInt = (trait.Value.Max-trait.Value.Min)/6;
			local newMin = trait.Value.Min + rangeInt*(tier-1);
			local newMax = trait.Value.Min + rangeInt*tier;
			local rngRange = random:NextNumber(newMin, newMax);
			
			tweaksReturn.Stats[trait.Stat] = math.floor(rngRange*100)/100;
		end
	end
	return tweaksReturn;
end


function ToolTweaks.GetTierColor(v)
	local value = math.abs(v)/100
	if value >= 0.8 then
		return Color3.fromRGB(255, 119, 0);
	elseif value >= 0.6 then
		return Color3.fromRGB(255, 0, 0);
	elseif value >= 0.4 then
		return Color3.fromRGB(255, 0, 242);
	elseif value >= 0.2 then
		return Color3.fromRGB(119, 0, 255);
	elseif value >= 0.05 then
		return Color3.fromRGB(0, 132, 255);
	end
	return Color3.fromRGB(255, 255, 255);
end


function ToolTweaks.LoadGraph(graphSeed, styleDir)
	if graphSeed == nil then
		return {};
	end
	local function MapNum(x, inMin, inMax, outMin, outMax)
		return (x - inMin)*(outMax - outMin)/(inMax - inMin) + outMin
	end
	local function lerp(a, b, t) return a * (1-t) + (b*t); end

	local seed = graphSeed;
	local data = {};

	local points = {};
	local peaks = {};

	local newRng = Random.new(seed);

	local function shuffle(tbl)
		for i = #tbl, 2, -1 do
			local j = newRng:NextInteger(1, i)
			tbl[i], tbl[j] = tbl[j], tbl[i]
		end
		return tbl;
	end

	table.insert(points, {
		X=newRng:NextNumber(0.2, 0.8);
		Y=newRng:NextInteger(1, 2) == 1 and 1 or -1;
	});

	local function addToPool(count, min, max)
		for a=1, count do
			local v = newRng:NextNumber(min, max) * (newRng:NextInteger(1,2) == 1 and 1 or -1);
			table.insert(peaks, v);
		end
	end
	addToPool(1, 0.6, 0.8);
	addToPool(2, 0.4, 0.6);
	addToPool(3, 0.2, 0.4);
	addToPool(3, 0.0, 0.2);
	addToPool(1, 0.0, 0.0);

	shuffle(peaks);

	local lastX = 0;
	local pSpacing = 1/(#peaks + 1);
	for a=1, #peaks do
		local newX = lastX;
		
		table.insert(points, {
			X = newX + pSpacing;
			Y = peaks[a];
		});
		lastX = newX + pSpacing;
	end

	table.sort(points, function(a, b) return a.X < b.X end)

	table.insert(points, 1, {X=0;Y=0;});
	table.insert(points, {X=1;Y=0;});

	local easingStyles = {
		Enum.EasingStyle.Quad;
		Enum.EasingStyle.Quart;
		Enum.EasingStyle.Circular;
		Enum.EasingStyle.Cubic;
		Enum.EasingStyle.Exponential;
		Enum.EasingStyle.Quint;
	}
	local easingDirections = {
		Enum.EasingDirection.In;
		Enum.EasingDirection.Out;
		Enum.EasingDirection.InOut;
	}

	local activeStyle = Enum.EasingStyle.Sine;
	local activeDirection = Enum.EasingDirection.InOut;
	
	local fixedSpacing = 1/(#points+1);
	lastX = 0;
	for a=1, #points do
		lastX = lastX + fixedSpacing;
		points[a].X = math.round(lastX*100);
	end
	
	local lastPoint = points[1];
	for a=2, #points do
		local currPoint = points[a];
		local range = currPoint.X-lastPoint.X;

		activeStyle = easingStyles[newRng:NextInteger(1, #easingStyles)];
		activeDirection = easingDirections[newRng:NextInteger(1, #easingDirections)];
		
		if styleDir then
			if styleDir.Style then
				activeStyle = styleDir.Style;
			end
			if styleDir.Dir then
				activeDirection = styleDir.Dir;
			end
		end
		
		for i=1, range do
			local t = TweenService:GetValue(math.clamp(i/range, 0, 1), activeStyle, activeDirection);
			local v = lerp(lastPoint.Y, currPoint.Y, t);
			
			table.insert(data, {
				Value = (v * 100);
				IsPeak = i == range and a ~= #points;
			});
		end
		
		lastPoint = currPoint;
	end
	
	return data;
end

function ToolTweaks.GetValuesFromGraph(points, tweakPivot)
	local values = {};
	
	local function get(pivot)
		if pivot >= 1 then
			pivot = pivot-1;
			
		elseif pivot <= 0 then
			pivot = 1+pivot;
			
		end
		
		local pivotx100 = pivot*#points;

		local aIndex = math.floor(pivotx100);
		local bIndex = math.ceil(pivotx100);

		if aIndex == bIndex then
			bIndex = bIndex + 1;
		end

		local pointA, pointB = points[aIndex], points[bIndex];

		if aIndex == 0 then
			pointA = {Value=0;};
		end
		if bIndex == #points+1 then
			pointB = {Value=0;};
		end

		local t = (pivotx100-aIndex)/(bIndex-aIndex);
		return modMath.Lerp(pointA.Value, pointB.Value, t);
	end
	
	local rootValue = get(tweakPivot); -- -100 - 100
	table.insert(values, rootValue);
	
	local flip = false;
	local spacing = 0.05;
	
	for a=2, math.ceil(math.abs(rootValue)/20) do
		local f = tweakPivot + spacing * math.floor(a/2) * (flip and 1 or -1);
		if f >= 1 then
			f = f -1;
		elseif f <= 0 then
			f = 1 +f;
		end
		
		table.insert(values, get(f))
		flip = not flip;
	end
	
	return values;
end

return ToolTweaks;
