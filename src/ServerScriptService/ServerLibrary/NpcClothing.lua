local NpcClothing = {}
local random = Random.new();

--== Zombie;

NpcClothing.ZombieShirts = {
	{Id="rbxassetid://15411470697"};
	{Id="rbxassetid://15411709932"};
	{Id="rbxassetid://15411731918"};
	{Id="rbxassetid://15411781070"};
	{Id="rbxassetid://15411800836"};
	
	{Id="rbxassetid://15411833660"};
	{Id="rbxassetid://15411838424"};
	{Id="rbxassetid://15411845793"};
	{Id="rbxassetid://15411881469"};
	{Id="rbxassetid://15411886681"};
	
	{Id="rbxassetid://15412167155"};
	{Id="rbxassetid://15412178944"};
	{Id="rbxassetid://15412185168"};
	{Id="rbxassetid://15412189628"};
	{Id="rbxassetid://15412194374"};
	
	{Id="rbxassetid://15412199081"};
	{Id="rbxassetid://15412203365"};
};

NpcClothing.ZombiePants = {
	{Id="rbxassetid://15411495818"};
	{Id="rbxassetid://15411716352"};
	{Id="rbxassetid://15411733696"};
	{Id="rbxassetid://15411789334"};
	{Id="rbxassetid://15411806928"};

	{Id="rbxassetid://15412211140"};
	{Id="rbxassetid://15412215422"};
	{Id="rbxassetid://15412220333"};
	
};

NpcClothing.ZombieSkinColor = {
	Color3.fromRGB(135, 130, 110);
	Color3.fromRGB(130, 125, 106);
	Color3.fromRGB(125, 120, 102);
	Color3.fromRGB(120, 115, 98);

	Color3.fromRGB(135, 126, 110);
	Color3.fromRGB(130, 121, 106);
	Color3.fromRGB(125, 116, 102);
	Color3.fromRGB(120, 111, 98);
};

NpcClothing.ZombieHair = script:WaitForChild("ZombieHair"):GetChildren();

NpcClothing.ZombieHairColor = {
	Color3.fromRGB(82, 70, 36);
	Color3.fromRGB(38, 38, 42);
	Color3.fromRGB(61, 51, 43);
	Color3.fromRGB(66, 58, 45);
	Color3.fromRGB(13, 13, 16);
	Color3.fromRGB(29, 33, 29);
	Color3.fromRGB(33, 29, 28);
	Color3.fromRGB(33, 28, 24);
};

NpcClothing.ZombieFaces = {
	{Id="rbxassetid://16258726851"};
	{Id="rbxassetid://16258726569"};
	{Id="rbxassetid://16258726269"};
	{Id="rbxassetid://16258725911"};
	{Id="rbxassetid://16258725550"};
	{Id="rbxassetid://16258725277"};
}

-- Bloater;
NpcClothing.BloaterShirts = {
	{Id="rbxassetid://16240828797"};
	{Id="rbxassetid://16240913172"};
	{Id="rbxassetid://16240917767"};
	{Id="rbxassetid://16240921283"};
};


-- Stranger;
NpcClothing.StrangerShirts = {
	{Id="rbxassetid://382537084";};
	{Id="rbxassetid://607785311";};
	{Id="rbxassetid://969769092";};
	{Id="rbxassetid://398635080";};
	{Id="rbxassetid://398633582";};
	{Id="rbxassetid://382538294";};
	{Id="rbxassetid://398634294";};
	{Id="rbxassetid://382537700";};
	{Id="rbxassetid://382538058";};
	{Id="rbxassetid://3670737337";};
};

NpcClothing.StrangerPants = {
	{Id="rbxassetid://348211416"};
	{Id="rbxassetid://129458425"};
	{Id="rbxassetid://129459076"};
	{Id="rbxassetid://382537568"};
	{Id="rbxassetid://398635336"};
	
	{Id="rbxassetid://398633811"};
	{Id="rbxassetid://398634485"};
	{Id="rbxassetid://382537949"};
	{Id="rbxassetid://382537805"};
	{Id="rbxassetid://382538502"};
};

