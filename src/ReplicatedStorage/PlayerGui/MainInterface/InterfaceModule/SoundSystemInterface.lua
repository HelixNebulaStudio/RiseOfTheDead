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
local remoteSafehomeRequest = modRemotesManager:Get("SafehomeRequest");
	
local mainFrame = script.Parent.Parent:WaitForChild("SafehomeSoundSystem");

mainFrame:WaitForChild("TitleFrame"):WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
	Interface:CloseWindow("SafehomeSoundSystem");
end)
--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);

	local window = Interface.NewWindow("SafehomeSoundSystem", mainFrame);
	window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1.5, 0));
	window:AddCloseButton(mainFrame);
	window.OnWindowToggle:Connect(function(visible, toolHandler)
		if visible and not modBranchConfigs.IsWorld("Safehome") then window:Close(); return; end
	end)
	
	
	local inputBox = mainFrame:WaitForChild("InputFrame"):WaitForChild("TextBox");
	
	mainFrame:WaitForChild("playButton").MouseButton1Click:Connect(function()
		local rPacket = remoteSafehomeRequest:InvokeServer("playSound", {SoundId=inputBox.Text;});
	end)
	
	mainFrame:WaitForChild("playSpeakersButton").MouseButton1Click:Connect(function()
		local rPacket = remoteSafehomeRequest:InvokeServer("playSound", {SoundId=inputBox.Text; Object=Interface.Object;});
	end)
	
	mainFrame:WaitForChild("togglePartyLightsButton").MouseButton1Click:Connect(function()
		local rPacket = remoteSafehomeRequest:InvokeServer("togglePartyLights", {Object=Interface.Object;});
	end)
	Interface.Garbage:Tag(workspace.ChildAdded:Connect(function(child)
		if child.Name == "GlobalSoundSystem" then
			local function update()
				if child.Playing then
					mainFrame.playButton.Text = "Stop";
					mainFrame.playSpeakersButton.Text = "Stop On Speakers";
				else
					mainFrame.playButton.Text = "Play";
					mainFrame.playSpeakersButton.Text = "Play On Speakers";
				end
			end
			child:GetPropertyChangedSignal("Playing"):Connect(update)
			update();
		end
	end));
	
	return Interface;
end;

function Interface.Update()

end

--Interface.Garbage is only initialized after .init();
return Interface;
