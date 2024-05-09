local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Dependencies;
local UserInputService = game:GetService("UserInputService");
local TextService = game:GetService("TextService");
local TweenService = game:GetService("TweenService");

local localPlayer = game.Players.LocalPlayer;
local playerGui = localPlayer:WaitForChild("PlayerGui");
local camera = workspace.CurrentCamera;

local modItemViewport = require(script.Parent:WaitForChild("ItemViewport"));
local modAudio = require(game.ReplicatedStorage.Library:WaitForChild("Audio"));
local modEventSignal = require(game.ReplicatedStorage.Library:WaitForChild("EventSignal"));
local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modGarbageHandler = require(game.ReplicatedStorage.Library.GarbageHandler);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);

local modColorPicker = require(game.ReplicatedStorage.Library.UI.ColorPicker);
local modDropdownList = require(game.ReplicatedStorage.Library.UI.DropdownList);

local modGuiObjectTween = require(playerGui:WaitForChild("GuiObjectTween"));

local quickBarFrame: Frame = script.Parent:WaitForChild("QuickButtons")
local blindsFrame: Frame = script.Parent:WaitForChild("GameBlinds");

local remoteStorageService = modRemotesManager:Get("StorageService");
local remotePlayerDataSync = modRemotesManager:Get("PlayerDataSync");


if script == nil then Debugger:Log("Load cancelled."); return {}; end;
--== Variables;
local Interface = {};
Interface.__index = Interface;

Interface.StorageInterfaces = {};
Interface.StorageInterfaceIndex = 1;

Interface.Garbage = modGarbageHandler.new();

Interface.Script = script;
Interface.MainInterface = script.Parent;
Interface.CameraInterface = script.Parent.Parent:WaitForChild("CameraInterface");

Interface.ColorPicker = modColorPicker.new();
Interface.ColorPicker.Frame.Parent = Interface.MainInterface;

Interface.DropdownList = modDropdownList.new();
Interface.DropdownList.Frame.Parent = Interface.MainInterface;

Interface.ItemViewport = modItemViewport;

Interface.modCharacter = nil;

Interface.Windows = {};
Interface.Visible = false;

Interface.CanInteract = true;
Interface.CanOpenWindows = true;

Interface.DisableHotKeys = false;
Interface.DisableGameplayBinds = false;

Interface.IsPremium = false;
Interface.QuickButtons = {};

Interface.ActiveWindowsKey = nil;

Interface.BindFuncs = {};

Interface.ScreenEffects = {};

function Interface:Bind(id, func)
	self.BindFuncs[id] = func;
	Debugger:Log("BindFuncs",id);
end

function Interface:CallBind(id, ...)
	local param = {...};

	task.spawn(function()
		if self.BindFuncs[id] == nil then
			for a=1, 5*60 do
				if self.BindFuncs[id] then
					break;
				else
					task.wait();
					if math.fmod(a/60, 1) == 0 then
						Debugger:Log("CallBind not yet binded",id);
					end
				end
			end
		end
		if self.BindFuncs[id] then
			self.BindFuncs[id](unpack(param));
			Debugger:Log("CallBind", id);
		end
	end)
end

Interface.Garbage:Tag(function()
	table.clear(Interface.BindFuncs);
end)

-- !outline: Interface:ToggleGameBlinds(openBlinds, duration)
function Interface:ToggleGameBlinds(openBlinds, duration)
	duration = duration or 2;
	if openBlinds then
		if blindsFrame.BackgroundTransparency >= 0.95 then return end;
	else
		if blindsFrame.BackgroundTransparency <= 0.05 then return end;
	end

	blindsFrame.Visible = true;
	TweenService:Create(blindsFrame, TweenInfo.new(duration), {BackgroundTransparency = openBlinds and 1 or 0;}):Play();
end
Interface:ToggleGameBlinds(true, 0.5);


local modData = require(localPlayer:WaitForChild("DataModule", 30) :: ModuleScript);
modData.modInterface = Interface;

local modChatRoomInterface = require(localPlayer.PlayerGui:WaitForChild("ChatInterface"):WaitForChild("ChatRoomInterface") :: ModuleScript);
modData.modChatRoomInterface = modChatRoomInterface;

