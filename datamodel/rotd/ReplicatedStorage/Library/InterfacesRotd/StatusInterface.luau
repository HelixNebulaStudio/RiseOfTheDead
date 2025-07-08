local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modStatusLibrary = shared.require(game.ReplicatedStorage.Library.StatusLibrary);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);

local modRadialImage = shared.require(game.ReplicatedStorage.Library.UI.RadialImage);

local RADIAL_CONFIG = '{"version":1,"size":128,"count":128,"columns":8,"rows":8,"images":["rbxassetid://4467212179","rbxassetid://4467212459"]}';

local interfacePackage = {
    Type = "Character";
};
--==

function interfacePackage.newInstance(interface: InterfaceInstance)
    local frame = script:WaitForChild("StatusBar"):Clone();
	frame.Parent = interface.ScreenGui;

	local window: InterfaceWindow = interface:NewWindow("StatusBar", frame);
	window.IgnoreHideAll = true;
	window.ReleaseMouse = false;
    window.Layers = {"CharacterHud"; "CompactHidden"};
    interface:BindConfigKey("DisableStatusHud", {window});
	
	if modConfigurations.CompactInterface then
        interface.Properties.OnChanged:Connect(function(k, v)
            if k == "IsCompactFullscreen" then
                if v == true then
                    frame.Visible = false;
                else
                    frame.Visible = true;
                end
            end
        end)
    end
	
	local templateStatusItem = script:WaitForChild("statusItem");

	local listings = {};
	local smoothTime, lastTick, lastOsTime = 0, 0, 0;

	local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
	local statusComp: StatusComp = playerClass.StatusComp;
	
	if modConfigurations.CompactInterface then
		frame.Size = UDim2.new(0.5, 0, 0.05, 0);
		frame.AnchorPoint = Vector2.new(0.5, 1);
		window:SetClosePosition(UDim2.new(0.5, 0, 1, 80), UDim2.new(0.5, 0, 1, -80));
	end
	window:Open();
	
	local function newStatus(lib, statusId, statusClass: StatusClassInstance)
		local libId = lib.Id;

		local status = listings[statusId] or {};
		listings[statusId] = status;

		if status.Button == nil then
			status.Button = templateStatusItem:Clone();
			status.Button.MouseMoved:Connect(function()
				for k, obj in pairs(listings) do
					obj.Info.Visible = k == statusId;
				end
			end)
			status.Button.MouseLeave:Connect(function()
				status.Info.Visible = false;
			end)
			status.Button.MouseButton1Click:Connect(function()
				if modBranchConfigs.CurrentBranch.Name == "Dev" then
					Debugger:Warn("Status id:",statusId,"table:", statusClass);
				end
			end)
			
			status.Button.Parent = frame;
			status.Radial = modRadialImage.new(RADIAL_CONFIG, status.Button:WaitForChild("radialBar"));
			status.Icon = status.Button:WaitForChild("icon");
			status.Info = status.Button:WaitForChild("info");
			status.Title = status.Button:WaitForChild("title");
			status.Quan = status.Button:WaitForChild("quantity");
			
			status.Icon.Image = lib.Icon or `rbxassetid://484211948`;
			status.Title.Text = lib.Name or libId;
			status.Button.radialBar.ImageColor3 = lib.Buff and Color3.fromRGB(27, 106, 23) or Color3.fromRGB(255, 60, 60);
		end
		
		
		local alpha = 1;
		local statusValues = statusClass.Values;
		
		if statusValues.Icon then
			status.Icon.Image = statusValues.Icon;
		end
		if statusValues.IconColor then
			status.Icon.ImageColor3 = statusValues.IconColor;
		end
		if statusClass.Name then
			status.Title.Text = lib.Name or ``;
		end

		if statusClass.Alpha then
			alpha = statusClass.Alpha;

		elseif statusClass.Duration and statusClass.Expires then
			alpha = (statusClass.Expires-smoothTime)/statusClass.Duration;
			
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
		
		if typeof(statusClass.Text) == "string" then
			status.Quan.Text = statusClass.Text;

		elseif lib.QuantityLabel then
			local stat = statusClass.Values[lib.QuantityLabel];
			local str = stat;
			local v = tonumber(stat);
			
			if v then
				local statStr = tostring(stat);
				if #statStr >= 7 then
					str = (math.round(v/100000)/10).."M";
				elseif #statStr >= 4 then
					str = (math.round(v/100)/10).."K";
				else
					str = math.round(v);
				end
			end
			status.Quan.Text = str or "";
		end
		
		local descStr = lib.Description;
		if descStr then
			if statusClass.Duration and statusClass.Expires then
				local timeRatio = (statusClass.Expires-smoothTime)/statusClass.Duration;
				descStr = descStr.. " ("..modSyncTime.ToString(timeRatio * statusClass.Duration)..")";
				
			end
			
			for k, v in pairs(statusClass.Values) do
				if typeof(v) ~= "string" and typeof(v) ~= "number" then continue end;
				
				if lib.DescProcess and lib.DescProcess[k] then
					v = lib.DescProcess[k](v);
				end
				descStr = descStr:gsub("$"..k, v);
			end
			
			status.Info.Text = descStr;
		end
	end
	
	interface.Garbage:Tag(RunService.Heartbeat:Connect(function()
		local newTime = workspace:GetServerTimeNow();
		if lastOsTime ~= newTime then
			lastOsTime = newTime;
			lastTick = tick();
		end
		smoothTime = lastOsTime+tick()-lastTick;
		
		local destroy = {};
		for id, _ in pairs(listings) do
			destroy[id] = true;
		end
		
		for statusId, statusClass: StatusClassInstance in pairs(statusComp.List) do
			local lib = modStatusLibrary:Find(statusClass.Id or statusId);
			if lib == nil then continue end;

			local showStatus = lib.ShowOnHud ~= false or localPlayer:GetAttribute("ShowHiddenStatus") == true;
			if showStatus then
				destroy[statusId] = false;
				newStatus(lib, statusId, statusClass);
			end
		end

		for id, shouldDestroy in pairs(destroy) do
			if shouldDestroy and listings[id] then
				if listings[id].Button then listings[id].Button:Destroy() end;
				listings[id] = nil;
			end
		end
	end));
	
	interface.Garbage:Tag(function()
		for id,_ in pairs(listings) do
			if listings[id].Button then listings[id].Button:Destroy() end;
			listings[id] = nil;
		end
	end);

end

return interfacePackage;

