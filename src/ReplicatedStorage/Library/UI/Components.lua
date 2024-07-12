local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");

local modMath = require(game.ReplicatedStorage.Library.Util.Math);

--==
local Components = {};

Components.TemplateGoldImageLabel = script:WaitForChild("GoldImageLabel");
Components.TemplatePerksImageLabel = script:WaitForChild("PerksImageLabel");

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

function Components.NewSliderButton()
	return script:WaitForChild("Slider"):Clone();
end

function Components.CreateSlider(mainInterface, paramPacket)
	local button = paramPacket.Button :: TextButton;
	
	local setFunc = paramPacket.SetFunc;
	local saveFunc = paramPacket.SaveFunc;

	local sliderName = paramPacket.Name;
	local rangeInfo = paramPacket.RangeInfo;
	local minVal, maxVal, defaultVal = rangeInfo.Min, rangeInfo.Max, rangeInfo.Default;
	local rangeScale = rangeInfo.Scale or 1;
	local valueType = rangeInfo.ValueType or "Percent";
	
	local gradientLayout = button:WaitForChild("UIGradient");
	local typeInput = button:WaitForChild("typeInput") :: TextBox;
	
	local currentVal = defaultVal;
	local percentVal = nil;
	
	local color1 = Color3.fromRGB(255, 255, 255);
	local color2 = Color3.fromRGB(205, 205, 205);
	
	local function refreshSlider()
		currentVal = math.round(math.clamp(currentVal, minVal, maxVal));
		percentVal = modMath.MapNum(currentVal, minVal, maxVal, 0, 1, true);
		
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
			button.Text = paramPacket.DisplayValueFunc(currentVal/rangeScale)
			return;
		end
		
		if valueType == "Percent" then
			button.Text = math.round(percentVal*100).."%";
		else
			button.Text = currentVal/rangeScale;
		end
	end
	refreshSlider();
	
	local function StartQuantitySlider()
		if button:GetAttribute("DisableSlider") == true then return end;

		local absSizeX = button.AbsoluteSize.X;

		local mousePositionLock = nil;
		RunService:BindToRenderStep("slider", Enum.RenderPriority.Input.Value+1, function(delta)
			local rawMousePos = UserInputService:GetMouseLocation();
			local mousePosition = rawMousePos;

			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
				mousePositionLock = mousePositionLock or rawMousePos;
				mousePosition = mousePositionLock + (rawMousePos-mousePositionLock)/10;
			else
				mousePositionLock = nil;
			end

			local sliderRatio = math.clamp(math.clamp(mousePosition.X-button.AbsolutePosition.X, 0, absSizeX)/absSizeX, 0, 1);
			
			currentVal = modMath.MapNum(sliderRatio, 0, 1, minVal, maxVal, true);
			refreshSlider();
			
			if not mainInterface.Button1Down or not Components.IsTrulyVisible(button) then
				RunService:UnbindFromRenderStep("slider");
				if saveFunc then
					saveFunc(currentVal/rangeScale);
				end
				setFunc(currentVal/rangeScale);
			end
		end)
	end
	
	button.TouchPan:Connect(StartQuantitySlider);
	button.MouseButton1Down:Connect(StartQuantitySlider);
	
	local lastClick = tick();
	button.MouseButton1Click:Connect(function()
		if button:GetAttribute("DisableSlider") == true then return end;

		local lastClickLapse = tick()-lastClick;
		
		if lastClickLapse <= 0.2 then
			typeInput.Text = "";
			button.Text = "";
			typeInput.Visible = true;
			typeInput:CaptureFocus();
			
		end
		lastClick = tick();
	end)
	
	local function resetDefaultValues()
		currentVal = defaultVal;
		refreshSlider();
		setFunc(currentVal/rangeScale);
	end
	button.MouseButton2Click:Connect(function()
		if button:GetAttribute("DisableSlider") == true then return end;
		resetDefaultValues();
	end);
	
	typeInput.FocusLost:Connect(function(enterPressed, inputObject)
		typeInput.Visible = false;
		
		local setVal = tonumber(typeInput.Text) or defaultVal;
		
		if tonumber(setVal) then
			setVal = setVal * rangeInfo.Scale;
		end

		currentVal = setVal;
		refreshSlider();
		if saveFunc then
			saveFunc(currentVal/rangeScale);
		end
		setFunc(currentVal/rangeScale);
	end)

	typeInput:GetPropertyChangedSignal("Text"):Connect(function()
		if typeInput:IsFocused() then
			button.Text = "";
		end
	end)

	local resetCooldown = nil;
	button:GetAttributeChangedSignal("Value"):Connect(function()
		local valueSet = button:GetAttribute("Value");
		if valueSet == "nil" then
			valueSet = nil;
			button:SetAttribute("Value", nil);
		end
		if valueSet == nil then 
			if resetCooldown and tick()-resetCooldown <= 0.2 then return end
			resetDefaultValues();
			return
		end;
		
		local setVal = tonumber(valueSet);
		resetCooldown = tick();
		button:SetAttribute("Value", nil);
		
		if tonumber(setVal) then
			setVal = setVal * rangeInfo.Scale;
		end

		currentVal = setVal;
		refreshSlider();
		setFunc(currentVal/rangeScale);
	end)

