local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local templateDropdownWindow = script:WaitForChild("DropdownList");
local templateOption = script:WaitForChild("ListButton");
--==
local DropdownList = {};
DropdownList.__index = DropdownList;

--==

function DropdownList.new()
	local self = {
		Frame = templateDropdownWindow:Clone();
	};
	
	local selectButton = self.Frame:WaitForChild("Bottom"):WaitForChild("SelectButton");
	local textInput = self.Frame.Bottom:WaitForChild("TextInput");
	
	local scrollFrame = self.Frame.Top:WaitForChild("ScrollingFrame");
	self.ScrollFrame = scrollFrame;
	
	local function search()
		local inputStr = textInput.Text;
		if #inputStr > 0 then
			for _, obj in pairs(scrollFrame:GetChildren()) do
				if not obj:IsA("GuiObject") then continue end;
				obj.Visible = obj.Name:find(inputStr) ~= nil;
			end
		else
			for _, obj in pairs(scrollFrame:GetChildren()) do
				if not obj:IsA("GuiObject") then continue end;
				obj.Visible = true;
			end
		end
	end
	
	textInput:GetPropertyChangedSignal("Text"):Connect(function()
		task.wait();
		search();
	end)
	
	textInput.FocusLost:Connect(function(enterPressed)
		if enterPressed then
		end
	end)
	
	local touchCloseButton = self.Frame:WaitForChild("touchCloseButton"):WaitForChild("closeButton");
	touchCloseButton.MouseButton1Click:Connect(function()
		self.Frame.Visible = false;
	end)
	
	setmetatable(self, DropdownList);
	return self;
end

function DropdownList:LoadOptions(list)
	for _, obj in pairs(self.ScrollFrame:GetChildren()) do
		if not obj:IsA("GuiObject") then continue end;
		obj:Destroy();
	end
	
	for a=1, #list do
		local new = templateOption:Clone();
		new.LayoutOrder = a;
		new.Text = list[a];
		new.Parent = self.ScrollFrame;
		
		new.MouseButton1Click:Connect(function()
			if self.OnOptionSelect then
				self:OnOptionSelect(a, list[a]);
			end
		end)
	end
end

return DropdownList;