local SkinsLibrary = {Library={}};
--== Libraries;
local CollectionService = game:GetService("CollectionService");

local modTexturePackage = require(game.ReplicatedStorage.Library.TexturePackage);
local modTextureAnimations = require(game.ReplicatedStorage.Library.TextureAnimations);

--== Variables;
SkinsLibrary.Packs = { -- LayoutOrder: Order in display;
	Basic = {Name="Basic"; LayoutOrder=0; List={}; Owned=true;};
	Camo = {Name="Camo"; LayoutOrder=1; List={}; Owned=false;};
	StreetArt = {Name="StreetArt"; LayoutOrder=10; List={}; Owned=false;};
	Wireframe = {Name="Wireframe"; LayoutOrder=11; List={}; Owned=false;};
	Wraps = {Name="Wraps"; LayoutOrder=12; List={}; Owned=false;};
	ScalePlating = {Name="ScalePlating"; LayoutOrder=13; List={}; Owned=false;};
	CarbonFiber = {Name="CarbonFiber"; LayoutOrder=14; List={}; Owned=false;};
	Hexatiles = {Name="Hexatiles"; LayoutOrder=15; List={}; Owned=false;};
	HalloweenPixelArt = {Name="HalloweenPixelArt"; LayoutOrder=16; List={}; Owned=false;};
	Offline = {Name="Offline"; LayoutOrder=17; List={}; Owned=false;};
	Ice = {Name="Ice"; LayoutOrder=18; List={}; Owned=false;};
	Windtrails = {Name="Windtrails"; LayoutOrder=19; List={}; Owned=false;};
	
	-- Free
	Xmas = {Name="Xmas"; LayoutOrder=54; List={}; Owned=false;};
	EasterSkins = {Name="EasterSkins"; LayoutOrder=55; List={}; Owned=false;};
	Halloween = {Name="Halloween"; LayoutOrder=56; List={}; Owned=false;};
	FestiveWrapping = {Name="FestiveWrapping"; LayoutOrder=57; List={}; Owned=false;};
	Easter2023 = {Name="Easter2023"; LayoutOrder=58; List={}; Owned=false;};
	CuteButScary = {Name="CuteButScary"; LayoutOrder=59; List={}; Owned=false;};
	Fancy = {Name="Fancy"; LayoutOrder=60; List={}; Owned=false;};
	
	-- Locked
	Full = {Name="Full"; LayoutOrder=98; List={}; Owned=false;};
	Special = {Name="Special"; LayoutOrder=99; List={}; Owned=false;};
}

local order = 0;
--== Script;
function AddTexture(data)
	local id = tostring(data.Id);

	if SkinsLibrary.Library[id] then error("Texture ID("..id..") already exist!"); return end;
	
	order = order+1;
	local texturePackage = modTexturePackage.new(id, data.TextureData);
	
	local color = data.Color or Color3.new(1, 1, 1);
	local tile = data.Tile or Vector2.new(0.1, 0.1);
	
	SkinsLibrary.Library[id] = {
		Id=id;
		Pack=data.Pack.Name;
		Name=data.Name;
		Icon=(type(color) == "string" and color or nil);
		Texture=texturePackage;
		Image=texturePackage:GetTexture(); --texture.Image;
		Color=color;
		StudsPerTile=tile;
		Transparency=0;
		IsMeshTexture=data.IsUVTexture; -- weapon uv skins
		Order=order;
		CanClear=data.CanClear;
		IsSurfaceAppearance=data.IsSurfaceAppearance;
	};
	
	table.insert(data.Pack.List, SkinsLibrary.Library[id]);
end

function NewTexture(id, pack, name, textureIds, color, tile, transparency, isMeshTexture)
	id = tostring(id);
	if SkinsLibrary.Library[id] then error("Texture ID("..id..") already exist!"); return end;
	order = order+1;
	local texturePackage = modTexturePackage.new(id, textureIds);

	local data = {
		Id=id;
		Pack=pack.Name;
		Name=name;
		Icon=(type(color) == "string" and color or nil);
		Texture=texturePackage;
		Image=texturePackage:GetTexture(); --texture.Image;
		Color=(color or Color3.new(1, 1, 1));
		StudsPerTile=(tile or Vector2.new(0.1, 0.1));
		Transparency=(transparency or 0);
		IsMeshTexture=isMeshTexture==true;
		Order=order;
	};
	SkinsLibrary.Library[id] = data;
	table.insert(pack.List, SkinsLibrary.Library[id]);
	return data;
end

function SkinsLibrary.Get(id)
	id = tostring(id);
	return SkinsLibrary.Library[id];
end

function SkinsLibrary.GetByName(name)
	for _, lib in pairs(SkinsLibrary.Library) do
		if lib.Name == name then
			return lib;
		end
	end
	return;
end

function SkinsLibrary.Refresh()
	
end

