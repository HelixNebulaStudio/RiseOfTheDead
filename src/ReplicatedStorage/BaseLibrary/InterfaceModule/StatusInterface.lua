local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};
Interface.__index = Interface;

local RunService = game:GetService("RunService");
local TextService = game:GetService("TextService");

local localplayer = game.Players.LocalPlayer;

local modData = require(localplayer:WaitForChild("DataModule"));

local modStatusLibrary = require(game.ReplicatedStorage.Library.StatusLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local modRadialImage = require(game.ReplicatedStorage.Library.UI.RadialImage);

local branchColor = modBranchConfigs.BranchColor
local radialConfig = '{"version":1,"size":128,"count":128,"columns":8,"rows":8,"images":["rbxassetid://4467212179","rbxassetid://4467212459"]}';

--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);
	
	local interfaceScreenGui = localplayer.PlayerGui:WaitForChild("MainInterface");
	
	local menu = script:WaitForChild("StatusBar"):Clone();
	menu.Parent = interfaceScreenGui;

	local window = Interface.NewWindow("StatusBar", menu);
	window.IgnoreHideAll = true;
	window.ReleaseMouse = false;
	window:Open();
	window:SetConfigKey("DisableStatusHud");
	
	function Interface:OnToggleHuds(value)
		if modConfigurations.CompactInterface then
			menu.Visible = value;
		end
	end
	
	local templateStatusItem = script:WaitForChild("statusItem");

	local listings = {};
	local smoothTime, lastTick, lastOsTime = 0, 0, 0;
	local heartbeatConn;
	
	local classPlayer = shared.modPlayers.Get(localplayer);
	
	if modConfigurations.CompactInterface then
		menu.AnchorPoint = Vector2.new(0.5, 0);
		menu.Position = UDim2.new(0.5, 0, 0, 45);
		menu.Size = UDim2.new(0.5, 0, 0.05, 0);
	end
	
	local function newStatus(lib, srcTable, id)
		local status = listings[lib.Id] or {};
		listings[lib.Id] = status;
		if status.Button == nil then
			status.Button = templateStatusItem:Clone();
			status.Button.MouseMoved:Connect(function()
				for id, obj in pairs(listings) do
					obj.Info.Visible = id == lib.Id;
				end
			end)
			status.Button.MouseLeave:Connect(function()
				status.Info.Visible = false;
			end)
			status.Button.MouseButton1Click:Connect(function()
				if modBranchConfigs.CurrentBranch.Name == "Dev" then
					Debugger:Warn("Status id:",id,"table:", srcTable[id]);
				end
			end)
			
			status.Button.Parent = menu;
			status.Radial = modRadialImage.new(radialConfig, status.Button:WaitForChild("radialBar"));
			status.Icon = status.Button:WaitForChild("icon");
			status.Info = status.Button:WaitForChild("info");
			status.Title = status.Button:WaitForChild("title");
			status.Quan = status.Button:WaitForChild("quantity");
			
			status.Icon.Image = lib.Icon;
			status.Title.Text = lib.Name;
			status.Button.radialBar.ImageColor3 = lib.Buff and Color3.fromRGB(27, 106, 23) or Color3.fromRGB(255, 60, 60);
		end
		
		local src = srcTable[id];
		
		local alpha = 1;
		if type(src) == "table" then
			
			if src.Alpha then
				alpha = src.Alpha;

			elseif src.Duration and src.EndTime then
				alpha = (src.EndTime-smoothTime)/src.Duration;
				
			elseif src.Duration and src.Expires then
				alpha = (src.Expires-smoothTime)/src.Duration;
				
			end
		end
		alpha = math.clamp(alpha, 0, 1);
		
		status.Radial:UpdateLabel(alpha);
		
		local statusVisible = true;--alpha >= 0.001;
		
		if typeof(src) == "table" then
			if src.Visible == false then
				statusVisible = false;
			end
		end
		
		status.Button.Visible = statusVisible;
		
		if lib.QuantityLabel then
			local stat = src[lib.QuantityLabel];
			local str = stat;
			local v = tonumber(stat);
			
			if tonumber(stat) then
				local statStr = tostring(stat);
				if #statStr >= 7 then
					str=(math.round(v/100000)/10).."M";
				elseif #statStr >= 4 then
					str=(math.round(v/100)/10).."K";
				else
					str=math.round(v);
				end
			end
			status.Quan.Text = str or "";
		end
		
		local descStr = lib.Description;
		if type(src) == "table" then
			if src.Duration and src.Expires then
				local timeRatio = (src.Expires-smoothTime)/src.Duration;
				descStr = descStr.. " ("..modSyncTime.ToString(timeRatio * src.Duration)..")"
			end
			
			for k, v in pairs(src) do
				if typeof(v) == "string" or typeof(v) == "number" then
					if lib.DescProcess and lib.DescProcess[k] then
						v = lib.DescProcess[k](v);
					end
					descStr = descStr:gsub("$"..k, v);
				end
			end
		end
		
		status.Info.Text = descStr;
	end
	
	Interface.Garbage:Tag(RunService.Heartbeat:Connect(function()
		local newTime = modSyncTime.GetTime();
		if lastOsTime ~= newTime then
			lastOsTime = newTime;
			lastTick = tick();
		end
		smoothTime = lastOsTime+tick()-lastTick;
		
		if classPlayer.Properties == nil then return end;
		local destroy = {};
		for id, _ in pairs(listings) do
			destroy[id] = true;
		end
		
		if classPlayer.Properties.HealSources then
			for id, src in pairs(classPlayer.Properties.HealSources) do
				local lib = modStatusLibrary:Find(id);
				if lib then
					destroy[id] = false;
					newStatus(lib, classPlayer.Properties.HealSources, id);
				end
			end
		end
		for id, src in pairs(classPlayer.Properties) do
			local lib = modStatusLibrary:Find(id);
			if lib then
				destroy[id] = false;
				newStatus(lib, classPlayer.Properties, id);
			end
		end
		for id, shouldDestroy in pairs(destroy) do
			if shouldDestroy and listings[id] then
				if listings[id].Button then listings[id].Button:Destroy() end;
				listings[id] = nil;
			end
		end
	end));
	
	Interface.Garbage:Tag(function()
		for id,_ in pairs(listings) do
			if listings[id].Button then listings[id].Button:Destroy() end;
			listings[id] = nil;
		end
	end);
	
	return Interface;
end;

return Interface;
