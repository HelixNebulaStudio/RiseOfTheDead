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


local templateMainFrame = script:WaitForChild("mainFrame");

--== Script;
function Interface.init(modInterfaceBase)
	setmetatable(Interface, modInterfaceBase);

	--local mainFrame = templateMainFrame:Clone();
	--mainFrame.Parent = Interface.ScreenGui;
	
	--local window = Interface.NewWindow("Window", mainFrame);
	--window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1.5, 0));
	--window.OnWindowToggle:Connect(function(visible)
	--	if visible then
	--		Interface:HideAll{[window.Name]=true;};
	--		Interface.Update();
	--	end
	--end)
	
	--Interface.Garbage:Tag();

	function Interface.Update()

	end
	
	return Interface;
end;

--Interface.Garbage is only initialized after .init();
return Interface;
