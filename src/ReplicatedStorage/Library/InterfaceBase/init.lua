local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Dependencies;
local UserInputService = game:GetService("UserInputService");
local TextService = game:GetService("TextService");

local modAudio = require(game.ReplicatedStorage.Library:WaitForChild("Audio"));
local modEventSignal = require(game.ReplicatedStorage.Library:WaitForChild("EventSignal"));
local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modGarbageHandler = require(game.ReplicatedStorage.Library.GarbageHandler);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

local remoteStorageService = modRemotesManager:Get("StorageService");

local localplayer = game.Players.LocalPlayer;
local camera = workspace.CurrentCamera;

local menuBlur = script:WaitForChild("MenuBlur");
--== Variables;
local InterfaceBase = {};
InterfaceBase.__index = InterfaceBase;

function InterfaceBase.new()
	local self = {
		ScreenGui = nil;
		
		Interfaces = {};
		Windows = {};
		Dir = {};
		
		Garbage = modGarbageHandler.new();
		OnWindowToggle = modEventSignal.new("OnWindowToggle");
	};
	
	self.__index = self;
	setmetatable(self, InterfaceBase);
	return self;
end

function InterfaceBase:Load(parent)
	Debugger:Log("Load ",parent.Name," interfaces.");

	local msrcs = {};
	for _, msrc in pairs(parent:GetChildren()) do
		if msrc:IsA("ModuleScript") then
			table.insert(msrcs, {
				Name=(msrc.Name);
				Msrc=msrc;
				Order=msrc:GetAttribute("LoadOrder") or 999;
			});
		end
	end

	table.sort(msrcs, function(a,b) return a.Order < b.Order end)
	for _, s in pairs(msrcs) do
		self.Interfaces[s.Name] = Debugger:Require(s.Msrc, true).init(self);
	end
end


--================= WindowBase
local WindowBase = {};
WindowBase.__index = WindowBase;

function WindowBase.new(name, frame)
	local self = {
		Name = name;
		Frame = frame;
		Visible = false;
		OpenPosition =  nil;--UDim2.new(0.5, 0, 0.5, 0);
		ClosePosition = nil;--UDim2.new(0.5, 0, 1.5, 0);
		IgnoreHideAll = false;
		
		WindowButtons = {};
		
		-- events;
		OnToggle = modEventSignal.new("OnToggle");
		OnUpdate = modEventSignal.new("OnUpdate");
	}
	
	
	setmetatable(self, WindowBase);
	return self;
end

local tweenSpeed = 0.3;
function WindowBase:Open(...)
	if self.Visible then
		self:Update(true, ...);
		return;
	end;

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
	
	self.OnToggle:Fire(true, ...);
	self.Interface.OnWindowToggle:Fire(self.Name, true, ...);

	self.Interface:RefreshVisibility();
	self.Interface:RefreshWindowButtons();
end

function WindowBase:Close(...)
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
	self.OnToggle:Fire(false, ...);
	self.Interface.OnWindowToggle:Fire(self.Name, false, ...);
	
	self.Interface:RefreshVisibility();
	self.Interface:RefreshWindowButtons();
end

function WindowBase:Update(...)
	self.OnUpdate:Fire(...);
end

function WindowBase:SetOpenClosePosition(open, close)
	self.OpenPosition = open;
	self.ClosePosition = close;
	self.Frame.Position = self.ClosePosition;
	self.Frame.Visible = false;
end

function WindowBase:Toggle(visible, ...)
	if visible == nil then visible = not self.Visible end;
	if visible then
		self:Open(...);
	else
		self:Close(...);
	end
end

--================= WindowBase

function InterfaceBase:NewWindow(name, frame)
	local window = WindowBase.new(name, frame);
	
	window.Interface = self;
	self.Windows[name] = window;
	
	return window;
end

local toggleDebounce = false;
function InterfaceBase:HideAll(blacklist)
	if toggleDebounce == true then return end;
	toggleDebounce = true;
	
	for name, window in pairs(self.Windows) do
		if window.Visible and (blacklist == nil or blacklist[name] == nil) and window.IgnoreHideAll ~= true then
			window:Close();
		end
	end
	
	toggleDebounce = false;
end

function InterfaceBase:NewWindowButton(name, packet)
	local button = packet.Button;
	
	if button == nil then
		button = self.Dir.MenuButton:Clone();
		button.Name = name;
		button.LayoutOrder = packet.LayoutOrder or 0;
		button.Visible = true;
		
		if packet.Parent then
			button.Parent = packet.Parent;
		end
		
		if button:FindFirstChild("Hint") then
			packet.HasHint = true;
			button.Hint.Text = name;
		end
		if button:FindFirstChild("Label") then
			button.Label.Text = name;
		end
		
		if button:IsA("ImageButton") then
			button.Image = packet.Image;
		elseif button:FindFirstChild("ImageLabel") then
			button.ImageLabel.Image = packet.Image;
		end
	end
	
	if UserInputService.MouseEnabled then
		if packet.HasHint == true then
			button.MouseEnter:Connect(function()
				if not button.Hint.Visible then delay(1, function() button.Hint.Visible = false; end) end;
				button.Hint.Visible = true;
			end)

			button.MouseLeave:Connect(function()
				button.Hint.Visible = false;
			end)
		end
	end
	packet.Button = button;
	
	
	local window = self.Windows[name];
	
	button.MouseButton1Click:Connect(function()
		self:PlayButtonClick();
		
		if packet.OnClick then
			packet.OnClick();
		else
			if window == nil then return end;
			window:Toggle();
		end
	end)
	
	if window then
		window.WindowButtons[button] = packet;
	end
	
	return packet;
end

function InterfaceBase:RefreshVisibility()
	local blurBackground;
	for name, window in pairs(self.Windows) do
		if window.Visible and window.MenuBlur then
			blurBackground = window.MenuBlur;
		end
	end
	
	if blurBackground then
		menuBlur.Parent = workspace.CurrentCamera;
		menuBlur.Size = blurBackground;
	else
		menuBlur.Parent = script;
	end
end

function InterfaceBase:RefreshWindowButtons()
	for name, window in pairs(self.Windows) do
		local windowButtons = window.WindowButtons;
		
		for button, packet in pairs(windowButtons) do
			button:SetAttribute("WindowVisible", window.Visible);
			if button:IsA("ImageButton") then
				button.ImageColor3 = window.Visible and Color3.fromRGB(1, 162, 254) or Color3.fromRGB(255,255,255);
			end
		end
	end
end

function InterfaceBase:PlayButtonClick(pitch)
	modAudio.Play("ButtonSound", nil, nil, false).PlaybackSpeed = pitch or 1;
end


return InterfaceBase;