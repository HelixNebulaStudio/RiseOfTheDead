local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local localPlayer = game.Players.LocalPlayer;

local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);

local interfacePackage = {
    Type = "Character";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));
    local remoteSafehomeRequest = modRemotesManager:Get("SafehomeRequest");

    local mainFrame = script:WaitForChild("SafehomeSoundSystem"):Clone();
    mainFrame.Parent = interface.ScreenGui;

	local window: InterfaceWindow = interface:NewWindow("SafehomeSoundSystem", mainFrame);
	window:SetClosePosition(UDim2.new(0.5, 0, -1.5, 0), UDim2.new(0.5, 0, 0.5, 0));
	window:AddCloseButton(mainFrame);

    local binds = window.Binds;
    binds.InteractPart = nil;

    mainFrame:WaitForChild("TitleFrame"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
        window:Close();
    end)

	window.OnToggle:Connect(function(visible, toolHandler)
		if visible and not modBranchConfigurations.IsWorld("Safehome") then 
            window:Close();
            return;
        end
	end)
	

	local inputBox = mainFrame:WaitForChild("InputFrame"):WaitForChild("TextBox");
	
	mainFrame:WaitForChild("playButton").MouseButton1Click:Connect(function()
		local rPacket = remoteSafehomeRequest:InvokeServer("playSound", {
            SoundId=inputBox.Text;
        });
	end)
	
	mainFrame:WaitForChild("playSpeakersButton").MouseButton1Click:Connect(function()
		local rPacket = remoteSafehomeRequest:InvokeServer("playSound", {
            SoundId=inputBox.Text;
            Object=binds.InteractPart;
        });
	end)
	
	mainFrame:WaitForChild("togglePartyLightsButton").MouseButton1Click:Connect(function()
		local rPacket = remoteSafehomeRequest:InvokeServer("togglePartyLights", {
            Object=binds.InteractPart;
        });
	end)

	interface.Garbage:Tag(workspace.ChildAdded:Connect(function(child)
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

end

return interfacePackage;

