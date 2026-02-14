local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local localPlayer = game.Players.LocalPlayer;

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modGameModeLibrary = shared.require(game.ReplicatedStorage.Library.GameModeLibrary);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modMarkers = shared.require(game.ReplicatedStorage.Library.Markers);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);
local modLeaderboardService = shared.require(game.ReplicatedStorage.Library.LeaderboardService);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);
local modLeaderboardInterface = shared.require(game.ReplicatedStorage.Library.UI.LeaderboardInterface);

local templateEndScreen = script:WaitForChild("templateEndScreen");
local templateName = script:WaitForChild("templateName");
local templateScore = script:WaitForChild("templateScore");
local templateSelectionStroke = script:WaitForChild("SelectionStroke");
local templateRewardOption = script:WaitForChild("rewardOption");
local templateAvatarLabel = script:WaitForChild("avatarLabel");

local ModeHudClass = shared.require(script.Parent);

local isPlayingEndTrack: boolean, survivalEndTrack:  Sound?;
local HUD_TASK_ID = "SurvivalHudTask";
--==
return function(interface, window, frame)
	local modData = shared.require(localPlayer:WaitForChild("DataModule"));

	local modeHud = ModeHudClass.new(interface, window, frame);

	modeHud.Soundtrack = nil;
	modeHud.BossHealthBars = {};

    local deathScreenElement: InterfaceElement = interface:GetOrDefaultElement("DeathScreenElement");
	local wavePassScreenElement: InterfaceElement = interface:GetOrDefaultElement("WavePassScreen", {
        Visible = false;
		Init = false;
		SelectionStroke = templateSelectionStroke:Clone();
		ItemButtons = {};
	});
	wavePassScreenElement.ReleaseMouse = true;
	wavePassScreenElement.BoolStringWhenActive = {String="!CharacterHud"; Priority=6;};
	
	local wavePassScreenFrame = frame.WavePassScreen;
    wavePassScreenElement.OnChanged:Connect(function(k, v, ov)
        if k == "Visible" then
            wavePassScreenFrame.Visible = v;
        end
    end)

    local itemToolTip = modItemInterface.newItemTooltip();
    itemToolTip.Frame.Name = `WavePassItemToolTip`;

	local activeLeaderboard;
	local endScreen;

	local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
	task.spawn(function() 
		modAudio.Preload("DarknessMarchG", 5);
	end)
	
	function modeHud:Update(data)
		modConfigurations.Set("AutoMarkEnemies", true);
		local gameType = data.Type;
		local gameStage = data.Stage;

		local gameLib = modGameModeLibrary.GetGameMode(gameType);
		local stageLib = gameLib and modGameModeLibrary.GetStage(gameType, gameStage);

		local titleText = `{gameType}: {gameStage}`;
		local headerText = data.Header or ``;
		local descLabel = data.Status or ``;

		-- MARK: TaskListHud		
		local taskHudWindow: InterfaceWindow = interface:GetWindow("TaskListHud");
		local hudTask = taskHudWindow and taskHudWindow.Binds.getOrNewTask(HUD_TASK_ID) or nil;

		if hudTask then
			hudTask.Order = 3;
			
			local frame = hudTask.Frame;
			hudTask.Properties.TitleText = titleText;
			hudTask.Properties.HeaderText = `<font color="rgb(180, 94, 94)">{headerText}</font>`;
			hudTask.Properties.DescText = descLabel;

			local objectiveLabel = hudTask.ObjectiveLabel;
			if objectiveLabel == nil then
				objectiveLabel = taskHudWindow.Binds.GenericLabel:Clone();
				objectiveLabel.Name = "ObjectiveLabel";
				objectiveLabel.LayoutOrder = 5;
				objectiveLabel.Parent = frame:WaitForChild("Content");
				hudTask.ObjectiveLabel = objectiveLabel;
			end

			local hazardLabel = hudTask.HazardLabel;
			if hazardLabel == nil then
				hazardLabel = taskHudWindow.Binds.GenericLabel:Clone();
				hazardLabel.Name = "HazardLabel";
				hazardLabel.LayoutOrder = 6;
				hazardLabel.Parent = frame:WaitForChild("Content");
				hudTask.HazardLabel = hazardLabel;
			end

			
			if data.WaveObjective ~= false and #data.WaveObjective >0 then
				objectiveLabel.Text = `Objective {data.WaveObjective}: {data.ObjectiveDesc}` or "";
			else
				objectiveLabel.Text = "";
			end
			if #descLabel <= 0 then
				hudTask.Properties.DescText = objectiveLabel.Text;
				objectiveLabel.Text = "";
			end

			if data.WaveHazard == false or #data.WaveHazard == 0 then
				hazardLabel.Text = "";
			elseif data.WaveHazard == "None" then
				hazardLabel.Text = `No hazard this wave.`;
			else
				hazardLabel.Text = `{data.WaveHazard}: {data.HazardDesc}` or "";
			end

			objectiveLabel.Visible = #objectiveLabel.Text > 0;
			hazardLabel.Visible = #hazardLabel.Text > 0;
		end


		if data.PlayWaveStart == true then
			data.PlayWaveStart = false;
			local soundName = stageLib.WaveStartTrack;
			
			if typeof(stageLib.WaveStartTrack) == "table" then
				soundName = stageLib.WaveStartTrack[math.random(1, #stageLib.WaveStartTrack)];
			end

			task.spawn(function() 
				modAudio.Preload(soundName, 5);
				modAudio.Play(soundName, self.MainFrame);
			end)
		end
		if data.PlayWaveEnd == true then
			data.PlayWaveEnd = false;
			local soundName = stageLib.WaveEndTrack;

			if typeof(stageLib.WaveEndTrack) == "table" then
				soundName = stageLib.WaveEndTrack[math.random(1, #stageLib.WaveEndTrack)]
			end
			
			task.spawn(function() 
				modAudio.Preload(soundName, 5);
				modAudio.Play(soundName, self.MainFrame);
			end)
		end
		if data.SurvivalEnded == true then
			local soundName = stageLib.SurvivalEndedTrack;

			if typeof(stageLib.SurvivalEndedTrack) == "table" then
				soundName = stageLib.SurvivalEndedTrack[math.random(1, #stageLib.SurvivalEndedTrack)];
			end
			
			if isPlayingEndTrack == false then
				isPlayingEndTrack = true;
				task.spawn(function()
					modAudio.Preload(soundName, 5);
					survivalEndTrack = modAudio.Play(soundName, self.MainFrame);
					if data.LootPrefab ~= nil and survivalEndTrack then
						survivalEndTrack.Volume = survivalEndTrack.Volume * 0.5;
					end
					if survivalEndTrack then
						game.Debris:AddItem(survivalEndTrack, 60);
					end
				end)
			end
		else
			isPlayingEndTrack = false;
			if survivalEndTrack and game:IsAncestorOf(survivalEndTrack) then
				local track = survivalEndTrack;
				survivalEndTrack = nil;
				
				game.Debris:AddItem(track, 5);
				TweenService:Create(track, TweenInfo.new(5), {
					Volume=0;
				}):Play();
			end
		end
		if data.BossKilled == true then
			data.BossKilled = false;
			local bossKillTrack = stageLib.BossKilledTrack;
			if typeof(stageLib.BossKilledTrack) == "table" then
				bossKillTrack = stageLib.BossKilledTrack[math.random(1, #stageLib.BossKilledTrack)];
			end

			task.spawn(function() 
				modAudio.Preload(bossKillTrack, 5);
				modAudio.Play(bossKillTrack, self.MainFrame);
			end)
		end


		-- MARK: Wave Pass Screen
		if data.WavePass ~= false then
			local timerLabel = wavePassScreenFrame.timerLabel;
			timerLabel.Text = `Lock In\n{data.WavePass.TimeLeft}`;
			if data.WavePass.TimeLeft <= 5 and data.WavePass.TimeLeft % 2 == 0 then
				timerLabel.TextColor3 = Color3.fromRGB(255, 60, 60);
				modAudio.Play("ClockTick", wavePassScreenFrame);
			else
				timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
			end

			local rewardOptionsFrame = wavePassScreenFrame.RewardOptionsFrame;
			local voteEndClaimButton = wavePassScreenFrame.VoteEndClaim;
			local voteContinueButton = wavePassScreenFrame.VoteContinue;

			local rewardInfoList = data.WavePass.Rewards;
			if wavePassScreenElement.Init ~= true then
				wavePassScreenElement.Init = true;

				local sndTrack = modAudio.Play("DarknessMarchG", workspace);
				TweenService:Create(sndTrack, TweenInfo.new(4), {Volume=0}):Play();

				wavePassScreenElement.SelectionStroke.Parent = script;
				
				local playerLevel = modData.GameSave and modData.GameSave.Stats and modData.GameSave.Stats.Level or 0;

				for _, obj in ipairs(rewardOptionsFrame:GetChildren()) do
					if not obj:IsA("GuiObject") then continue end;
					game.Debris:AddItem(obj, 0);
				end
				for a, rewardInfo in ipairs(rewardInfoList) do
					local itemId = rewardInfo.ItemId;
					local itemLib = modItemsLibrary:Find(itemId);

					local newOption = templateRewardOption:Clone();
					newOption.Name = a;
					newOption.LayoutOrder = a;
					newOption.Size = UDim2.new(0, 150, 0, 150);
					TweenService:Create(newOption, TweenInfo.new(0.3), {
						Size = UDim2.new(0, 300, 0, 300);
					}):Play();
					newOption.Parent = rewardOptionsFrame;
					if a==1 then
						wavePassScreenElement.SelectionStroke.Parent = newOption;
					end

					local rewardRequireLevel = rewardInfo.Level or 0;
					local levelLabel = newOption:WaitForChild("levelLabel");
					levelLabel.Text = rewardRequireLevel > 0 and `Level {rewardInfo.Level}+` or ``;
					levelLabel.TextColor3 = playerLevel >= rewardRequireLevel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 94, 94);

					local chanceLabel = newOption:WaitForChild("chanceLabel");
					chanceLabel.Text = `{math.max(math.floor(rewardInfo.WinChance*100),1)}%`;

					local itemButtonObject = modItemInterface.newItemButton();
					itemButtonObject:SetZIndex(1);
					itemButtonObject:SetItemId(itemId);

					local newItemButton: ImageButton = itemButtonObject.ImageButton;
					newItemButton.Active = false;
					newItemButton.Interactable = false;

                    itemToolTip:BindHoverOver(newOption, function()
                        itemToolTip.Frame.Parent = interface.ScreenGui;
                        itemToolTip:Update(itemId);
                        itemToolTip:SetPosition(newOption);
                    end, 1);

					newItemButton.Name = itemId;
					newItemButton.Size = UDim2.new(1, 0, 1, 0);
					newItemButton.Parent = newOption;
					
					itemButtonObject:Update();
					newItemButton.Image = itemLib.Icon;

					if playerLevel < rewardRequireLevel then
						newOption.AutoButtonColor = false;
						newItemButton.ImageColor3 = Color3.fromRGB(100, 100, 100);
					end
					newOption.MouseButton1Click:Connect(function()
						if #rewardInfoList <= 1 then return end;
						if playerLevel < rewardRequireLevel then
							return;
						end
						interface:PlayButtonClick();
						wavePassScreenElement.SelectionStroke.Parent = newOption;
						window.Binds.FireServer("selectReward", a);

						data.WavePass.Players[tostring(localPlayer.UserId)].RewardPick = a;
						self:Update(data);
					end)
					
					if #rewardInfoList <= 1 then
						newOption.UIPadding:Destroy();
						newOption.PlayerVote.Visible = false;
						newOption.BackgroundTransparency = 1;
						wavePassScreenElement.SelectionStroke.Parent = script;
						levelLabel.Text = ``;
						chanceLabel.Text = ``;
					end
				end

				if #rewardInfoList <= 1 then
					wavePassScreenFrame.descLabel.Text = `Your reward for passing this wave!`;
				else
					wavePassScreenFrame.descLabel.Text = `Pick a reward, then end to claim your rewards or continue.`;
				end

				voteContinueButton.MouseButton1Click:Connect(function() 
					interface:PlayButtonClick();
					window.Binds.FireServer("vote", 1);

					data.WavePass.Players[tostring(localPlayer.UserId)].VotePick = 1;
					self:Update(data);
				end)
				voteEndClaimButton.MouseButton1Click:Connect(function() 
					interface:PlayButtonClick();
					window.Binds.FireServer("vote", 2);

					data.WavePass.Players[tostring(localPlayer.UserId)].VotePick = 2;
					self:Update(data);
				end)
			end

			local playerList = data.WavePass.Players;
			for userId, playerData in pairs(playerList) do
				local hasVoted = playerData.HasVoted;
				local votePick = playerData.VotePick;

				if votePick == 1 then
					game.Debris:AddItem(voteEndClaimButton.PlayerVote:FindFirstChild(userId), 0);
					local newAvatar = voteContinueButton.PlayerVote:FindFirstChild(userId) or templateAvatarLabel:Clone();
					newAvatar.Name = userId;
					task.spawn(function() 
						newAvatar.Image = shared.modPlayers.getAvatar(userId);
					end)
					newAvatar.Parent = voteContinueButton.PlayerVote;
					if hasVoted then
						newAvatar.BackgroundColor3 = Color3.fromRGB(27, 106, 23);
					else
						newAvatar.BackgroundColor3 = Color3.fromRGB(20, 20, 20);
					end

				elseif votePick == 2 then
					game.Debris:AddItem(voteContinueButton.PlayerVote:FindFirstChild(userId), 0);
					local newAvatar = voteEndClaimButton.PlayerVote:FindFirstChild(userId) or templateAvatarLabel:Clone();
					newAvatar.Name = userId;
					task.spawn(function() 
						newAvatar.Image = shared.modPlayers.getAvatar(userId);
					end)
					newAvatar.Parent = voteEndClaimButton.PlayerVote;
					if hasVoted then
						newAvatar.BackgroundColor3 = Color3.fromRGB(27, 106, 23);
					else
						newAvatar.BackgroundColor3 = Color3.fromRGB(20, 20, 20);
					end

				end

				local rewardPick = playerData.RewardPick;
				for _, rewardOption in ipairs(rewardOptionsFrame:GetChildren()) do
					if not rewardOption:IsA("GuiObject") then continue end;

					local playerVoteFrame = rewardOption:FindFirstChild("PlayerVote");
					if playerVoteFrame == nil then continue end;

					if playerVoteFrame:FindFirstChild(userId) and rewardOption.Name ~= tostring(rewardPick) then
						playerVoteFrame[userId]:Destroy();

					elseif playerVoteFrame:FindFirstChild(userId) == nil and rewardOption.Name == tostring(rewardPick) then
						local newAvatar = templateAvatarLabel:Clone();
						newAvatar.Name = userId;
						newAvatar.Size = UDim2.new(0, 40, 0, 40);
						task.spawn(function() 
							newAvatar.Image = shared.modPlayers.getAvatar(userId);
						end)
						newAvatar.Parent = playerVoteFrame;
					end
				end

			end

			local survivalRewards = modData.GetStorage("survivalrewards");
			local lootScrollFrame = wavePassScreenFrame.LootFrame.SurvivalRewards.ScrollingFrame;
			local itemButtonsCache = wavePassScreenElement.ItemButtons;

			if survivalRewards then
				for siid, storageItem in pairs(survivalRewards.Container) do
					local itemButtonObject = itemButtonsCache[siid] or modItemInterface.newItemButton(storageItem.ItemId);
					itemButtonObject:SetZIndex(1);
					
					local newItemButton: ImageButton = itemButtonObject.ImageButton;
					if itemButtonsCache[siid] == nil then
						itemButtonsCache[siid] = itemButtonObject;

						itemToolTip:BindHoverOver(newItemButton, function()
							itemToolTip.Frame.Parent = interface.ScreenGui;
							itemToolTip:Update(storageItem);
							itemToolTip:SetPosition(newItemButton);
						end);
					end

					newItemButton.Name = siid;
					newItemButton.Size = UDim2.new(0, 100, 0, 100);
					newItemButton.LayoutOrder = storageItem.Index;
					newItemButton.Parent = lootScrollFrame;
					
					itemButtonObject:Update(storageItem);
				end
			end

			
			local nextRewardsScrollFrame = wavePassScreenFrame.LootFrame.NextRewards.ScrollingFrame;
			if data.IsHard and stageLib.HardRewardId then
				local rewardsLib = modRewardsLibrary:Find(stageLib.HardRewardId);
				local nextRewardInfoList = {};

				if rewardsLib and rewardsLib.Rewards then
					local rewardsList = rewardsLib.Rewards;
					local wave = data.Wave+1;
					
					local matchWave = nil;
					for a=1, #rewardsList do
						local rewardInfo = rewardsList[a];
						if matchWave == nil and rewardInfo.Wave >= wave then
							matchWave = rewardInfo.Wave;
						end
						if rewardInfo.Wave ~= matchWave then continue end;
						table.insert(nextRewardInfoList, rewardInfo);
					end
				end
				
				for a=1, #nextRewardInfoList do
					local rewardInfo = nextRewardInfoList[a];
					local itemId = rewardInfo.ItemId;
					
					local itemButtonObject = itemButtonsCache[itemId] or modItemInterface.newItemButton();
					itemButtonObject:SetItemId(itemId);

					local newItemButton = itemButtonObject.ImageButton;

					if itemButtonsCache[itemId] == nil then
						itemButtonsCache[itemId] = itemButtonObject;

						itemToolTip:BindHoverOver(newItemButton, function()
							itemToolTip.Frame.Parent = interface.ScreenGui;
							itemToolTip:Update(itemId);
							itemToolTip:SetPosition(newItemButton);
						end);
					end

					newItemButton.Name = itemId;
					newItemButton.Size = UDim2.new(0, 100, 0, 100);
					newItemButton.Parent = nextRewardsScrollFrame;
					
					itemButtonObject:Update(itemId);
				end

				if #nextRewardInfoList > 0 then
					local newXSize = (#nextRewardInfoList * 100) + 40;
					wavePassScreenFrame.LootFrame.SurvivalRewards.Size = UDim2.new(1, -newXSize, 0, 120);
					wavePassScreenFrame.LootFrame.NextRewards.Visible = true;
				else
					wavePassScreenFrame.LootFrame.SurvivalRewards.Size = UDim2.new(1, 0, 0, 120);
					wavePassScreenFrame.LootFrame.NextRewards.Visible = false;
				end
			end

			if wavePassScreenElement.Visible ~= true then
				wavePassScreenElement.Visible = true;
				interface:RefreshInterfaces();
			end

		else
			itemToolTip.Frame.Visible = false;
			itemToolTip.Frame.Parent = script;
			if wavePassScreenElement.Init then
				modAudio.Play(math.random(1,2) == 1 and "StorageItemDrop" or "StorageItemPickup", wavePassScreenFrame);
				wavePassScreenElement.Init = false;
			end

			for _, itemButton in pairs(wavePassScreenElement.ItemButtons) do
				itemButton:Destroy();
			end
			table.clear(wavePassScreenElement.ItemButtons);

			if wavePassScreenElement.Visible ~= false then
				wavePassScreenElement.Visible = false;
				interface:RefreshInterfaces();
			end
		end

		-- MARK: EndScreen
		local statsBoard = data.StatsCount or data.Stats;
		if statsBoard ~= nil then
			if statsBoard ~= false then
				if endScreen == nil then
					endScreen = templateEndScreen:Clone();

					if playerClass.HealthComp.IsDead then
						endScreen.Parent = deathScreenElement.Frame;
					else
						endScreen.Parent = frame.EndScreen;
					end

					local waveLabel = endScreen:WaitForChild("waveLabel");
					waveLabel.Text = data.LastWave and ("Survived to wave $wave..."):gsub("$wave", data.LastWave or "unknown") or "Survival Complete";
					local titleImage = endScreen:WaitForChild("TitleImage");
					titleImage.Image = stageLib.TitleImage;

					local nameList = endScreen:WaitForChild("scoreboard"):WaitForChild("names");
					local scoreList = endScreen:WaitForChild("scoreboard"):WaitForChild("score");

					local ordering = {};
					for name, kills in pairs(statsBoard) do
						table.insert(ordering, {Name=name; Kills=kills});
					end
					table.sort(ordering, function(a, b) return a.Kills > b.Kills; end)
					local orderIndex = {};
					for a=1, #ordering do
						orderIndex[ordering[a].Name] = a;
					end

					for name, kills in pairs(statsBoard) do
						local newName = templateName:Clone();
						newName.LayoutOrder = orderIndex[name];
						newName.Text = name;
						newName.Parent = nameList;
						local newScore = templateScore:Clone();
						newScore.LayoutOrder = orderIndex[name];
						newScore.Text = kills;
						newScore.Parent = scoreList;

						if game.Players:FindFirstChild(name) == nil then
							newName.TextColor3 = Color3.fromRGB(200, 80, 80);
							newScore.TextColor3 = Color3.fromRGB(200, 80, 80);
						end
					end

					if stageLib.LeaderboardKeyTable then
						modLeaderboardService.ClientGamemodeBoardRequest(gameType, gameStage);

						local keyTable = {
							StatName=stageLib.LeaderboardDataKey;
						};

						for key, data in pairs(stageLib.LeaderboardKeyTable) do
							if data.Folder == "AllTimeStats" then
								keyTable.AllTimeTableKey = key;
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

						if activeLeaderboard == nil then
							activeLeaderboard = modLeaderboardInterface.new(keyTable);
							activeLeaderboard:AddToggleButton();
						end
						activeLeaderboard.Frame.AnchorPoint = Vector2.new(0, 1);
						activeLeaderboard.Frame.Position = UDim2.new(0, 20, 1, -60);
						activeLeaderboard.Frame.Size = UDim2.new(0, 400, 0.6, 0);

						activeLeaderboard.ToggleButton.AnchorPoint = Vector2.new(0, 1);
						activeLeaderboard.ToggleButton.Position = UDim2.new(0, 20, 1, -20);

						if playerClass.HealthComp.IsDead then
							activeLeaderboard.Frame.Parent = deathScreenElement.Frame;
							activeLeaderboard.ToggleButton.Parent = deathScreenElement.Frame;
						else
							activeLeaderboard.Frame.Parent = frame.EndScreen;
							activeLeaderboard.ToggleButton.Parent = frame.EndScreen;
						end
					end
				end
			end
		else
			if activeLeaderboard then
				activeLeaderboard:Destroy();
				activeLeaderboard = nil;
			end

			game.Debris:AddItem(endScreen, 0);
			endScreen = nil;
		end

		if data.LootPrefab ~= nil and data.LootPrefab ~= false then
			local point = data.LootPrefab and data.LootPrefab.PrimaryPart and data.LootPrefab.PrimaryPart.CFrame.p;
			if point then
				local markerLabel = `{gameStage} Loot`;
				if data.LootPrefab.Name == "WavePassCrate" then
					markerLabel = "Survival Rewards";
				end
				modMarkers.SetMarker("LootPrefab", point, markerLabel, modMarkers.MarkerTypes.Waypoint);

				if typeof(data.LootPrefab) == "Instance" then
					local dropTier = data.LootPrefab:GetAttribute("Tier");

					if dropTier == 3 then
						modMarkers.SetColor("LootPrefab", Color3.fromRGB(101, 59, 169));
					elseif dropTier == 2 then
						modMarkers.SetColor("LootPrefab", Color3.fromRGB(51, 102, 204));
					else
						modMarkers.SetColor("LootPrefab", Color3.fromRGB(200, 200, 200));
					end
				end
			end
		else
			modMarkers.ClearMarker("LootPrefab");
		end

		if data.SupplyStation ~= nil and data.SupplyStation ~= false then
			local point = data.SupplyStation and data.SupplyStation.PrimaryPart and data.SupplyStation.PrimaryPart.CFrame.p;
			if point then
				modMarkers.SetMarker("SupplyStation", point, "Resupply Station", modMarkers.MarkerTypes.Waypoint);

				modMarkers.SetColor("SupplyStation", Color3.fromRGB(207, 164, 120));
			end
		else
			modMarkers.ClearMarker("SupplyStation");
		end
		
		--== Objective Props;
		if data.HookEntity ~= nil and typeof(data.HookEntity) == "table" then
			for a=1, #data.HookEntity do
				local prefab = data.HookEntity[a];
				interface:FireEvent("TryHookEntity", prefab, 600);

				if prefab:GetAttribute("MarketSet") ~= true then
					prefab:SetAttribute("MarketSet", true);

					local markerName = prefab.Name;

					modMarkers.SetMarker(markerName, prefab, markerName, modMarkers.MarkerTypes.Object);
					modMarkers.SetColor(markerName, Color3.fromRGB(36, 140, 49));

					prefab.Destroying:Connect(function()
						modMarkers.ClearMarker(markerName);
					end)
				end
			end
		end

		--== Objective Boss;
		if typeof(data.BossList) == "table" then
			for a=1, #data.BossList do
				--self.Interface.modEntityHealthHudInterface.TryHookEntity(data.BossList[a], 300);
			end
		end
		
		-- Spectator;
		local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
		if playerClass.HealthComp.IsDead then
			modClientGuis.toggleGameBlinds(true, 2);
			if not self:IsSpectating() then
				self:Spectate();
			end
		end
	end
	
	modeHud.OnActiveChanged:Connect(function(isActive)
		local taskHudWindow: InterfaceWindow = interface:GetWindow("TaskListHud");
		if taskHudWindow == nil then return end;

		if isActive then
			taskHudWindow.Binds.getOrNewTask(HUD_TASK_ID, true);
		else
			taskHudWindow.Binds.destroyHudTask(HUD_TASK_ID);
		end
	end)

	return modeHud;
end