for a=1, 10*60 do
	if modData:IsSettingsLoaded() ~= true then
		task.wait()
		if math.fmod(a/60, 1) == 0 then
			Debugger:Warn("Waiting for settings to load 1s..");
		end
		
	elseif camera.ViewportSize.Magnitude <= 10 then
		task.wait();
		if math.fmod(a/60, 1) == 0 then
			Debugger:Warn("Waiting for viewport to load..");
		end
		
	else
		break;
		
	end
end

local smallViewportSize = Vector2.new(1024, 600);
if camera.ViewportSize.X < smallViewportSize.X or camera.ViewportSize.X < smallViewportSize.Y then
	modConfigurations.Set("CompactInterface", true);
	
elseif modData.Settings.CompactInterface == 1 then
	modConfigurations.Set("CompactInterface", true);
	
elseif modData.Settings.CompactInterface == 2 then
	modConfigurations.Set("CompactInterface", false);
	
else
	modConfigurations.Set("CompactInterface", camera.ViewportSize.X <= smallViewportSize.X or camera.ViewportSize.Y <= smallViewportSize.Y);
	
end

local WarningHint = Interface.MainInterface:WaitForChild("WarningHint");

Interface.Elements = {};
Interface.Frozen = false;

Interface.TouchControls = script.Parent:WaitForChild("TouchControls");

Interface.Templates = {
	BasicButton = script:WaitForChild("templateBasicButton");
	ScrollingFrame = script:WaitForChild("templateScrollingFrame");
}

local tweenSpeed = 0.3;

local menuBlur = script:WaitForChild("MenuBlur");
--== Script;
local GenericUICheckbox = {};
GenericUICheckbox.__index = GenericUICheckbox;
GenericUICheckbox.Instance = script:WaitForChild("templateCheckbox");
Interface.Templates.Checkbox = GenericUICheckbox;

function GenericUICheckbox:Clone()
	local new = GenericUICheckbox.Instance:Clone();
	
	new:SetAttribute("Checked", false);
	
	local checkFrame = new:WaitForChild("checkboxFrame");
	
	Interface.Garbage:Tag(new.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Interface:PlayButtonClick();
			new:SetAttribute("Checked", not new:GetAttribute("Checked"));
			
			local checked = new:GetAttribute("Checked");
			checkFrame.BackgroundColor3 = checked and Color3.fromRGB(150, 184, 250) or Color3.fromRGB(50, 50, 50);
		end
	end))
	
	return new;
end

function Interface:PlayButtonClick(pitch: number?)
	modAudio.Play("ButtonSound", nil, nil, false).PlaybackSpeed = pitch or 1;
end

function Interface:ToggleInteraction(v)
	if v == nil then v = not Interface.CanInteract end;
	Interface.CanInteract = v;
end

function Interface:Freeze(value)
	Interface.Frozen = value == true;
end

function Interface:ToggleHuds(value)
	local generalStats = script.Parent:WaitForChild("GeneralStats");
	if modConfigurations.CompactInterface then
		
		for k, v in pairs(Interface) do
			if typeof(v) == "table" and v.OnToggleHuds then
				v:OnToggleHuds(value);
			end
		end
		
		script.Parent:WaitForChild("QuickButtons").Visible = value;
		script.Parent:WaitForChild("ProgressionBar").Visible = (not modConfigurations.DisableExperiencebar) and value;
		
		if script.Parent:FindFirstChild("MissionPinHud") then
			script.Parent.MissionPinHud.Visible = (not modConfigurations.DisablePinnedMission) and value;
		end
		
		if value then
			generalStats.AnchorPoint = Vector2.new(0.5, 1);
			generalStats.Position = UDim2.new(0.5, 0, 1, -6);
			generalStats.Size = UDim2.new(0.55, 0, 0, 14);
			generalStats.Visible = not modConfigurations.DisableGeneralStats;
			generalStats:WaitForChild("perkslabel").Position = UDim2.new(1, -10, 0.5, 0);
			generalStats:WaitForChild("moneylabel").Position = UDim2.new(0, 10, 0.5, 0);
			
		else
			
			if (Interface.Windows.Inventory and Interface.Windows.Inventory.Visible) or (Interface.Windows.Workbench and Interface.Windows.Workbench.Visible) then
				generalStats.Visible = not modConfigurations.DisableGeneralStats;
			else
				generalStats.Visible = false;
			end
			generalStats.AnchorPoint = Vector2.new(0, 0);
			generalStats.Position = UDim2.new(0, 0, 0, 4);
			generalStats.Size = UDim2.new(0.5, 0, 0, 24);
			generalStats:WaitForChild("perkslabel").Position = UDim2.new(0.5, -5, 0.5, 0);
			generalStats:WaitForChild("moneylabel").Position = UDim2.new(0.5, 5, 0.5, 0);
		end
	end
	
	script.Parent:WaitForChild("TouchControls").Visible = UserInputService.TouchEnabled and value;
