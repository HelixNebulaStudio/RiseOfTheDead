local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modMarkers = require(game.ReplicatedStorage.Library.Markers);

local remoteGameModeHud = modRemotesManager:Get("GameModeHud");
local hudFrameTemplate = script:WaitForChild("GameModeHud");

local modeHudClass = script:WaitForChild("ModeHudClass");
local hudModules = {};

for _, modeModule in pairs(modeHudClass:GetChildren()) do
	hudModules[modeModule.Name] = require(modeModule);
end
--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);
	
	local hudData = {};
	local gameHudObjects = {};
	
	local windowFrame = hudFrameTemplate:Clone();
	windowFrame.Parent = modInterface.MainInterface;

	local window = Interface.NewWindow("GameModeHud", windowFrame);
	window.IgnoreHideAll = true;
	window.ReleaseMouse = false;
	window:SetOpenClosePosition(UDim2.new(0, 0, 0, 0), UDim2.new(0, 0, -1.1, 0));
	
	Interface.Garbage:Tag(remoteGameModeHud.OnClientEvent:Connect(function(data)
		for k, _ in pairs(data) do
			hudData[k] = data[k];
		end

		local action = data.Action;
		if action == "Open" then
			window:Open();
			Interface.Update();

		elseif action == "Close" then
			window:Close();
			
			for k, hudObject in pairs(gameHudObjects) do
				hudObject:SetActive(false);
			end
			modMarkers.ClearMarker("GameModeWaypoint");

		elseif action == "SetMarker" then
			if data.ClearMarker == true then
				modMarkers.ClearMarker("GameModeWaypoint");

			elseif data.Marker then
				modMarkers.SetMarker("GameModeWaypoint", data.Marker.Target, data.Marker.Label or "", data.Marker.MarkType);
				modMarkers.SetColor("GameModeWaypoint", Color3.fromRGB(255, 255, 255));
			end

		end
		
		Interface.UpdateGameHud();
	end))
	
	Interface.Garbage:Tag(modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
		Interface.UpdateGameHud();
	end))
	Interface.Garbage:Tag(function()
		for k, hudObject in pairs(gameHudObjects) do
			hudObject:SetActive(false);
		end
	end)
	
	function Interface.Update()
		if not windowFrame.Visible then return end;
		
		local activeMode = hudData.Type;
		
		for _, frame in pairs(windowFrame:GetChildren()) do
			if frame.Name ~= activeMode then

				local currentHudObject = gameHudObjects[activeMode];
				if currentHudObject then
					currentHudObject:SetActive(false);
				end
				frame.Visible = false;
				
				continue;
			end
			
			
			frame.Visible = true;

			local currentHudObject = gameHudObjects[activeMode];
			if currentHudObject == nil and hudModules[activeMode] then
				gameHudObjects[activeMode] = hudModules[activeMode](Interface, frame); -- new modeHud Object;
			end
			currentHudObject = gameHudObjects[activeMode];

			if currentHudObject then
				currentHudObject:SetActive(true);
				currentHudObject:Update(hudData);
			end
		end
	end
	
	function Interface.UpdateGameHud()
		local activeMode = hudData.Type;
		local currentHudObject = gameHudObjects[activeMode];
		if currentHudObject == nil then return end;

		if not currentHudObject.Active then return end;
		currentHudObject:Update(hudData);
	end
	
	return Interface;
end;

return Interface;