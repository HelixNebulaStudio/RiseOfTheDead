local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};
Interface.__index = Interface;

local RunService = game:GetService("RunService");
local TextService = game:GetService("TextService");
local TweenService = game:GetService("TweenService");

local localplayer = game.Players.LocalPlayer;
local camera = workspace.CurrentCamera;

local modData = require(localplayer:WaitForChild("DataModule"));

local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local branchColor = modBranchConfigs.BranchColor

local remoteNotifyPlayer = modRemotesManager:Get("NotifyPlayer");

local menu = script.Parent.Parent:WaitForChild("NotificationBoard");
local menuLayout = menu:WaitForChild("UIListLayout");
local templateNotification = menuLayout:WaitForChild("templateNotification");

local squadFrameLayout = script.Parent.Parent:WaitForChild("SquadMenu"):WaitForChild("SquadList"):WaitForChild("UIListLayout");

local notificationDuration = 10;
local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut);
local listings = {};
local textAlignment = Enum.TextXAlignment.Right;
--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);

	return Interface;
end;

function Interface.UpdatePos()
	local displayState = modConfigurations.NotificationViewPos or 1;
	
	if modConfigurations.CompactInterface then
		displayState = 2;
	end
	
	if displayState == 1 then
		menu.AnchorPoint = Vector2.new(1, 1);
		menu.Position = UDim2.new(1, -30, 1, -squadFrameLayout.AbsoluteContentSize.Y-40 );
		menu.Size = UDim2.new(0.2, 0, 0, 0);
		menuLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left;
		textAlignment = Enum.TextXAlignment.Right;
		
	elseif displayState == 2 then
		menu.AnchorPoint = Vector2.new(0.5, 1);
		menu.Position = UDim2.new(0.5, 0, 0.13, 0);
		menu.Size = UDim2.new(0.6, 0, 0, 0);
		menuLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
		textAlignment = Enum.TextXAlignment.Center;
		
	end
end

function Interface.Notify(key, messageData)
	Interface.UpdatePos();
	
	local cinematicMode = modData and modData.Settings and modData.Settings.CinematicMode == 1;
	if cinematicMode then
		if messageData.Message:match("has arrived from") ~= nil
			or messageData.Message:match("has entered the game") ~= nil then
			return;
		end
	end
	
	local new = templateNotification:Clone();
	local label = new:WaitForChild("TextLabel");
	label.Text = tostring(messageData.Message);
	
	label.TextXAlignment = textAlignment;
	
	if messageData.ExtraData then
		if messageData.ExtraData.ChatColor then
			label.TextColor3 = messageData.ExtraData.ChatColor;
		end
		if messageData.ExtraData.Font then
			label.Font = messageData.ExtraData.Font;
		end
	end
	
	new.Parent = menu;

	local packet = messageData.Packet or {};
	if packet.SndId then
		modAudio.Play(packet.SndId, menu);
	end
	
	delay(modData.Settings.CinematicMode == 1 and 2 or notificationDuration, function()
		if not new:IsDescendantOf(localplayer.PlayerGui) then return end;
		label:TweenPosition(UDim2.new(0, 0, 0, (camera.ViewportSize.Y-label.AbsolutePosition.Y+10)), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 1);
		TweenService:Create(label, tweenInfo, {TextTransparency = 1; TextStrokeTransparency = 1;}):Play();
		wait(1);
		new:Destroy();
	end)
	if key then
		if listings[key] and listings[key]:IsDescendantOf(menu) then
			listings[key].Visible = false;
		end
		listings[key] = new;
	end
end

local remoteOnNotify = remoteNotifyPlayer.OnClientEvent:Connect(Interface.Notify)

squadFrameLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	wait(0.1);
	Interface.UpdatePos();
end)

script.AncestryChanged:Connect(function(c, p)
	if c == script and p == nil then
		if remoteOnNotify then remoteOnNotify:Disconnect(); end;
	end
end)
return Interface;