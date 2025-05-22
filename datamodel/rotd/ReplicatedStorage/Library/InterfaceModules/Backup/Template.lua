local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;
local modData = shared.require(localPlayer:WaitForChild("DataModule"));
local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modRemotesManager = shared.require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modPlayers = shared.require(game.ReplicatedStorage.Library.Players);

local remotes = game.ReplicatedStorage.Remotes;
	
local windowFrameTemplate = script:WaitForChild("StatusBars");

--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);
	
	local windowFrame = windowFrameTemplate:Clone();
	windowFrame.Parent = modInterface.MainInterface;

	local window = Interface.NewWindow("StatusWindow", windowFrame);
	
	--Interface.Garbage:Tag();
	
	return Interface;
end;

return Interface;