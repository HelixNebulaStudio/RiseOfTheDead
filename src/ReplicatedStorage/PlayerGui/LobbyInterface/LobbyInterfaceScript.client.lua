local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local newLobbyAsPublic = true;
local hardModeCreate = false;

--== Variables;
local UserInputService = game:GetService("UserInputService");
local SoundService = game:GetService("SoundService");

local localPlayer = game.Players.LocalPlayer;
local camera: Camera = workspace.CurrentCamera;

local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
local modCharacter = modData:GetModCharacter();

local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modGameModeLibrary = require(game.ReplicatedStorage.Library.GameModeLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modDropRateCalculator = require(game.ReplicatedStorage.Library.DropRateCalculator);
local modLeaderboardService = require(game.ReplicatedStorage.Library.LeaderboardService);

local modLeaderboardInterface = require(game.ReplicatedStorage.Library.UI.LeaderboardInterface);
local modGuiTween = require(game.ReplicatedStorage.Library.UI.GuiObjectTween);
local modGuiObjectPlus = require(game.ReplicatedStorage.Library.UI.GuiObjectPlus);
local modItemInterface = require(game.ReplicatedStorage.Library.UI.ItemInterface);


local remoteGameModeRequest = modRemotesManager:Get("GameModeRequest");
local remoteGameModeUpdate = modRemotesManager:Get("GameModeUpdate");
local remoteGameModeExit = modRemotesManager:Get("GameModeExit");

local remotes = game.ReplicatedStorage.Remotes;
local bindOpenLobbyInterface = remotes.LobbyInterface.OpenLobbyInterface;
local bindLeavingBossArena = remotes.BossInterface.LeavingBossArena;

local mainInterface = script.Parent.Parent.MainInterface;
local modInterface = require(mainInterface:WaitForChild("InterfaceModule") :: ModuleScript);

local lobbyInterface = script.Parent;
local mainFrame = script.Parent:WaitForChild("Interface");

local templateUnlockHardmode = script:WaitForChild("UnlockHardmode");

local readyPartPrefab = script:WaitForChild("readyPart");
local verticalListTemplate = script:WaitForChild("VerticalList");
local templateUIRatio = script:WaitForChild("UIAspectRatioConstraint");
local templateLine = script:WaitForChild("line");

local gameLobby = {
	Type = nil;
	Stage = nil;
	BossName = nil;
	Lobbies = {};
};
local lobbyInfo = {
	StageLib = nil;
	GameLib = nil;
};

local readyIndicators = {};

local roomId, lobbyCameraPoint;

local createPublicLobbyButton, createSquadLobbyButton, createHardLobbyButton;

local debounce = false;
local refreshStatus = false;

local enumRequests = modGameModeLibrary.RequestEnums;

local cameraLight = nil;
local branchColor = modBranchConfigs.BranchColor
local currentWeekDay = modSyncTime.GetWeekDay();

local unreadyColor = Color3.fromRGB(101, 101, 102);
local rewardsId;
local activeLeaderboard;

local itemToolTip = modItemInterface.newItemTooltip();
--== Script;

--Ready Indicators
local function clearIndicators()
	for a=#readyIndicators, 1, -1 do
		readyIndicators[a].Destroyed = true;
		game.Debris:AddItem(readyIndicators[a].Object, 0);
		table.remove(readyIndicators, a);
	end
end

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

local function GetRoom(id)
	if id == nil then return end;
	for a=1, #gameLobby.Lobbies do
		if gameLobby.Lobbies[a].Id == id then
			return gameLobby.Lobbies[a], a;
		end
	end
	return;
end

local function GetPlayerRoom(player)
	if gameLobby.Lobbies == nil then return end;
	for a=1, #gameLobby.Lobbies do
		for b=1, #gameLobby.Lobbies[a].Players do
			if gameLobby.Lobbies[a].Players[b].Name == player.Name then
				return gameLobby.Lobbies[a], gameLobby.Lobbies[a].Players[b];
			end
		end
	end
	return;
end

local function UpdateButtons(roomId)
	local room, roomIndex = GetRoom(roomId);
	
	local isInSquad = false;
	if room then
		for a=1, #room.Players do
			if modData.Squad and modData.Squad:FindMember(room.Players[a].Name) then
				isInSquad = true;
				break;
			end
		end
	end
	
	mainFrame.HardTitle.Visible = room.IsHard == true;
	mainFrame.TitleImage.ImageColor3 = room.IsHard == true and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255);
	task.spawn(function()
		UpdateInformation(room);
	end)
	
	local playerRoom, playerData = GetPlayerRoom(localPlayer);
	if playerRoom == nil then -- when player not in a lobby;
		mainFrame.JoinButton.Visible = #room.Players < lobbyInfo.StageLib.MaxPlayers
		and (room.State == 1 or (lobbyInfo.StageLib.SingleArena and room.State == 2))
		and (room.IsPublic or isInSquad);
		
		if not (room.IsPublic or isInSquad) then
			mainFrame.LobbyHint.Text = "Private";
		else
			mainFrame.LobbyHint.Text = "";
		end
		
		if #room.Players >= lobbyInfo.StageLib.MaxPlayers then
			mainFrame.LobbyHint.Text = "Full";
		else
			mainFrame.LobbyHint.Text = "";
		end
		
		mainFrame.ReadyButton.Visible = false;
		mainFrame.UnreadyButton.Visible = false;
		
		if workspace:GetAttribute("GameModeComplete") then
			mainFrame.CreateRoom.Visible = false;
			mainFrame.ExitGame.Visible = true;
		else
			mainFrame.ExitGame.Visible = false;
			mainFrame.CreateRoom.Visible = #gameLobby.Lobbies < (lobbyInfo.GameLib.MaxRooms or 6) and lobbyInfo.StageLib.SingleArena ~= true;
		end

		--mainFrame.ExitMenu.Visible = true;
		
	else
		mainFrame.CreateRoom.Visible = false;
		mainFrame.JoinButton.Visible = false;
		
		--mainFrame.LeaveButton.Visible = true;
		
		if lobbyInfo.StageLib.SingleArena then
			mainFrame.ReadyButton.Visible = false;
			mainFrame.UnreadyButton.Visible = false;
			
		elseif room.State == 1 then
			if playerRoom.Id == roomId then
				mainFrame.ReadyButton.Visible = not playerData.Ready;
				mainFrame.UnreadyButton.Visible = playerData.Ready;
			end
			
		elseif room.State == 2 then
			if playerRoom.Id == roomId then
				mainFrame.ReadyButton.Visible = not playerData.Ready;
				mainFrame.UnreadyButton.Visible = playerData.Ready;
			end
			
		elseif room.State >= 3 then
			mainFrame.ReadyButton.Visible = false;
			mainFrame.UnreadyButton.Visible = false;
			
		end
	end;
	
	if #gameLobby.Lobbies > 1 then
		if roomIndex > 1 and roomIndex < #gameLobby.Lobbies then
			mainFrame.PreviousRoom.Visible = true;
			mainFrame.NextRoom.Visible = true;
		elseif roomIndex == 1 then
			mainFrame.PreviousRoom.Visible = false;
			mainFrame.NextRoom.Visible = true;
		else
			mainFrame.PreviousRoom.Visible = true;
			mainFrame.NextRoom.Visible = false;
		end
	else
		mainFrame.PreviousRoom.Visible = false;
		mainFrame.NextRoom.Visible = false;
	end
