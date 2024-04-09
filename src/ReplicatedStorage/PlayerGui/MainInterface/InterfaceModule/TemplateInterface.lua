local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local localplayer = game.Players.LocalPlayer;
local modData = require(localplayer:WaitForChild("DataModule"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local remotes = game.ReplicatedStorage.Remotes;
local remoteGameModeExit = modRemotesManager:Get("GameModeExit");
	
local mainFrame = script.Parent.Parent:WaitForChild("SpectatorMenu");

--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);

	local window = Interface.NewWindow("TemplateInterface", mainFrame);
	--window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1.5, 0));
	
	--Interface.Garbage:Tag();
	
	return Interface;
end;

function Interface.Update()

end

--Interface.Garbage is only initialized after .init();
return Interface;
