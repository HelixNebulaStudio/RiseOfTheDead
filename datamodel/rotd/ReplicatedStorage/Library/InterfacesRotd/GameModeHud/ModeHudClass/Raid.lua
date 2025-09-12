local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local localPlayer = game.Players.LocalPlayer;

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modGameModeLibrary = shared.require(game.ReplicatedStorage.Library.GameModeLibrary);
local modFormatNumber = shared.require(game.ReplicatedStorage.Library.FormatNumber);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modMarkers = shared.require(game.ReplicatedStorage.Library.Markers);

local HUD_TASK_ID = "RaidHudTask";

local ModeHudClass = shared.require(script.Parent);
--==
return function(interface: InterfaceInstance, window, frame)
	local modeHud = ModeHudClass.new(interface, window, frame);
	
	local stopWatchRs = nil;
	modeHud.Soundtrack = nil;
	
	function modeHud:Update(data)
		local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);

		modConfigurations.Set("AutoMarkEnemies", true);
		local gameType = data.Type;
		local gameStage = data.Stage;

		local gameLib = modGameModeLibrary.GetGameMode(gameType);
		local stageLib = gameLib and modGameModeLibrary.GetStage(gameType, gameStage);

		local titleText = `{gameType}: {gameStage}`;
		local headerText = data.Header or ``;
		local descLabel = data.Status or ``;

		if self.Soundtrack == nil then
			modAudio.Preload(stageLib.Soundtrack, 5);
			self.Soundtrack = modAudio.Play(stageLib.Soundtrack, script.Parent);
			if self.Soundtrack then
				self.Soundtrack.Volume = 0;
			end
		end

		if data.NextStageSound == true then
			modAudio.Play("MissionUpdated");
		end

		if data.PlayMusic == true and not self.IsPlaying then
			self.Soundtrack.TimePosition = 0;
			TweenService:Create(self.Soundtrack, TweenInfo.new(5), {Volume=0.5}):Play();
			self.IsPlaying = true;

		elseif data.PlayMusic == false and self.IsPlaying then
			TweenService:Create(self.Soundtrack, TweenInfo.new(5), {Volume=0}):Play();
			self.IsPlaying = false;

		end

		if data.LootPrefab ~= nil and data.LootPrefab ~= false then
			local point = data.LootPrefab and data.LootPrefab:GetPivot().Position;
			if point then
				modMarkers.SetMarker("LootPrefab", point, gameStage.." Loot", modMarkers.MarkerTypes.Waypoint);
				modMarkers.SetColor("LootPrefab", Color3.fromRGB(55, 234, 181));
			end
		else
			modMarkers.ClearMarker("LootPrefab");
		end
		

		local taskHudWindow: InterfaceWindow = interface:GetWindow("TaskListHud");
		local raidHudTask = taskHudWindow and taskHudWindow.Binds.getOrNewTask(HUD_TASK_ID) or nil;

		if raidHudTask then
			raidHudTask.Order = 3;
			
			local frame = raidHudTask.Frame;
			raidHudTask.Properties.TitleText = titleText;
			raidHudTask.Properties.HeaderText = headerText;
			raidHudTask.Properties.DescText = descLabel;

			local stopwatchLabel = raidHudTask.StopwatchLabel;
			if stopwatchLabel == nil then
				stopwatchLabel = taskHudWindow.Binds.GenericLabel:Clone();
				stopwatchLabel.Name = "StopwatchLabel";
				stopwatchLabel.LayoutOrder = 5;
				stopwatchLabel.Parent = frame:WaitForChild("Content");
				raidHudTask.StopwatchLabel = stopwatchLabel;
			end
			
			if stopwatchLabel then
				if stageLib.EnableStopwatch then
					stopwatchLabel.Visible = true;

					if stopWatchRs == nil then
						stopwatchLabel.Text = "00:00.000";
						stopWatchRs = RunService.RenderStepped:Connect(function(delta)
							if data.StopwatchFinal then
								stopwatchLabel.Text = `Final Time: {modSyncTime.FormatMs(data.StopwatchFinal *1000)}!`;
								return;
							end

							if data.StopwatchTick == nil then
								stopwatchLabel.Text = "00:00.000";
								return;
							end

							local timeLapse = (workspace:GetServerTimeNow()-data.StopwatchTick);
							stopwatchLabel.Text = `{modSyncTime.FormatMs(timeLapse *1000)}`;
						end)
					end

				else
					stopwatchLabel.Visible = false;

				end
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