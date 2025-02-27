local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};
Interface.__index = Interface;

local RunService = game:GetService("RunService");

local localplayer = game.Players.LocalPlayer;

local modData = require(localplayer:WaitForChild("DataModule") :: ModuleScript);

local modStatusLibrary = require(game.ReplicatedStorage.Library.StatusLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local modRadialImage = require(game.ReplicatedStorage.Library.UI.RadialImage);

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
	
	local function newStatus(lib, srcTable, key)
		local statusId = lib.Id;

		local status = listings[key] or {};
		listings[key] = status;

		local statusClass = srcTable[key];

		if status.Button == nil then
			status.Button = templateStatusItem:Clone();
			status.Button.MouseMoved:Connect(function()
				for k, obj in pairs(listings) do
					obj.Info.Visible = k == key;
				end
			end)
			status.Button.MouseLeave:Connect(function()
				status.Info.Visible = false;
			end)
			status.Button.MouseButton1Click:Connect(function()
				if modBranchConfigs.CurrentBranch.Name == "Dev" then
					Debugger:Warn("Status id:",key,"table:", statusClass);
				end
			end)
			
			status.Button.Parent = menu;
			status.Radial = modRadialImage.new(radialConfig, status.Button:WaitForChild("radialBar"));
			status.Icon = status.Button:WaitForChild("icon");
			status.Info = status.Button:WaitForChild("info");
			status.Title = status.Button:WaitForChild("title");
			status.Quan = status.Button:WaitForChild("quantity");
			
			status.Icon.Image = lib.Icon or `rbxassetid://484211948`;
			status.Title.Text = lib.Name or statusId;
			status.Button.radialBar.ImageColor3 = lib.Buff and Color3.fromRGB(27, 106, 23) or Color3.fromRGB(255, 60, 60);
		end
		
		
		local alpha = 1;
		if type(statusClass) == "table" then
			if statusClass.Icon then
				status.Icon.Image = statusClass.Icon;
			end
			if statusClass.IconColor then
				status.Icon.ImageColor3 = statusClass.IconColor;
			end
			if statusClass.Name then
				status.Title.Text = lib.Name or ``;
			end

			if statusClass.Alpha then
				alpha = statusClass.Alpha;

			elseif statusClass.Duration and statusClass.EndTime then
				alpha = (statusClass.EndTime-smoothTime)/statusClass.Duration;
				
			elseif statusClass.Duration and statusClass.Expires then
				alpha = (statusClass.Expires-smoothTime)/statusClass.Duration;
				
			end
		end
		alpha = math.clamp(alpha, 0, 1);
		
		status.Radial:UpdateLabel(alpha);
		
		local statusVisible = true;--alpha >= 0.001;
		
		if typeof(statusClass) == "table" then
			if statusClass.Visible == false then
				statusVisible = false;
			end
		end
		
		status.Button.Visible = statusVisible;
		
		if lib.QuantityLabel then
			local stat = statusClass[lib.QuantityLabel];
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
		if descStr then
			if type(statusClass) == "table" then
				if statusClass.Duration and statusClass.Expires then
					local timeRatio = (statusClass.Expires-smoothTime)/statusClass.Duration;
					descStr = descStr.. " ("..modSyncTime.ToString(timeRatio * statusClass.Duration)..")";
					
				end
				
				for k, v in pairs(statusClass) do
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
	end
	
	Interface.Garbage:Tag(RunService.Heartbeat:Connect(function()
		local newTime = modSyncTime.GetTime();
		if lastOsTime ~= newTime then
			lastOsTime = newTime;
			lastTick = tick();
		end
		smoothTime = lastOsTime+tick()-lastTick;
		
		if classPlayer.Properties == nil then return end;
		if classPlayer.IsAlive == false then return end;
		
		local destroy = {};
		for id, _ in pairs(listings) do
			destroy[id] = true;
		end
		
		if classPlayer.Properties.HealSources then
			for id, src in pairs(classPlayer.Properties.HealSources) do
				local lib = modStatusLibrary:Find(id);
				if lib == nil then continue end;

				local showStatus = lib.ShowOnHud ~= false or localplayer:GetAttribute("ShowHiddenStatus") == true;
				if showStatus then
					destroy[id] = false;
					newStatus(lib, classPlayer.Properties.HealSources, id);
				end
			end
		end

		for key, src in pairs(classPlayer.Properties) do
			local statusId = key;
			if type(src) == "table" then
				if src.UniqueId then
					statusId = string.gsub(key, src.UniqueId, "");
				end
			end

			local lib = modStatusLibrary:Find(statusId);
			if lib == nil then continue end;

			local showStatus = lib.ShowOnHud ~= false or localplayer:GetAttribute("ShowHiddenStatus") == true;
			if showStatus then
				destroy[key] = false;
				newStatus(lib, classPlayer.Properties, key);
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