local normals = {Enum.NormalId.Back; Enum.NormalId.Bottom; Enum.NormalId.Front; Enum.NormalId.Left; Enum.NormalId.Right; Enum.NormalId.Top};
function SkinsLibrary.SetTexture(part, id, generateTag)
	local itemId = part.Parent:GetAttribute("ItemId");
	local modelFloat = part.Parent:GetAttribute("Float") or 0.5;
	
	for _, c in pairs(part:GetChildren()) do
		if c:IsA("Texture") and c.Name == "SkinTexture" then
			c:Destroy();
		elseif c:IsA("SurfaceAppearance") and c:GetAttribute("SkinId") then
			c:Destroy();
		end
	end
	part:SetAttribute("SkinId", nil);
	
	if part:IsA("MeshPart") then
		part.TextureID = "";
	end
	
	if id == 0 then return end;
	if id ~= nil then
		local library = SkinsLibrary.Get(id);
		
		if library == nil then error("SkinsLibrary>>  Failed to get skin id("..id..")"); end;
		if generateTag ~= false then -- for preview
			part:SetAttribute("SkinId", id);
			
		end
		
		if library.IsSurfaceAppearance then -- and workspace:IsAncestorOf(part)
			if part.Transparency > 0 then return end;
			
			local skinName = library.Name;
			local surfApp = script:FindFirstChild(skinName) and script[skinName]:FindFirstChild(itemId);
			
			for _, obj in pairs(part:GetChildren()) do
				if not obj:IsA("SurifaceAppearance") then continue end;
				obj:Destroy();
			end
			
			if surfApp then
				local newSurfApp = surfApp:Clone();
				newSurfApp:SetAttribute("SkinId", id);
				newSurfApp.Parent = part;
			end
			
		elseif library.IsMeshTexture and part:IsA("MeshPart") then
			
			local texturePackage = library.Texture;
			if texturePackage and texturePackage.UVPack and texturePackage.UVPack[itemId] then
				part.TextureID = texturePackage.UVPack[itemId].Id;
			end
			
		else
			local texturePackage = library.Texture;
			
			for b=1, #texturePackage.Pack do
				local txtPack = texturePackage.Pack[b];
				
				if txtPack.ItemId and txtPack.ItemId ~= itemId then continue end;
				
				local texture = Instance.new("Texture");
				texture.Name = "SkinTexture";
				texture.Color3 = txtPack.Color or library.Color;
				
				texture.StudsPerTileU = (txtPack.StudTileUV and txtPack.StudTileUV.X) or library.StudsPerTile.X or 1;
				texture.StudsPerTileV = (txtPack.StudTileUV and txtPack.StudTileUV.Y) or library.StudsPerTile.Y or 1;
				texture.Texture = txtPack.Id;
				texture.ZIndex = txtPack.ZIndex or 1;
				
				if txtPack.Attributes then
					for k, v in pairs(txtPack.Attributes) do
						texture:SetAttribute(k, v);
					end
				end
				
				if modTextureAnimations.Library:Find(txtPack.AnimationId or txtPack.Id) then
					texture:SetAttribute("TextureAnimationId", txtPack.Id);
					CollectionService:AddTag(texture, "AnimatedTextures");
				end

				local modItemSkinWear = require(game.ReplicatedStorage.Library.ItemSkinWear);
				texture.Transparency = modItemSkinWear.MapTransparency(modelFloat, txtPack.AlphaMap);
				
				for a=1, #normals do
					if a ~= 1 then
						texture = texture:Clone();
					end
					texture.Face = normals[a];
					texture.Parent = part;
				end
				
			end
		end
	else
		if part:GetAttribute("BaseTexture") then
			part.TextureID = part:GetAttribute("BaseTexture");
		end
	end
end

--== Texture Pack: Basic
local basicConvert = function(lib)

end
NewTexture(1, SkinsLibrary.Packs.Basic, "Red Grids", "rbxassetid://2686209243", Color3.fromRGB(72, 49, 49), Vector2.new(0.1, 0.1)).Convert = basicConvert;
NewTexture(2, SkinsLibrary.Packs.Basic, "Green Grids", "rbxassetid://2686209243", Color3.fromRGB(59, 72, 49), Vector2.new(0.1, 0.1)).Convert = basicConvert;
NewTexture(3, SkinsLibrary.Packs.Basic, "Blue Grids", "rbxassetid://2686209243", Color3.fromRGB(44, 54, 72), Vector2.new(0.1, 0.1)).Convert = basicConvert;
NewTexture(4, SkinsLibrary.Packs.Basic, "Red Dots", "rbxassetid://2686209162", Color3.fromRGB(72, 49, 49), Vector2.new(0.05, 0.05)).Convert = basicConvert;
NewTexture(5, SkinsLibrary.Packs.Basic, "Green Dots", "rbxassetid://2686209162", Color3.fromRGB(59, 72, 49), Vector2.new(0.05, 0.05)).Convert = basicConvert;
NewTexture(6, SkinsLibrary.Packs.Basic, "Blue Dots", "rbxassetid://2686209162", Color3.fromRGB(44, 54, 72), Vector2.new(0.05, 0.05)).Convert = basicConvert;
NewTexture(7, SkinsLibrary.Packs.Basic, "Red Checkers", "rbxassetid://2692783156", Color3.fromRGB(72, 49, 49), Vector2.new(0.1, 0.1)).Convert = basicConvert;
NewTexture(8, SkinsLibrary.Packs.Basic, "Green Checkers", "rbxassetid://2692783156", Color3.fromRGB(59, 72, 49), Vector2.new(0.1, 0.1)).Convert = basicConvert;
NewTexture(9, SkinsLibrary.Packs.Basic, "Blue Checkers", "rbxassetid://2692783156", Color3.fromRGB(44, 54, 72), Vector2.new(0.1, 0.1)).Convert = basicConvert;

--== Texture Pack: Camo
NewTexture(11, SkinsLibrary.Packs.Camo, "Red Camo", "rbxassetid://4386335941", Color3.fromRGB(72, 49, 49), Vector2.new(1, 1));
NewTexture(12, SkinsLibrary.Packs.Camo, "Green Camo", "rbxassetid://4386336507", Color3.fromRGB(59, 72, 49), Vector2.new(1, 1));
NewTexture(13, SkinsLibrary.Packs.Camo, "Blue Camo", "rbxassetid://4386337276", Color3.fromRGB(44, 54, 72), Vector2.new(1, 1));
NewTexture(14, SkinsLibrary.Packs.Camo, "Yellow Camo", "rbxassetid://4386335941", Color3.fromRGB(71, 72, 43), Vector2.new(1, 1));
NewTexture(15, SkinsLibrary.Packs.Camo, "Purple Camo", "rbxassetid://4386336507", Color3.fromRGB(49, 43, 72), Vector2.new(1, 1));
NewTexture(16, SkinsLibrary.Packs.Camo, "Pink Camo", "rbxassetid://4386337276", Color3.fromRGB(67, 41, 72), Vector2.new(1, 1));
NewTexture(17, SkinsLibrary.Packs.Camo, "White Camo", "rbxassetid://4386480680", Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));
NewTexture(18, SkinsLibrary.Packs.Camo, "Grey Camo", "rbxassetid://4386479893", Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));
NewTexture(19, SkinsLibrary.Packs.Camo, "Black Camo", "rbxassetid://4386481250", Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));