end

local function SetRoom(room)
	if room == nil then return end;
	local function setCamPoint()
		lobbyCameraPoint = room.LobbyPrefab and room.LobbyPrefab.PrimaryPart and room.LobbyPrefab.PrimaryPart:WaitForChild("CameraPoint");
	end
	if room.Id == roomId then 
		setCamPoint();
		modGuiTween.FadeTween(lobbyInterface.Transition, modGuiTween.FadeDirection.Out, TweenInfo.new(0.1));
		wait(0.1);
		lobbyInterface.Transition.Visible = false;
		return;
	end;
	
	lobbyInterface.Transition.Visible = true;
	modGuiTween.FadeTween(lobbyInterface.Transition, modGuiTween.FadeDirection.In, TweenInfo.new(0.1));
	wait(0.1);
	clearIndicators();
	roomId = room.Id;
	Update();
	setCamPoint();
	
	UpdateButtons(roomId);
	
	modGuiTween.FadeTween(lobbyInterface.Transition, modGuiTween.FadeDirection.Out, TweenInfo.new(0.1));
	wait(0.1);
	lobbyInterface.Transition.Visible = false;
end

function ChangeRoom(increase)
	if debounce then return end 
	debounce = true;

	local change = increase and 1 or -1;
	
	local _room, roomIndex = GetRoom(roomId);
	
	if roomIndex+change <= #gameLobby.Lobbies and roomIndex+change >= 1 then
		SetRoom(gameLobby.Lobbies[roomIndex+change]);
	end
	debounce = false;
