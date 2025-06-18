local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local RunService = game:GetService("RunService");
local TextService = game:GetService("TextService");

local localPlayer = game.Players.LocalPlayer;

local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modStatusLibrary = shared.require(game.ReplicatedStorage.Library.StatusLibrary);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);


local interfacePackage = {
    Type = "Character";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));
    local remoteKeypadInput = modRemotesManager:Get("KeypadInput");

    local branchColor = modBranchConfigs.BranchColor;
    local activeInput = "";

	local menu = script:WaitForChild("Keypad"):Clone();
	menu.Parent = interface.ScreenGui;

	local window: InterfaceWindow = interface:NewWindow("Keypad", menu);
    window.DisableInteractables = true;
    window.CloseWithInteract = true;
	window:SetClosePosition(UDim2.new(0.5, 0, -1, 0), UDim2.new(0.5, 0, 0.5, 0));

    local binds = window.Binds;
    binds.Interactable = nil;

	window.OnToggle:Connect(function(visible, interactable)
        if interactable then
            binds.Interactable = interactable;
        end
		if visible then
			interface:HideAll{[window.Name]=true;};
            
			activeInput = "";
            window:Update();

			spawn(function()
				repeat until not window.Visible 
                    or binds.Interactable == nil or binds.Interactable.Part == nil
                    or not workspace:IsAncestorOf(binds.Interactable.Part)
                    or localPlayer:DistanceFromCharacter(binds.Interactable.Part.Position) >= 16 
                    or not wait(0.5);
				window:Close();
			end)
		end
	end)

    local enterButton = menu:WaitForChild("enterButton");
    local clearButton = menu:WaitForChild("clearButton");
    local numpad = menu:WaitForChild("numpad");

    local Inputframe = menu:WaitForChild("Inputframe");
    local inputLabel = Inputframe:WaitForChild("label");

    local templateButton = script:WaitForChild("templateButton");

	local inputDebounce = false;
	for a=0, 9, 1 do
		local button = templateButton:Clone();
		button.Parent = numpad;
		local buttonText = button:WaitForChild("buttonText");
		buttonText.Text = a;
		button.MouseButton1Click:Connect(function()
			if inputDebounce then return end;
			inputDebounce = true;
			if #activeInput <= 10 then
				activeInput = activeInput..a;
                window:Update();
			end
			interface:PlayButtonClick();
			wait(0.1);
			inputDebounce = false;
		end)
	end
    
    --MARK: OnUpdate
    window.OnUpdate:Connect(function()
        inputLabel.Text = activeInput;
    end)

    local enterDebounce = false;
    enterButton.MouseButton1Click:Connect(function()
        if enterDebounce then return end;
        enterDebounce = true;
        interface:PlayButtonClick();
        remoteKeypadInput:FireServer(binds.Interactable and binds.Interactable.Config, activeInput);
        wait(1);
        enterDebounce = false;
    end)

    local clearDebounce = false;
    clearButton.MouseButton1Click:Connect(function()
        if clearDebounce then return end;
        clearDebounce = true;
        interface:PlayButtonClick();
        activeInput = "";
        window:Update();
        wait(0.2);
        clearDebounce = false;
    end)


end

return interfacePackage;