end

function Interface.NewWindow(name, frame)
	local Window = {};
	Window.Name = name;
	Window.Frame = frame;
	Window.Visible = false;
	Window.OpenPosition =  nil;--UDim2.new(0.5, 0, 0.5, 0);
	Window.ClosePosition = nil;--UDim2.new(0.5, 0, 1.5, 0);
	Window.CompactFullscreen = false;
	Window.IgnoreHideAll = false;
	Window.LastHideAllTick = 0;
	
	-- events;
	Window.OnWindowToggle = modEventSignal.new("OnWindowToggle");
	Window.OnWindowUpdate = modEventSignal.new("OnWindowUpdate");
	
	function Window:Open(...)
		if Interface.Frozen then return end;
		if tick()-self.LastHideAllTick <= 0.2 then return end;
		
		if self.Visible then
			self:Update(true, ...);
			return;
		end;
		if not Interface.CanOpenWindows then Debugger:Log("Cannot toggle interface at this moment"); return false; end;
		
		if self.OpenPosition then
			if self.ToggleTweenAnimation ~= false then
				self.Frame.Visible = true;
				self.Frame:TweenPosition(self.OpenPosition, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, tweenSpeed, true);
			else
				self.Frame.Visible = true;
				self.Frame.Position = self.OpenPosition;
			end
		else
			self.Frame.Visible = true;
		end
		self.Visible = true;
		Interface:RefreshVisibility();
		if self.QuickButton then Interface.RefreshQuickButton(self.QuickButton, self.Visible); end
		self.OnWindowToggle:Fire(true, ...);
		
		return;
	end
	
	function Window:Close(...)
		if Interface.Frozen then return end;
		if not self.Visible then return end;
		
		if self.ClosePosition then
			if self.ToggleTweenAnimation ~= false then
				self.Frame:TweenPosition(self.ClosePosition, Enum.EasingDirection.In, Enum.EasingStyle.Quad, tweenSpeed, true, function(status)
					if status == Enum.TweenStatus.Completed then
						self.Frame.Visible = false;
					end
				end);
			else
				self.Frame.Position = self.ClosePosition;
				self.Frame.Visible = false;
			end
		else
			self.Frame.Visible = false;
		end
		
		self.Visible = false;
		Interface:RefreshVisibility();
		if self.QuickButton then Interface.RefreshQuickButton(self.QuickButton, self.Visible); end
		self.OnWindowToggle:Fire(false, ...);
	end
	
	function Window:Update(...)
		self.OnWindowUpdate:Fire(...);
	end
	
	function Window:SetOpenClosePosition(open, close)
		self.OpenPosition = open;
		self.ClosePosition = close;
		self.Frame.Position = self.ClosePosition;
		self.Frame.Visible = false;
	end
	
	function Window:Toggle(visible, ...)
		if Interface.Frozen then return end;
		if visible == nil then visible = not self.Visible end;
		if visible then
			self:Open(...);
		else
			self:Close(...);
		end
	end
	
	function Window:AddCloseButton(parent)
		local hotKeyButton = script:WaitForChild("hotKeyButton"):Clone();
		local closeButton = hotKeyButton:WaitForChild("closeButton");
		local buttonLabel = hotKeyButton:WaitForChild("button");
		hotKeyButton.Parent = parent:WaitForChild("BackgroundFrame");
		self.CloseButtonLabel = buttonLabel;
		closeButton.MouseButton1Click:Connect(function()
			if self.Visible then 
				self:Close();
			end
		end)
		if modData:GetSetting("HideHotkey") == 1 then
			hotKeyButton.Visible = false;
		else
			hotKeyButton.Visible = true;
		end
	end
	
	function Window:Refresh()
		local visible = not (modConfigurations[self.ConfigKey] or false);
		
		if self.ConfigChangeConditions then
			visible = visible and self.ConfigChangeConditions();
		end
		
		self.Frame.Visible = self.Visible and visible;
		if self.QuickButton then
			self.QuickButton.Visible = visible;
		end
		if self.OnRefreshFunc then
			self.OnRefreshFunc(visible);
		end
		
	end
	
	function Window:SetConfigKey(configKey, conditions)
		self.ConfigChangeConditions = conditions;
		self.ConfigKey = configKey;
		modConfigurations.OnChanged(configKey, function()
			self:Refresh();
		end);
		self:Refresh();
	end
	
	Interface.Windows[name] = Window;
	return Window;
