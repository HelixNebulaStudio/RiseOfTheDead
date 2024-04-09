local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local localPlayer = game.Players.LocalPlayer;

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modGameModeLibrary = require(game.ReplicatedStorage.Library.GameModeLibrary);
local modFormatNumber = require(game.ReplicatedStorage.Library.FormatNumber);

local ModeHudClass = require(script.Parent);
--==
return function(...)
	local modeHud = ModeHudClass.new(...);
	
	modeHud.Soundtrack = nil;
	
	local prevData;
	function modeHud:Update(data)
		prevData = data;
		
		local gameType = data.Type;
		local gameStage = data.Stage;
		local room = data.Room;

		local gameLib = modGameModeLibrary.GetGameMode(gameType);
		local stageLib = gameLib and modGameModeLibrary.GetStage(gameType, gameStage);

		local bossNameTag = self.MainFrame.bossName;
		local statusTag = self.MainFrame.status;

		bossNameTag.Text = gameStage;
		bossNameTag.TextColor3 = room.IsHard and Color3.fromRGB(229, 93, 83) or Color3.fromRGB(255, 255, 255);

		if room.State == 3 then
			statusTag.Text = "";

			if room.BossPrefabs then
				for a=1, #room.BossPrefabs do
					self.Interface.modEntityHealthHudInterface.TryHookEntity(room.BossPrefabs[a], 600);
				end
			end

		elseif room.State == 4 then
			if data.EndTime then
				statusTag.Text = "Room is closing in "..math.clamp(math.floor(data.EndTime-modSyncTime.GetTime()), 0, 30).." seconds..";
			end

		end
		
	end
	
	modeHud.Garbage:Tag(modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
		local data = prevData;
		local statusTag = modeHud.MainFrame.status;

		if data.Room.State >= 4 then
			if data.EndTime then
				statusTag.Text = "Room is closing in "..math.clamp(math.floor(data.EndTime-modSyncTime.GetTime()), 0, 30).." seconds..";
				if modeHud.Soundtrack then
					local sound = modeHud.Soundtrack;
					modeHud.Soundtrack = nil;
					TweenService:Create(sound, TweenInfo.new(5), {Volume=0}):Play();
					Debugger.Expire(sound, 5);
				end
			end
		end
	end))
	
	return modeHud;
end
