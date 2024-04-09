local LevelBadge = {}

function LevelBadge:Update(iconInstance, level)
	local iconLabel = iconInstance:WaitForChild("LevelTag");
	local tier = math.ceil((level+1)/100);
	local sublevel = math.fmod(level, 100);
	local color;
	if sublevel < 10 then
		local b = 120+(135/10)*sublevel;
		color = Color3.fromRGB(255, 255, 255);
	elseif sublevel < 20 then
		color = Color3.fromRGB(200, 255, 166);--Color3.fromRGB(37, 190, 255);
	elseif sublevel < 30 then
		color = Color3.fromRGB(157, 255, 157); --Color3.fromRGB(64, 0, 255);
	elseif sublevel < 40 then
		color = Color3.fromRGB(165, 240, 255);--Color3.fromRGB(44, 252, 255);
	elseif sublevel < 50 then
		color = Color3.fromRGB(123, 165, 255);--Color3.fromRGB(43, 255, 138);
	elseif sublevel < 60 then
		color = Color3.fromRGB(173, 165, 255);--Color3.fromRGB(255, 61, 213);
	elseif sublevel < 70 then
		color = Color3.fromRGB(255, 164, 246);--Color3.fromRGB(255, 61, 213);
	elseif sublevel < 80 then
		color = Color3.fromRGB(255, 164, 246);--Color3.fromRGB(255, 26, 79);
	elseif sublevel < 90 then
		color = Color3.fromRGB(255, 133, 133);--Color3.fromRGB(255, 26, 79);
	elseif sublevel < 100 then
		color = Color3.fromRGB(255, 133, 133);--Color3.fromRGB(255, 0, 0);
	else
		color = Color3.fromRGB(255, 255, 255);
	end
	if tier <= 1 then
		local fmodLevel = math.fmod(level, 10);
		if fmodLevel == 0 then
			iconInstance.Image = "rbxassetid://4512200001";
			
		elseif fmodLevel == 1 then
			iconInstance.Image = "rbxassetid://4512200655";
			
		elseif fmodLevel == 2 then
			iconInstance.Image = "rbxassetid://4512200999";
			
		elseif fmodLevel == 3 then
			iconInstance.Image = "rbxassetid://4512201441";
			
		elseif fmodLevel == 4 then
			iconInstance.Image = "rbxassetid://4512202131";
			
		elseif fmodLevel == 5 then
			iconInstance.Image = "rbxassetid://4512204198";
			
		elseif fmodLevel == 6 then
			iconInstance.Image = "rbxassetid://4512204504";
			
		elseif fmodLevel == 7 then
			iconInstance.Image = "rbxassetid://4512205226";
			
		elseif fmodLevel == 8 then
			iconInstance.Image = "rbxassetid://4512205814";
			
		elseif fmodLevel == 9 then
			iconInstance.Image = "rbxassetid://4512206495";
			
		end
	elseif tier == 2 then
		iconInstance.Image = "rbxassetid://3163061542";
	elseif tier == 3 then
		iconInstance.Image = "rbxassetid://7150127446"; --3163061188
	elseif tier == 4 then
		iconInstance.Image = "rbxassetid://7150129654"; --3163061347
	elseif tier == 5 then
		iconInstance.Image = "rbxassetid://7150130564"; --3163061542
	elseif tier >= 6 then
		iconInstance.Image = "rbxassetid://7150131437"; --3163061699
	end
	iconInstance.ImageColor3 = color;
	iconLabel.Text = level;
	iconLabel.TextColor3 = Color3.fromRGB(math.clamp(color.r*255+20, 0, 255),math.clamp(color.g*255+20, 0, 255),math.clamp(color.b*255+20, 0, 255));
end

return LevelBadge;