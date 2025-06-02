local ShowcaseObject = {}

local modColorsLibrary = shared.require(game.ReplicatedStorage.Library:WaitForChild("ColorsLibrary"));
local modSkinsLibrary = shared.require(game.ReplicatedStorage.Library:WaitForChild("SkinsLibrary"));

local templateFrame = script:WaitForChild("appearanceImage");
local templateIcon = script:WaitForChild("ImageIcon");

function ShowcaseObject.new(interface, parent, library)
	if library == nil or library.PackType == nil or library.PackId == nil then return end;
	
	local listLibrary = library.PackType == "Colors" and modColorsLibrary or modSkinsLibrary;
	local packLib = listLibrary.Packs[library.PackId];
	if packLib == nil then return end;
	
	local self = {};
	
	local new = templateFrame:Clone();
	for a=1, #packLib.List do
		local info = packLib.List[a];
		local newOption = templateIcon:Clone();
		
		if library.PackType == "Colors" then
			newOption.Image = "";
			newOption.BackgroundTransparency = 0;
			newOption.BackgroundColor3 = info.Color;
			
		elseif library.PackType == "Skins" then
			newOption.Image = info.Image;
			newOption.ImageColor3 = info.Color;
			
		end
		newOption.Parent = new;
	end
	
	new.Parent = parent;
	
	self.Frame = new;

    function self:Destroy()
		game.Debris:AddItem(new, 0);
    end

	return self;
end

return ShowcaseObject;