--== Texture Pack: Xmas
NewTexture(20, SkinsLibrary.Packs.Xmas, "Stripes Wrapping Paper 1", "rbxassetid://4527242130", Color3.fromRGB(180, 180, 180), Vector2.new(0.3, 0.3));
NewTexture(21, SkinsLibrary.Packs.Xmas, "Stripes Wrapping Paper 2", "rbxassetid://4527242331", Color3.fromRGB(180, 180, 180), Vector2.new(0.3, 0.3));
NewTexture(22, SkinsLibrary.Packs.Xmas, "Stars Wrapping Paper 1", "rbxassetid://4527242469", Color3.fromRGB(180, 180, 180), Vector2.new(0.1, 0.1));
NewTexture(23, SkinsLibrary.Packs.Xmas, "Stars Wrapping Paper 2", "rbxassetid://4527242591", Color3.fromRGB(180, 180, 180), Vector2.new(0.1, 0.1));
NewTexture(24, SkinsLibrary.Packs.Xmas, "Crystal Wrapping Paper 1", "rbxassetid://4527242713", Color3.fromRGB(180, 180, 180), Vector2.new(0.2, 0.2));
NewTexture(25, SkinsLibrary.Packs.Xmas, "Crystal Wrapping Paper 2", "rbxassetid://4527242820", Color3.fromRGB(180, 180, 180), Vector2.new(0.2, 0.2));
NewTexture(26, SkinsLibrary.Packs.Xmas, "Crystal Wrapping Paper 3", "rbxassetid://4527259843", Color3.fromRGB(180, 180, 180), Vector2.new(0.2, 0.2));
NewTexture(27, SkinsLibrary.Packs.Xmas, "Crystal Wrapping Paper 4", "rbxassetid://4527259963", Color3.fromRGB(180, 180, 180), Vector2.new(0.2, 0.2));
NewTexture(28, SkinsLibrary.Packs.Xmas, "Checkers Wrapping Paper 1", "rbxassetid://4527257042", Color3.fromRGB(180, 180, 180), Vector2.new(0.5, 0.5));
NewTexture(29, SkinsLibrary.Packs.Xmas, "Checkers Wrapping Paper 2", "rbxassetid://4527242932", Color3.fromRGB(180, 180, 180), Vector2.new(0.5, 0.5));
NewTexture(30, SkinsLibrary.Packs.Xmas, "Checkers Wrapping Paper 3", "rbxassetid://4527256263", Color3.fromRGB(180, 180, 180), Vector2.new(0.5, 0.5));

--== Texture Pack: StreetArt
NewTexture(31, SkinsLibrary.Packs.StreetArt, "Jerry", {
	{Id="rbxassetid://4610326832"; Rotations={"rbxassetid://4610890070"; "rbxassetid://4610905873"; "rbxassetid://4610907110";};};
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));
NewTexture(32, SkinsLibrary.Packs.StreetArt, "The Helix", {
	{Id="rbxassetid://4611060133"; Rotations={"rbxassetid://4611068146"; "rbxassetid://4611068392"; "rbxassetid://4611068901";};};
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));
NewTexture(33, SkinsLibrary.Packs.StreetArt, "Genetical", {
	{Id="rbxassetid://4611094988"; Rotations={"rbxassetid://4611106796"; "rbxassetid://4611107124"; "rbxassetid://4611107401";};};
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));
NewTexture(34, SkinsLibrary.Packs.StreetArt, "WaveMix", {
	{Id="rbxassetid://4641413755"; Rotations={"rbxassetid://4641426526"; "rbxassetid://4641428407"; "rbxassetid://4641429840";};};
}, Color3.fromRGB(170, 170, 170), Vector2.new(3, 3));

--== Texture Pack: Wireframe
NewTexture(41, SkinsLibrary.Packs.Wireframe, "Red", {
	{Id="rbxassetid://4790500605"; Rotations={"rbxassetid://4790500605"; "rbxassetid://4790500605"; "rbxassetid://4790500605";};};
}, Color3.fromRGB(255, 0, 0), Vector2.new(1, 1));
NewTexture(42, SkinsLibrary.Packs.Wireframe, "Green", {
	{Id="rbxassetid://4790500605"; Rotations={"rbxassetid://4790500605"; "rbxassetid://4790500605"; "rbxassetid://4790500605";};};
}, Color3.fromRGB(0, 255, 0), Vector2.new(1, 1));
NewTexture(43, SkinsLibrary.Packs.Wireframe, "Blue", {
	{Id="rbxassetid://4790500605"; Rotations={"rbxassetid://4790500605"; "rbxassetid://4790500605"; "rbxassetid://4790500605";};};
}, Color3.fromRGB(0, 213, 255), Vector2.new(1, 1));
NewTexture(44, SkinsLibrary.Packs.Wireframe, "Yellow", {
	{Id="rbxassetid://4790500605"; Rotations={"rbxassetid://4790500605"; "rbxassetid://4790500605"; "rbxassetid://4790500605";};};
}, Color3.fromRGB(255, 255, 0), Vector2.new(1, 1));
NewTexture(45, SkinsLibrary.Packs.Wireframe, "Purple", {
	{Id="rbxassetid://4790500605"; Rotations={"rbxassetid://4790500605"; "rbxassetid://4790500605"; "rbxassetid://4790500605";};};
}, Color3.fromRGB(93, 0, 255), Vector2.new(1, 1));
NewTexture(46, SkinsLibrary.Packs.Wireframe, "Pink", {
	{Id="rbxassetid://4790500605"; Rotations={"rbxassetid://4790500605"; "rbxassetid://4790500605"; "rbxassetid://4790500605";};};
}, Color3.fromRGB(255, 0, 255), Vector2.new(1, 1));
NewTexture(47, SkinsLibrary.Packs.Wireframe, "White", {
	{Id="rbxassetid://4790500605"; Rotations={"rbxassetid://4790500605"; "rbxassetid://4790500605"; "rbxassetid://4790500605";};};
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));
NewTexture(48, SkinsLibrary.Packs.Wireframe, "Grey", {
	{Id="rbxassetid://4790500605"; Rotations={"rbxassetid://4790500605"; "rbxassetid://4790500605"; "rbxassetid://4790500605";};};
}, Color3.fromRGB(128, 128, 128), Vector2.new(1, 1));
NewTexture(49, SkinsLibrary.Packs.Wireframe, "Black", {
	{Id="rbxassetid://4790500605"; Rotations={"rbxassetid://4790500605"; "rbxassetid://4790500605"; "rbxassetid://4790500605";};};
}, Color3.fromRGB(0, 0, 0), Vector2.new(1, 1));