end

function Update()
	local currentRoom, _roomIndex = GetRoom(roomId);
	if currentRoom == nil then
		mainFrame.LobbyInfo.Text = "";
		return;
	end

	if currentRoom.State == 1 then
		mainFrame.LobbyInfo.Text = "Waiting for players..";
	
	elseif currentRoom.State == 2 then
		mainFrame.LobbyInfo.Text = "This room is starting in "..math.floor(math.clamp((currentRoom.StartTime or modSyncTime.GetTime()+5)-modSyncTime.GetTime(), 0, 60)).." seconds.";
	
	elseif currentRoom.State == 3 then
		if lobbyInfo.StageLib.WorldId then
			mainFrame.LobbyInfo.Text = "Traveling to "..lobbyInfo.StageLib.WorldId.."..";
			
		elseif currentRoom.StartTime then
			local clock = os.date("*t", modSyncTime.GetTime()-currentRoom.StartTime);
			if clock ~= nil then
				mainFrame.LobbyInfo.Text = "In battle for: "..(clock.min > 0 and clock.min..":"..clock.sec.." minutes." or clock.sec.." seconds.");
			end
			
		end
	
	elseif currentRoom.State == 4 and currentRoom.EndTime then
		mainFrame.LobbyInfo.Text = "Room is closing in "..math.floor(math.clamp(currentRoom.EndTime-modSyncTime.GetTime(), 0, 15)).." seconds..";
	
	elseif currentRoom.State == 5 then
		mainFrame.LobbyInfo.Text = "Room is closed..";
		
	else
		mainFrame.LobbyInfo.Text = "";
	end
	
	local specialTxt = "";
	if currentRoom.MapStorageItem then
		local itemValues = currentRoom.MapStorageItem.Values;

		if itemValues.Seed then
			specialTxt = specialTxt.."Seed: ".. itemValues.Seed;
		end
	end
	mainFrame.SpecialData.Text = specialTxt;
	
	local hostPlayerData = currentRoom.Players[1];
	if hostPlayerData and hostPlayerData.LobbyPosition then
		local hostPosition: Vector3 = hostPlayerData.LobbyPosition.WorldPosition;

		local screenPoint, _ = camera:WorldToViewportPoint(hostPosition);
		mainFrame.HostIcon.Visible = true;
		mainFrame.HostIcon.ImageColor3 = branchColor;
		mainFrame.HostIcon.Position = UDim2.new(0, screenPoint.X, 0, screenPoint.Y+30);

	else
		mainFrame.HostIcon.Visible = false;
		
	end
	

	UpdateButtons(roomId);
	
	local updated = {};
	if currentRoom.State <= 2 and lobbyInfo.StageLib.SingleArena ~= true then
		for a=1, #currentRoom.Players do
			local playerData = currentRoom.Players[a];
			local LobbyPosition = playerData.LobbyPosition;
			
			if LobbyPosition then
				local indicator = getIndicator(playerData.Name)
				if indicator == nil then
					indicator = newIndicator(playerData.Name);
				end

				pcall(function()
					indicator.Object.CFrame = LobbyPosition.WorldCFrame * CFrame.Angles(math.rad(-90), 0, 0); --CFrame.new(LobbyPosition.WorldPosition) * rotCf;
					indicator.Object.Parent = workspace.Debris;
					indicator.Object.Color = playerData.Ready and branchColor or unreadyColor;
					indicator.Object.Attachment.SpotLight.Color = playerData.Ready and branchColor or unreadyColor;
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
end

local linesList = {};
local itemButtonList = {};
local unlockHardModeButton = nil;

function UpdateInformation(room)
	mainFrame.GameMode.Text = gameLobby.Type or "";
	mainFrame.Description.Text = lobbyInfo.StageLib.Description or "";
	mainFrame.ExtremeLabel.Visible = lobbyInfo.StageLib.IsExtreme or false;
	mainFrame.RewardsHint.Text = "";
	
	if createHardLobbyButton then
		createHardLobbyButton.Visible = lobbyInfo.StageLib.HardModeEnabled == true;
		createHardLobbyButton.HardMode.Text = lobbyInfo.GameLib.HardModeText or "Hard Mode";
		
		mainFrame.HardTitle.Image = lobbyInfo.GameLib.HardModeTitleImage or "http://www.roblox.com/asset/?id=5006434147";
	end
	
	if lobbyInfo.StageLib.TitleImage then
		mainFrame.TitleImage.Image = lobbyInfo.StageLib.TitleImage;
		mainFrame.TitleImage.ImageColor3 = Color3.fromRGB(255,255,255);
	end
	
	local itemButtonCaches = {};
	local rewardsList = mainFrame.Rewards;
	
	for _, obj in pairs(rewardsList:GetChildren()) do
		if obj:IsA("GuiObject") then
			obj.Visible = false;
		end
	end
	if lobbyInfo.StageLib.CrateId == nil then
		local crateList = lobbyInfo.StageLib.RewardsIds or {lobbyInfo.StageLib.RewardsId};
		
		local newVertList = rewardsList:FindFirstChild("crateList") or verticalListTemplate:Clone();
		newVertList.Visible = true;
		newVertList.Name = "crateList";
		newVertList.LayoutOrder = 99;
		--newVertList.Size = UDim2.new(0, 60, 1, 0);
		
		local gridLayout = newVertList:WaitForChild("UIGridLayout");
		gridLayout.CellSize = UDim2.new(0, 50, 0, 50);
		
		for a=1, #crateList do
			local itemButtonObject = itemButtonList[crateList[a]] or modItemInterface.newItemButton(crateList[a]);
			local newItemButton = itemButtonObject.ImageButton;
			if itemButtonList[crateList[a]] == nil then
				itemToolTip:BindHoverOver(newItemButton, function()
					itemToolTip.Frame.Parent = script.Parent;
					itemToolTip:Update(crateList[a]);
					itemToolTip:SetPosition(newItemButton);
				end);
				
				newItemButton.MouseButton1Click:Connect(function()
					rewardsId = crateList[a];
					UpdateInformation(room);
				end)
				
				templateUIRatio:Clone().Parent = newItemButton;
			end
			itemButtonList[crateList[a]] = itemButtonObject;
			itemButtonCaches[crateList[a]] = itemButtonObject;
			
			newItemButton.Name = crateList[a];
			
			newItemButton.BackgroundColor3 = rewardsId == crateList[a] and branchColor or Color3.fromRGB(10, 10, 10);
			newItemButton.BackgroundTransparency = 0.25;
			newItemButton.Parent = newVertList;
			
			itemButtonObject:Update();
		end
		newVertList.Parent = rewardsList;
	end
	
	mainFrame.RewardsButton.Visible = rewardsId ~= nil;
	if rewardsId then
		local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
		local rewardsLib = modRewardsLibrary:Find(rewardsId);
		if rewardsLib then
			if rewardsLib.Level then
				local playerLevel = modData.GameSave and modData.GameSave.Stats and modData.GameSave.Stats.Level or 0;
				
				mainFrame.RewardsHint.Text = "Mastery Level "..rewardsLib.Level.."+";
				mainFrame.RewardsHint.TextColor3 = playerLevel >= rewardsLib.Level and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(197, 103, 103);
			end
			
			local isHardMode = false;
			if lobbyInfo.StageLib.SingleArena then
				isHardMode = room and room.IsHard == true;
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

					local gridLayout = newVertList:WaitForChild("UIGridLayout");

					if vpSize.Y <= 360 then
						gridLayout.CellSize = UDim2.new(0, 30, 0, 30);
					elseif vpSize.Y <= 600 then
						gridLayout.CellSize = UDim2.new(0, 45, 0, 45);
					else
						gridLayout.CellSize = UDim2.new(0, 60, 0, 60);
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
					
					local itemButtonObject = itemButtonList[rewardInfo.ItemId..b] or modItemInterface.newItemButton(rewardInfo.ItemId);
					local newItemButton = itemButtonObject.ImageButton;
					
					if itemButtonList[rewardInfo.ItemId..b] == nil then
						itemToolTip:BindHoverOver(newItemButton, function()
							itemToolTip.Frame.Parent = script.Parent;
							itemToolTip:Update(rewardInfo.ItemId);
							itemToolTip:SetPosition(newItemButton);
						end);
						
						templateUIRatio:Clone().Parent = newItemButton;
					end
					
					itemButtonList[rewardInfo.ItemId..b] = itemButtonObject;
					itemButtonCaches[rewardInfo.ItemId..b] = itemButtonObject;
					
					newItemButton.Name = rewardInfo.ItemId..b;
					newItemButton.BackgroundTransparency = 0.25;
					
					itemButtonObject:Update();
					
					newItemButton.LayoutOrder = b;
			
					if rewardInfo.HardMode and not isHardMode then
						hasHardLoot = true;
						newItemButton.ImageColor3 = Color3.fromRGB(255, 60, 60);

					else
						itemButtonObject:Update();

					end
					
					if hasHardLoot and lobbyInfo.StageLib.HardModeItem then
						if unlockHardModeButton == nil then
							unlockHardModeButton = templateUnlockHardmode:Clone();
							unlockHardModeButton.MouseButton1Click:Connect(function()
								if debounce then return end 
								debounce = true;
								modInterface:PlayButtonClick();
								LeaveLobbyMenu();

								modInterface:OpenWindow("GoldMenu", "SummonsItems");
								debounce = false;
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
			mainFrame.TimerLabel.Visible = hasWeeklyRewards;
		end
	end
	
	for _, obj in pairs(itemButtonList) do
		local itemId = obj.ImageButton.Name;
		if itemButtonCaches[itemId] == nil then
			itemButtonList[itemId] = nil;
			obj:Destroy();
		end
	end
	
end

function LeaveLobbyMenu(skipRequest)
	if cameraLight then cameraLight.Enabled = false; end
	modCharacter:ToggleMouseLock(true);
	lobbyInterface.Enabled = false;
	refreshStatus = false;
	hardModeCreate = false;
	
	modInterface:ToggleGameBlinds(false, 0.5);
	
	local timeLapse = tick();
	if skipRequest ~= true then
		remoteGameModeRequest:InvokeServer(enumRequests.CloseInterface);
	end
	wait(math.clamp(0.5-(tick()-timeLapse), 0, 0.5));
	
	mainInterface.Enabled = true;
	modCharacter.CharacterProperties.CharacterCameraEnabled = true;
	modCharacter.CharacterProperties.CanInteract = true;
	modCharacter.CharacterProperties.CanMove = true;
	modCharacter.CharacterProperties.CanAction = true;
	modCharacter.CharacterProperties.AllowLerpBody = true;
	
	modData.CameraHandler:Unbind("lobbycamera");
	clearIndicators();

	modInterface:ToggleGameBlinds(true, 0.5);
	
	if activeLeaderboard then
		activeLeaderboard.Frame:Destroy();
		activeLeaderboard = nil;
	end
end

local function UpdateGameLobby(data)
	if data == nil then return end;
	gameLobby = data;
	
	local room = GetRoom(roomId);
	if room == nil then
		SetRoom(gameLobby.Lobbies[#gameLobby.Lobbies]);
	else
		SetRoom(room);
	end
	Update();
end

remoteGameModeUpdate.OnClientEvent:Connect(function(data)
	if data == nil then
		Debugger:Log("Update with nil");
		LeaveLobbyMenu();
		
	elseif data.CloseMenu then
		LeaveLobbyMenu(true);
		
	else
		UpdateGameLobby(data);
	end
end);


-- !outline: signal    bindLeavingBossArena.Event
bindLeavingBossArena.Event:Connect(function() --cleared max depth check
	LeaveLobbyMenu(true);
end);


-- !outline: signal    bindOpenLobbyInterface.Event
bindOpenLobbyInterface.Event:Connect(function(lobbyData) --cleared max depth check
	if lobbyData == nil then return end;
	gameLobby = lobbyData;
	hardModeCreate = false;
	
	task.spawn(function()
		local joinSuccessOrReason = remoteGameModeRequest:InvokeServer(enumRequests.OpenInterface, gameLobby.Type, gameLobby.Stage);
		if joinSuccessOrReason ~= true then
			Debugger:Warn("Failed to join game room. Reason:", joinSuccessOrReason);
			task.wait(1);
			LeaveLobbyMenu(true);
		end
	end)
	
	local gameLib = modGameModeLibrary.GetGameMode(gameLobby.Type);
	local stageLib = gameLib and modGameModeLibrary.GetStage(gameLobby.Type, gameLobby.Stage);
	lobbyInfo.GameLib = gameLib;
	lobbyInfo.StageLib = stageLib;
	
	rewardsId = lobbyInfo.StageLib.RewardsId;
	if lobbyInfo.StageLib.RewardsIds then
		rewardsId = lobbyInfo.StageLib.RewardsIds[1];
	end
	
	UpdateInformation();
	mainFrame.LeaveButton.Visible = false;
	mainFrame.ExitMenu.Visible = true;
	mainFrame.Rewards.Visible = rewardsId ~= nil;
	mainFrame.RewardsButton.Visible = rewardsId ~= nil;
	
	UpdateGameLobby(gameLobby);
	
	refreshStatus = true;
	
	modData.CameraHandler:Bind("lobbycamera", {
		RenderStepped=function(camera)
			if lobbyCameraPoint then
				local cf = CFrame.new(lobbyCameraPoint.WorldPosition) * (lobbyCameraPoint.CFrame - lobbyCameraPoint.CFrame.p);
				camera.CFrame = CFrame.new(cf.Position, (cf * CFrame.new(1, 0, 0)).Position);
				camera.Focus = cf;
			end
		end;
	}, 2);
	
	modCharacter.CharacterProperties.CharacterCameraEnabled = false;
	modCharacter.CharacterProperties.CanInteract = false;
	modCharacter.CharacterProperties.CanMove = false;
	modCharacter.CharacterProperties.CanAction = false;
	modCharacter.CharacterProperties.AllowLerpBody = false;
	mainInterface.Enabled = false;
	lobbyInterface.Enabled = true;
	modCharacter:ToggleMouseLock(false);
	
	
	Update();
	mainFrame.Visible = true;
	modInterface:ToggleGameBlinds(true, 0.5);
	
	if activeLeaderboard then
		activeLeaderboard.Frame:Destroy();
		activeLeaderboard = nil;
	end
	if stageLib.LeaderboardKeyTable then
		modLeaderboardService.ClientGamemodeBoardRequest(gameLobby.Type, gameLobby.Stage);
		
		local keyTable = {
			StatName=stageLib.LeaderboardDataKey;
		};
		
		for key, data in pairs(stageLib.LeaderboardKeyTable) do
			if data.Folder == "AllTimeStats" then
				keyTable.AllTimeTableKey = key;
			elseif data.Folder == "WeeklyStats" then
				keyTable.WeeklyTableKey = key;
			elseif data.Folder == "DailyStats" then
				keyTable.DailyTableKey = key;
			end
		end
		
		activeLeaderboard = modLeaderboardInterface.new(keyTable);
		activeLeaderboard.Frame.Parent = mainFrame;
		activeLeaderboard.Frame.Position = UDim2.new(0, 20, 0, 95);
		activeLeaderboard.Frame.Size = UDim2.new(0, 400, 0, 400);

		local vpSize = workspace.CurrentCamera.ViewportSize;
		
		if vpSize.Y <= 360 then
			activeLeaderboard.Frame.Size = UDim2.new(0, 200, 0, 200);
		elseif vpSize.Y <= 600 then
			activeLeaderboard.Frame.Size = UDim2.new(0, 240, 0, 240);
		end
		
		activeLeaderboard:AddToggleButton();
		activeLeaderboard.ToggleButton.Position = UDim2.new(0, 20, 0, 65);
	end
end)

local classPlayer = shared.modPlayers.Get(localPlayer);
classPlayer:OnNotIsAlive(function(character)
	if not mainFrame.Visible then return end;
	LeaveLobbyMenu();
end)

modGuiTween.FadeTween(lobbyInterface.Transition, modGuiTween.FadeDirection.Out, TweenInfo.new(0));

for _, button in pairs(lobbyInterface:GetDescendants()) do
	if button:IsA("ImageButton") and button.Name ~= "CreateFrame" then
		local function checkButtonHighlight(buttonObject)
			if buttonObject.Visible then 
				if modGuiObjectPlus.IsMouseOver(buttonObject) then
					buttonObject.ImageColor3 = branchColor;
				else
					buttonObject.ImageColor3 = Color3.fromRGB(255, 255, 255);
				end
			end
		end
		
		if button.Name == "ExitMenu" then
			button.MouseButton1Click:Connect(function()
				if debounce then return end 
				debounce = true;
				
				modInterface:PlayButtonClick();
				LeaveLobbyMenu();
				
				debounce = false;
			end)
			
		elseif button.Name == "JoinButton" then
			button.MouseButton1Click:Connect(function()
				if debounce then return end 
				debounce = true;
				
				modInterface:PlayButtonClick();
				
				button.Visible = false;
				mainFrame.ExitMenu.Visible = false;
				mainFrame.CreateRoom.Visible = false;
				
				mainFrame.LeaveButton.Visible = true;
				mainFrame.ReadyButton.Visible = lobbyInfo.StageLib.SingleArena ~= true;
				
				mainFrame.ReadyButton.ImageColor3 = Color3.fromRGB(100, 100, 100);
				local data = remoteGameModeRequest:InvokeServer(enumRequests.JoinRoom, roomId);
				UpdateGameLobby(data);
				checkButtonHighlight(mainFrame.ReadyButton);
				
				debounce = false;
			end)
			
		elseif button.Name == "LeaveButton" then
			button.MouseButton1Click:Connect(function()
				if debounce then return end
				debounce = true;
				modInterface:PlayButtonClick();
				
				button.Visible = false;
				mainFrame.LeaveButton.Visible = false;
				mainFrame.ReadyButton.Visible = false;
				mainFrame.UnreadyButton.Visible = false;
				mainFrame.PreviousRoom.Visible = false;
				mainFrame.NextRoom.Visible = false;

				mainFrame.ExitMenu.Visible = true;
				--mainFrame.CreateRoom.Visible = lobbyInfo.StageLib.SingleArena ~= true;
				
				local localLobby = GetPlayerRoom(localPlayer);
				if localLobby == nil or roomId == localLobby.Id then
					mainFrame.JoinButton.Visible = true;
					mainFrame.JoinButton.ImageColor3 = Color3.fromRGB(100, 100, 100);
				end
				
				removeIndicator(localPlayer.Name);
				
				remoteGameModeRequest:InvokeServer(enumRequests.LeaveRoom);
				checkButtonHighlight(mainFrame.ExitMenu);
				checkButtonHighlight(mainFrame.JoinButton);
				
				debounce = false;
			end)
			
		elseif button.Name == "CreateRoom" then
			button.MouseButton1Click:Connect(function()
				if not mainFrame.CreateFrame.Visible and UserInputService.TouchEnabled then
					mainFrame.CreateFrame.Visible = true;
				else
					if debounce then return end 
					debounce = true;
					
					mainFrame.CreateFrame.Visible = false;
					button.Visible = false;
					
					mainFrame.ExitMenu.Visible = false;
					mainFrame.JoinButton.Visible = false;
					mainFrame.PreviousRoom.Visible = false;
					mainFrame.NextRoom.Visible = false;
					
					lobbyInterface.Transition.Visible = true;
					modGuiTween.FadeTween(lobbyInterface.Transition, modGuiTween.FadeDirection.In, TweenInfo.new(0.25));
					local data, id = remoteGameModeRequest:InvokeServer(enumRequests.CreateRoom, newLobbyAsPublic, hardModeCreate);
					
					UpdateGameLobby(data);
					
					if id ~= nil then
						SetRoom(GetRoom(id));
						mainFrame.ExitMenu.Visible = false;
						mainFrame.CreateRoom.Visible = false;

						mainFrame.LeaveButton.Visible = true;
						mainFrame.ReadyButton.Visible = lobbyInfo.StageLib.SingleArena ~= true;
						
					else
						modGuiTween.FadeTween(lobbyInterface.Transition, modGuiTween.FadeDirection.Out, TweenInfo.new(0.25));
						lobbyInterface.Transition.Visible = false;

						mainFrame.ExitMenu.Visible = true;
						mainFrame.JoinButton.Visible = true;
						
					end
					UpdateGameLobby(data);
					
					debounce = false;
				end
			end)
			
		elseif button.Name == "NextRoom" then
			button.MouseButton1Click:Connect(function()
				modInterface:PlayButtonClick();
				ChangeRoom(true);
			end);
			
		elseif button.Name == "PreviousRoom" then
			button.MouseButton1Click:Connect(function()
				modInterface:PlayButtonClick();
				ChangeRoom(false);
			end);
			
		elseif button.Name == "ReadyButton" then
			button.MouseButton1Click:Connect(function()
				if debounce then return end 
				debounce = true;

				modInterface:PlayButtonClick();
				
				button.Visible = false;
				mainFrame.UnreadyButton.Visible = true;
				mainFrame.UnreadyButton.ImageColor3 = Color3.fromRGB(100, 100, 100);
				
				local room = GetRoom(roomId);
				if room then
					for a=1, #room.Players do
						if room.Players[a].Name == localPlayer.Name then
							room.Players[a].Ready = true;
						end
					end
				end
				Update();
				
				local data = remoteGameModeRequest:InvokeServer(enumRequests.Ready);
				UpdateGameLobby(data);
				checkButtonHighlight(mainFrame.UnreadyButton);
				
				debounce = false;
			end);
			
		elseif button.Name == "UnreadyButton" then
			button.MouseButton1Click:Connect(function()
				if debounce then return end
				debounce = true;
				modInterface:PlayButtonClick();
				button.Visible = false;
				
				mainFrame.ReadyButton.ImageColor3 = Color3.fromRGB(100, 100, 100);
				
				local room = GetRoom(roomId);
				if room then
					for a=1, #room.Players do
						if room.Players[a].Name == localPlayer.Name then
							room.Players[a].Ready = false;
						end
					end
				end
				Update();
				
				local data = remoteGameModeRequest:InvokeServer(enumRequests.Unready);
				UpdateGameLobby(data);
				checkButtonHighlight(mainFrame.ReadyButton);
				
				debounce = false;
			end);
			
		elseif button.Name == "RewardsButton" then
			button.MouseButton1Click:Connect(function()
				mainFrame.Rewards.Visible = not mainFrame.Rewards.Visible;
			end)
			
		elseif button.Name == "ExitGame" then
			button.MouseButton1Click:Connect(function()
				modInterface:PlayButtonClick();
				LeaveLobbyMenu();
				
				task.delay(0.5, function()
					if workspace:GetAttribute("GameModeComplete") then
						local worldName = modBranchConfigs.GetWorldDisplayName(modBranchConfigs.WorldName);
						local promptWindow = modInterface:PromptQuestion("Leave ".. worldName .."?", "Are you sure you want to leave?");
						local YesClickedSignal, NoClickedSignal;

						local function exitPrompt()
							modInterface:ToggleGameBlinds(true, 1);
							SoundService:SetListener(Enum.ListenerType.ObjectCFrame, modCharacter.RootPart);

							modCharacter.CharacterProperties.CanMove = true;
							modCharacter.CharacterProperties.CanInteract = true;
						end

						YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
							modInterface:PlayButtonClick();
							modInterface:ToggleGameBlinds(false, 3);
							promptWindow:Close();
							modCharacter.CharacterProperties.CanMove = false;
							modCharacter.CharacterProperties.CanInteract = false;
							local success = remoteGameModeExit:InvokeServer("lobbyexitgame");
							if success then
								SoundService:SetListener(Enum.ListenerType.CFrame, CFrame.new(0, 1000, 0));
							else
								exitPrompt();
								modInterface:ToggleGameBlinds(true, 1);
							end
							YesClickedSignal:Disconnect();
							NoClickedSignal:Disconnect();
						end);
						NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
							modInterface:PlayButtonClick();
							promptWindow:Close();
							exitPrompt();
							YesClickedSignal:Disconnect();
							NoClickedSignal:Disconnect();
						end);
					end
				end)
			end)
		end
		
		if not UserInputService.TouchEnabled then
			button.MouseMoved:Connect(function()
				button.ImageColor3 = branchColor;
				
				if button.Name == "CreateRoom" and not debounce then
					mainFrame.CreateFrame.Visible = lobbyInfo.StageLib.SingleArena ~= true;
				end
			end)
			button.MouseLeave:Connect(function()
				checkButtonHighlight(button);
				if button.Name ~= "CreateRoom" then
					mainFrame.CreateFrame.Visible = false;
				end
			end)
		end
		button:GetPropertyChangedSignal("Visible"):Connect(function()
			checkButtonHighlight(button);
		end)
	end
	if button.Name == "CreateFrame" then
		if not UserInputService.TouchEnabled then
			button.MouseLeave:Connect(function()
				mainFrame.CreateFrame.Visible = false;
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
			UpdateInformation();
		end)
		if button.Parent.Name == "CreateFrame" then
			createHardLobbyButton = button;
		end
	end
end

modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
	if refreshStatus then Update() end;
	if gameLobby and gameLobby.BossName then
		if modSyncTime.GetWeekDay() ~= currentWeekDay then
			currentWeekDay = modSyncTime.GetWeekDay();
		end
	end
	if mainFrame.TimerLabel.Visible then
		local secsLeft = modSyncTime.TimeOfEndOfDay()-modSyncTime.GetTime();
		mainFrame.TimerLabel.Text = "Next Rewards: ".. modSyncTime.ToString(secsLeft);
	end
end);