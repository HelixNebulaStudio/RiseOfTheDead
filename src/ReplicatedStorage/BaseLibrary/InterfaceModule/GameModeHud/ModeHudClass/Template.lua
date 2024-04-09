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

	return modeHud;
end
