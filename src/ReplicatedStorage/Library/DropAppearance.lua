local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local library = modLibraryManager.new();
local normals = {Enum.NormalId.Back; Enum.NormalId.Bottom; Enum.NormalId.Front; Enum.NormalId.Left; Enum.NormalId.Right; Enum.NormalId.Top};

local modItemLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

library:Add{
	Id="factorycrate";
	Scale=4;
	Offset=CFrame.new(0, -1, 0);
};

library:Add{
	Id="officecrate";
	Scale=4;
	Offset=CFrame.new(0, -1, 0);
};

library:Add{
	Id="sectorfcrate";
	Scale=4;
	Offset=CFrame.new(0, -1, 0);
	Parts={
		["Top"]={Color=Color3.fromRGB(94, 125, 114)};
		["LeftHandle"]={Color=Color3.fromRGB(77, 103, 94)};
		["RightHandle"]={Color=Color3.fromRGB(77, 103, 94)};
		["Bottom"]={Color=Color3.fromRGB(77, 103, 94)};
	};
};

library:Add{
	Id="ucsectorfcrate";
	Scale=4;
	Offset=CFrame.new(0, -1, 0);
	Parts={
		["Top"]={Color=Color3.fromRGB(94, 125, 114); Reflectance=0.4; Material=Enum.Material.SmoothPlastic; Texture=script.SoftNoise;};
		["LeftHandle"]={Color=Color3.fromRGB(77, 103, 94); Reflectance=0.4; Material=Enum.Material.SmoothPlastic; Texture=script.SoftNoise;};
		["RightHandle"]={Color=Color3.fromRGB(77, 103, 94); Reflectance=0.4; Material=Enum.Material.SmoothPlastic; Texture=script.SoftNoise;};
		["Bottom"]={Color=Color3.fromRGB(77, 103, 94); Reflectance=0.4; Material=Enum.Material.SmoothPlastic; Texture=script.SoftNoise;};
	};
	DropTier=3;
};

library:Add{
	Id="prisoncrate";
	Scale=4;
	Offset=CFrame.new(0, -1, 0);
	GlowImageSize=4;
	Parts={
		["Top"]={};
		["Top2"]={};
		["Base3"]={};
		["base"]={};
		["base02"]={};
		["hinge"]={};
	};
};

library:Add{
	Id="nprisoncrate";
	Scale=4;
	Offset=CFrame.new(0, -1, 0);
	GlowImageSize=4;
	Parts={
		["Top"]={Texture=script.SoftNoise;};
		["Top2"]={Texture=script.SoftNoise;};
		["Base3"]={Texture=script.SoftNoise;};
		["base"]={Texture=script.SoftNoise;};
		["base02"]={Texture=script.SoftNoise;};
		["hinge"]={Texture=script.SoftNoise;};
	};
	DropTier=2;
};

library:Add{
	Id="tombschest";
	Scale=4;
	Offset=CFrame.new(0, -1, 0);
	GlowImageSize=4;
};

library:Add{
	Id="banditcrate";
	Scale=4;
	Offset=CFrame.new(0, -0.5, 0);
	GlowImageSize=4;
};

library:Add{
	Id="hbanditcrate";
	Scale=4;
	Offset=CFrame.new(0, -0.5, 0);
	GlowImageSize=4;
	DropTier=3;
};

library:Add{
	Id="railwayscrate";
	Scale=4;
	Offset=CFrame.new(0, -0.75, 0);
	GlowImageSize=4;
};

library:Add{
	Id="barbedwooden";
	Scale=3;
	Offset=CFrame.new(0, -0.5, 0);
	GlowImageSize=4;
};

library:Add{
	Id="sectordcrate";
	Scale=4;
	Offset=CFrame.new(0, -1, 0);
	GlowImageSize=4;
};

library:Add{
	Id="ucsectordcrate";
	Scale=4;
	Offset=CFrame.new(0, -1, 0);
	GlowImageSize=4;
	DropTier=3;
};