--== Texture Pack: EasterSkins
NewTexture(50, SkinsLibrary.Packs.EasterSkins, "Green Egg 1", {
	"rbxassetid://4835841001";
}, Color3.fromRGB(187, 255, 171), Vector2.new(0.2, 0.2));

NewTexture(52, SkinsLibrary.Packs.EasterSkins, "Pink Egg 1", {
	"rbxassetid://4835841001";
}, Color3.fromRGB(255, 181, 217), Vector2.new(0.2, 0.2));

NewTexture(53, SkinsLibrary.Packs.EasterSkins, "Blue Egg 1", {
	"rbxassetid://4835841001";
}, Color3.fromRGB(175, 223, 255), Vector2.new(0.2, 0.2));

NewTexture(54, SkinsLibrary.Packs.EasterSkins, "Yellow Egg 1", {
	"rbxassetid://4835841001";
}, Color3.fromRGB(255, 243, 175), Vector2.new(0.2, 0.2));

--
NewTexture(55, SkinsLibrary.Packs.EasterSkins, "Green Egg 2", {
	"rbxassetid://4836204240";
}, Color3.fromRGB(187, 255, 171), Vector2.new(0.2, 0.2));

NewTexture(56, SkinsLibrary.Packs.EasterSkins, "Pink Egg 2", {
	"rbxassetid://4836204240";
}, Color3.fromRGB(255, 181, 217), Vector2.new(0.2, 0.2));

NewTexture(57, SkinsLibrary.Packs.EasterSkins, "Blue Egg 2", {
	"rbxassetid://4836204240";
}, Color3.fromRGB(175, 223, 255), Vector2.new(0.2, 0.2));

NewTexture(58, SkinsLibrary.Packs.EasterSkins, "Yellow Egg 2", {
	"rbxassetid://4836204240";	
}, Color3.fromRGB(255, 243, 175), Vector2.new(0.2, 0.2));

--
NewTexture(59, SkinsLibrary.Packs.EasterSkins, "Orange Egg Stripe", {
	"rbxassetid://4835841305";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));

NewTexture(60, SkinsLibrary.Packs.EasterSkins, "Purple Egg Stripe", {
	"rbxassetid://4835841576";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));

NewTexture(61, SkinsLibrary.Packs.EasterSkins, "Turquoise Egg Stripe", {
	"rbxassetid://4835841746";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));

--== Texture Pack: Wraps;
NewTexture(70, SkinsLibrary.Packs.Wraps, "Bandage Wraps", {
	"rbxassetid://5065061974";
}, Color3.fromRGB(200, 200, 200), Vector2.new(0.5, 0.5));
NewTexture(71, SkinsLibrary.Packs.Wraps, "Bandage Wraps 90", {
	"rbxassetid://5065128803";
}, Color3.fromRGB(200, 200, 200), Vector2.new(0.5, 0.5));
NewTexture(72, SkinsLibrary.Packs.Wraps, "Yellow Bandage Wraps", {
	"rbxassetid://5065061974";
}, Color3.fromRGB(113, 90, 57), Vector2.new(0.5, 0.5));
NewTexture(73, SkinsLibrary.Packs.Wraps, "Yellow Bandage Wraps 90", {
	"rbxassetid://5065128803";
}, Color3.fromRGB(113, 90, 57), Vector2.new(0.5, 0.5));
NewTexture(74, SkinsLibrary.Packs.Wraps, "Brown Bandage Wraps", {
	"rbxassetid://5065061974";
}, Color3.fromRGB(77, 55, 40), Vector2.new(0.5, 0.5));
NewTexture(75, SkinsLibrary.Packs.Wraps, "Brown Bandage Wraps 90", {
	"rbxassetid://5065128803";
}, Color3.fromRGB(77, 55, 40), Vector2.new(0.5, 0.5));
NewTexture(76, SkinsLibrary.Packs.Wraps, "Transparent Bandage Wraps", {
	"rbxassetid://5065128031";
}, Color3.fromRGB(255, 255, 255), Vector2.new(0.5, 0.5));
NewTexture(77, SkinsLibrary.Packs.Wraps, "Transparent Bandage Wraps 90", {
	"rbxassetid://5065127222";
}, Color3.fromRGB(255, 255, 255), Vector2.new(0.5, 0.5));

