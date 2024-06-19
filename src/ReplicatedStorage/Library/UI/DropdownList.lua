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
				obj.Visible = obj.Name:lower():find(inputStr:lower()) ~= nil;
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

	self.Frame.Destroying:Connect(function()
		table.clear(self);
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
		new.Name = list[a];
		new.Text = list[a];
		new.Parent = self.ScrollFrame;
		
		if self.OnNewButton then
			task.spawn(function()
				self:OnNewButton(a, new);
			end)
		end

		new.MouseButton1Click:Connect(function()
			if self.OnOptionSelect then
				self:OnOptionSelect(a, new);
			end
		end)
	end
end

return DropdownList;