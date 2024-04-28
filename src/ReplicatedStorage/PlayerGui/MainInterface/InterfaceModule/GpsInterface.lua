local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local localplayer = game.Players.LocalPlayer;
local modData = require(localplayer:WaitForChild("DataModule"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modGpsLibrary = require(game.ReplicatedStorage.Library.GpsLibrary);
local modMarkers = require(game.ReplicatedStorage.Library.Markers);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);


local remoteGpsRemote = modRemotesManager:Get("GpsRemote");
	
local gpsFrame = script.Parent.Parent:WaitForChild("GpsInterface");
local listFrame = gpsFrame:WaitForChild("ScrollingFrame");
local listLayout = listFrame:WaitForChild("UIListLayout");
local costLabel = gpsFrame:WaitForChild("costLabel");

local templateTitle = script:WaitForChild("templateTitle");
local templateButton = script:WaitForChild("templateButton");

local markerTarget = nil;
local toolHandler;
--== Script;
if modConfigurations.CompactInterface then
	gpsFrame.AnchorPoint = Vector2.new(0.5, 0.5);
end

gpsFrame:WaitForChild("TitleFrame"):WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
	Interface:CloseWindow("GpsWindow");
end)

function Interface.init(modInterface)
	setmetatable(Interface, modInterface);

	local window = Interface.NewWindow("GpsWindow", gpsFrame);
	window.CompactFullscreen = true;
	if modConfigurations.CompactInterface then
		window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1.5, 0));
	else
		window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.1, 0), UDim2.new(0.5, 0, -1.5, 0));
	end
	window:AddCloseButton(gpsFrame);
	
	local finit = false;
	window.OnWindowToggle:Connect(function(visible, toolHandler)
		if visible then
			Interface:HideAll{[window.Name]=true;};
			Interface.Update(toolHandler);
		end
	end)
	
	return Interface;
end;