--== Texture Pack: ScalePlating;
NewTexture(80, SkinsLibrary.Packs.ScalePlating, "Blue Scales Plating", {
	"rbxassetid://5180756308";
}, Color3.fromRGB(255, 255, 255), Vector2.new(0.5, 0.5));
NewTexture(81, SkinsLibrary.Packs.ScalePlating, "Dark Blue Scales Plating", {
	"rbxassetid://5180763234";
}, Color3.fromRGB(255, 255, 255), Vector2.new(0.5, 0.5));
NewTexture(82, SkinsLibrary.Packs.ScalePlating, "Green Scales Plating", {
	"rbxassetid://5180764589";
}, Color3.fromRGB(255, 255, 255), Vector2.new(0.5, 0.5));
NewTexture(83, SkinsLibrary.Packs.ScalePlating, "Orange Scales Plating", {
	"rbxassetid://5180765908";
}, Color3.fromRGB(255, 255, 255), Vector2.new(0.5, 0.5));
NewTexture(84, SkinsLibrary.Packs.ScalePlating, "Pink Scales Plating", {
	"rbxassetid://5180767362";
}, Color3.fromRGB(255, 255, 255), Vector2.new(0.5, 0.5));
NewTexture(85, SkinsLibrary.Packs.ScalePlating, "Purple Scales Plating", {
	"rbxassetid://5180768559";
}, Color3.fromRGB(255, 255, 255), Vector2.new(0.5, 0.5));
NewTexture(86, SkinsLibrary.Packs.ScalePlating, "Red Scales Plating", {
	"rbxassetid://5180770264";
}, Color3.fromRGB(255, 255, 255), Vector2.new(0.5, 0.5));
NewTexture(87, SkinsLibrary.Packs.ScalePlating, "Yellow Scales Plating", {
	"rbxassetid://5180771371";
}, Color3.fromRGB(255, 255, 255), Vector2.new(0.5, 0.5));
NewTexture(88, SkinsLibrary.Packs.ScalePlating, "Rainbow Scales Plating", {
	"rbxassetid://5180772738";
}, Color3.fromRGB(255, 255, 255), Vector2.new(0.5, 0.5));


--== Texture Pack: CarbonFiber;
NewTexture(90, SkinsLibrary.Packs.CarbonFiber, "Blue Scales Plating", {
	"rbxassetid://5635457255";
}, Color3.fromRGB(19, 80, 126), Vector2.new(0.5, 0.5));
NewTexture(91, SkinsLibrary.Packs.CarbonFiber, "Dark Grey Scales Plating", {
	"rbxassetid://5635457255";
}, Color3.fromRGB(50, 50, 50), Vector2.new(0.5, 0.5));
NewTexture(92, SkinsLibrary.Packs.CarbonFiber, "Green Scales Plating", {
	"rbxassetid://5635457255";
}, Color3.fromRGB(29, 68, 21), Vector2.new(0.5, 0.5));
NewTexture(93, SkinsLibrary.Packs.CarbonFiber, "Orange Scales Plating", {
	"rbxassetid://5635457255";
}, Color3.fromRGB(122, 69, 51), Vector2.new(0.5, 0.5));
NewTexture(94, SkinsLibrary.Packs.CarbonFiber, "Pink Scales Plating", {
	"rbxassetid://5635457255";
}, Color3.fromRGB(102, 60, 82), Vector2.new(0.5, 0.5));
NewTexture(95, SkinsLibrary.Packs.CarbonFiber, "Purple Scales Plating", {
	"rbxassetid://5635457255";
}, Color3.fromRGB(69, 50, 95), Vector2.new(0.5, 0.5));
NewTexture(96, SkinsLibrary.Packs.CarbonFiber, "Red Scales Plating", {
	"rbxassetid://5635457255";
}, Color3.fromRGB(95, 53, 54), Vector2.new(0.5, 0.5));
NewTexture(97, SkinsLibrary.Packs.CarbonFiber, "Yellow Scales Plating", {
	"rbxassetid://5635457255";
}, Color3.fromRGB(109, 107, 57), Vector2.new(0.5, 0.5));
NewTexture(98, SkinsLibrary.Packs.CarbonFiber, "Rainbow Scales Plating", {
	"rbxassetid://5635675457";
}, Color3.fromRGB(140, 140, 140), Vector2.new(0.5, 0.5));


--== Texture Pack: Halloween;
NewTexture(110, SkinsLibrary.Packs.Halloween, "Orange Pumpkins", {
	"rbxassetid://5888890391";
}, Color3.fromRGB(255, 106, 0), Vector2.new(0.5, 0.5));
NewTexture(111, SkinsLibrary.Packs.Halloween, "Purple Pumpkins", {
	"rbxassetid://5888890391";
}, Color3.fromRGB(106, 0, 255), Vector2.new(0.5, 0.5));
NewTexture(112, SkinsLibrary.Packs.Halloween, "Green Pumpkins", {
	"rbxassetid://5888890391";
}, Color3.fromRGB(27, 106, 23), Vector2.new(0.5, 0.5));
NewTexture(113, SkinsLibrary.Packs.Halloween, "Orange Skulls", {
	"rbxassetid://5888891774";
}, Color3.fromRGB(255, 106, 0), Vector2.new(0.5, 0.5));
NewTexture(114, SkinsLibrary.Packs.Halloween, "Purple Skulls", {
	"rbxassetid://5888891774";
}, Color3.fromRGB(106, 0, 255), Vector2.new(0.5, 0.5));
NewTexture(115, SkinsLibrary.Packs.Halloween, "Green Skulls", {
	"rbxassetid://5888891774";
}, Color3.fromRGB(27, 106, 23), Vector2.new(0.5, 0.5));
NewTexture(116, SkinsLibrary.Packs.Halloween, "Orange Witch hats", {
	"rbxassetid://5888922149";
}, Color3.fromRGB(255, 106, 0), Vector2.new(0.5, 0.5));
NewTexture(117, SkinsLibrary.Packs.Halloween, "Purple Witch hats", {
	"rbxassetid://5888922149";
}, Color3.fromRGB(106, 0, 255), Vector2.new(0.5, 0.5));
NewTexture(118, SkinsLibrary.Packs.Halloween, "Green Witch hats", {
	"rbxassetid://5888922149";
}, Color3.fromRGB(27, 106, 23), Vector2.new(0.5, 0.5));


