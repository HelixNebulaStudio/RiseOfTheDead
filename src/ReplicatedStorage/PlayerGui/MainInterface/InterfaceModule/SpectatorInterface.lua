local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local localplayer = game.Players.LocalPlayer;
local modData = require(localplayer:WaitForChild("DataModule"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local remoteGameModeExit = modRemotesManager:Get("GameModeExit");
	
local specFrame = script.Parent.Parent:WaitForChild("SpectatorMenu");
local leaveButton = specFrame:WaitForChild("LeaveButton");

--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);

	local window = Interface.NewWindow("SpectatorWindow", specFrame);
	--window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1.5, 0));
	
	return Interface;
end;

leaveButton.MouseMoved:Connect(function()
	leaveButton.ImageColor3 = modBranchConfigs.CurrentBranch.Color;
end)
leaveButton.MouseLeave:Connect(function()
	leaveButton.ImageColor3 = Color3.fromRGB(255,255,255);
end)
leaveButton.MouseButton1Click:Connect(function()
	local promptWindow = Interface:PromptQuestion("You are about to leave this world", "Are you sure you want to leave?");
	local YesClickedSignal, NoClickedSignal;
	
	local function exitPrompt()
		Interface:ToggleGameBlinds(true, 1);
	end
	
	YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
		Interface:PlayButtonClick();
		Interface:ToggleGameBlinds(false, 3);
		promptWindow:Close();
		local success = remoteGameModeExit:InvokeServer();
		if success then
			
		else
			exitPrompt();
			Interface:ToggleGameBlinds(true, 1);
		end
		YesClickedSignal:Disconnect();
		NoClickedSignal:Disconnect();
	end);
	NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
		Interface:PlayButtonClick();
		promptWindow:Close();
		exitPrompt();
		YesClickedSignal:Disconnect();
		NoClickedSignal:Disconnect();
	end);
end)


function Interface.Update()

end

function Interface.disconnect()
	
end

script.AncestryChanged:Connect(function(c, p)
	if c == script and p == nil and Interface.disconnect then
		Interface.disconnect();
	end
end)
return Interface;