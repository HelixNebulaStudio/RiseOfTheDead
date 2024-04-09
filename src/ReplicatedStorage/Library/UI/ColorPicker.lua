local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local templatePicker = script:WaitForChild("ColorPicker");
local templateOption = script:WaitForChild("ColorOption");
--==
local ColorPicker = {};
ColorPicker.__index = ColorPicker;

ColorPicker.ColorIndex = {};

for a=1, 365 do
	local bC = BrickColor.new(a);
	if bC.Name == "Medium stone grey" and a ~= 194 then
		continue;
	end
	
	table.insert(ColorPicker.ColorIndex, bC);
end

for a=1001, 1032 do
	local bC = BrickColor.new(a);
	if bC.Name == "Medium stone grey" then continue end;
	table.insert(ColorPicker.ColorIndex, bC);
end

for a=1, #ColorPicker.ColorIndex do
	local brickColor = ColorPicker.ColorIndex[a];
	local new = templateOption:Clone();
	
	new.BackgroundColor3 = brickColor.Color;
	new.LayoutOrder = a;
	new.Parent = templatePicker:WaitForChild("Top"):WaitForChild("ScrollingFrame");
end

--==

function ColorPicker.new()
	local self = {
		Frame = templatePicker:Clone();
	};
	
	local activeColor = self.Frame:WaitForChild("Bottom"):WaitForChild("ActiveColor");
	local textInput = self.Frame.Bottom:WaitForChild("TextInput");
	
	local scrollFrame = self.Frame.Top:WaitForChild("ScrollingFrame");
	
	for _, obj in pairs(scrollFrame:GetChildren()) do
		if obj:IsA("TextButton") then
			
			local brickColor = ColorPicker.ColorIndex[obj.LayoutOrder];
			obj.MouseMoved:Connect(function()
				activeColor.BackgroundColor3 = brickColor.Color;
				textInput.Text = brickColor.Color:ToHex();
			end)
			
			obj.MouseButton1Click:Connect(function()
				if self.OnColorSelect then
					self:OnColorSelect(brickColor.Color);
				end
			end)
		end
	end
	
	textInput.FocusLost:Connect(function(enterPressed)
		activeColor.BackgroundColor3 = Color3.fromHex(textInput.Text);
		if enterPressed then
			if self.OnColorSelect then
				self:OnColorSelect(activeColor.BackgroundColor3);
			end
		end
	end)
	
	activeColor.MouseButton1Click:Connect(function()
		if self.OnColorSelect then
			self:OnColorSelect(activeColor.BackgroundColor3);
		end
	end)
	
	local touchCloseButton = self.Frame:WaitForChild("touchCloseButton"):WaitForChild("closeButton");
	touchCloseButton.MouseButton1Click:Connect(function()
		self.Frame.Visible = false;
	end)
	
	setmetatable(self, ColorPicker);
	return self;
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