end

-- !outline: Interface:RefreshVisibility()
function Interface:RefreshVisibility()
	Interface.Visible = script.Parent.OptionPopup.Visible;
	
	if playerGui:FindFirstChild("LobbyInterface") then
		Interface.Visible = Interface.Visible or playerGui.LobbyInterface.Enabled;
	end
	if playerGui:FindFirstChild("ChatInterface") then
		Interface.Visible = Interface.Visible or playerGui.ChatInterface.DisplayOrder ~= 0;
	end
	
	local hideHuds = false;
	local blurBackground = false;
	for name, window in pairs(Interface.Windows) do
		if window.Visible and window.ReleaseMouse ~= false then
			Interface.Visible = true;
		end
		if window.Visible and window.CompactFullscreen == true then
			hideHuds = true;
		end
		if window.Visible and window.MenuBlur then
			blurBackground = true;
		end
		--window:Refresh();
	end
	
	if Interface.modCharacter then
		Interface.modCharacter:ToggleMouseLock(not Interface.Visible);
	end
	if not Interface.Visible then
		script.Parent.MouseLockHint.Visible = false;
		Interface.Object = nil;
	end
	
	if hideHuds then
		Interface:ToggleHuds(false);
	else
		Interface:ToggleHuds(true);
	end
	
	if blurBackground then
		menuBlur.Parent = workspace.CurrentCamera;
	else
		menuBlur.Parent = script;
	end
end

-- !outline: Interface:HideAll(blacklist)
local toggleDebounce = false;
function Interface:HideAll(blacklist)
	if toggleDebounce then return end;
	toggleDebounce = true;
	for name, window in pairs(Interface.Windows) do
		if window.Visible and (blacklist == nil or blacklist[name] == nil) and window.IgnoreHideAll ~= true then
			window.LastHideAllTick = tick();
			window:Close();
		end
	end
	toggleDebounce = false;
end

-- !outline: Interface:IsVisible(name)
function Interface:IsVisible(name)
	if Interface.Windows[name] then
		return Interface.Windows[name].Visible;
	else
		Debugger:Warn("Window named (",name,") does not exist.");
	end

	return false;
end

-- !outline: Interface:GetWindow(name)
function Interface:GetWindow(name)
	return Interface.Windows[name];
end

-- !outline: Interface:ToggleWindow(name, visible, ...)
function Interface:ToggleWindow(name, visible, ...)
	if Interface.Windows[name] then
		Interface.Windows[name]:Toggle(visible, ...);
	else
		Debugger:Warn("Window named (",name,") does not exist.");
	end
end

-- !outline: Interface:OpenWindow(name, ...)
function Interface:OpenWindow(name, ...)
	if Interface.Windows[name] then
		Interface.Windows[name]:Open(...);
	else
		Debugger:Warn("Window named (",name,") does not exist.");
	end
end

-- !outline: Interface:CloseWindow(name, ...)
function Interface:CloseWindow(name, ...)
	if Interface.Windows[name] then
		Interface.Windows[name]:Close(...);
		task.spawn(function()
			Interface.ColorPicker.Frame.Visible = false;
			Interface.DropdownList.Frame.Visible = false;
		end)
	else
		Debugger:Warn("Window named (",name,") does not exist.");
	end
end

-- !outline: Interface:UpdateWindow(name, ...)
function Interface:UpdateWindow(name, ...)
	if Interface.Windows[name] then
		Interface.Windows[name]:Update(...);
	else
		Debugger:Warn("Window named (",name,") does not exist.");
	end
