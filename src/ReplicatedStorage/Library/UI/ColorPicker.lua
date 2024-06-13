local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UserInputService = game:GetService("UserInputService");

local modComponents = require(game.ReplicatedStorage.Library.UI.Components);

local colorPaletteTemplate = script:WaitForChild("ColorPicker");
local colorOptionTemplate = script:WaitForChild("ColorOption");
local selectTemplate = script:WaitForChild("SelectTemplate");
local lockedTemplate = script:WaitForChild("LockedTemplate");
--==
local ColorPicker = {};
ColorPicker.__index = ColorPicker;

ColorPicker.LastColors = {};
--==
function ColorPicker:Destroy()
	Debugger.Expire(self.Frame);
	Debugger.Expire(self.SelectLabel);
end

function ColorPicker:SetUnlocked(hexList)
	hexList = hexList or {};

	local contentFrame = self.Frame:WaitForChild("Content") :: TextButton;
	local colorPaletteImage = contentFrame:WaitForChild("ColorPalette");

	for _, imgLabel in pairs(colorPaletteImage:GetChildren()) do
		if not imgLabel:IsA("ImageLabel") then continue end;
		local hexId = string.lower(imgLabel.ImageColor3:ToHex());
		
		if hexList[hexId] == nil and imgLabel:FindFirstChild("LockedTemplate") == nil then
			local newLocked = lockedTemplate:Clone();
			newLocked.ImageColor3 = ColorPicker.GetBackColor(imgLabel.ImageColor3);
			newLocked.Parent = imgLabel;
		end
		
	end
end

function ColorPicker.new(mainInterface)
	local self = {};
	function self.SelectFunc() end;
	function self:OnColorSelect(color: Color3, colorId: string?) end;

	self.HighlightLoop = false;

	self.Frame = colorPaletteTemplate:Clone();
	self.SelectLabel = selectTemplate:Clone();
	
	local contentFrame = self.Frame:WaitForChild("Content") :: TextButton;
	local colorPaletteImage = contentFrame:WaitForChild("ColorPalette");

	local advanceFrame = contentFrame:WaitForChild("Advance");
	local lastColorsFrame = advanceFrame:WaitForChild("LastColors");

	local activeColor = advanceFrame:WaitForChild("ActiveColor");
	local colorInput = activeColor:WaitForChild("TextInput") :: TextBox;

	self.Frame:GetPropertyChangedSignal("Visible"):Connect(function()
		if self.Frame.Visible ~= true then return end;
		if self.HighlightLoop then return end
		self.HighlightLoop = true;

		for _, obj in pairs(lastColorsFrame:GetChildren()) do
			if not obj:IsA("GuiObject") then continue end;
			obj:Destroy();
		end

		for a=1, math.min(#ColorPicker.LastColors, 12) do
			local colorLabel = ColorPicker.LastColors[a] :: ImageLabel;

			local new = colorOptionTemplate:Clone() :: ImageButton;
			new.ImageColor3 = colorLabel.ImageColor3;
			new.MouseButton1Click:Connect(function()
				self:OnColorSelect(colorLabel.ImageColor3, colorLabel.Name);
			end)

			new.Parent = lastColorsFrame;
		end

		local colorsPaletteTable = {};
		for _, obj in pairs(colorPaletteImage:GetChildren()) do
			if obj:IsA("ImageLabel") then
				table.insert(colorsPaletteTable, {
					Point = obj.AbsolutePosition + (obj.AbsoluteSize/2);
					Label = obj;
				});
			end
		end
		
		self.SelectFunc = function()
			local mousePosition = UserInputService:GetMouseLocation() + Vector2.new(0, -game.GuiService.TopbarInset.Height);
		
			local closestLabel, closestDist = nil, math.huge;
			
			for a=1, #colorsPaletteTable do
				local point = colorsPaletteTable[a].Point;
				local label = colorsPaletteTable[a].Label;
				
				local dist = (point-mousePosition).Magnitude;
				if dist < closestDist then
					closestLabel = label;
					closestDist = dist;
				end
			end
			
			if closestDist <= 19 then
				activeColor.BackgroundColor3 = closestLabel.ImageColor3;
				colorInput.PlaceholderText = string.upper("#"..closestLabel.ImageColor3:ToHex());
				self.SelectLabel.Parent = closestLabel;
				
			else
				self.SelectLabel.Parent = nil;
				closestLabel = nil;
				
			end

			return closestLabel;
		end;

		while self.HighlightLoop do
			self.SelectFunc();
			task.wait();
			if not self.Frame.Visible then break; end
		end

		self.HighlightLoop = false;
	end)

	contentFrame.MouseButton1Click:Connect(function()
		local selectLabel = self.SelectFunc();
		if selectLabel then
			while #ColorPicker.LastColors >= 12 do
				table.remove(ColorPicker.LastColors, 1);
			end
			local existIndex = nil;
			for a=1, #ColorPicker.LastColors do
				if ColorPicker.LastColors[a].Name == selectLabel.Name then
					existIndex = a;
					break;
				end
			end
			if existIndex then
				ColorPicker.LastColors[existIndex], ColorPicker.LastColors[#ColorPicker.LastColors] = ColorPicker.LastColors[#ColorPicker.LastColors], ColorPicker.LastColors[existIndex];
			else
				table.insert(ColorPicker.LastColors, selectLabel);
			end

			self:OnColorSelect(selectLabel.ImageColor3, selectLabel.Name);
		end
	end)

	setmetatable(self, ColorPicker);

	local touchCloseButton = self.Frame:WaitForChild("touchCloseButton"):WaitForChild("closeButton");
	touchCloseButton.MouseButton1Click:Connect(function()
		self.Frame.Visible = false;
	end)

	return self;
end

local approvedColors = {
	["#323232"]=true;
	["#4b4b4b"]=true;
	["#969696"]=true;
	["#c8c8c8"]=true;
	["#ffffff"]=true;
};
function ColorPicker.GetColor(tag, allowCustomColors) : Color3?
	tag = tostring(tag);

	if tonumber(tag) then
		return BrickColor.new(tag).Color;
	elseif tag:sub(1,1) == "#" then
		if allowCustomColors ~= true and approvedColors[string.lower(tag)] ~= true then
			return;
		end
		return Color3.fromHex(tag);
	end

	return;
end

function ColorPicker.GetBackColor(color) : Color3
	local h, s, v = color:ToHSV();
	return Color3.fromHSV(h, s, v > 0.5 and math.max(v-0.5, 0) or math.min(v+0.5, 1));
end

function ColorPicker.GradientLerp(color1, color2, alpha)
	if alpha <= 0 then
		return ColorSequence.new(color1);
	elseif alpha >= 1 then
		return ColorSequence.new(color2);
	end

	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, color1),
		ColorSequenceKeypoint.new(math.min(alpha, 0.998), color1),
		ColorSequenceKeypoint.new(math.min(alpha+0.001, 0.999), color2),
		ColorSequenceKeypoint.new(1, color2)
	});
end

return ColorPicker;