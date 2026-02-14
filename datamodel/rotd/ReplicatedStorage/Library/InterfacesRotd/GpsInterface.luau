local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local localPlayer = game.Players.LocalPlayer;

local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modGpsLibrary = shared.require(game.ReplicatedStorage.Library.GpsLibrary);
local modMarkers = shared.require(game.ReplicatedStorage.Library.Markers);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local interfacePackage = {
    Type = "Character";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));
    local remoteGpsRemote = modRemotesManager:Get("GpsRemote");

    local templateTitle = script:WaitForChild("templateTitle");
    local templateButton = script:WaitForChild("templateButton");

    local gpsFrame = script:WaitForChild("GpsInterface"):Clone();
    gpsFrame.Parent = interface.ScreenGui;

    local listFrame = gpsFrame:WaitForChild("ScrollingFrame");
    local listLayout = listFrame:WaitForChild("UIListLayout");
    local costLabel = gpsFrame:WaitForChild("costLabel");

    if modConfigurations.CompactInterface then
        gpsFrame.AnchorPoint = Vector2.new(0.5, 0.5);
    end

    local markerTarget = nil;
    local activeToolHandler;
    
	local window: InterfaceWindow = interface:NewWindow("GpsWindow", gpsFrame);
	window.CompactFullscreen = true;
    window.CloseWithInteract = true;
	if modConfigurations.CompactInterface then
		window:SetClosePosition(UDim2.new(0.5, 0, -1.5, 0), UDim2.new(0.5, 0, 0.5, 0));
	else
		window:SetClosePosition(UDim2.new(0.5, 0, -1.5, 0), UDim2.new(0.5, 0, 0.1, 0));
	end
	
    local binds = window.Binds;

	local finit = false;
	window.OnToggle:Connect(function(visible, toolHandler)
		if visible then
			interface:HideAll{[window.Name]=true;};
            window:Update(toolHandler);
		end
	end)

    window.OnUpdate:Connect(function(toolHandler)
        if toolHandler then
            activeToolHandler = toolHandler;
        end
        if activeToolHandler == nil then return end;

        local storageItem = activeToolHandler.StorageItem;
        
        if storageItem == nil then
            window:Close();
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
            
            if gpsLib.Locations == nil then
                new.Parent = listFrame;
                continue;
            end

            local isInLocation = false;

            for a=1, #gpsLib.Locations do
                if gpsLib.Locations[a] == localPlayer:GetAttribute("Location") then
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
                    interface:PlayButtonClick();
                    if markerTarget == gpsLib.Id then
                        binds.SetDestinationMarker();
                    else
                        binds.SetDestinationMarker(gpsLib.Id);
                    end
                    window:Close();
                end)
            end
            
            new.MouseButton1Click:Connect(function()
                interface:PlayButtonClick();
                
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
                        modClientGuis.promptWarning("You need to complete mission \"Home Sweet Home\" from Mason before you can travel here.");
                        return;
                    end
                end

                if unlockedGps[gpsLib.Id] == nil and gpsLib.UnlockedByDefault ~= true then

                    for a=1, #gpsLib.Locations do
                        if gpsLib.Locations[a] == localPlayer:GetAttribute("Location") then 
                            isInLocation = true;
                            break;
                        end
                    end
                    
                    if isInLocation then
                        remoteGpsRemote:InvokeServer(storageItem.ID, "unlock", gpsLib.Id);
                        window:Update();
                        
                    else
                        modClientGuis.promptDialogBox{
                            Title=`Unlock GPS Location`;
                            Desc=`You are not close enough to (<b>{gpsLib.Name}</b>) to unlock it.\nDo you want to unlock it with <b><font color='rgb(170, 120, 0)'>100 Gold</font></b> instead?`;
                            Buttons={
                                {
                                    Text="Unlock";
                                    Style="Gold";
                                    HideButtonsOnClick = true;
                                    OnPrimaryClick=function(dialogWindow)
                                        local statusLabel = dialogWindow.Binds.StatusLabel;
                                        statusLabel.Text = "Unlocking GPS location<...>";
                                        
                                        local r = remoteGpsRemote:InvokeServer(storageItem.ID, "unlockGold", gpsLib.Id);
                                        if r == 1 then
                                            statusLabel.Text = "Location unlocked";

                                        elseif r == 2 then
                                            statusLabel.Text= "Already purchased";

                                        elseif r == 3 then
                                            statusLabel.Text = "Not enough Gold";

                                            task.wait(1);
                                            dialogWindow:Close();
                                            interface:ToggleWindow("GoldMenu", true, "GoldPage");
                                            return;
                                        end
                                        task.wait(2);
                                        dialogWindow:Close();
                                        window:Update();
                                    end;
                                };
                                {
                                    Text="Cancel";
                                    Style="Cancel";
                                };
                            }
                        };

                    end
                    
                else
                    local lastFastTravel = modData.GameSave and modData.GameSave.LastFastTravel;
                    local cost = modGpsLibrary:GetTravelCost(lastFastTravel, modData.Profile);
                    
                    if gpsLib.FreeTravel then
                        cost = 0;
                    end
                    
                    modClientGuis.promptDialogBox{
                        Title = `Travel`;
                        Desc = `Are you sure you want to fast travel to <b>{gpsLib.Name}</b> for <b>${cost}</b>?`;
                        Icon = gpsLib.Image;
                        Buttons = {
                            {
                                Text="Travel";
                                Style="Money";
                                HideButtonsOnClick = true;
                                OnPrimaryClick=function(dialogWindow)
                                    local statusLabel = dialogWindow.Binds.StatusLabel;
                                    statusLabel.Text = "Travelling<...>";

                                    local r = remoteGpsRemote:InvokeServer(storageItem.ID, "travel", gpsLib.Id);
                                    if r == 0 then
                                        interface:ToggleGameBlinds(false, 3);
                                        window:Close();
                                        
                                    elseif r == 1 then
                                        statusLabel.Text = "Not enough money!";
                                        task.wait(2);
                                        dialogWindow:Close();

                                    elseif r == 2 then
                                        interface:ToggleGameBlinds(false, 1);
                                        wait(0.5);
                                        interface:ToggleGameBlinds(true, 1);
                                    end

                                end;
                            };
                            {
                                Text="Cancel";
                                Style="Cancel";
                            };
                        }
                    };
                end
            end)
                
            new.Parent = listFrame;
        end
        wait(1/60);
        listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y+10);
    end)

    gpsFrame:WaitForChild("TitleFrame"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
        window:Close();
    end)


    function binds.SetDestinationMarker(gpsId)
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
                                remoteGpsRemote:InvokeServer(activeToolHandler and activeToolHandler.StorageItem.ID, "setmarker", gpsId);
                                return;
                            end
                        end
                    end
                end)
                
                if gpsLib.WorldName == modBranchConfigurations.WorldName then
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


    interface.Scheduler.OnStepped:Connect(function(tickData)
        if tickData.ms1000 ~= true then return end;
        if not window.Visible then return end;

        local lastFastTravel = modData.GameSave and modData.GameSave.LastFastTravel;
        local cost = lastFastTravel and modGpsLibrary:GetTravelCost(lastFastTravel, modData.Profile);
        local timeLapse = lastFastTravel and 300-math.clamp(modSyncTime.GetTime()-lastFastTravel, 0, 300)
        if cost then
            costLabel.Text = "<b>Travel Cost: </b>$"..cost..(
                (timeLapse and timeLapse > 0 and " ("..modSyncTime.ToString(timeLapse)..")") or ""
            );
        else
            costLabel.Text = "loading";
        end
    end)

end

return interfacePackage;