end

-- !outline: Interface:NewQuickButton(name, hint, image)
local quickButtonTemplate = script.Parent:WaitForChild("quickButtonTemplate");
Interface.QuickBar = quickBarFrame;
function Interface:NewQuickButton(name, hint, image)
	local new = quickButtonTemplate:Clone();

	new.Name = name;
	new.Image = image;

	local quickButtonLabel = new:WaitForChild("Hint");
	quickButtonLabel.Text = hint or name;
	
	new.Parent = quickBarFrame -- script.Parent:FindFirstChild("QuickButtons");
	
	return new;
end

-- !outline: Interface:ConnectQuickButton(obj, keyId)
function Interface:ConnectQuickButton(obj, keyId)
	if obj:GetAttribute("ConnectedQuickButton") == true then
		return;
	end
	obj:SetAttribute("ConnectedQuickButton", true);
	
	local quickButton = obj;
	if UserInputService.MouseEnabled then
		quickButton.MouseEnter:Connect(function()
			if not quickButton.Hint.Visible then delay(1, function() quickButton.Hint.Visible = false; end) end;
			quickButton.Hint.Visible = true;
		end)
		
		quickButton.MouseLeave:Connect(function()
			quickButton.Hint.Visible = false;
		end)
	end
	quickButton.MouseButton1Click:Connect(function()
		Interface:PlayButtonClick();
		Debugger:Warn("quickButton.Name", quickButton.Name);
		Interface:ToggleWindow(quickButton.Name);
	end)
	
	if Interface.Windows[quickButton.Name] then
		Interface.Windows[quickButton.Name].QuickButton = quickButton;
		Interface.Windows[quickButton.Name]:Refresh();
	end
	
	if keyId ~= nil then
		local hotKeyLabel = quickButton:WaitForChild("hotKey"):WaitForChild("button");
		hotKeyLabel.Text = modKeyBindsHandler:ToString(keyId) or "";
	end
	
	quickButton.hotKey.Visible = not modConfigurations.DisableHotKeyLabels and UserInputService.KeyboardEnabled or false;
	if modData:GetSetting("HideHotkey") == 1 or modConfigurations.CompactInterface then
		quickButton.hotKey.Visible = false;
	end
	Interface.RefreshQuickButton(quickButton, false);
end


function Interface.RefreshQuickButton(button, visible)
	if button == nil then return end;
	local defaultColor = Color3.fromRGB(255, 255, 255);
	
	if button.Name == "GoldMenu" then
		defaultColor = Color3.fromRGB(255, 220, 112);
	end
	button.ImageColor3 = visible and Color3.fromRGB(1, 162, 254) or defaultColor;
	button.hotKey.Size = UDim2.new(0, 18+(#button.hotKey.button.Text-1)*8, 0, 18);
end

local questionWindow = Interface.NewWindow("QuestionPrompt", script.Parent:WaitForChild("QuestionPrompt"));
questionWindow:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, 1.5, 0));
questionWindow.OnWindowToggle:Connect(function(visible)
	if visible then
		Interface:HideAll{[questionWindow.Name]=true;};
		Interface:ToggleInteraction(false);
		Interface.CanOpenWindows = false;
	else
		Interface.CanOpenWindows = true;
		Interface:ToggleInteraction(true);
	end
end)

function Interface:PromptQuestion(title, desc, yesText, noText, imageId)
	questionWindow.Frame.titleTag.Text = title;
	questionWindow.Frame.descTag.Text = desc or "Are you sure?";
	questionWindow.Frame.Yes.buttonText.Text = yesText or "Yes";
	questionWindow.Frame.Yes.ImageColor3 = Color3.fromRGB(54, 107, 51);
	questionWindow.Frame.No.buttonText.Text = noText or "No";
	questionWindow.Frame.No.ImageColor3 = Color3.fromRGB(102, 38, 38);
	questionWindow.Frame.Icon.Visible = imageId ~= nil;
	questionWindow.Frame.Icon.Image = imageId or "";
	questionWindow:Open();
	return questionWindow;
end