--
NewTexture(120, SkinsLibrary.Packs.FestiveWrapping, "Festive Wrapping 01", "rbxassetid://6109052204", Color3.fromRGB(255, 255, 255), Vector2.new(0.1, 0.1));
NewTexture(121, SkinsLibrary.Packs.FestiveWrapping, "Festive Wrapping 02", "rbxassetid://6109059756", Color3.fromRGB(255, 255, 255), Vector2.new(0.1, 0.1));
NewTexture(122, SkinsLibrary.Packs.FestiveWrapping, "Festive Wrapping 03", "rbxassetid://6109074464", Color3.fromRGB(255, 255, 255), Vector2.new(0.1, 0.1));
NewTexture(123, SkinsLibrary.Packs.FestiveWrapping, "Festive Wrapping 04", "rbxassetid://6109088388", Color3.fromRGB(255, 255, 255), Vector2.new(0.1, 0.1));
NewTexture(124, SkinsLibrary.Packs.FestiveWrapping, "Festive Wrapping 05", "rbxassetid://6109084797", Color3.fromRGB(255, 255, 255), Vector2.new(0.1, 0.1));
NewTexture(125, SkinsLibrary.Packs.FestiveWrapping, "Festive Wrapping 06", "rbxassetid://6109085983", Color3.fromRGB(255, 255, 255), Vector2.new(0.1, 0.1));
NewTexture(126, SkinsLibrary.Packs.FestiveWrapping, "Festive Wrapping 07", "rbxassetid://6109157985", Color3.fromRGB(255, 255, 255), Vector2.new(0.5, 0.5));
NewTexture(127, SkinsLibrary.Packs.FestiveWrapping, "Festive Wrapping 08", "rbxassetid://6109215107", Color3.fromRGB(255, 255, 255), Vector2.new(0.2, 0.2));

NewTexture(130, SkinsLibrary.Packs.Hexatiles, "Hexatiles Red", "rbxassetid://6534768496", Color3.fromRGB(140, 49, 51), Vector2.new(0.2, 0.2));
NewTexture(131, SkinsLibrary.Packs.Hexatiles, "Hexatiles Blue", "rbxassetid://6534768496", Color3.fromRGB(49, 49, 140), Vector2.new(0.2, 0.2));
NewTexture(132, SkinsLibrary.Packs.Hexatiles, "Hexatiles Green", "rbxassetid://6534768496", Color3.fromRGB(58, 140, 49), Vector2.new(0.2, 0.2));
NewTexture(133, SkinsLibrary.Packs.Hexatiles, "Hexatiles Yellow", "rbxassetid://6534768496", Color3.fromRGB(140, 120, 49), Vector2.new(0.2, 0.2));
NewTexture(134, SkinsLibrary.Packs.Hexatiles, "Hexatiles Orange", "rbxassetid://6534768496", Color3.fromRGB(140, 84, 49), Vector2.new(0.2, 0.2));
NewTexture(135, SkinsLibrary.Packs.Hexatiles, "Hexatiles Purple", "rbxassetid://6534768496", Color3.fromRGB(91, 49, 140), Vector2.new(0.2, 0.2));
NewTexture(136, SkinsLibrary.Packs.Hexatiles, "Hexatiles Pink", "rbxassetid://6534768496", Color3.fromRGB(140, 49, 129), Vector2.new(0.2, 0.2));
NewTexture(137, SkinsLibrary.Packs.Hexatiles, "Hexatiles Cyan", "rbxassetid://6534768496", Color3.fromRGB(49, 113, 140), Vector2.new(0.2, 0.2));
NewTexture(138, SkinsLibrary.Packs.Hexatiles, "Hexatiles Rainbow", "rbxassetid://6534829842", Color3.fromRGB(255, 255, 255), Vector2.new(0.8, 0.8));

--== HalloweenPixelArt
NewTexture(140, SkinsLibrary.Packs.HalloweenPixelArt, "Spooky Skeletons", {
	"rbxassetid://7605195491";
}, Color3.fromRGB(255, 255, 255), Vector2.new(0.3, 0.3)); --
NewTexture(141, SkinsLibrary.Packs.HalloweenPixelArt, "Zombie Face", {
	"rbxassetid://7605205046";
}, Color3.fromRGB(255, 255, 255), Vector2.new(0.5, 0.5));
NewTexture(142, SkinsLibrary.Packs.HalloweenPixelArt, "Possessed Jane", {
	"rbxassetid://7605214869";
}, Color3.fromRGB(255, 255, 255), Vector2.new(0.2, 0.2));
NewTexture(143, SkinsLibrary.Packs.HalloweenPixelArt, "Haunted Ghost", {
	"rbxassetid://7605218975";
}, Color3.fromRGB(255, 255, 255), Vector2.new(0.4, 0.4));
NewTexture(144, SkinsLibrary.Packs.HalloweenPixelArt, "Cursed Cat", {
	"rbxassetid://7605222982";
}, Color3.fromRGB(255, 255, 255), Vector2.new(0.6, 0.6));
NewTexture(145, SkinsLibrary.Packs.HalloweenPixelArt, "Spooky Skeletons RGB", {
	"rbxassetid://7605228557";
}, Color3.fromRGB(255, 255, 255), Vector2.new(0.3, 0.3));
NewTexture(146, SkinsLibrary.Packs.HalloweenPixelArt, "Haunted Ghost RGB", {
	"rbxassetid://7605250341";
}, Color3.fromRGB(255, 255, 255), Vector2.new(0.4, 0.4));

--== Texture Pack: Offline
NewTexture(150, SkinsLibrary.Packs.Offline, "Colored Static", {
	"rbxassetid://7866772353";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));
NewTexture(151, SkinsLibrary.Packs.Offline, "Pink Static", {
	"rbxassetid://7866772353";
}, Color3.fromRGB(255, 0, 255), Vector2.new(1, 1));
NewTexture(152, SkinsLibrary.Packs.Offline, "Cyan Static", {
	"rbxassetid://7866772353";
}, Color3.fromRGB(0, 255, 255), Vector2.new(1, 1));
NewTexture(153, SkinsLibrary.Packs.Offline, "Lime Static", {
	"rbxassetid://7866772353";
}, Color3.fromRGB(255, 255, 0), Vector2.new(1, 1));
NewTexture(154, SkinsLibrary.Packs.Offline, "Mono Static", {
	"rbxassetid://7866840036";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));

