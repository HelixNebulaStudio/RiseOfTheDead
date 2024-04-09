local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local localPlayer = game.Players.LocalPlayer;

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modGameModeLibrary = require(game.ReplicatedStorage.Library.GameModeLibrary);
local modFormatNumber = require(game.ReplicatedStorage.Library.FormatNumber);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

local templateLabel = script:WaitForChild("label");

local ModeHudClass = require(script.Parent);
--==
return function(...)
	local modeHud = ModeHudClass.new(...);

	modeHud.Soundtrack = nil;
	
	function modeHud:Update(data)
		modConfigurations.Set("AutoMarkEnemies", true);
		local gameType = data.Type;
		local gameStage = data.Stage;

		local gameLib = modGameModeLibrary.GetGameMode(gameType);
		local stageLib = gameLib and modGameModeLibrary.GetStage(gameType, gameStage);

		if self.Soundtrack == nil then
			self.Soundtrack = modAudio.Play(stageLib.Soundtrack, script.Parent);
			self.Soundtrack.Volume = 0;
		end

		local labelsList = self.MainFrame.Labels;
		if data.TimeLimit then
			local timeLimitLabel = labelsList:FindFirstChild("TimeLimitLabel")
			if timeLimitLabel == nil then
				timeLimitLabel = templateLabel:Clone();
				timeLimitLabel.Name = "TimeLimitLabel";
				timeLimitLabel.Parent = labelsList;

			end

			local timeLeft = math.clamp(data.TimeLimit-modSyncTime.GetTime(), 0, 300);
			timeLimitLabel.Text = modSyncTime.ToString(timeLeft);
			timeLimitLabel.TextColor3 = timeLeft <= 0 and Color3.fromRGB(144, 70, 70) or Color3.fromRGB(255,255,255);

			if math.fmod(timeLeft, 60) == 0 then
				modAudio.Play("Sonar", script.Parent);
			end
		end
		
		local classPlayer = shared.modPlayers.Get(localPlayer);
		if classPlayer.IsAlive == false then
			self.Interface:ToggleGameBlinds(true, 2);
			if not self:IsSpectating() then
				self:Spectate();
			end
		end
	end

	return modeHud;
end