library:Add{
	Id="genesiscrate";
	Scale=4;
	Offset=CFrame.new(0, -1, 0);
	GlowImageSize=4;
};

library:Add{
	Id="ggenesiscrate";
	Scale=4;
	Offset=CFrame.new(0, -1, 0);
	GlowImageSize=4;
	DropTier=3;
};

library:Add{
	Id="sunkenchest";
	Scale=4;
	Offset=CFrame.new(0, -1, 0);
	GlowImageSize=4;
};

library:Add{
	Id="communitycrate";
	Scale=4;
	Offset=CFrame.new(0, -1, 0);
	GlowImageSize=4;
};

library:Add{
	Id="communitycrate2";
	Scale=4;
	Offset=CFrame.new(0, -1, 0);
	GlowImageSize=4;
};

library:Add{
	Id="ammobox";
	Offset=CFrame.new(0, -0.5, 0);
};

library:Add{
	Id="abandonedbunkercrate";
	Scale=4;
	Offset=CFrame.new(0, -1, 0);
	GlowImageSize=4;
};

--== Resource Packages
local function applyResourceCrate(lib, model)
	local packageItemLib = modItemLibrary:Find(lib.Id);
	local resourceItemLib = modItemLibrary:Find(packageItemLib.ResourceItemId);

	for _, object in pairs(model:GetDescendants()) do
		if object:IsA("Decal") then
			object.Texture = resourceItemLib.Icon;
		end
	end
end;

library:Add{
	Id="metalpackage";
	Scale=4;
	Offset=CFrame.new(0, -1, 0);
	GlowImageSize=4;
	Apply=applyResourceCrate;
};

library:Add{
	Id="clothpackage";
	Scale=4;
	Offset=CFrame.new(0, -1, 0);
	GlowImageSize=4;
	Apply=applyResourceCrate;
};

library:Add{
	Id="glasspackage";
	Scale=4;
	Offset=CFrame.new(0, -1, 0);
	GlowImageSize=4;
	Apply=applyResourceCrate;
};

library:Add{
	Id="woodpackage";
	Scale=4;
	Offset=CFrame.new(0, -1, 0);
	GlowImageSize=4;
	Apply=applyResourceCrate;
};

function library.ApplyAppearance(dropAppearanceLib, prefab: Model)
	local toolDropPrimary = prefab.Parent;

	if toolDropPrimary then
		if toolDropPrimary:FindFirstChild("DropGlow") then
			pcall(function()
				local glowParticle = toolDropPrimary.DropGlow.Glow;
				local rayParticle = toolDropPrimary.DropGlow.Rays;
				
				glowParticle.Size = NumberSequence.new(dropAppearanceLib.Scale);
				rayParticle.Size = NumberSequence.new(dropAppearanceLib.Scale);
			end)
		end
	end

	for partName, appearanceData in pairs(dropAppearanceLib.Parts or {}) do
		local part = prefab:WaitForChild(partName);
		
		if appearanceData.Color then
			part.Color = appearanceData.Color;
		end
		if appearanceData.Reflectance then
			part.Reflectance = appearanceData.Reflectance;
		end
		if appearanceData.Material then
			part.Material = appearanceData.Material;
		end
		if appearanceData.Texture then
			for a=1, #normals do
				local texture = appearanceData.Texture:Clone();
				texture.Color3 = appearanceData.Color or Color3.fromRGB(255, 255, 255);
				texture.Face = normals[a];
				texture.Parent = part;
				
				texture:SetAttribute("TextureAnimationId", texture.Name);
				CollectionService:AddTag(texture, "AnimatedTextures");
			end
		end
	end
	
	if dropAppearanceLib.Apply then
		dropAppearanceLib.Apply(dropAppearanceLib, prefab);
	end
	
	prefab:SetAttribute("Tier", dropAppearanceLib.DropTier or 2);
end

return library;