NewTexture(160, SkinsLibrary.Packs.Ice, "Red", {
	"rbxassetid://8532292678";
}, Color3.fromRGB(255, 105, 105), Vector2.new(4, 4));
NewTexture(161, SkinsLibrary.Packs.Ice, "Green", {
	"rbxassetid://8532360403";
}, Color3.fromRGB(105, 255, 105), Vector2.new(4, 4));
NewTexture(162, SkinsLibrary.Packs.Ice, "Blue", {
	"rbxassetid://8532366520";
}, Color3.fromRGB(105, 105, 255), Vector2.new(4, 4));
NewTexture(163, SkinsLibrary.Packs.Ice, "Purple", {
	"rbxassetid://8532292678";
}, Color3.fromRGB(255, 105, 255), Vector2.new(4, 4));
NewTexture(164, SkinsLibrary.Packs.Ice, "Cyan", {
	"rbxassetid://8532360403";
}, Color3.fromRGB(105, 255, 255), Vector2.new(4, 4));
NewTexture(165, SkinsLibrary.Packs.Ice, "Yellow", {
	"rbxassetid://8532366520";
}, Color3.fromRGB(255, 255, 105), Vector2.new(4, 4));
NewTexture(166, SkinsLibrary.Packs.Ice, "White", {
	"rbxassetid://8532292678";
}, Color3.fromRGB(255, 255, 255), Vector2.new(4, 4));
NewTexture(167, SkinsLibrary.Packs.Ice, "Grey", {
	"rbxassetid://8532360403";
}, Color3.fromRGB(100, 100, 100), Vector2.new(4, 4));
NewTexture(168, SkinsLibrary.Packs.Ice, "Black", {
	"rbxassetid://8532366520";
}, Color3.fromRGB(50, 50, 50), Vector2.new(4, 4));


--== Texture Pack: Easter 2023
NewTexture(170, SkinsLibrary.Packs.Easter2023, "Purple Egg", {
	"rbxassetid://12961909431";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));

NewTexture(171, SkinsLibrary.Packs.Easter2023, "Green Egg", {
	"rbxassetid://12961914801";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));

NewTexture(172, SkinsLibrary.Packs.Easter2023, "Cherry Blossom Egg", {
	"rbxassetid://12961916162";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));
NewTexture(173, SkinsLibrary.Packs.Easter2023, "Purple Egg 2", {
	"rbxassetid://12961909431";
}, Color3.fromRGB(255, 255, 255), Vector2.new(0.5, 0.5));

NewTexture(174, SkinsLibrary.Packs.Easter2023, "Green Egg 2", {
	"rbxassetid://12961914801";
}, Color3.fromRGB(255, 255, 255), Vector2.new(0.5, 0.5));

NewTexture(175, SkinsLibrary.Packs.Easter2023, "Cherry Blossom Egg 2", {
	"rbxassetid://12961916162";
}, Color3.fromRGB(255, 255, 255), Vector2.new(0.5, 0.5));


--== Windtrails
NewTexture(180, SkinsLibrary.Packs.Windtrails, "Wind Vertical", {
	"rbxassetid://14249893630";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1.5, 1));
NewTexture(181, SkinsLibrary.Packs.Windtrails, "Wind Horizontal", {
	"rbxassetid://14249961683";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1.5, 1));
NewTexture(182, SkinsLibrary.Packs.Windtrails, "Wind 2 Right", {
	"rbxassetid://14250624431";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1.5, 1));
NewTexture(183, SkinsLibrary.Packs.Windtrails, "Wind 2 Up", {
	"rbxassetid://14250629686";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1.5, 1));
NewTexture(184, SkinsLibrary.Packs.Windtrails, "Cloud 1 Right", {
	"rbxassetid://14250875240";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));
NewTexture(185, SkinsLibrary.Packs.Windtrails, "Cloud 1 Left", {
	"rbxassetid://14250921231";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));
NewTexture(186, SkinsLibrary.Packs.Windtrails, "Cloud 1 Up", {
	"rbxassetid://14250924060";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));
NewTexture(187, SkinsLibrary.Packs.Windtrails, "Cloud 1 Down", {
	"rbxassetid://14250925805";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));


--== CuteButScary
NewTexture(190, SkinsLibrary.Packs.CuteButScary, "Pumpkins 1", {
	"rbxassetid://15016449317";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));
NewTexture(191, SkinsLibrary.Packs.CuteButScary, "Pumpkins 2", {
	"rbxassetid://15016458759";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));

NewTexture(192, SkinsLibrary.Packs.CuteButScary, "Skulls 1", {
	"rbxassetid://15016462697";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));
NewTexture(193, SkinsLibrary.Packs.CuteButScary, "Skulls 2", {
	"rbxassetid://15016466372";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));
NewTexture(194, SkinsLibrary.Packs.CuteButScary, "Skulls BW", {
	"rbxassetid://15016503835";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));
NewTexture(195, SkinsLibrary.Packs.CuteButScary, "Skulls RGB", {
	"rbxassetid://15016521823";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));

NewTexture(196, SkinsLibrary.Packs.CuteButScary, "Ghosts 1", {
	"rbxassetid://15016470436";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));
NewTexture(197, SkinsLibrary.Packs.CuteButScary, "Ghosts 2", {
	"rbxassetid://15016474733";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));
NewTexture(198, SkinsLibrary.Packs.CuteButScary, "Ghosts BW", {
	"rbxassetid://15016524848";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));
NewTexture(199, SkinsLibrary.Packs.CuteButScary, "Ghosts RGB", {
	"rbxassetid://15016528084";
}, Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));