NpcClothing.StrangerFaces = {
	{Id="rbxassetid://147144198"};
}

NpcClothing.StrangerHair = script:WaitForChild("HumanHair"):GetChildren();

NpcClothing.StrangerHairColor = {
	Color3.fromRGB(82, 70, 36);
	Color3.fromRGB(38, 38, 42);
	Color3.fromRGB(61, 51, 43);
	Color3.fromRGB(66, 58, 45);
	Color3.fromRGB(13, 13, 16);
	Color3.fromRGB(29, 33, 29);
	Color3.fromRGB(33, 29, 28);
	Color3.fromRGB(33, 28, 24);
};

-- Human
NpcClothing.StrangerSkinColor = {
	Color3.fromRGB(234, 184, 146);
	Color3.fromRGB(108, 88, 75);
	Color3.fromRGB(86, 66, 54);
	Color3.fromRGB(204, 142, 105);
	Color3.fromRGB(215, 197, 154);
	Color3.fromRGB(175, 148, 131);
};

--== Bandit

NpcClothing.HumanSkinColor = {
	Color3.fromRGB(234, 184, 146);
	Color3.fromRGB(108, 88, 75);
	Color3.fromRGB(86, 66, 54);
	Color3.fromRGB(204, 142, 105);
	Color3.fromRGB(215, 197, 154);
	Color3.fromRGB(175, 148, 131);
};

--==
function NpcClothing:GetSkinColor(npcName, seed)
	npcName = npcName or "";
	
	local dice = random;
	if seed then dice = Random.new(seed); end

	local colorsList = self[npcName.."SkinColor"] or self.ZombieSkinColor;
	local pick = colorsList[dice:NextInteger(1, #colorsList)];
	return pick;
end

function NpcClothing:GetShirt(npcName, seed, spawnObj)
	npcName = npcName or "";
	
	local dice = random;
	if seed then dice = Random.new(seed); end


	local shirtsList = self[npcName.."Shirts"] or self.ZombieShirts;
	local pick = shirtsList[dice:NextInteger(1, #shirtsList)];
	
	local newShirt;
	if spawnObj == true then
		newShirt = Instance.new("Shirt");
		newShirt.Name = "Shirt";
		newShirt.ShirtTemplate = pick.Id;
	end
	
	return pick, newShirt;
end

function NpcClothing:GetPants(npcName, seed, spawnObj)
	npcName = npcName or "";
	
	local dice = random;
	if seed then dice = Random.new(seed); end

	local pantsList = self[npcName.."Pants"] or self.ZombiePants;
	local pick = pantsList[dice:NextInteger(1, #pantsList)];
	
	local newPants;
	if spawnObj == true then
		newPants = Instance.new("Pants");
		newPants.Name = "Pants";
		newPants.PantsTemplate = pick.Id;
	end

	return pick, newPants;
end

function NpcClothing:GetHair(npcName, seed)
	npcName = npcName or "";
	
	local dice = random;
	if seed then dice = Random.new(seed); end

	local hairList = self[npcName.."Hair"] or self.ZombieHair;
	local roll = dice:NextInteger(0, #hairList);
	
	if roll == 0 then
		return;
	end

	local hairColorList = self[npcName.."HairColor"] or self.ZombieHairColor;
	
	return hairList[roll], hairColorList[dice:NextInteger(1, #hairColorList)];
end

function NpcClothing:GetFace(npcName, seed)
	npcName = npcName or "";

	local dice = random;
	if seed then dice = Random.new(seed); end

	local facesList = self[npcName.."Faces"] or self.ZombieFaces;
	local pick = facesList[dice:NextInteger(1, #facesList)];
	
	return pick;
end

return NpcClothing;