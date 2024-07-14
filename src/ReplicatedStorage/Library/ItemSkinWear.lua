local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local ItemSkinWear = {};
--==
local RunService = game:GetService("RunService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modWorkbenchLibrary = require(game.ReplicatedStorage.Library.WorkbenchLibrary);
local modMath = require(game.ReplicatedStorage.Library.Util.Math);

ItemSkinWear.Titles = {
	"Factory New";
	"Mint Condition";
	"Ideal Model";
	"Heavily Worn";
	"Battle-Tested";
}

--==
local idealSeeds = {702925; 186711; 922565; 228877; 326920; 380975; 473148; 166530};
function ItemSkinWear.Generate(player, storageItem, action)
	local itemDisplayLib = modWorkbenchLibrary.ItemAppearance[storageItem.ItemId];
	if itemDisplayLib == nil then return; end
	if storageItem.Values.SkinWearId ~= nil then return; end
	
	if action == "setideal" then
		local closestFloat, closestSeed = math.huge, 0;
		local seed, gen;
		
		for a=1, 256 do
			seed = math.random(0, 999999);
			gen = ItemSkinWear.LoadFloat(storageItem.ItemId, seed);
			
			local wearFloat = 0.21;
			local dist = math.abs(gen.Float-wearFloat);
			
			if dist < closestFloat then
				closestFloat = dist;
				closestSeed = seed;

				if dist <= 0.01 then
					seed = closestSeed;
					break;
				end
			end
		end
		
		if closestFloat >= 0.01 then
			seed = idealSeeds[math.random(1, #idealSeeds)]
		end
		
		storageItem.Values.SkinWearId = seed;
		
	else
		local profile = shared.modProfile:Get(player);
		local modPseudoRandom = require(game.ReplicatedStorage.Library.PseudoRandom);
		
		local nextSeed = modPseudoRandom:NextNumber(player, "gunwear", 0, 999999);
		storageItem.Values.SkinWearId = nextSeed;
		
	end
	
	Debugger:Log("Generated skinwearid ", storageItem);
end

function ItemSkinWear.GetWearLib(itemId)
	if modWorkbenchLibrary.ItemUpgrades[itemId] and modWorkbenchLibrary.ItemUpgrades[itemId].SkinWear then
		return modWorkbenchLibrary.ItemUpgrades[itemId].SkinWear;
	end
	return {
		Wear={Min=0.000001; Max=0.999999;};
	}
end

function ItemSkinWear.PolishTool(storageItem)
	local itemId = storageItem.ItemId;
	local itemValues = storageItem.Values;

	local oldSeed = itemValues.SkinWearId;
	local oldFloat = ItemSkinWear.LoadFloat(itemId, oldSeed).Float;

	local cleanMin, cleanMax = modWorkbenchLibrary.PolishRangeBase.Min, modWorkbenchLibrary.PolishRangeBase.Max;
				
	local rngChange = math.random(cleanMin*100000, cleanMax*100000)/100000;

	local success = false;

	local newSeed;

	local closestSeed, closestGenData;
	local closestDif = math.huge;

	local targetFloat = oldFloat-rngChange;
	local changeFloat = 0;

	local maxRangeFloat = math.floor(oldFloat*100000);
	if targetFloat <= 0 and maxRangeFloat > 999 and math.random(1, 10) == 1 then
		targetFloat = math.random(999, maxRangeFloat)/100000;
	end

	if targetFloat > 0 then
		local a=0;

		repeat
			local seed = math.random(0, 999999);
			local genData = ItemSkinWear.LoadFloat(itemId, seed);
			
			local absDif = math.abs(genData.Float-targetFloat);
			
			if genData.Float < oldFloat and absDif <= closestDif then
				closestDif = absDif;
				closestSeed = seed;
				closestGenData = genData;
				
			end

			a = a +1;
		until a > 64;
		
		if closestSeed and closestDif <= 0.01 then
			newSeed = closestSeed;
			changeFloat = closestGenData.Float - oldFloat;
			success = true;
		end
	end

	if not success then
		changeFloat = 0;
		newSeed = oldSeed;
		
		Debugger:StudioWarn(`Failed polish: Old: {oldFloat} New: {oldFloat}, Closest: {closestDif}`);
	else
		Debugger:StudioWarn(`Success polish: Old: {oldFloat} New: {oldFloat+changeFloat}, Change: {changeFloat}`);
	end

	return newSeed, changeFloat;
end

function ItemSkinWear.LoadFloat(itemId, seed)
	local returnPacket = {};
	if seed == nil then return returnPacket end;
	
	local wearLib = ItemSkinWear.GetWearLib(itemId);
	--local wearLib = {
	--	Wear={Min=0.000001; Max=0.999999;};
	--}
	
	--if modWorkbenchLibrary.ItemUpgrades[itemId] and modWorkbenchLibrary.ItemUpgrades[itemId].SkinWear then
	--	wearLib = modWorkbenchLibrary.ItemUpgrades[itemId].SkinWear;
	--end
	
	local random = Random.new(seed);
	local wearFloat = modMath.MapNum(random:NextNumber(), 0, 1, wearLib.Wear.Min, wearLib.Wear.Max);
	
	returnPacket.Float = wearFloat;
	
	if wearFloat <= 0.1 then -- 0.06
		returnPacket.Title = 1;
		
	elseif wearFloat <= 0.31 then -- 0.12
		returnPacket.Title = 2;	
		
	elseif wearFloat <= 0.55 then -- 0.44
		returnPacket.Title = 3;	
		
	elseif wearFloat <= 0.79 then -- 0.66
		returnPacket.Title = 4;	
		
	elseif wearFloat <= 1 then
		returnPacket.Title = 5;	
		
	end
	
	return returnPacket;
end


ItemSkinWear.WearMap = {
	{--Factory New
		Wear = {Min=0; Max=0.1;};
		TextureRange = {Min=0.2; Max=0.6;};
		
		Metal = {
			{Max=0.5; Varient="Brushed Metal"};
			{Max=1; Varient="Scratched Metal"};
		};
		Wood = {
			{Max=0; Varient=""};
		};
	};
	{--Mint Condition
		Wear = {Min=0.11; Max=0.31;};
		TextureRange = {Min=0.4; Max=0.7;};
		
		Metal = {
			{Max=0.5; Varient="Scratched Metal"};
			{Max=1; Varient=""};
		};
		Wood = {
			{Max=0.5; Varient=""};
			{Max=1; Varient="Rough Wood"};
		};
	};
	{--Ideal Model
		Wear = {Min=0.32; Max=0.55;};
		TextureRange = {Min=0.45; Max=0.7;};
		
		Metal = {
			{Max=0.75; Varient=""};
			{Max=1; Varient="Worn Metal"};
		};
		Wood = {
			{Max=1; Varient="Rough Wood"};
		};
	};
	{--Heavily Worn
		Wear = {Min=0.56; Max=0.79;};
		TextureRange = {Min=0.5; Max=0.75;};
		
		Metal = {
			{Max=0.75; Varient="Worn Metal"};
			{Max=1; Varient="Old Metal"};
		};
		Wood = {
			{Max=1; Varient="Rough Wood"};
		};
	};
	{--Battle-Tested
		Wear = {Min=0.80; Max=1;};
		TextureRange = {Min=0.55; Max=0.75;};
		
		Metal = {
			{Max=0.75; Varient="Old Metal"};
			{Max=1; Varient="Corroded Metal"};
		};
		Wood = {
			{Max=0.75; Varient="Rough Wood"};
			{Max=1; Varient="Dead Wood"};
		};
	};
}

function ItemSkinWear.ApplyAppearance(weaponModel, itemId, seed)
	local wearLib = ItemSkinWear.LoadFloat(itemId, seed);
	local random = Random.new(wearLib.Float);
	
	weaponModel:SetAttribute("Float", wearLib.Float);
	
	local sortedParts = {};
	
	for _, obj in pairs(weaponModel:GetChildren()) do
		if obj:IsA("BasePart") then
			if obj:GetAttribute("BaseMat") == nil then
				obj:SetAttribute("BaseMat", obj.Material.Name);
			end
			table.insert(sortedParts, obj);
		end
	end
	
	table.sort(sortedParts, function(a, b)
		return tostring(a) < tostring(b);
	end);
	
	local wearMap = ItemSkinWear.WearMap[wearLib.Title];
	local floatMap = wearMap and modMath.MapNum(wearLib.Float, wearMap.Wear.Min, wearMap.Wear.Max, 0, 1);
		
	for _, obj in pairs(sortedParts) do
		
		local matVars = wearMap and wearMap[obj:GetAttribute("BaseMat")] or nil;
		if matVars then
			local rngFloat = math.clamp(floatMap + random:NextNumber(-0.25, 0.25), 0, 1);
			
			for a=1, #matVars do
				local matVar = matVars[a];
				if rngFloat <= matVar.Max then
					obj:SetAttribute("PartFloat", rngFloat);
					obj.MaterialVariant = matVar.Varient;
					break;
				end
			end
		end
		--if obj:GetAttribute("BaseMat") == "Metal" then
		--	if wearLib.Title == 1 then
		--		obj.MaterialVariant = "Glossy Metal";
				
		--	elseif wearLib.Title == 2 then
		--		obj.MaterialVariant = "Brushed Metal";
				
		--	elseif wearLib.Title == 3 then
		--		obj.MaterialVariant = "";
				
		--	elseif wearLib.Title == 4 then
		--		obj.MaterialVariant = "Rusty Metal";
				
		--	elseif wearLib.Title == 5 then
		--		obj.MaterialVariant = "Old Metal";
				
		--	end
		--end
	end
end

function ItemSkinWear.MapTransparency(wearFloat, alphaMap)
	local tranparency = 0.8;
	
	for _, info in pairs(ItemSkinWear.WearMap) do
		if wearFloat <= info.Wear.Max then
			tranparency = modMath.MapNum(wearFloat, info.Wear.Min, info.Wear.Max, alphaMap and alphaMap.Min or info.TextureRange.Min, alphaMap and alphaMap.Max or info.TextureRange.Max);
			break;
		end
	end
	
	--if wearFloat <= 0.06 then
	--	return modMath.MapNum(wearFloat, 0, 0.06, 0.4, 0.8);

	--elseif wearFloat <= 0.12 then
	--	return modMath.MapNum(wearFloat, 0.07, 0.12, 0.5, 0.8);

	--elseif wearFloat <= 0.44 then
	--	return modMath.MapNum(wearFloat, 0.13, 0.44, 0.55, 0.8);

	--elseif wearFloat <= 0.66 then
	--	return modMath.MapNum(wearFloat, 0.45, 0.66, 0.6, 0.8);

	--elseif wearFloat <= 1 then
	--	return modMath.MapNum(wearFloat, 0.67, 1, 0.65, 0.8);

	--end
	
	return tranparency;
end

return ItemSkinWear;