end

function Components.CreateSliderType2(mainInterface, paramPacket)
	local self = {
		Disabled = false;
	};
	
	local sliderBar = paramPacket.SliderBar :: TextButton;
	
	local defaultValue = paramPacket.DefaultValue or 1;
	self.MaxValue = paramPacket.MaxValue or 1;
	
	local setFunc = paramPacket.SetFunc;

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
	
	sliderBar.TouchPan:Connect(StartQuantitySlider);
	sliderBar.MouseButton1Down:Connect(StartQuantitySlider);
	sliderBar.SliderNob.MouseButton1Down:Connect(StartQuantitySlider);
	
	task.delay(0.1, function()
		update(defaultValue);
	end)
	
	return self;
end

local sliderTextBoxTemplate = script:WaitForChild("sliderTextBox");
function Components.CreateSliderTextbox(mainInterface)
	local meta = {};
	meta.__index = meta;

	local self = {};
	self.Frame = sliderTextBoxTemplate;
	self.Button = self.Frame:WaitForChild("Button");

	local rangeInfo = {Min=0; Max=100; Default=(50);};
	Components.CreateSlider(mainInterface, {
		Button=self.Button;
		RangeInfo=rangeInfo;
		SetFunc=function(value)
			
		end;
	});

	setmetatable(self, meta);

	return self;
end

local taskProcessTemplate = script:WaitForChild("taskProcess");
function Components.CreateProgressListing(mainInterface, paramPacket)
	local meta = {};
	meta.__index = meta;

	function meta:Destroy()
		Debugger.Expire(self.Button);
		self.Button = nil;
	end

	function meta:Update(taskData)
		if taskData then
			self.ProgressValue = taskData.ProgressValue or 0;
			self.ProgressLabel = taskData.ProgressLabel or "";
			self.Title = taskData.Title or "n/a";
			self.DescText = taskData.DescText or "";
		end
		if self.Button == nil then return end;

		local titleTag = self.Button:WaitForChild("titleTag");
		titleTag.Text = self.Title;

		local barFrame = self.Button:WaitForChild("BarFrame");
		local progressBar = barFrame:WaitForChild("Bar");
		local timeTag = barFrame:WaitForChild("TimeTag");

		pcall(function()
			progressBar:TweenSize(UDim2.new(self.ProgressValue, 0, 1, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 1.1, true);
		end);

		timeTag.Text = self.ProgressLabel;

		local detailsFrame = self.Button:WaitForChild("DetailsFrame");
		
		local descLabel = detailsFrame:WaitForChild("Description") :: TextLabel;
		if self.DescText == nil or #self.DescText <= 0 then
			descLabel.Visible = false;
		else
			descLabel.Visible = true;
			descLabel.Text = self.DescText;
		end

		local isComplete = self.ProgressValue >= 1
		
		local completeButton = detailsFrame:WaitForChild("CompleteButton") :: TextButton;
		completeButton.Visible = isComplete;
		
		self.CancelHoldDownObject.Button.Visible = not isComplete;

		local skipButton = detailsFrame:WaitForChild("SkipButton") :: TextButton;
		skipButton.Visible = not isComplete and self.IsSkipVisible;
	end

	local self = {};
	self.Id = paramPacket.Id;

	self.Title = "n/a";
	self.ProgressValue = 0;
	self.ProgressLabel = "";
	self.IsSkipVisible = false;

	self.OnSkipClick = function(packet) end;
	self.OnCompleteClick = function(packet) end;
	self.OnCancelClick = function(packet) end;
	
	local newButton = taskProcessTemplate:Clone() :: ImageButton;
	newButton.Name = self.Id;
	newButton.Parent = paramPacket.Parent;
	self.Button = newButton;

	local detailsFrame = newButton:WaitForChild("DetailsFrame");
	newButton.MouseButton1Click:Connect(function()
		mainInterface:PlayButtonClick();
		detailsFrame.Visible = not detailsFrame.Visible;
	end)

	local skipButton = detailsFrame:WaitForChild("SkipButton") :: TextButton;
	skipButton.MouseButton1Click:Connect(function()
		mainInterface:PlayButtonClick();
		if self.OnSkipClick then
			self.OnSkipClick({
				Button=skipButton;
			});
		end
	end)

	local completeButton = detailsFrame:WaitForChild("CompleteButton") :: TextButton;
	completeButton.MouseButton1Click:Connect(function()
		mainInterface:PlayButtonClick();

		if self.OnCompleteClick then
			self.OnCompleteClick({
				Button=completeButton;
			});
		end
	end)

	self.CancelHoldDownObject = Components.CreateHoldDownButton(mainInterface, {
		Name = "CancelButton";
		Text = "Cancel Task";
	})
	self.CancelHoldDownObject.OnHoldDownConfirm = function()
		if self.OnCancelClick then
			self.OnCancelClick({
				Button=self.CancelHoldDownObject.Button;
			});
		end
	end
	local cancelButton = self.CancelHoldDownObject.Button;
	cancelButton.Size = UDim2.new(1, -20, 0, 30);
	cancelButton.Parent = detailsFrame;

	setmetatable(self, meta);

	detailsFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		self:Update();
	end)

	return self;
