local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modGameModeLibrary = shared.require(game.ReplicatedStorage.Library.GameModeLibrary);

local ModeHudClass = shared.require(script.Parent);
--==
return function(interface, window, frame)
	local modeHud = ModeHudClass.new(interface, window, frame);
	
	modeHud.Soundtrack = nil;
	
	function modeHud:Update(data)
		local gameType = data.Type;
		local gameStage = data.Stage;
		local room = data.Room;

		local gameLib = modGameModeLibrary.GetGameMode(gameType);
		local _stageLib = gameLib and modGameModeLibrary.GetStage(gameType, gameStage);

		local bossNameTag = self.MainFrame.bossName;
		local statusTag = self.MainFrame.status;

		bossNameTag.Text = gameStage;
		bossNameTag.TextColor3 = room.IsHard and Color3.fromRGB(229, 93, 83) or Color3.fromRGB(255, 255, 255);

		if room.State == 3 then
			statusTag.Text = "";

			if room.BossPrefabs then
				for a=1, #room.BossPrefabs do
    				interface:FireEvent("TryHookEntity", room.BossPrefabs[a], 600);
				end
			end

		elseif room.State == 4 then
			if room.EndTime then
				local timeRemaining = math.floor(room.EndTime - modSyncTime.GetTime());
				statusTag.Text = "Room is closing in "..math.clamp(timeRemaining, 0, 30).." seconds..";
				
				if modeHud.Soundtrack then
					local sound = modeHud.Soundtrack;
					modeHud.Soundtrack = nil;
					TweenService:Create(sound, TweenInfo.new(5), {Volume=0}):Play();
					Debugger.Expire(sound, 5);
				end
			end

		end
		
	end
	
	return modeHud;
end