local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");

local camera = workspace.CurrentCamera;
local localPlayer = game.Players.LocalPlayer;

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modGameModeLibrary = shared.require(game.ReplicatedStorage.Library.GameModeLibrary);
local modDropRateCalculator = shared.require(game.ReplicatedStorage.Library.DropRateCalculator);
local modLeaderboardService = shared.require(game.ReplicatedStorage.Library.LeaderboardService);
local modCameraGraphics = shared.require(game.ReplicatedStorage.PlayerScripts.CameraGraphics);

local modLeaderboardInterface = shared.require(game.ReplicatedStorage.Library.UI.LeaderboardInterface);
local modGuiTween = shared.require(game.ReplicatedStorage.Library.UI.GuiObjectTween);
local modGuiObjectPlus = shared.require(game.ReplicatedStorage.Library.UI.GuiObjectPlus);
local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);


local UNREADY_COLOR = Color3.fromRGB(101, 101, 102);
local DEFAULT_COLOR = Color3.fromRGB(255, 255, 255);
local REQUESTS_ENUM = modGameModeLibrary.RequestEnums;

local interfacePackage = {
    Type = "Character";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

    local readyPartPrefab = script:WaitForChild("readyPart");
    local verticalListTemplate = script:WaitForChild("VerticalList");
    local templateUIRatio = script:WaitForChild("UIAspectRatioConstraint");
    local templateLine = script:WaitForChild("line");
    local templateUnlockHardmode = script:WaitForChild("UnlockHardmode");

    local remoteGameModeRequest = modRemotesManager:Get("GameModeRequest");
	local remoteGameModeUpdate = modRemotesManager:Get("GameModeUpdate");

    local gameRoomFrame = script:WaitForChild("GameRoom"):Clone();
    gameRoomFrame.Parent = interface.ScreenGui;

    --Menu Screen
    local joinButton = gameRoomFrame:WaitForChild("JoinButton");
    local exitMenuButton = gameRoomFrame:WaitForChild("ExitMenu");
    local createRoomButton = gameRoomFrame:WaitForChild("CreateRoom");
    local createFrame = gameRoomFrame:WaitForChild("CreateFrame");

    local titleImageLabel = gameRoomFrame:WaitForChild("TitleImage");
    local gameModeLabel = gameRoomFrame:WaitForChild("GameMode");
    local descLabel = gameRoomFrame:WaitForChild("Description");
    local extremeLabel = gameRoomFrame:WaitForChild("ExtremeLabel");
    local rewardsHintLabel = gameRoomFrame:WaitForChild("RewardsHint");
    local hardTitleImageLabel = gameRoomFrame:WaitForChild("HardTitle");
    local rewardsList = gameRoomFrame:WaitForChild("RewardsFrame");
    local rewardsButton = gameRoomFrame:WaitForChild("RewardsButton");
    local leaderboardButton = gameRoomFrame:WaitForChild("LeaderboardButton");

    --Room Screen
    local leaveButton = gameRoomFrame:WaitForChild("LeaveButton");
    local readyButton = gameRoomFrame:WaitForChild("ReadyButton");
    local unreadyButton = gameRoomFrame:WaitForChild("UnreadyButton");

    local prevRoomButton = gameRoomFrame:WaitForChild("PreviousRoom");
    local nextRoomButton = gameRoomFrame:WaitForChild("NextRoom");

    local timerLabel = gameRoomFrame:WaitForChild("TimerLabel");
    local lobbyInfoLabel = gameRoomFrame:WaitForChild("LobbyInfo");
    local specialDataLabel = gameRoomFrame:WaitForChild("SpecialData");
    local hostIcon = gameRoomFrame:WaitForChild("HostIcon");

    local itemToolTip = modItemInterface.newItemTooltip();

    local window: InterfaceWindow = interface:NewWindow("GameRoom", gameRoomFrame)
    window.UseTween = false;
    window.IgnoreHideAll = true;
    window.Layers = {"GameRoom"};
    window.BoolStringWhenActive = {String="!CharacterHud"; Priority=5;};

	local gameLib, stageLib;
    local rewardsId;
    local activeLeaderboard;

    local binds = window.Binds;
    binds.ActiveLobbyData = nil;
    binds.MenuState = "Menu";

    binds.LobbyCameraPoint = nil;
    binds.ViewingRoomId = nil;
    binds.PlayerRoomId = nil;

    binds.ItemButtonList = {};

    --Ready Indicators
    local readyIndicators = {};

    local function clearIndicators()
        for a=#readyIndicators, 1, -1 do
            readyIndicators[a].Destroyed = true;
            game.Debris:AddItem(readyIndicators[a].Object, 0);
            table.remove(readyIndicators, a);
        end
    end
    interface.Garbage:Tag(clearIndicators);

    local function getIndicator(name)
        for a=1, #readyIndicators do
            if readyIndicators[a].Destroyed then continue end;
            if readyIndicators[a].Name ~= name then continue end;
            return readyIndicators[a];
        end
        return;
    end

    local function removeIndicator(name)
        for a=#readyIndicators, 1, -1 do
            if readyIndicators[a].Name ~= name then continue end;
            readyIndicators[a].Destroyed = true;
            
            game.Debris:AddItem(readyIndicators[a].Object, 0)
            table.remove(readyIndicators, a);
        end
    end

    local function newIndicator(name)
        local indicator = {
            Name=name;
            Object=readyPartPrefab:Clone();
        };
        table.insert(readyIndicators, indicator);
        return indicator;
    end
    --

    local createPublicLobbyButton, createSquadLobbyButton, createHardLobbyButton;
    local newLobbyAsPublic = false;
    local hardModeCreate = false;

    local debounceTick = tick();
    local debounceDuration = 0.5;
    exitMenuButton.MouseButton1Click:Connect(function()
        if tick()-debounceTick < debounceDuration then return end;
        debounceTick = tick();
        
        interface:ToggleGameBlinds(false, 0.5);
        task.wait(0.5);
        remoteGameModeRequest:InvokeServer(REQUESTS_ENUM.CloseInterface);
        window:Close();
    end)

    joinButton.MouseButton1Click:Connect(function()
        if tick()-debounceTick < debounceDuration then return end;
        debounceTick = tick();
        if binds.ViewingRoomId == nil then return end;
        
        local lobbyData = remoteGameModeRequest:InvokeServer(REQUESTS_ENUM.JoinRoom, binds.ViewingRoomId);
        if lobbyData then
            binds.ActiveLobbyData = lobbyData;
            window:Update();
        end
    end)

    leaveButton.MouseButton1Click:Connect(function()
        if tick()-debounceTick < debounceDuration then return end;
        debounceTick = tick();
        if binds.PlayerRoomId == nil then return end;
    
        removeIndicator(localPlayer.Name);
        
        local lobbyData = remoteGameModeRequest:InvokeServer(REQUESTS_ENUM.LeaveRoom);
        if lobbyData then
            binds.ActiveLobbyData = lobbyData;
            window:Update();
        end
    end)

    local function createRoomOnClick(skipJoiningRoom)
        if not createFrame.Visible and UserInputService.TouchEnabled then
            createFrame.Visible = true;
        else
            if tick()-debounceTick < debounceDuration then return end;
            debounceTick = tick();

            local createParams = {
                IsPublic = newLobbyAsPublic; 
                IsHard = hardModeCreate;
                SkipJoinRoom = skipJoiningRoom;
            };
            Debugger:StudioWarn(`Create lobby`, createParams);
            local lobbyData = remoteGameModeRequest:InvokeServer(
                REQUESTS_ENUM.CreateRoom,
                createParams
            );

			if lobbyData then
                binds.ActiveLobbyData = lobbyData;
                
                local playerRoom = binds.GetPlayerRoom(localPlayer.Name);
                binds.PlayerRoomId = playerRoom and playerRoom.Id or nil;
                binds.ViewingRoomId = binds.PlayerRoomId;

                window:Update();
            end
        end
    end

    createRoomButton.MouseButton1Click:Connect(createRoomOnClick)
    if RunService:IsStudio() then
        createRoomButton.MouseButton2Click:Connect(function()
            createRoomOnClick(true);
        end)
    end

    if not UserInputService.TouchEnabled then
        createRoomButton.MouseMoved:Connect(function()
            if stageLib == nil then return end;

            createRoomButton.ImageColor3 = interface.Colors.Branch;
            createFrame.Visible = stageLib.SingleArena ~= true;
        end)
    end

    readyButton.MouseButton1Click:Connect(function()
        if tick()-debounceTick < debounceDuration then return end;
        debounceTick = tick();
        if binds.PlayerRoomId == nil then return end;
    
        local lobbyData = remoteGameModeRequest:InvokeServer(REQUESTS_ENUM.Ready);
        if lobbyData then
            binds.ActiveLobbyData = lobbyData;
            window:Update();
        end
    end)

    unreadyButton.MouseButton1Click:Connect(function()
        if tick()-debounceTick < debounceDuration then return end;
        debounceTick = tick();
        if binds.PlayerRoomId == nil then return end;

        local lobbyData = remoteGameModeRequest:InvokeServer(REQUESTS_ENUM.Unready);
        if lobbyData then
            binds.ActiveLobbyData = lobbyData;
            window:Update();
        end
    end)
        
    rewardsButton.MouseButton1Click:Connect(function()
        rewardsList.Visible = not rewardsList.Visible;
    end)

    leaderboardButton.MouseButton1Click:Connect(function()
        if activeLeaderboard then
		    activeLeaderboard.Frame.Visible = not activeLeaderboard.Frame.Visible;
        end
    end)

    prevRoomButton.MouseButton1Click:Connect(function()
        if binds.ActiveLobbyData == nil then return end;
        binds.ChangeRoom(false);
    end);
    nextRoomButton.MouseButton1Click:Connect(function()
        if binds.ActiveLobbyData == nil then return end;
        binds.ChangeRoom(true);
    end);

    if not UserInputService.TouchEnabled then
        createFrame.MouseLeave:Connect(function()
            createFrame.Visible = false;
        end)
    end
    for _, button in pairs(createFrame:GetDescendants()) do
        if button.Name == "CreateFrame" then
            if not UserInputService.TouchEnabled then
                button.MouseLeave:Connect(function()
                    createFrame.Visible = false;
                end)
            end
        elseif button.Name == "CreatePublicLobby" then
            button.MouseButton1Click:Connect(function()
                newLobbyAsPublic = true;
                if createPublicLobbyButton then createPublicLobbyButton.BackgroundTransparency = 0.3; end
                if createSquadLobbyButton then createSquadLobbyButton.BackgroundTransparency = 0.8; end
            end)
            if button.Parent.Name == "CreateFrame" then
                createPublicLobbyButton = button;
            end
            
        elseif button.Name == "CreateSquadLobby" then
            button.MouseButton1Click:Connect(function()
                newLobbyAsPublic = false;
                if createPublicLobbyButton then createPublicLobbyButton.BackgroundTransparency = 0.8; end
                if createSquadLobbyButton then createSquadLobbyButton.BackgroundTransparency = 0.3; end
            end)
            if button.Parent.Name == "CreateFrame" then
                createSquadLobbyButton = button;
            end
            
        elseif button.Name == "HardMode" then
            button.MouseButton1Click:Connect(function()
                hardModeCreate = not hardModeCreate;
                if createHardLobbyButton then createHardLobbyButton.BackgroundTransparency = hardModeCreate and 0.3 or 0.8; end;
                window:Update();
            end)
            if button.Parent.Name == "CreateFrame" then
                createHardLobbyButton = button;
            end
        end
    end

    local imgButtons = {
        joinButton;
        exitMenuButton;
        createRoomButton;
        leaveButton;
        readyButton;
        unreadyButton;
        prevRoomButton;
        nextRoomButton;
        rewardsButton;
        leaderboardButton;
    };

    for _, button in pairs(imgButtons) do
        interface:ConnectImageButton(button);
    end


    --MARK: OnToggle
    window.OnToggle:Connect(function(visible, lobbyData)
        if lobbyData then
            binds.ActiveLobbyData = lobbyData;
        end
        if visible then
            interface:HideAll{[window.Name]=true;};

            local joinSuccessOrReason = remoteGameModeRequest:InvokeServer(
                REQUESTS_ENUM.OpenInterface, 
                binds.ActiveLobbyData.Type, 
                binds.ActiveLobbyData.Stage
            );
            if joinSuccessOrReason ~= true then
                Debugger:Warn("Failed to join game room. Reason:", joinSuccessOrReason);
                window:Close();
                return;
            end

            window:Update();
            gameRoomFrame.Visible = true;
	        
            modCameraGraphics:Bind("lobbycamera", {
                RenderStepped=function(camera)
                    binds.Blinds = true;
                    if binds.LobbyCameraPoint == nil then return end;

                    local cf = CFrame.new(binds.LobbyCameraPoint.WorldPosition) 
                            * (binds.LobbyCameraPoint.CFrame - binds.LobbyCameraPoint.CFrame.p);
                    camera.CFrame = CFrame.new(cf.Position, (cf * CFrame.new(1, 0, 0)).Position);
                    camera.Focus = cf;
                    binds.Blinds = false;
                end;
            }, 2);
            
        else
            gameLib, stageLib, rewardsId = nil, nil, nil;

            if activeLeaderboard then
                activeLeaderboard.Frame:Destroy();
                activeLeaderboard = nil;
            end

            gameRoomFrame.Visible = false;
	        modCameraGraphics:Unbind("lobbycamera");
            binds.ViewingRoomId = nil;
            binds.PlayerRoomId = nil;
            interface:ToggleGameBlinds(true, 0.5);

        end
    end)

    interface.Garbage:Tag(function()
        modCameraGraphics:Unbind("lobbycamera");
    end)

    function binds.GetRoom(id)
        if binds.ActiveLobbyData == nil then return end;

        local lobbies = binds.ActiveLobbyData.Lobbies;
        for a=#lobbies, 1, -1 do
            if id and lobbies[a].Id ~= id then continue end;
            
            return lobbies[a], a;
        end

        return lobbies[#lobbies], #lobbies;
    end
    
    function binds.GetPlayerRoom(name)
        if binds.ActiveLobbyData == nil then return end;

        local lobbies = binds.ActiveLobbyData.Lobbies;
        for a=#lobbies, 1, -1 do
            for b=1, #lobbies[a].Players do
                if lobbies[a].Players[b].Name ~= name then continue end;
                return lobbies[a], lobbies[a].Players[b];
            end
        end
        return;
    end

    function binds.ChangeRoom(increase)
        if binds.ActiveLobbyData == nil then return end;

        local change = increase and 1 or -1;
        
        local _room, roomIndex = binds.GetRoom(binds.ViewingRoomId);
        
        if roomIndex+change <= #binds.ActiveLobbyData.Lobbies and roomIndex+change >= 1 then
            binds.ViewingRoomId = binds.ActiveLobbyData.Lobbies[roomIndex+change].Id;
            window:Update();
        end
    end

    
    if RunService:IsStudio() then
        UserInputService.InputBegan:Connect(function(inputObject, gameProcessed)
            if gameProcessed then return end;
            if inputObject.UserInputState ~= Enum.UserInputType.MouseButton3 then return end;
            if inputObject.UserInputState ~= Enum.UserInputState.Begin then return end;

            Debugger:StudioLog(`ActiveLobbyData`, binds.ActiveLobbyData);
            Debugger:Warn(`ViewingRoomId=`, binds.ViewingRoomId, "PlayerRoomId=", binds.PlayerRoomId);

            local viewingRoom = binds.GetRoom(binds.PlayerRoomId or binds.ViewingRoomId);
            Debugger:Log(`viewingRoom`, viewingRoom);
        end)
    end

    local linesList = {};
    local unlockHardModeButton = nil;
    --MARK: OnUpdate
    window.OnUpdate:Connect(function()
        if binds.ActiveLobbyData == nil then return end;

        local gameMode, gameStage = binds.ActiveLobbyData.Type, binds.ActiveLobbyData.Stage;
        gameLib = modGameModeLibrary.GetGameMode(gameMode);
        stageLib = modGameModeLibrary.GetStage(gameMode, gameStage);
        
        local playerRoom, playerData = binds.GetPlayerRoom(localPlayer.Name);
        binds.PlayerRoomId = playerRoom and playerRoom.Id or nil;

        local viewingRoom, viewIndex = binds.GetRoom(binds.PlayerRoomId or binds.ViewingRoomId);
        if viewingRoom == nil then return end;
        binds.ViewingRoomId = viewingRoom.Id;
        
        if viewingRoom and viewingRoom.LobbyPrefab and viewingRoom.LobbyPrefab.PrimaryPart then
            binds.LobbyCameraPoint = viewingRoom.LobbyPrefab.PrimaryPart:FindFirstChild("CameraPoint");
        end


        if binds.PlayerRoomId then
            binds.MenuState = "Room";
        else
            binds.MenuState = "Menu";
        end

        if binds.MenuState == "Menu" then
            joinButton.Visible = true;
            exitMenuButton.Visible = true;
            createRoomButton.Visible = true;

            leaveButton.Visible = false;
            readyButton.Visible = false;
            unreadyButton.Visible = false;
            prevRoomButton.Visible = false;
            nextRoomButton.Visible = false;

            local lobbyCount = #binds.ActiveLobbyData.Lobbies;
            if lobbyCount > 1 then
                prevRoomButton.Visible = viewIndex > 1;
                nextRoomButton.Visible = viewIndex < lobbyCount;
            end

        elseif binds.MenuState == "Room" then
            joinButton.Visible = false;
            exitMenuButton.Visible = false;
            createRoomButton.Visible = false;
            
            leaveButton.Visible = true;

            if stageLib.SingleArena ~= true then
                readyButton.Visible = not playerData.Ready;
                unreadyButton.Visible = playerData.Ready;
            else
                readyButton.Visible = false;
                unreadyButton.Visible = false;
            end

            prevRoomButton.Visible = false;
            nextRoomButton.Visible = false;

            createFrame.Visible = false;
        end
       
        gameModeLabel.Text = gameMode or "";
        descLabel.Text = stageLib.Description or "";
        extremeLabel.Visible = stageLib.IsExtreme or false;
        rewardsHintLabel.Text = "";
        
        if createHardLobbyButton then
            createHardLobbyButton.Visible = stageLib.HardModeEnabled == true;
            createHardLobbyButton.HardMode.Text = gameLib.HardModeText or "Hard Mode";
            
            hardTitleImageLabel.Image = gameLib.HardModeTitleImage or "http://www.roblox.com/asset/?id=5006434147";
        end

        if stageLib.TitleImage then
            titleImageLabel.Image = stageLib.TitleImage;
            titleImageLabel.ImageColor3 = Color3.fromRGB(255,255,255);
        end	
        hardTitleImageLabel.Visible = viewingRoom.IsHard == true;
	    titleImageLabel.ImageColor3 = viewingRoom.IsHard == true and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255);

        --MARK: Rewards render
        
        local itemButtonCaches = {};

        for _, obj in pairs(rewardsList:GetChildren()) do
            if obj:IsA("GuiObject") then
                obj.Visible = false;
            end
        end
        if stageLib.CrateId == nil then
            local crateList = stageLib.RewardsIds or {stageLib.RewardsId};
            
            local newVertList = rewardsList:FindFirstChild("crateList") or verticalListTemplate:Clone();
            newVertList.Visible = true;
            newVertList.Name = "crateList";
            newVertList.LayoutOrder = 99;
            
            local crateOrder = 9;
            local function newCrateItemButton(crateItemId, param)
                param = param or {};

                local itemButtonObject = binds.ItemButtonList[crateItemId] or modItemInterface.newItemButton(crateItemId);
                local newItemButton = itemButtonObject.ImageButton;
                if binds.ItemButtonList[crateItemId] == nil then
                    itemToolTip:BindHoverOver(newItemButton, function()
                        itemToolTip.Frame.Parent = script.Parent;
                        itemToolTip:Update(crateItemId);
                        itemToolTip:SetPosition(newItemButton);
                    end);
                    
                    newItemButton.MouseButton1Click:Connect(function()
                        rewardsId = crateItemId;
                        window:Update();
                    end)
                    
                    templateUIRatio:Clone().Parent = newItemButton;

                    if param.Hard then
                        local uiStroke = Instance.new("UIStroke");
                        uiStroke.Color = Color3.fromRGB(255, 60, 60);
                        uiStroke.Thickness = 2;
                        uiStroke.Parent = newItemButton;

                    end
                end
                binds.ItemButtonList[crateItemId] = itemButtonObject;
                itemButtonCaches[crateItemId] = itemButtonObject;
                
                newItemButton.Name = crateItemId;
                
                newItemButton.BackgroundColor3 = rewardsId == crateItemId
                                             and interface.Colors.Branch 
                                             or Color3.fromRGB(10, 10, 10);
                newItemButton.BackgroundTransparency = 0.25;
                newItemButton.Size = UDim2.new(0, 50, 0, 50);
                newItemButton.Parent = newVertList;
                
                itemButtonObject:Update();

                crateOrder = crateOrder - 1;
                newItemButton.LayoutOrder = crateOrder;
            end

            for a=1, #crateList do
                local crateItemId = crateList[a];
                newCrateItemButton(crateItemId);
            end
            
            if stageLib.HardModeEnabled and stageLib.HardRewardId then
                newCrateItemButton(stageLib.HardRewardId, {Hard=true;});
            end
            
            newVertList.Parent = rewardsList;
        end

        if rewardsId == nil then
            rewardsId = stageLib.RewardsId;
            if stageLib.RewardsIds then
                rewardsId = stageLib.RewardsIds[1];
            end
        end

	    rewardsList.Visible = rewardsId ~= nil;
        rewardsButton.Visible = rewardsId ~= nil;
        if rewardsId then
            local isHardReward = stageLib.HardModeEnabled 
                             and stageLib.HardRewardId 
                             and stageLib.HardRewardId == rewardsId;

            local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);
            local rewardsLib = modRewardsLibrary:Find(rewardsId);

            if rewardsLib then
                if rewardsLib.Level then
                    local playerLevel = modData.GameSave and modData.GameSave.Stats and modData.GameSave.Stats.Level or 0;
                    
                    rewardsHintLabel.Text = "Mastery Level "..rewardsLib.Level.."+";
                    rewardsHintLabel.TextColor3 = playerLevel >= rewardsLib.Level and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(197, 103, 103);
                end
                
                local isHardMode = false;
                if stageLib.SingleArena then
                    isHardMode = viewingRoom and viewingRoom.IsHard == true;
                else
                    isHardMode = hardModeCreate;
                end

                local vpSize = workspace.CurrentCamera.ViewportSize;
                
                local lists = modDropRateCalculator.Calculate(rewardsLib, {HardMode=isHardMode;});
                local hasWeeklyRewards = false;
                
                local hasHardLoot = false;
                
                for a=#lists, 1, -1 do
                    local list = lists[a];
                    local newParent;
                    
                    if #list >= 1 then
                        local newVertList = rewardsList:FindFirstChild(a) or verticalListTemplate:Clone();
                        newVertList.Visible = true;
                        newVertList.Name = a;
                        newVertList.LayoutOrder = a;
                        newVertList.Parent = rewardsList;

                        local sizeConstraint = newVertList:FindFirstChild("UISizeConstraint");
                        if sizeConstraint then
                            sizeConstraint.MaxSize = Vector2.new(math.huge, vpSize.Y/2.3);
                        end
                        
                        local lineFrame = linesList[a] or templateLine:Clone();
                        linesList[a] = lineFrame;
                        
                        local listaplusone = lists[a+1];
                        
                        if listaplusone then
                            lineFrame.Visible = true;
                            lineFrame.LayoutOrder = a;
                            lineFrame.Parent = rewardsList;
                            lineFrame.Size = UDim2.new(0, 1, 0, (math.max(#list, listaplusone and #listaplusone or 0) * 65)-5);
                        end
                        
                        newParent = newVertList;
                    else
                        newParent = rewardsList;
                    end
                    
                    for b=1, #list do
                        local rewardInfo = list[b];
                        
                        local itemButtonObject = binds.ItemButtonList[rewardInfo.ItemId..b] 
                                              or modItemInterface.newItemButton(rewardInfo.ItemId);
                        local newItemButton = itemButtonObject.ImageButton;
                        
                        if binds.ItemButtonList[rewardInfo.ItemId..b] == nil then
                            itemToolTip:BindHoverOver(newItemButton, function()
                                itemToolTip.Frame.Parent = script.Parent;
                                itemToolTip:Update(rewardInfo.ItemId);
                                itemToolTip:SetPosition(newItemButton);
                            end);
                            
                            templateUIRatio:Clone().Parent = newItemButton;
                        end
                        
                        binds.ItemButtonList[rewardInfo.ItemId..b] = itemButtonObject;
                        itemButtonCaches[rewardInfo.ItemId..b] = itemButtonObject;
                        
                        newItemButton.Name = rewardInfo.ItemId..b;
                        newItemButton.BackgroundTransparency = 0.25;
                        
                        itemButtonObject:Update();

                        newItemButton.LayoutOrder = b;
                        if vpSize.Y <= 360 then
                            newItemButton.Size = UDim2.new(0, 30, 0, 30);
                        elseif vpSize.Y <= 600 then
                            newItemButton.Size = UDim2.new(0, 45, 0, 45);
                        else
                            newItemButton.Size = UDim2.new(0, 60, 0, 60);
                        end

                        if rewardInfo.HardMode and not isHardMode then
                            hasHardLoot = true;
                            newItemButton.ImageColor3 = Color3.fromRGB(255, 60, 60);

                        else
                            itemButtonObject:Update();

                        end
                        
                        if hasHardLoot and stageLib.HardModeItem then
                            if unlockHardModeButton == nil then
                                unlockHardModeButton = templateUnlockHardmode:Clone();
                                unlockHardModeButton.MouseButton1Click:Connect(function()
                                    if tick()-debounceTick < debounceDuration then return end;
                                    debounceTick = tick();
                                    interface:PlayButtonClick();

                                    interface:ToggleWindow("GoldMenu", true, "SummonsItems");
                                end)

                                unlockHardModeButton.Parent = newParent;
                            end
                            
                        else
                            if unlockHardModeButton then
                                game.Debris:AddItem(unlockHardModeButton, 0);
                                unlockHardModeButton = nil;
                            end
                        end
                        
                        local quantityLabel = newItemButton:WaitForChild("QuantityLabel");
                        quantityLabel.Font = Enum.Font.Arial;
                        quantityLabel.TextSize = 10;
                        quantityLabel.Visible = true;
                        
                        if vpSize.Y <= 360 then
                            quantityLabel.Position = UDim2.new(0, 0, 0, -5);
                        elseif vpSize.Y <= 600 then
                            quantityLabel.Position = UDim2.new(0, 0, 0, -5);
                        end
                        
                        if rewardInfo.HardMode and not isHardMode then
                            quantityLabel.Text = "Hard Mode";
                            
                        elseif isHardReward and rewardInfo.Wave then
                            quantityLabel.RichText = true;
                            quantityLabel.TextSize = 17;
                            quantityLabel.Text = `<font size="9">Wave</font> {rewardInfo.Wave}`;
                            quantityLabel.TextColor3 = Color3.fromRGB(255, 60, 0);
                            quantityLabel.AnchorPoint = Vector2.new(0.5, 0);
                            quantityLabel.Position = UDim2.new(0.5, 0, 0, 2);
                            quantityLabel.Size = UDim2.new(1, -5, 0.3, 0);
                            quantityLabel.TextScaled = true;
                            quantityLabel.TextStrokeTransparency = 0; 

                        elseif rewardInfo.Weekday == nil then
                            quantityLabel.Text = (math.ceil(rewardInfo.Chance/list.TotalChance*10000)/100).."%";
                            
                        else
                            quantityLabel.Text = rewardInfo.Weekday;
                            if rewardInfo.Weekday == modSyncTime.GetWeekDay() then
                                quantityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                            else
                                quantityLabel.TextColor3 = Color3.fromRGB(160, 160, 160);
                            end
                        end
                        
                        newItemButton.Parent = newParent;
                    end
                end
                timerLabel.Visible = hasWeeklyRewards;
            end
        end
        
        for _, obj in pairs(binds.ItemButtonList) do
            local itemId = obj.ImageButton.Name;
            if itemButtonCaches[itemId] == nil then
                binds.ItemButtonList[itemId] = nil;
                obj:Destroy();
            end
        end

        --MARK: Leaderboards
        if activeLeaderboard == nil then
            if stageLib.LeaderboardKeyTable then
                modLeaderboardService.ClientGamemodeBoardRequest(gameMode, gameStage);
                
                local keyTable = {
                    StatName=stageLib.LeaderboardDataKey;
                };
                
                for key, data in pairs(stageLib.LeaderboardKeyTable) do
                    if data.Folder == "AllTimeStats" then
                        keyTable.AllTimeTableKey = key;

                    elseif data.Folder == "YearlyStats" then
                        keyTable.YearlyTableKey = key;

                    elseif data.Folder == "SeasonlyStats" then
                        keyTable.SeasonlyTableKey = key;

                    elseif data.Folder == "MonthlyStats" then
                        keyTable.MonthlyTableKey = key;

                    elseif data.Folder == "WeeklyStats" then
                        keyTable.WeeklyTableKey = key;
                        
                    elseif data.Folder == "DailyStats" then
                        keyTable.DailyTableKey = key;
                    end
                end
                
                local vpSize = workspace.CurrentCamera.ViewportSize;

                activeLeaderboard = modLeaderboardInterface.new(keyTable);
                activeLeaderboard.Frame.Parent = gameRoomFrame;
                activeLeaderboard.Frame.AnchorPoint = Vector2.new(0, 1);
                activeLeaderboard.Frame.Position = UDim2.new(0, 20, 0.781, -10);
                activeLeaderboard.Frame.Size = UDim2.new(0, 300, 0, math.min(400, (vpSize.Y*0.781)-100));

                if vpSize.Y <= 360 then
                    activeLeaderboard.Frame.Size = UDim2.new(0, 200, 0, 200);
                elseif vpSize.Y <= 600 then
                    activeLeaderboard.Frame.Size = UDim2.new(0, 240, 0, 240);
                end

                leaderboardButton.Visible = true;
            else
                leaderboardButton.Visible = false;
            end
        end
    end)

    interface.Scheduler.OnStepped:Connect(function(tickData: TickData)
        if not window.Visible then return end
        if tickData.ms100 ~= true then return end;

        if timerLabel.Visible then
            local secsLeft = modSyncTime.TimeOfEndOfDay()-modSyncTime.GetTime();
            timerLabel.Text = "Next Rewards: ".. modSyncTime.ToString(secsLeft);
        end
        
        if binds.ActiveLobbyData == nil then return end;
        if stageLib == nil then return end;

        local viewingRoom, _viewIndex = binds.GetRoom(binds.ViewingRoomId);
        if viewingRoom == nil then return end;

        if viewingRoom.State == 1 then
            lobbyInfoLabel.Text = "Waiting for players..";
        
        elseif viewingRoom.State == 2 then
            lobbyInfoLabel.Text = "This room is starting in "..math.floor(
                math.clamp((viewingRoom.StartTime or modSyncTime.GetTime()+5)-modSyncTime.GetTime(), 0, 60)
            ).." seconds.";
        
        elseif viewingRoom.State == 3 then
            if stageLib.WorldId then
                lobbyInfoLabel.Text = "Traveling to "..stageLib.WorldId.."..";
                
            elseif viewingRoom.StartTime then
                local clock = os.date("*t", modSyncTime.GetTime()-viewingRoom.StartTime);
                if clock ~= nil then
                    lobbyInfoLabel.Text = "In battle for: "..(
                        clock.min > 0 and clock.min..":"..clock.sec.." minutes." or clock.sec.." seconds."
                    );
                end
                
            end
        
        elseif viewingRoom.State == 4 and viewingRoom.EndTime then
            lobbyInfoLabel.Text = "Room is closing in "..math.floor(
                math.clamp(viewingRoom.EndTime-modSyncTime.GetTime(), 0, 15)
            ).." seconds..";
        
        elseif viewingRoom.State == 5 then
            lobbyInfoLabel.Text = "Room is closed..";
            
        else
            lobbyInfoLabel.Text = "";
        end
        
        
        local descText = {};
        if viewingRoom.MapStorageItem then
            local itemValues = viewingRoom.MapStorageItem.Values;

            if itemValues.Seed then
                table.insert(descText, "Seed: ".. itemValues.Seed);
            end
        end
        for k, v in pairs(viewingRoom.Values) do
            table.insert(descText, `{k}: {tostring(v)}`);
        end
        specialDataLabel.Text = table.concat(descText, "  |  ");
        
        local hostPlayerData = viewingRoom.Players[1];
        if hostPlayerData and hostPlayerData.LobbyPosition then
            local hostPosition: Vector3 = hostPlayerData.LobbyPosition.WorldPosition;

            local screenPoint, _ = camera:WorldToViewportPoint(hostPosition);
            hostIcon.Visible = true;
            hostIcon.ImageColor3 = interface.Colors.Branch;
            hostIcon.Position = UDim2.new(0, screenPoint.X, 0, screenPoint.Y+30);

        else
            hostIcon.Visible = false;
            
        end

        local updated = {};
        if viewingRoom.State <= 2 and stageLib.SingleArena ~= true then
            for a=1, #viewingRoom.Players do
                local playerData = viewingRoom.Players[a];
                local lobbyAtt = playerData.LobbyPosition;
                
                if lobbyAtt then
                    local indicator = getIndicator(playerData.Name)
                    if indicator == nil then
                        indicator = newIndicator(playerData.Name);
                    end

                    pcall(function()
                        indicator.Object.CFrame = lobbyAtt.WorldCFrame * CFrame.Angles(math.rad(-90), 0, 0); --CFrame.new(LobbyPosition.WorldPosition) * rotCf;
                        indicator.Object.Parent = workspace.Debris;
                        indicator.Object.Color = playerData.Ready and interface.Colors.Branch or UNREADY_COLOR;
                        indicator.Object.Attachment.SpotLight.Color = playerData.Ready and interface.Colors.Branch or UNREADY_COLOR;
                    end)
                end
                updated[playerData.Name] = true;
            end
        end
        
        for a=#readyIndicators, 1, -1 do
            if updated[readyIndicators[a].Name] == nil then
                readyIndicators[a].Destroyed = true;
                game.Debris:AddItem(readyIndicators[a].Object, 0);
                table.remove(readyIndicators, a);
            end
        end
        -- if refreshStatus then Update() end;
        -- if gameLobby and gameLobby.BossName then
        --     if modSyncTime.GetWeekDay() ~= currentWeekDay then
        --         currentWeekDay = modSyncTime.GetWeekDay();
        --     end
        -- end
    end)

    interface.Garbage:Tag(remoteGameModeUpdate.OnClientEvent:Connect(function(action, data)
        if not window.Visible then return end;

        if action == "synclobby" then
            binds.ActiveLobbyData = data;
            window:Update();

        elseif action == "closemenu" then
            window:Close();

        end
    end))
    
end

return interfacePackage;