function Interface.SetDestinationMarker(gpsId)
	if gpsId == nil then
		modMarkers.ClearMarker("GpsMarker");
		markerTarget = nil;
	else
		local gpsLib = modGpsLibrary:Find(gpsId);
		markerTarget = gpsId;
		
		if gpsLib then
			task.spawn(function()
				if modData.GameSave and modData.GameSave.Missions then
					local missionsList = modData.GameSave.Missions;
					for a=1, #missionsList do
						local missionData = missionsList[a];
						if missionData.Id == 49 and missionData.Type == 1 and missionData.ProgressionPoint == 2 then
							remoteGpsRemote:InvokeServer(toolHandler and toolHandler.StorageItem.ID, "setmarker", gpsId);
							return;
						end
					end
				end
			end)
			
			if gpsLib.WorldName == modBranchConfigs.WorldName then
				modMarkers.SetMarker("GpsMarker", gpsLib.Position, "GPS", modMarkers.MarkerTypes.Waypoint);
				
			else
				modMarkers.SetMarker("GpsMarker", gpsLib.WorldName, "GPS", modMarkers.MarkerTypes.Travel);
				
			end
			modMarkers.SetColor("GpsMarker", Color3.fromRGB(100, 200, 200));
			local iconLabel = modMarkers.GetIconInstance("GpsMarker");
			iconLabel.Size = UDim2.new(0.3, 0, 0.3, 0);
			iconLabel:TweenSize(UDim2.new(0.04, 0, 0.04, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.6, true);
		end
	end
end

function Interface.Update(toolH)
	toolHandler = toolH;
	local storageItem = toolHandler.StorageItem;

	toolHandler.StorageItem = modData.GetItemById(storageItem.ID);
	storageItem = toolHandler.StorageItem;
	
	if storageItem == nil then
		Interface:CloseWindow("GpsWindow");
		return;
	end;

	modData:RequestData("GameSave/LastFastTravel");
	local unlockedGps = storageItem.Values.Gps or {};

	for _, obj in pairs(listFrame:GetChildren()) do
		if obj:IsA("GuiObject") then
			obj:Destroy();
		end
	end

	local libList = modGpsLibrary:GetIndexList();
	for a=1, modGpsLibrary.Size do
		local gpsLib = libList[a];

		local new = gpsLib.Locations and templateButton:Clone() or templateTitle:Clone();
		
		local label = new:WaitForChild("buttonText");
		label.Text = gpsLib.Name;
		new.Name = gpsLib.Id;
		
		if gpsLib.Locations then
			local isInLocation = false;

			for a=1, #gpsLib.Locations do
				if gpsLib.Locations[a] == localplayer:GetAttribute("Location") then
					isInLocation = true;
					break;
				end
			end
			
			local lockText = "";
			
			if unlockedGps[gpsLib.Id] == nil and gpsLib.UnlockedByDefault ~= true then
				if isInLocation then
					lockText = "<b><font color='rgb(86, 135, 75)'>[Click To Unlock]</font></b> ";
				else
					lockText = "<b><font color='rgb(255,102,102)'>[Locked]</font></b> ";
				end
			end
			label.Text = lockText..label.Text;
			
			local thumbnail = new:WaitForChild("thumbnail");
			thumbnail.Image = gpsLib.Image;

			local guideButton = new:WaitForChild("guideButton");
			
			if gpsLib.Position == nil then
				guideButton.Visible = false;
			else
				guideButton.MouseButton1Click:Connect(function()
					Interface:PlayButtonClick();
					if markerTarget == gpsLib.Id then
						Interface.SetDestinationMarker();
					else
						Interface.SetDestinationMarker(gpsLib.Id);
					end
					Interface:CloseWindow("GpsWindow");
				end)
			end
			
			new.MouseButton1Click:Connect(function()
				Interface:PlayButtonClick();
				
				if gpsLib.Id == "pwsafehome" then
					local missionCompleted = false;
					if modData.GameSave and modData.GameSave.Missions then
						local missionsList = modData.GameSave.Missions;
						for a=1, #missionsList do
							local missionData = missionsList[a];
							if missionData.Id == 54 and (missionData.Type == 1 or missionData.Type == 3) then
								missionCompleted = true;
								break;
							end
						end
					end
					
					if not missionCompleted then
						Interface:PromptWarning("You need to complete mission \"Home Sweet Home\" from Mason before you can travel here.");
						return;
					end
				end
				if unlockedGps[gpsLib.Id] == nil and gpsLib.UnlockedByDefault ~= true then

					for a=1, #gpsLib.Locations do
						if gpsLib.Locations[a] == localplayer:GetAttribute("Location") then 
							isInLocation = true;
							break;
						end
					end
					
					if isInLocation then
						remoteGpsRemote:InvokeServer(storageItem.ID, "unlock", gpsLib.Id);
						Interface.Update(toolHandler);
						
					else
						local promptWindow = Interface:PromptQuestion("Unlock GPS Location", 
							"You are not close enough to (<b>"..gpsLib.Name.."</b>) to unlock it. Do you want to unlock it with <b><font color='rgb(170, 120, 0)'>100 Gold</font></b> instead?");
						local YesClickedSignal, NoClickedSignal;

						YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
							if debounce then return end;
							debounce = true;
							Interface:PlayButtonClick();
							local r = remoteGpsRemote:InvokeServer(storageItem.ID, "unlockGold", gpsLib.Id);
							if r == 1 then
								promptWindow.Frame.Yes.buttonText.Text = "Location unlocked";

							elseif r == 2 then
								promptWindow.Frame.Yes.buttonText.Text = "Already purchased";

							elseif r == 3 then
								promptWindow.Frame.Yes.buttonText.Text = "Not enough Gold";
			
								wait(1);
								promptWindow:Close();
								Interface:OpenWindow("GoldMenu", "GoldPage");
								return;

							end
							wait(1.6);
							debounce = false;
							promptWindow:Close();
							Interface:OpenWindow("GpsWindow", toolHandler);
							YesClickedSignal:Disconnect();
							NoClickedSignal:Disconnect();
						end);
						NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
							if debounce then return end;
							Interface:PlayButtonClick();
							promptWindow:Close();
							Interface:OpenWindow("GpsWindow", toolHandler);
							YesClickedSignal:Disconnect();
							NoClickedSignal:Disconnect();
						end);
						
					end
					
				else
					local lastFastTravel = modData.GameSave and modData.GameSave.LastFastTravel;
					local cost = modGpsLibrary:GetTravelCost(lastFastTravel, modData.Profile);
					
					if gpsLib.FreeTravel then
						cost = 0;
					end
					
					local promptWindow = Interface:PromptQuestion("Travel", 
						"Are you sure you want to fast travel to <b>"..gpsLib.Name.."</b> for <b>$"..cost.."</b>?", 
						"Travel", "Cancel", gpsLib.Image);
					local YesClickedSignal, NoClickedSignal;

					YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
						if debounce then return end;
						debounce = true;
						Interface:PlayButtonClick();
						promptWindow.Frame.Yes.buttonText.Text = "Travelling...";
						local r = remoteGpsRemote:InvokeServer(storageItem.ID, "travel", gpsLib.Id);
						if r == 0 then
							Interface:ToggleGameBlinds(false, 3);
							
						elseif r == 1 then
							promptWindow.Frame.Yes.buttonText.Text = "Not enough money!";

						elseif r == 2 then
							Interface:ToggleGameBlinds(false, 1);
							wait(0.5);
							Interface:ToggleGameBlinds(true, 1);
							
						end
						wait(1.6);
						debounce = false;
						promptWindow:Close();
						YesClickedSignal:Disconnect();
						NoClickedSignal:Disconnect();
					end);
					NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
						if debounce then return end;
						Interface:PlayButtonClick();
						promptWindow:Close();
						Interface:OpenWindow("GpsWindow", toolHandler);
						YesClickedSignal:Disconnect();
						NoClickedSignal:Disconnect();
					end);
				end
			end)
		end
		new.Parent = listFrame;
	end
	wait(1/60);
	listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y+10);
end

local updateClock = modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
	if not gpsFrame.Visible then return end;
	local lastFastTravel = modData.GameSave and modData.GameSave.LastFastTravel;
	local cost = lastFastTravel and modGpsLibrary:GetTravelCost(lastFastTravel, modData.Profile);
	local timeLapse = lastFastTravel and 300-math.clamp(modSyncTime.GetTime()-lastFastTravel, 0, 300)
	if cost then
		costLabel.Text = "<b>Travel Cost: </b>$"..cost..((timeLapse and timeLapse > 0 and " ("..modSyncTime.ToString(timeLapse)..")") or "");
	else
		costLabel.Text = "loading";
	end
end)

function Interface.disconnect()
	if updateClock then
		updateClock:Disconnect();
	end
end

script.AncestryChanged:Connect(function(c, p)
	if c == script and p == nil and Interface.disconnect then
		Interface.disconnect();
	end
end)
return Interface;