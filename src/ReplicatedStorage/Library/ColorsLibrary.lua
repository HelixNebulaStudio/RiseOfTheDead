local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local modSkinsLibrary = require(game.ReplicatedStorage.Library.SkinsLibrary);
local modWorkbenchLibrary = require(game.ReplicatedStorage.Library:WaitForChild("WorkbenchLibrary"));

local ColorsLibary = {Library={}};
--== Configuration;

--== Variables;
ColorsLibary.Packs = {
	Dull = {Name="Dull"; LayoutOrder=1; List={}; Owned=true;};
	Lively = {Name="Lively"; LayoutOrder=1; List={};};
	Army = {Name="Army"; LayoutOrder=2; List={};};
	EasterColors = {Name="EasterColors"; LayoutOrder=3; List={};};
	Arctic = {Name="Arctic"; LayoutOrder=3; List={};}; 
	Hellsfire = {Name="Hellsfire"; LayoutOrder=3; List={};};
	TurquoiseShades = {Name="TurquoiseShades"; LayoutOrder=3; List={};};
	Sunset = {Name="Sunset"; LayoutOrder=3; List={};};
	Abyss = {Name="Abyss"; LayoutOrder=4; List={};};
}

local order = 0;
--== Script;
function NewColor(id, pack, colorName, colorValue)
	id = tostring(id);
	if ColorsLibary.Library[id] then error("Color ID("..id..") already exist!"); return end;
	order = order+1;
	ColorsLibary.Library[id] = {Id=id; Pack=pack.Name; Name=colorName; Color=colorValue; Order=order};
	table.insert(pack.List, ColorsLibary.Library[id]);
end

function ColorsLibary.Get(id)
	id = tostring(id);

	if id:sub(1,1) == "#" then
		local hex = (string.gsub(id, "#", ""));
		ColorsLibary.Library[id] = {
			Id=id;
			Pack="Custom";
			Name=hex;
			Color=Color3.fromHex(hex);
		};
	end

	return ColorsLibary.Library[id];
end

function ColorsLibary.SetColor(part, id, generateTag)
	if part == nil then return end;
	if part:GetAttribute("DefaultColor") == nil then
		part:SetAttribute("DefaultColor", part.Color);
	end

	part:SetAttribute("ColorId", nil);
	if id ~= nil then
		local getColor = ColorsLibary.Get(id);
		
		if generateTag ~= false then -- for preview
			part:SetAttribute("ColorId", id);
		end
		if getColor and part then
			part.Color = getColor.Color;
		end
		if part:GetAttribute("BaseTexture") and part.TextureID == part:GetAttribute("BaseTexture") then
			part.TextureID = "";
		end
	else
		local defaultColor = part:GetAttribute("DefaultColor");
		if defaultColor and part then
			part.Color = defaultColor;
		end
		if part:GetAttribute("BaseTexture") and part.TextureID == "" then
			part.TextureID = part:GetAttribute("BaseTexture");
		end
	end
end

