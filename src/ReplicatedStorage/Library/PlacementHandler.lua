local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local PlacementHandler = {};
PlacementHandler.__index = PlacementHandler;

local EnumColors = {
	Placable=Color3.fromRGB(93, 120, 93);
	Invalid=Color3.fromRGB(116, 90, 90);
}

PlacementHandler.EnumColors = EnumColors;
PlacementHandler.ActiveHighlight = nil;
--== Script;

function PlacementHandler.new(placementPrefab)
	local self = {};
	
	local new = placementPrefab:Clone();
	new.PrimaryPart.Anchored = true;
	
	self.PartsList = {};
	for _, obj in pairs(new:GetDescendants()) do
		if obj:IsA("BasePart") then
			table.insert(self.PartsList, obj);
			
		elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceAppearance") then
			obj:Destroy();
			
		end
	end
	
	self.Prefab = new;
	
	setmetatable(self, PlacementHandler);

	self:SetHighlightColor(EnumColors.Placable);
	
	return self;
end

function PlacementHandler:SetHighlightColor(color)
	if self.PartsList == nil then return end;
	
	for _, obj in pairs(self.PartsList) do
		if obj.ClassName == "MeshPart" then
			obj.TextureID = "";
		end
		
		obj.Anchored = true;
		obj.CanCollide = false;
		obj.Transparency = obj.Name == "Hitbox" and 1 or 0.5;
		obj.Material = Enum.Material.Neon;
		obj.Color = color;
	end
end

function PlacementHandler:Destroy()
	if PlacementHandler.ActiveHighlight == self then
		PlacementHandler.ActiveHighlight = nil;
	end
	
	Debugger.Expire(self.Prefab, 0);
	table.clear(self.PartsList);
	table.clear(self);
end

function PlacementHandler:DestroyActive()
	if PlacementHandler.ActiveHighlight == nil then return end;
	PlacementHandler.ActiveHighlight:Destroy();
end

return PlacementHandler;