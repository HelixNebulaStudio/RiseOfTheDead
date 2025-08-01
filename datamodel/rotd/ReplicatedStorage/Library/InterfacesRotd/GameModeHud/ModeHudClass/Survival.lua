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

local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);
local modLeaderboardInterface = shared.require(game.ReplicatedStorage.Library.UI.LeaderboardInterface);

local templateEndScreen = script:WaitForChild("templateEndScreen");
local templateName = script:WaitForChild("templateName");
local templateScore = script:WaitForChild("templateScore");

local ModeHudClass = shared.require(script.Parent);

local survivalFailTrack: Sound?;
--==
return function(interface, window, frame)
	local modeHud = ModeHudClass.new(interface, window, frame);

	modeHud.Soundtrack = nil;
	modeHud.BossHealthBars = {};

    local deathScreenElement: InterfaceElement = interface:GetOrDefaultElement("DeathScreenElement");
	
	local activeLeaderboard;
	local endScreen;
	local nextRewardItemButton;
	
	function modeHud:Update(data)
		modConfigurations.Set("AutoMarkEnemies", true);
		local gameType = data.Type;
		local gameStage = data.Stage;

		local gameLib = modGameModeLibrary.GetGameMode(gameType);
		local stageLib = gameLib and modGameModeLibrary.GetStage(gameType, gameStage);


		local statusTag = self.MainFrame.statusTag;
		local waveTag = self.MainFrame.waveTag;

		local waveObjectiveTag = self.MainFrame.waveObjectiveTag;
		local waveHazardTag = self.MainFrame.waveHazardTag;

		waveObjectiveTag.Text = data.WaveObjective or "";
		waveHazardTag.Text = data.WaveHazard or "";

		statusTag.Text = data.Status or "";
		waveTag.Text = data.Wave or 1;

		if data.PlayWaveStart == true then
			local soundName = stageLib.WaveStartTrack;
			
			if typeof(stageLib.WaveStartTrack) == "table" then
				soundName = stageLib.WaveStartTrack[math.random(1, #stageLib.WaveStartTrack)];
			end

			modAudio.Preload(soundName, 5);
			modAudio.Play(soundName, script.Parent);
		end
		if data.PlayWaveEnd == true then
			local soundName = stageLib.WaveEndTrack;

			if typeof(stageLib.WaveEndTrack) == "table" then
				soundName = stageLib.WaveEndTrack[math.random(1, #stageLib.WaveEndTrack)]
			end
			
			modAudio.Preload(soundName, 5);
			modAudio.Play(soundName, script.Parent);
		end
		if data.SurvivalFailed == true then
			local soundName = stageLib.SurvivalFailedTrack;

			if typeof(stageLib.SurvivalFailedTrack) == "table" then
				soundName = stageLib.SurvivalFailedTrack[math.random(1, #stageLib.SurvivalFailedTrack)];
			end
			
			modAudio.Preload(soundName, 5);
			survivalFailTrack = modAudio.Play(soundName, script.Parent);
			if survivalFailTrack then
				game.Debris:AddItem(survivalFailTrack, 60);
			end
		else
			if survivalFailTrack and game:IsAncestorOf(survivalFailTrack) then
				local track = survivalFailTrack;
				survivalFailTrack = nil;
				
				game.Debris:AddItem(track, 5);
				TweenService:Create(track, TweenInfo.new(5), {
					Volume=0;
				}):Play();
			end
		end
		if data.BossKilled == true then
			local bossKillTrack = stageLib.BossKilledTrack;
			if typeof(stageLib.BossKilledTrack) == "table" then
				bossKillTrack = stageLib.BossKilledTrack[math.random(1, #stageLib.BossKilledTrack)];
			end

			modAudio.Preload(bossKillTrack, 5);
			modAudio.Play(bossKillTrack, script.Parent);
		end


		-- MARK: Show Next Reward
		if data.IsHard and stageLib.HardRewardId then
			local nextRewardFrame = self.MainFrame.NextReward; 
			if data.GameState == "Intermission" then

				local rewardsLib = modRewardsLibrary:Find(stageLib.HardRewardId);
				if rewardsLib and rewardsLib.Rewards then
					local rewardsList = rewardsLib.Rewards;
					local wave = data.Wave+1;
					
					local nextRewardInfo = nil;

					for a=1, #rewardsList do
						local rewardInfo = rewardsList[a];
						if rewardInfo.Wave >= wave then
							nextRewardInfo = rewardInfo;
							break;
						end
					end
	
					if nextRewardInfo then
						local itemId = nextRewardInfo.ItemId;
						local itemLib = modItemsLibrary:Find(itemId);
						nextRewardFrame.rewardLabel.Text = `<font size="10">Next Reward</font>\n{itemLib.Name} drops after wave {nextRewardInfo.Wave}`;

						local itemButtonObject = nextRewardItemButton or modItemInterface.newItemButton();
						itemButtonObject:SetItemId(itemId);

						nextRewardItemButton = itemButtonObject;
						local newItemButton = itemButtonObject.ImageButton;

						newItemButton.Name = itemId;
						newItemButton.Size = UDim2.new(0, 80, 0, 80);
						newItemButton.Parent = nextRewardFrame;
						
						itemButtonObject:Update();
						newItemButton.Image = itemLib.Icon;

						if nextRewardFrame:GetAttribute("Hidden") == true then
							nextRewardFrame:SetAttribute("Hidden", false);

							TweenService:Create(nextRewardFrame, TweenInfo.new(1), {
								Position=UDim2.new(0.5, 0, 0, 140);
							}):Play();
						end
					end
				end

			else
				if nextRewardFrame:GetAttribute("Hidden") == false then
					nextRewardFrame:SetAttribute("Hidden", true);

					TweenService:Create(nextRewardFrame, TweenInfo.new(1), {
						Position=UDim2.new(0.5, 0, 0, -140);
					}):Play();
				end

			end
		end


		-- MARK: EndScreen
		local statsBoard = data.StatsCount or data.Stats;
		if statsBoard ~= nil then
			if statsBoard ~= false then
				if endScreen == nil then
					endScreen = templateEndScreen:Clone();
					endScreen.Parent = deathScreenElement.Frame;

					task.delay(60, function()
						game.Debris:AddItem(endScreen, 0);
						endScreen = nil;
					end)


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
						activeLeaderboard.Frame.Parent = endScreen;
						activeLeaderboard.Frame.AnchorPoint = Vector2.new(0, 0.5);
						activeLeaderboard.Frame.Position = UDim2.new(0, 20, 0.5, 0);
						activeLeaderboard.Frame.Size = UDim2.new(0, 400, 0.6, 0);

						activeLeaderboard.ToggleButton.Parent = endScreen;
						activeLeaderboard.ToggleButton.Position = UDim2.new(0, 20, 0, 65);
					end
				end
			end
		end

		if data.LootPrefab ~= nil and data.LootPrefab ~= false then
			local point = data.LootPrefab and data.LootPrefab.PrimaryPart and data.LootPrefab.PrimaryPart.CFrame.p;
			if point then
				modMarkers.SetMarker("LootPrefab", point, gameStage.." Loot", modMarkers.MarkerTypes.Waypoint);

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
				interface:FireEvent("TryHookEntity", prefab, 300);

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
				self.Interface.modEntityHealthHudInterface.TryHookEntity(data.BossList[a], 300);
			end
		end
		
		-- Spectator;
		local classPlayer = shared.modPlayers.get(localPlayer);
		if classPlayer.IsAlive == false then
			self.Interface:ToggleGameBlinds(true, 2);
			if not self:IsSpectating() then
				self:Spectate();
			end
		end
	end
	
	return modeHud;
end