local warningWindow = Interface.NewWindow("WarningPrompt", script.Parent:WaitForChild("WarningFrame"));
warningWindow:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, 1.5, 0));
warningWindow.OnWindowToggle:Connect(function(visible)
	if visible then
		Interface:HideAll{[warningWindow.Name]=true; ["Store"]=true;};
		Interface:ToggleInteraction(false);
		Interface.CanOpenWindows = false;
	else
		Interface.CanOpenWindows = true;
		Interface:ToggleInteraction(true);
	end
end)
warningWindow.Frame:WaitForChild("No").MouseButton1Click:Connect(function()
	Interface:PlayButtonClick();
	warningWindow:Close();
end);

function Interface:PromptWarning(warningMessage)
	warningWindow.Frame.Size = UDim2.new(0, 400, 0, 1000);
	local textBound = TextService:GetTextSize(warningMessage, warningWindow.Frame.Label.TextSize, warningWindow.Frame.Label.Font, Vector2.new(400, 1000));
	warningWindow.Frame.Label.Text = warningMessage;
	warningWindow.Frame.Size = UDim2.new(0, 400, 0, textBound.Y+85);
	warningWindow:Open();
	return warningWindow;
end


function Interface:NewDropdownList(options, newButtonTemplate)
	local dropdownObj = {};
	dropdownObj.OptionButtons = {};
	dropdownObj.ScrollFrame = Interface.Templates.ScrollingFrame:Clone();
	dropdownObj.Destroyed = false;
	
	function dropdownObj:Destroy()
		if dropdownObj.Destroyed then return end;
		for a=1, #dropdownObj.OptionButtons do
			game.Debris:AddItem(dropdownObj.OptionButtons[a], 0);
			dropdownObj.OptionButtons[a] = nil;
		end
		game.Debris:AddItem(dropdownObj.ScrollFrame, 0);
		dropdownObj.ScrollFrame = nil;
		dropdownObj.Destroyed = true;
	end
	
	function dropdownObj:OnOptionClick(func)
		if dropdownObj.Destroyed then return end;
		dropdownObj.optionClickFunc = func;
	end
	
	function dropdownObj:SetPosition(vec2Pos)
		local parPos = dropdownObj.ScrollFrame.Parent.AbsolutePosition;
		dropdownObj.ScrollFrame.Position = UDim2.new(0, vec2Pos.X-parPos.X+1, 0, vec2Pos.Y-parPos.Y+1);
	end
	
	function dropdownObj:SetZIndex(v)
		for a=1, #dropdownObj.OptionButtons do
			if dropdownObj.OptionButtons[a] then
				dropdownObj.OptionButtons[a].ZIndex = v;
			end
		end
		dropdownObj.ScrollFrame.ZIndex = v;
	end
	
	function dropdownObj:NewOption(option, newButtonTemplate)
		local newButton;
		if newButtonTemplate then
			newButton = newButtonTemplate:Clone();
			newButton.Parent = dropdownObj.ScrollFrame;
			newButton.Text = option.Text;
			newButton.LayoutOrder = option.LayoutOrder or 0;
			newButton.ZIndex = newButton.ZIndex +1;
		else
			newButton = Interface.Templates.BasicButton:Clone();
			newButton.Size = option.Size or UDim2.new(1, 0, 0, 30);
			newButton.LayoutOrder = option.LayoutOrder or 0;
			newButton.Text = option.Text;
			newButton.Parent = dropdownObj.ScrollFrame;
			newButton.RichText = true;
			newButton.TextColor3 = option.TextColor3 or Color3.fromRGB(255,255,255);
			newButton.BackgroundColor3 = option.BackgroundColor3 or newButton.BackgroundColor3;
		end
		
		if option.OnNewButton then
			option:OnNewButton(newButton);
		end
		
		table.insert(dropdownObj.OptionButtons, newButton);
		newButton.MouseButton1Click:Connect(function()
			if dropdownObj.Destroyed then return end;
			if dropdownObj.optionClickFunc then
				dropdownObj.optionClickFunc(option.Id);
			end
		end)
	end
	
	for a=1, #options do
		dropdownObj:NewOption(options[a], newButtonTemplate);
	end
	dropdownObj:SetZIndex(2);
	
	return dropdownObj;
end
	