function ColorsLibary.ApplyAppearance(weaponModel, itemValues)
	if itemValues == nil then return end;
	local itemId = weaponModel:GetAttribute("ItemId") or weaponModel.Name;
	
	local modelName = string.find(itemId, "dual") ~= nil and (string.gsub(itemId, "dual", "")) or itemId;
	local itemPrefabs = game.ReplicatedStorage.Prefabs.Items;
	local baseItemModel = itemPrefabs:FindFirstChild(modelName);
	
	local prefix = weaponModel.Name:sub(1,4) == "Left" and "L-" or weaponModel.Name:sub(1,5) == "Right" and "R-" or nil;
	if itemValues.Colors then
		for partKey, colorId in pairs(itemValues.Colors) do
			local partName = partKey;
			if prefix and partKey:sub(1, 2) == prefix then
				partName = partKey:sub(3, #partKey);
			end
			local part = weaponModel:FindFirstChild(partName);
			ColorsLibary.SetColor(part, colorId);
		end
	end
	
	if itemValues.SkinWearId then
		
		local modItemSkinWear = require(game.ReplicatedStorage.Library.ItemSkinWear);
		modItemSkinWear.ApplyAppearance(weaponModel, itemId, itemValues.SkinWearId);
	end
	
	local texturedParts = {};
	if itemValues.Textures then
		for partKey, textureId in pairs(itemValues.Textures) do
			local partName = partKey;
			if prefix and partKey:sub(1, 2) == prefix then
				partName = partKey:sub(3, #partKey);
			end
			local part = weaponModel:FindFirstChild(partName);
			if part then
				modSkinsLibrary.SetTexture(part, textureId);
				texturedParts[part] = textureId;
			end
		end
	end
	
	if itemValues.ActiveSkin then
		local itemDisplayLib = modWorkbenchLibrary.ItemAppearance[itemId];
		
		local appearLib = itemDisplayLib and itemDisplayLib[(prefix == "R-" and "Right" or prefix == "L-" and "Left" or "").."ToolGrip"];
		if appearLib then
			for _, baseItemPart in pairs(baseItemModel:GetChildren()) do
				if not baseItemPart:IsA("BasePart") then continue end;
				if baseItemPart:GetAttribute("SkipPattern") then continue end;
				
				local partName = baseItemPart.Name;

				local part = weaponModel:FindFirstChild(partName);
				if part == nil then continue end;
				if texturedParts[part] then continue end;
				modSkinsLibrary.SetTexture(part, itemValues.ActiveSkin);
			end
		end
		
	end
	
	if itemValues.PartAlpha then
		for _, part in pairs(weaponModel:GetChildren()) do
			if part:GetAttribute("DefaultTransparency") then
				part.Transparency = part:GetAttribute("DefaultTransparency");
				part:SetAttribute("CustomTransparency", nil);
			end
		end
		for partKey, textureId in pairs(itemValues.PartAlpha) do
			local partName = partKey;
			if prefix and partKey:sub(1, 2) == prefix then
				partName = partKey:sub(3, #partKey);
			end
			local part = weaponModel:FindFirstChild(partName);
			if part then
				if part:GetAttribute("DefaultTransparency") == nil then
					part:SetAttribute("DefaultTransparency", part.Transparency);
				end
				part.Transparency = 1;
				part:SetAttribute("CustomTransparency", 1);
			end
		end
	end
end

--== Color Pack: Dull
NewColor("dullred", ColorsLibary.Packs.Dull, "Dull Red", Color3.fromRGB(72, 49, 49));
NewColor("dullgreen", ColorsLibary.Packs.Dull, "Dull Green", Color3.fromRGB(59, 72, 49));
NewColor("dullblue", ColorsLibary.Packs.Dull, "Dull Blue", Color3.fromRGB(44, 54, 72));
NewColor("dullyellow", ColorsLibary.Packs.Dull, "Dull Yellow", Color3.fromRGB(71, 72, 43));
NewColor("dullpurple", ColorsLibary.Packs.Dull, "Dull Purple", Color3.fromRGB(49, 43, 72));
NewColor("dullpink", ColorsLibary.Packs.Dull, "Dull Pink", Color3.fromRGB(67, 41, 72));
NewColor("dullorange", ColorsLibary.Packs.Dull, "Dull Orange", Color3.fromRGB(72, 52, 41));
NewColor("dullteal", ColorsLibary.Packs.Dull, "Dull Teal", Color3.fromRGB(51, 66, 72));
NewColor("dullgrey", ColorsLibary.Packs.Dull, "Dull Grey", Color3.fromRGB(50, 50, 50));

--== Color Pack: Lively
NewColor("livelyred", ColorsLibary.Packs.Lively, "Lively Red", Color3.fromRGB(255, 65, 77));
NewColor("livelygreen", ColorsLibary.Packs.Lively, "Lively Green", Color3.fromRGB(139, 255, 139));
NewColor("livelyblue", ColorsLibary.Packs.Lively, "Lively Blue", Color3.fromRGB(133, 227, 255));
NewColor("livelyyellow", ColorsLibary.Packs.Lively, "Lively Yellow", Color3.fromRGB(255, 248, 142));
NewColor("livelypurple", ColorsLibary.Packs.Lively, "Lively Purple", Color3.fromRGB(182, 129, 255));
NewColor("livelyorange", ColorsLibary.Packs.Lively, "Lively Orange", Color3.fromRGB(218, 139, 102));
NewColor("livelylapis", ColorsLibary.Packs.Lively, "Lively Lapis", Color3.fromRGB(61, 106, 255));
NewColor("livelygrey", ColorsLibary.Packs.Lively, "Lively Grey", Color3.fromRGB(146, 147, 162));

--== Color Pack: Army
NewColor("army1", ColorsLibary.Packs.Army, "Jungle Moss", Color3.fromRGB(15, 36, 15));
NewColor("army2", ColorsLibary.Packs.Army, "Swamp", Color3.fromRGB(15, 36, 25));
NewColor("army3", ColorsLibary.Packs.Army, "Army Teal", Color3.fromRGB(15, 36, 36));
NewColor("army4", ColorsLibary.Packs.Army, "Deep Navy", Color3.fromRGB(15, 26, 36));
NewColor("army5", ColorsLibary.Packs.Army, "Desert Orange", Color3.fromRGB(152, 118, 83));
NewColor("army6", ColorsLibary.Packs.Army, "Sand Ops", Color3.fromRGB(207, 177, 139));

--== Color Pack: EasterColors
NewColor("easter1", ColorsLibary.Packs.EasterColors, "Easter Green", Color3.fromRGB(187, 255, 171));
NewColor("easter2", ColorsLibary.Packs.EasterColors, "Easter Pink", Color3.fromRGB(255, 181, 217));
NewColor("easter3", ColorsLibary.Packs.EasterColors, "Easter Blue", Color3.fromRGB(175, 223, 255));
NewColor("easter4", ColorsLibary.Packs.EasterColors, "Easter Yellow", Color3.fromRGB(255, 243, 175));

--== Color Pack: Arctic
NewColor("white1", ColorsLibary.Packs.Arctic, "Arctic Snow", Color3.fromRGB(225, 225, 225));
NewColor("white2", ColorsLibary.Packs.Arctic, "Arctic Snow 2", Color3.fromRGB(190, 190, 190));
NewColor("ice", ColorsLibary.Packs.Arctic, "Ice Cold", Color3.fromRGB(168, 191, 212));
NewColor("ice2", ColorsLibary.Packs.Arctic, "Ice Cold 2", Color3.fromRGB(160, 203, 212));
NewColor("ice3", ColorsLibary.Packs.Arctic, "Ice Wash", Color3.fromRGB(4, 171, 189));
NewColor("artic", ColorsLibary.Packs.Arctic, "Arctic Depth", Color3.fromRGB(76, 109, 180));

--== Color Pack: Hellsfire
NewColor("black1", ColorsLibary.Packs.Hellsfire, "Pitch Black", Color3.fromRGB(11, 11, 11));
NewColor("black2", ColorsLibary.Packs.Hellsfire, "Glaring Black", Color3.fromRGB(20, 20, 20));
NewColor("hsred", ColorsLibary.Packs.Hellsfire, "Hells Stone Red", Color3.fromRGB(44, 26, 26));
NewColor("hsred2", ColorsLibary.Packs.Hellsfire, "Hells Stone Red 2", Color3.fromRGB(44, 16, 16));
NewColor("hsred3", ColorsLibary.Packs.Hellsfire, "Red River", Color3.fromRGB(112, 45, 45));
NewColor("bloodred", ColorsLibary.Packs.Hellsfire, "Blood Red", Color3.fromRGB(127, 14, 14));

--== Color Pack: TurquoiseShades
NewColor("turquo1", ColorsLibary.Packs.TurquoiseShades, "Turquoise 1", Color3.fromRGB(0, 255, 170));
NewColor("turquo2", ColorsLibary.Packs.TurquoiseShades, "Turquoise 2", Color3.fromRGB(0, 204, 136));
NewColor("turquo3", ColorsLibary.Packs.TurquoiseShades, "Turquoise 3", Color3.fromRGB(0, 153, 102));
NewColor("turquo4", ColorsLibary.Packs.TurquoiseShades, "Turquoise 4", Color3.fromRGB(0, 102, 68));
NewColor("turquo5", ColorsLibary.Packs.TurquoiseShades, "Turquoise 5", Color3.fromRGB(0, 51, 34));


--== Color Pack: Sunset
NewColor("sun1", ColorsLibary.Packs.Sunset, "Sunset 1", Color3.fromRGB(255, 162, 0));
NewColor("sun2", ColorsLibary.Packs.Sunset, "Sunset 2", Color3.fromRGB(204, 129, 0));
NewColor("sun3", ColorsLibary.Packs.Sunset, "Sunset 3", Color3.fromRGB(153, 94, 0));
NewColor("sun4", ColorsLibary.Packs.Sunset, "Sunset 4", Color3.fromRGB(102, 61, 0));
NewColor("sun5", ColorsLibary.Packs.Sunset, "Sunset 5", Color3.fromRGB(51, 30, 0));

--== Color Pack: Abyss
NewColor("abyss1", ColorsLibary.Packs.Abyss, "Abyss 1", Color3.fromRGB(107, 123, 153));
NewColor("abyss2", ColorsLibary.Packs.Abyss, "Abyss 2", Color3.fromRGB(81, 90, 116));
NewColor("abyss3", ColorsLibary.Packs.Abyss, "Abyss 3", Color3.fromRGB(47, 68, 107));
NewColor("abyss4", ColorsLibary.Packs.Abyss, "Abyss 4", Color3.fromRGB(31, 45, 71));
NewColor("abyss5", ColorsLibary.Packs.Abyss, "Abyss 5", Color3.fromRGB(29, 29, 66));

return ColorsLibary;