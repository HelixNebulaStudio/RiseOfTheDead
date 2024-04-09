
local RunService = game:GetService("RunService");
local attachmentTag = script.Parent:WaitForChild("AttachmentTag");

local buttons = script.Parent:WaitForChild("buttons");
local posButtons = script.Parent:WaitForChild("position");
local rotButtons = script.Parent:WaitForChild("rotation");

local viewModelCFrame = CFrame.new();
local posRate, rotRate = 0.1, 1;
local int = 1;

attachmentTag:GetAttributeChangedSignal("ADS"):Connect(function()
	local object = attachmentTag.Value;
	local cf = object.CFrame;
	viewModelCFrame = cf;

	updateLabel();
end)

attachmentTag:GetPropertyChangedSignal("Value"):Connect(function()
	local object = attachmentTag.Value;
	local cf = object.CFrame;
	viewModelCFrame = cf;
	
	updateLabel();
end)

function updateLabel()
	script.Parent.cframe.Text = tostring(viewModelCFrame);
	script.Parent:WaitForChild("TextLabel").Text = ("Intervals: $int")
		:gsub("$int", int);
end

script.Parent:WaitForChild("cframe").FocusLost:Connect(function(enterPressed)
	if enterPressed then
		print("Load input cframe");
		local cfInput = script.Parent.cframe.Text:split(",");
		
		local newCFrame 
		local s, e = pcall(function()
			newCFrame = CFrame.new(unpack(cfInput));
		end)
		if s then
			script.Parent.cframe.BorderColor3 = Color3.fromRGB(109, 170, 214);
			viewModelCFrame = newCFrame;
			
			local object = attachmentTag.Value;
			object.CFrame = viewModelCFrame;
		else
			script.Parent.cframe.BorderColor3 = Color3.fromRGB(200, 0, 0);
			wait(2);
			script.Parent.cframe.BorderColor3 = Color3.fromRGB(109, 170, 214);
			warn(e);
		end
	end
end)

local function newPosition(axis, times)
	local object = attachmentTag.Value;
	local camera = workspace.CurrentCamera;
	
	if axis == "X" then
		object.CFrame = object.CFrame * CFrame.new(camera.CFrame.RightVector * int * posRate * times);
		
	elseif axis == "Y" then
		object.CFrame = object.CFrame * CFrame.new(camera.CFrame.UpVector * int * posRate * times);
		
	elseif axis == "Z" then
		object.CFrame = object.CFrame * CFrame.new(camera.CFrame.LookVector * int * posRate * times);
		
	end
	
	
	viewModelCFrame = object.CFrame;
	updateLabel();
end

local function newRotation(axis, times)
	local object = attachmentTag.Value;
	
	if axis == "X" then
		object.Orientation = object.Orientation + Vector3.new((int * rotRate * times), 0, 0);
		
	elseif axis == "Y" then
		object.Orientation = object.Orientation + Vector3.new(0, (int * rotRate * times), 0);
		
	elseif axis == "Z" then
		object.Orientation = object.Orientation + Vector3.new(0, 0, (int * rotRate * times));
		
	end
	
	viewModelCFrame = object.CFrame;
	updateLabel();
end

task.wait(1);

buttons.int1.MouseButton1Click:Connect(function()
	int = 1;
	updateLabel();
end)
buttons.int2.MouseButton1Click:Connect(function()
	int = 0.1;
	updateLabel();
end)
buttons.int3.MouseButton1Click:Connect(function()
	int = 0.05;
	updateLabel();
end)
local cycleSmallInt = {0.02, 0.01, 0.005};
local activeIndex = #cycleSmallInt;
buttons.int4.MouseButton1Click:Connect(function()
	activeIndex = activeIndex + 1;
	if activeIndex > #cycleSmallInt then
		activeIndex = 1;
	end
	
	int = cycleSmallInt[activeIndex];
	updateLabel();
end)


posButtons.XButton.MouseButton1Click:Connect(function()
	newPosition("X", 1)
end)
posButtons.XButton.MouseButton2Click:Connect(function()
	newPosition("X", -1)
end)

posButtons.YButton.MouseButton1Click:Connect(function()
	newPosition("Y", 1)
end)
posButtons.YButton.MouseButton2Click:Connect(function()
	newPosition("Y", -1)
end)

posButtons.ZButton.MouseButton1Click:Connect(function()
	newPosition("Z", 1)
end)
posButtons.ZButton.MouseButton2Click:Connect(function()
	newPosition("Z", -1)
end)



rotButtons.XButton.MouseButton1Click:Connect(function()
	newRotation("X", 1)
end)
rotButtons.XButton.MouseButton2Click:Connect(function()
	newRotation("X", -1)
end)

rotButtons.YButton.MouseButton1Click:Connect(function()
	newRotation("Y", 1)
end)
rotButtons.YButton.MouseButton2Click:Connect(function()
	newRotation("Y", -1)
end)

rotButtons.ZButton.MouseButton1Click:Connect(function()
	newRotation("Z", 1)
end)
rotButtons.ZButton.MouseButton2Click:Connect(function()
	newRotation("Z", -1)
end)