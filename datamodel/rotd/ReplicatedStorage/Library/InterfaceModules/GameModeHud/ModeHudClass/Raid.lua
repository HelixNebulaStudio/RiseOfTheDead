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

local ModeHudClass = shared.require(script.Parent);
--==
return function(...)
	local modeHud = ModeHudClass.new(...);
	
	local stopWatchRs = nil;
	modeHud.Soundtrack = nil;
	
	function modeHud:Update(data)
		modConfigurations.Set("AutoMarkEnemies", true);
		local gameType = data.Type;
		local gameStage = data.Stage;

		local gameLib = modGameModeLibrary.GetGameMode(gameType);
		local stageLib = gameLib and modGameModeLibrary.GetStage(gameType, gameStage);


		local headerTag = self.MainFrame.headerTag;
		local statusTag = self.MainFrame.statusTag;

		headerTag.Text = data.Header or "";
		statusTag.Text = data.Status or "";

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
		
		local classPlayer = shared.modPlayers.get(localPlayer);
		if classPlayer.IsAlive == false then
			self.Interface:ToggleGameBlinds(true, 2);
			if not self:IsSpectating() then
				self:Spectate();
			end
		end

		local stopwatchLabel = self.MainFrame.stopwatchLabel;
		if stageLib.EnableStopwatch then
			stopwatchLabel.Visible = true;

			if stopWatchRs == nil then
				stopwatchLabel.Text = "Stopwatch: Ready";
				stopWatchRs = RunService.RenderStepped:Connect(function(delta)
					if data.StopwatchFinal then
						stopwatchLabel.Text = `Run Time: {modSyncTime.FormatMs(data.StopwatchFinal *1000)}!`;
						return;
					end

					if data.StopwatchTick == nil then
						stopwatchLabel.Text = "Stopwatch: Ready";
						return;
					end

					local timeLapse = (workspace:GetServerTimeNow()-data.StopwatchTick);
					stopwatchLabel.Text = `Stopwatch: {modSyncTime.FormatMs(timeLapse *1000)}`;
				end)
			end

		else
			stopwatchLabel.Visible = false;

		end
	end
	
	return modeHud;
end