--== Skin Pack: Fancy
local FancyTypes = {
	{""; Color3.fromRGB(255, 255, 255)};
	{"Red"; Color3.fromRGB(255, 0, 0)};
	{"Green"; Color3.fromRGB(0, 255, 0)};
	{"Blue"; Color3.fromRGB(0, 0, 255)};
};
local FancyId = 300;
for a=1, #FancyTypes do
	FancyId = FancyId +1;
	NewTexture(FancyId, SkinsLibrary.Packs.Fancy, FancyTypes[a][1].."Fancy", {
		"rbxassetid://17282157675";
	}, FancyTypes[a][2], Vector2.new(2, 2));
	FancyId = FancyId +1;
	NewTexture(FancyId, SkinsLibrary.Packs.Fancy, FancyTypes[a][1].."Fancy Inner Shadow", {
		"rbxassetid://17282156952";
	}, FancyTypes[a][2], Vector2.new(2, 2));
	FancyId = FancyId +1;
	NewTexture(FancyId, SkinsLibrary.Packs.Fancy, FancyTypes[a][1].."Fancy Glow", {
		"rbxassetid://17282157229";
	}, FancyTypes[a][2], Vector2.new(2, 2));
	FancyId = FancyId +1;
	NewTexture(FancyId, SkinsLibrary.Packs.Fancy, FancyTypes[a][1].."Fancy Bevel", {
		"rbxassetid://17282157420";
	}, FancyTypes[a][2], Vector2.new(2, 2));
end


--== Texture Pack: Special
NewTexture(101, SkinsLibrary.Packs.Special, "Diamonds", "rbxassetid://2751750764", Color3.fromRGB(79, 238, 255), Vector2.new(0.1, 0.1));
NewTexture(102, SkinsLibrary.Packs.Special, "DeathCamo", "rbxassetid://4386399917", Color3.fromRGB(255, 255, 255), Vector2.new(1, 1));
NewTexture(103, SkinsLibrary.Packs.Special, "Cosmos", "rbxassetid://4873625719", Color3.fromRGB(255, 255, 255), Vector2.new(4, 4));

AddTexture{
	Id=104;
	Name="Galaxy";
	Pack=SkinsLibrary.Packs.Special;
	TextureData={
		{Id="rbxassetid://8769490320"; AlphaMap={Min=0; Max=0;}; StudTileUV=Vector2.new(2, 2);};
	};
	CanClear=false;
}

NewTexture(105, SkinsLibrary.Packs.Special, "Frostivus", {
	{Id="rbxassetid://11796319046"; ZIndex=2; StudTileUV=Vector2.new(1, 1);};
	{Id="rbxassetid://11796312620"; ZIndex=1; StudTileUV=Vector2.new(1, 1);}; -- background
});
NewTexture(106, SkinsLibrary.Packs.Special, "Fortune", {
	{Id="rbxassetid://11853778222"; StudTileUV=Vector2.new(0.3, 0.3);};
});

NewTexture(107, SkinsLibrary.Packs.Special, "Fallen Leaves", {
	{Id="rbxassetid://12960875825"; ZIndex=2; StudTileUV=Vector2.new(1, 1); Attributes={ColorA=Color3.fromRGB(74, 179, 86); ColorB=Color3.fromRGB(180, 169, 42);}};
	{Id="rbxassetid://12960941945"; ZIndex=1; StudTileUV=Vector2.new(1, 1); Color=Color3.fromRGB(170, 255, 201);};
});

NewTexture(108, SkinsLibrary.Packs.Special, "Cherry Blossom", {
	{Id="rbxassetid://12960875825"; ZIndex=2; StudTileUV=Vector2.new(1, 1); Attributes={ColorA=Color3.fromRGB(238, 107, 131); ColorB=Color3.fromRGB(251, 120, 255);}};
	{Id="rbxassetid://12960941945"; ZIndex=1; StudTileUV=Vector2.new(1, 1); Color=Color3.fromRGB(254, 231, 255);};
});

NewTexture(109, SkinsLibrary.Packs.Special, "Dev Textures", "rbxassetid://17633873288", Color3.fromRGB(255, 255, 255), Vector2.new(4, 4));

--== Skin Pack: Full
AddTexture{
	Id=201;
	Name="Toy Gun";
	Pack=SkinsLibrary.Packs.Full;
	TextureData={
		["czevo3"]={Id="rbxassetid://5013618682";};
		["desolatorheavy"]={Id="rbxassetid://12929982078";};
	};
	IsUVTexture=true;
};

AddTexture{
	Id=202;
	Name="Asiimov";
	Pack=SkinsLibrary.Packs.Full;
	TextureData={
		["czevo3"]={Id="rbxassetid://13846887623";};
	};
	IsUVTexture=true;
};

AddTexture{
	Id=203;
	Name="Antique";
	Pack=SkinsLibrary.Packs.Full;
	TextureData={
		["arelshiftcross"]={Id="rbxassetid://13157322160";};
	};
	IsSurfaceAppearance=true;
	IsUVTexture=true;
};

AddTexture{
	Id=204;
	Name="Blaze";
	Pack=SkinsLibrary.Packs.Full;
	TextureData={
		["rusty48"]={Id="rbxassetid://13822368962";};
		["flamethrower"]={Id="rbxassetid://17229432117";};
	};
	IsUVTexture=true;
};

AddTexture{
	Id=205;
	Name="Slaughter Woods";
	Pack=SkinsLibrary.Packs.Full;
	TextureData={
		["sr308"]={Id="rbxassetid://16494491062";}; --rbxassetid://15004595476
	};
	IsSurfaceAppearance=true;
	IsUVTexture=true;
};

AddTexture{
	Id=206;
	Name="Possession";
	Pack=SkinsLibrary.Packs.Full;
	TextureData={
		["vectorx"]={Id="rbxassetid://15006578225";};
	};
	IsUVTexture=true;
};

AddTexture{
	Id=207;
	Name="Horde";
	Pack=SkinsLibrary.Packs.Full;
	TextureData={
		["sr308"]={Id="rbxassetid://16570456572";};
	};
	IsSurfaceAppearance=true;
	IsUVTexture=true;
};

AddTexture{
	Id=208;
	Name="Cryogenics";
	Pack=SkinsLibrary.Packs.Full;
	TextureData={
		["deagle"]={Id="rbxassetid://17227620804";};
	};
	IsSurfaceAppearance=true;
	IsUVTexture=true;
};




return SkinsLibrary;