modGuiObjectTween.FadeTween(WarningHint, modGuiObjectTween.FadeDirection.Out, TweenInfo.new(0));
function Interface:HintWarning(message, duration, color)
	if modConfigurations.CompactInterface then
		WarningHint.Position = UDim2.new(0.5, 0, 1, -85);
	else
		WarningHint.Position = UDim2.new(0.5, 0, 1, -185);
	end
	
	WarningHint.Text = message;
	WarningHint.TextColor3 = color or Color3.fromRGB(255, 76, 76);
	WarningHint.Visible = true;
	spawn(function()
		modGuiObjectTween.FadeTween(WarningHint, modGuiObjectTween.FadeDirection.In, TweenInfo.new(0.2));
		wait(duration or 1.2);
		modGuiObjectTween.FadeTween(WarningHint, modGuiObjectTween.FadeDirection.Out, TweenInfo.new(0.2));
	end)
end

function Interface:ModFrame(frameName)
	local new = Instance.new("Frame");
	new.Name = frameName;
	new.BackgroundTransparency = 1;
	new.AnchorPoint = Vector2.new(0.5, 0.5);
	new.Size = UDim2.new(1, 0, 1, 0);
	new.Position = UDim2.new(0.5, 0, 0.5, 0);
	new.Parent = self.MainInterface;
	return new;
end

function Interface.SetPositionWithPadding(guiObject, position, padding)
	padding = padding or 5;

	local targetPos = position or (UserInputService:GetMouseLocation() + Vector2.new(0, -36));

	local parentPos = guiObject.Parent:IsA("GuiObject") and guiObject.Parent.AbsolutePosition or Vector2.zero;
	local frameSize = guiObject.AbsoluteSize;
	
	local vpSize = camera.ViewportSize;
	local posX = targetPos.X+frameSize.X+(padding*2) > vpSize.X-10 and targetPos.X-frameSize.X-padding or targetPos.X;
	local posY = targetPos.Y+frameSize.Y+(padding*2) > vpSize.Y-10 and targetPos.Y-frameSize.Y+padding or targetPos.Y;

	guiObject.Position = UDim2.new(0, 
		math.clamp(posX - parentPos.X, 10, vpSize.X-frameSize.X-10), 
		0, 
		math.clamp(posY - parentPos.Y, 10, vpSize.Y-frameSize.Y-10)
	);
end

function Interface.HandleStorage(action, request, storageIds)
	local rPacket = remoteStorageService:InvokeServer({
		Action=action;
		StorageIds=(storageIds or {"Inventory"; "Clothing"; "Wardrobe"});
		Request=request;
	});

	if rPacket.Storages then
		for storageId, _ in pairs(rPacket.Storages) do
			modData.SetStorage(rPacket.Storages[storageId]);
		end
	end
end

function Interface:Get(interfaceName: string)
	return self["mod"..interfaceName];
end


local function interfaceRequire(module)
	local r;
	local rS, rE;
	
	if modConfigurations["DisableScript:"..module.Name] == true then
		r = {
			init = function() end;
		};
		
	else
		local successful = false;
		task.delay(5, function()
			if not successful then
				Debugger:Warn("Interface Module("..module.Name..") require timed out.");
			end 
		end)

		rS, rE = pcall(function()
			local sTick = tick();
			r = require(module);
			if r.Inited == nil then
				r.Inited = true;
				r = r.init(Interface);
			end
			
			Debugger:Log("Interface (",module.Name,") loaded. Took: ".. math.round((tick()-sTick)*100)/100 .."s");
			successful = true;
		end)
		if not rS then
			Debugger:Warn("Interface (",module.Name,") load failed: ",rE);
		end
		
	end
	
	return r;
end

local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedInterface = modModEngineService:GetModule(script.Name, nil, 5);
if moddedInterface then
	local s, e = pcall(function()
		moddedInterface:Init(Interface);
	end)
	if not s then
		task.spawn(function()
			Debugger:Warn(e);
		end);
	end
else
	Debugger:Warn("Only loading core interface.");
end

Interface.modNotificationInterface = interfaceRequire( script:WaitForChild("NotificationInterface") );