end


local holdDownButtonTemplate = script:WaitForChild("holdDownButton");
function Components.CreateHoldDownButton(mainInterface, paramPacket)
	local meta = {};
	meta.__index = meta;

	local self = {};
	self.OnHoldDownConfirm = function() end;

	self.Button = holdDownButtonTemplate:Clone() :: TextButton;
	self.Button.Name = paramPacket.Name or self.Button.Name;
	self.Button.Text = paramPacket.Text;

	local progressBar = self.Button:WaitForChild("Bar") :: Frame;

	local holdDuration = 1;
	if paramPacket.Duration then
		holdDuration = paramPacket.Duration;
	end

	if paramPacket.Color then
		local color: Color3 = paramPacket.Color;
		local h,s,v = color:ToHSV();
		self.Button.BackgroundColor3 = color;
		progressBar.BackgroundColor3 = Color3.fromHSV(h, s+0.4, v+0.4);
	end

	local buttonDebounce = false;
	local initTick;
	local buttonDown = false;
	
	self.Button.InputBegan:Connect(function(inputObject, gameProcessed)
		if gameProcessed then return end;
		if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 and inputObject.UserInputType ~= Enum.UserInputType.Touch then return end;

		buttonDown = true;
		initTick = tick();

		RunService:BindToRenderStep("ButtonConfirmation", Enum.RenderPriority.Input.Value+1, function(delta)
			local percent = math.clamp((tick()-initTick)/holdDuration, 0, 1);
			progressBar.Size = UDim2.new(math.max(percent, 0.05), 0, 1, 0);

			if percent >= 1 and not buttonDebounce then
				buttonDebounce = true;

				mainInterface:PlayButtonClick();
				if self.OnHoldDownConfirm then
					self.OnHoldDownConfirm();
				end
				
				progressBar.Size = UDim2.new(0, 0, 1, 0);
				buttonDown = false;
			end
			
			if not buttonDown then
				RunService:UnbindFromRenderStep("ButtonConfirmation");
				progressBar.Size = UDim2.new(0, 0, 1, 0);
				task.delay(0.2, function()
					if self.Button then
						self.Button.Text = paramPacket.Text;
					end
					buttonDebounce = false;
				end)
			end
		end)
	end)
		
	self.Button.InputEnded:Connect(function() 
		buttonDown = false;
	end)

	setmetatable(self, meta);
	return self;
end

return Components;