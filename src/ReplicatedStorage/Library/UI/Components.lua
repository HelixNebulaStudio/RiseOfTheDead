local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");

local modGlobalVars = require(game.ReplicatedStorage.GlobalVariables);

--==
local Components = {};

function Components.IsTrulyVisible(guiObject)
	local screenGui = guiObject:FindFirstAncestorWhichIsA("ScreenGui");

	if screenGui == nil or screenGui.Enabled == false then
		return false;
	end

	while guiObject ~= screenGui and guiObject ~= nil do
		if guiObject:IsA("GuiObject") and guiObject.Visible == false then
			return false;
		end

		guiObject = guiObject.Parent;
	end

	return true;
end

function Components.CreateSlider(mainInterface, paramPacket)
	local button = paramPacket.Button;
	local setFunc = paramPacket.SetFunc;
	
	local rangeInfo = paramPacket.RangeInfo;
	local minVal, maxVal, defaultVal = rangeInfo.Min, rangeInfo.Max, rangeInfo.Default;
	local valueType = rangeInfo.ValueType or "Percent";
	
	local gradientLayout = button:WaitForChild("UIGradient");
	local typeInput = button:WaitForChild("typeInput");
	
	local currentVal = defaultVal;
	local percentVal = nil;
	
	local color1 = Color3.fromRGB(255, 255, 255);
	local color2 = Color3.fromRGB(205, 205, 205);
	
	local function refreshSlider()
		percentVal = math.clamp(currentVal, minVal, maxVal)/maxVal;
		
		gradientLayout.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color1),
			ColorSequenceKeypoint.new(math.min(percentVal, 0.998), color1),
			ColorSequenceKeypoint.new(math.min(percentVal+0.001, 0.999), color2),
			ColorSequenceKeypoint.new(1, color2)
		});
		
		if typeInput.Visible then
			button.Text = "";
			return;
		end 
		
		if paramPacket.DisplayValueFunc then
			button.Text = paramPacket.DisplayValueFunc(currentVal)
			return;
		end
		
		if valueType == "Percent" then
			button.Text = math.round(percentVal*100).."%";
		else
			button.Text = currentVal;
		end
	end
	refreshSlider();
	
	local function StartQuantitySlider()
		local mousePosition = UserInputService:GetMouseLocation();
		local mouseXOrigin = mousePosition.X;

		local absSizeX = button.AbsoluteSize.X;
		RunService:BindToRenderStep("slider", Enum.RenderPriority.Input.Value+1, function(delta)
			local mousePosition = UserInputService:GetMouseLocation();
			local sliderRatio = math.clamp(math.clamp(mousePosition.X-button.AbsolutePosition.X, 0, absSizeX)/absSizeX, 0, 0.999);
			
			currentVal = math.clamp(math.round(sliderRatio*maxVal), minVal, maxVal);
			refreshSlider();
			
			if not mainInterface.Button1Down or not Components.IsTrulyVisible(button) then
				setFunc(currentVal);
				RunService:UnbindFromRenderStep("slider");
			end
		end)
	end
	
	button.MouseButton1Down:Connect(StartQuantitySlider);
	
	local lastClick = tick();
	button.MouseButton1Click:Connect(function()
		local lastClickLapse = tick()-lastClick;
		
		if lastClickLapse <= 0.2 then
			typeInput.Text = "";
			button.Text = "";
			typeInput.Visible = true;
			typeInput:CaptureFocus();
			
		end
		lastClick = tick();
	end)
	
	button.MouseButton2Click:Connect(function()
		currentVal = defaultVal;
		refreshSlider();
		setFunc(currentVal);
	end)
	
	typeInput.FocusLost:Connect(function(enterPressed, inputObject)
		typeInput.Visible = false;
		
		local setVal = tonumber(typeInput.Text) or defaultVal;
		
		currentVal = setVal;
		refreshSlider();
		setFunc(currentVal);
	end)
end

function Components.CreateSliderType2(mainInterface, paramPacket)
	local self = {};
	
	local sliderBar = paramPacket.SliderBar;
	
	local defaultValue = paramPacket.DefaultValue or 1;
	self.MaxValue = paramPacket.MaxValue or 1;
	
	local setFunc = paramPacket.SetFunc;

	local currentVal = nil;
	
	local function update(sliderRatio)
		local absSizeX = sliderBar.AbsoluteSize.X-6;
		
		sliderBar.SliderNob.Visible = true;
		sliderBar.SliderNob.Position = UDim2.new(0, absSizeX*sliderRatio + 2, 0.5, 0);
	end
	self.Update = update;
	
	
	local isActive = false;
	local function StartQuantitySlider()
		if self.Disabled == true then return end;
		if isActive then return end;
		isActive = true;
		
		local mousePosition = UserInputService:GetMouseLocation();
		local mouseXOrigin = mousePosition.X;
		local absSizeX = sliderBar.AbsoluteSize.X-6;
		
		RunService:BindToRenderStep("slider", Enum.RenderPriority.Input.Value+1, function(delta)
			local mousePosition = UserInputService:GetMouseLocation();
			local sliderRatio = math.clamp(math.clamp(mousePosition.X-sliderBar.AbsolutePosition.X, 0, absSizeX)/absSizeX, 0, self.MaxValue);

			if not mainInterface.Button1Down or not Components.IsTrulyVisible(sliderBar) then
				setFunc(sliderRatio, true);
				RunService:UnbindFromRenderStep("slider");
				isActive = false;
				if RunService:IsStudio() then
					Debugger:Warn("Unbind slider");
				end
			end
			
			setFunc(sliderRatio);
			update(sliderRatio);
		end)
	end
	
	sliderBar.MouseButton1Down:Connect(StartQuantitySlider);
	sliderBar.SliderNob.MouseButton1Down:Connect(StartQuantitySlider);
	
	task.delay(0.1, function()
		update(defaultValue);
	end)
	
	return self;
end

return Components;