Interface.modMailboxInterface = interfaceRequire( script:WaitForChild("MailboxInterface") );
Interface.modSocialInterface = interfaceRequire( script:WaitForChild("SocialInterface"));
Interface.modEmotesInterface = interfaceRequire( script:WaitForChild("EmotesInterface") );
Interface.modDialogueInterface = interfaceRequire( script:WaitForChild("DialogueInterface") );
Interface.modMasteryInterface = interfaceRequire( script:WaitForChild("MasteryInterface") );
Interface.modUpdatesInterface = interfaceRequire( script:WaitForChild("UpdatesInterface") );
Interface.modWeaponStatsInterface = interfaceRequire( script:WaitForChild("WeaponStatsInterface") );
Interface.modSpectatorInterface = interfaceRequire( script:WaitForChild("SpectatorInterface") );
Interface.modGoldInterface = interfaceRequire( script:WaitForChild("GoldInterface") );
Interface.modRenameInterface = interfaceRequire( script:WaitForChild("RenameInterface") );
Interface.modKeypadInterface = interfaceRequire( script:WaitForChild("KeypadInterface") );
Interface.modBoomboxInterface = interfaceRequire( script:WaitForChild("BoomboxInterface") );
Interface.modDisguiseKitInterface = interfaceRequire( script:WaitForChild("DisguiseKitInterface") );
Interface.modInstrumentInterface = interfaceRequire( script:WaitForChild("InstrumentInterface") );
Interface.modGpsInterface = interfaceRequire( script:WaitForChild("GpsInterface") );
Interface.modAccessoryHudInterface = interfaceRequire( script:WaitForChild("AccessoryHudInterface") );
Interface.modTerminalInterface = interfaceRequire( script:WaitForChild("TerminalInterface") );
Interface.modSoundSystemInterface = interfaceRequire( script:WaitForChild("SoundSystemInterface") );
Interface.modMysteryChestInterface = interfaceRequire( script:WaitForChild("MysteryChestInterface") );
Interface.modVoteInterface = interfaceRequire( script:WaitForChild("VoteInterface") );
Interface.modCardGameInterface = interfaceRequire( script:WaitForChild("CardGameInterface") );
Interface.modEntityHealthHudInterface = interfaceRequire( script:WaitForChild("EntityHealthHudInterface") );
Interface.modHurtInterface = interfaceRequire( script:WaitForChild("HurtInterface") );


--if Interface.modInventoryInterface == nil then
--	Interface.modInventoryInterface = interfaceRequire( script:WaitForChild("InventoryInterface") );
--end
--Interface.modRatShopInterface = interfaceRequire( script:WaitForChild("RatShopInterface") );
--Interface.modFactionsInterface = interfaceRequire( script:WaitForChild("FactionsInterface") );
--Interface.modMissionInterface = interfaceRequire( script:WaitForChild("MissionInterface") );
--if Interface.modExternalStorageInterface == nil then
--	Interface.modExternalStorageInterface = interfaceRequire( script:WaitForChild("ExternalStorageInterface") );
--end
--Interface.modGameModeHud = interfaceRequire( script:WaitForChild("GameModeHud") );
--Interface.modSupplyInterface = interfaceRequire( script:WaitForChild("SupplyInterface") );
--Interface.modWorkbenchInterface = interfaceRequire( script:WaitForChild("WorkbenchInterface") );
--Interface.modStatusInterface = interfaceRequire( script:WaitForChild("StatusInterface") );
--Interface.modMapInterface = interfaceRequire( script:WaitForChild("MapInterface") );
--Interface.modSafehomeInterface = interfaceRequire( script:WaitForChild("SafehomeInterface") );
--Interface.modHealthInterface = interfaceRequire( script:WaitForChild("HealthInterface") );
--Interface.modPosterInterface = interfaceRequire( script:WaitForChild("PosterInterface") );
--Interface.modTradeInterface = interfaceRequire( script:WaitForChild("TradeInterface") );

Interface.modSettingsInterface = interfaceRequire( script:WaitForChild("SettingsInterface") ); -- should always be last for keybind load.
Interface.modSettingsInterface.LoadSettings();

for _, window in pairs(Interface.Windows) do
	window:Refresh();
end

script.Destroying:Connect(function()
	game.Debris:AddItem(menuBlur, 0);
	Interface.Garbage:Destruct();
	Debugger:Log("Cleaning up GUI garbage.");
end)

return Interface;






