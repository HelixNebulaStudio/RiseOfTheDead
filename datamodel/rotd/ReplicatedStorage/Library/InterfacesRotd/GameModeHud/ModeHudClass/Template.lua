local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local localPlayer = game.Players.LocalPlayer;

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modGameModeLibrary = shared.require(game.ReplicatedStorage.Library.GameModeLibrary);
local modFormatNumber = shared.require(game.ReplicatedStorage.Library.FormatNumber);

local ModeHudClass = shared.require(script.Parent);
--==
return function(interface, window, frame)
	local modeHud = ModeHudClass.new(interface, window, frame);

	return modeHud;
end