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
	window.DisableInteractables = true;
	window:SetClosePosition(UDim2.new(0.5, 0, -1.5, 0), UDim2.new(0.5, 0, 0.5, 0));
	window:AddCloseButton(mainFrame);

    local binds = window.Binds;
    binds.InteractConfig = nil;

    mainFrame:WaitForChild("TitleFrame"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
        window:Close();
    end)

	window.OnToggle:Connect(function(visible, interactable: InteractableInstance?)
		if interactable then
			binds.InteractConfig = interactable.Config;
		end
		if visible and not modBranchConfigurations.IsWorld("Safehome") then 
            window:Close();
            return;
        end
	end)
	

	local inputBox = mainFrame:WaitForChild("InputFrame"):WaitForChild("TextBox");
	
	mainFrame:WaitForChild("playButton").MouseButton1Click:Connect(function()
		local rPacket = remoteSafehomeRequest:InvokeServer("playSound", {
            SoundId = inputBox.Text;
			RadioPlay = true;
			InteractConfig = binds.InteractConfig;
        });
	end)
	
	mainFrame:WaitForChild("playSpeakersButton").MouseButton1Click:Connect(function()
		local rPacket = remoteSafehomeRequest:InvokeServer("playSound", {
            SoundId = inputBox.Text;
            InteractConfig = binds.InteractConfig;
        });
	end)
	
	mainFrame:WaitForChild("togglePartyLightsButton").MouseButton1Click:Connect(function()
		local rPacket = remoteSafehomeRequest:InvokeServer("togglePartyLights", {
            InteractConfig = binds.InteractConfig;
        });
	end)

	interface.Garbage:Tag(workspace.ChildAdded:Connect(function(child)
		if child.Name == "GlobalSoundSystem" then
			local function update()
				if child.IsPlaying then
					mainFrame.playButton.Text = "Stop";
					mainFrame.playSpeakersButton.Text = "Stop On Speakers";
				else
					mainFrame.playButton.Text = "Play";
					mainFrame.playSpeakersButton.Text = "Play On Speakers";
				end
			end
			child:GetPropertyChangedSignal("IsPlaying"):Connect(update)
			update();
		end
	end));

end

return interfacePackage;

