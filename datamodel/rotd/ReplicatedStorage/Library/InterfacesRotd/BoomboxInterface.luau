local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modRemotesManager = shared.require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local interfacePackage = {
    Type = "Character";
};
--==

function interfacePackage.newInstance(interface: InterfaceInstance)
    local remoteBoomboxRemote = modRemotesManager:Get("BoomboxRemote");

    local templateButton = script:WaitForChild("testButton");
    local testSound = script:WaitForChild("Sound");

    local mainFrame = script:WaitForChild("Boombox"):Clone();
    mainFrame.Parent = interface.ScreenGui;

    local label = mainFrame:WaitForChild("label");
    local addButton = mainFrame:WaitForChild("addButton");
    local testButton = mainFrame:WaitForChild("testButton");
    local inputBox = mainFrame:WaitForChild("Inputframe"):WaitForChild("TextBox");
    local playList = mainFrame:WaitForChild("list"):WaitForChild("ScrollingFrame");

    local window: InterfaceWindow = interface:NewWindow("BoomboxWindow", mainFrame);
	window.CompactFullscreen = true;
	window:SetClosePosition(UDim2.new(0.5, 0, -1.5, 0), UDim2.new(0.5, 0, 0.5, 0));
	window.OnToggle:Connect(function(visible)
		if visible then
			interface:HideAll{[window.Name]=true;};
            window:Update();
		else
			testSound:Stop();
		end
	end)

    mainFrame:WaitForChild("TitleFrame"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
        window:Close();
    end)

    testSound.Ended:Connect(function()
        testButton.buttonText.Text = "Test Sound";
    end)
        
    local activeToolHandler: ToolHandlerInstance;

    local testDebounce = false;
    testButton.MouseButton1Click:Connect(function()
        if testDebounce then return end;
        testDebounce = true;
        
        local inputId = tonumber(inputBox.Text);
        if inputId then
            if testSound.Playing and testSound.SoundId == ("rbxassetid://"..inputId) then
                testSound:Stop();
                testButton.buttonText.Text = "Test Sound";
            else
                testSound.SoundId = "rbxassetid://"..inputId;
                testButton.buttonText.Text = "Loading..";
                for a=1, 20 do
                    if testSound.IsLoaded then
                        testSound:Play();
                        testButton.buttonText.Text = "Playing";
                        testDebounce = false;
                        return;
                    end
                    wait(0.1)
                end
                testButton.buttonText.Text = "Could not load";
                wait(1);
                testButton.buttonText.Text = "Test Sound";
            end 
            
        end
        testDebounce = false;
    end)

    addButton.MouseButton1Click:Connect(function()
        testSound:Stop();
        local inputId = tonumber(inputBox.Text);
        if inputId == nil then
            addButton.buttonText.Text = "Missing input";
            wait(1);
            addButton.buttonText.Text = "Add Track";
            return;
        end

        modClientGuis.promptDialogBox{
            Title = "Add track to boombox";
            Desc = `Are you sure you want to add track ({inputId}) for <b><font color='rgb(170, 120, 0)'>200 Gold</font></b>?`;
            Buttons = {
                {
                    Style = "Gold";
                    Text = "Add Track";
                    HideButtonsOnClick = true;
                    OnPrimaryClick = function(dialogWindow, newButton)
                        local statusLabel = dialogWindow.Binds.StatusLabel;
                        
                        statusLabel.Text = "Adding track to boom box...";
                        local r = remoteBoomboxRemote:InvokeServer("add", activeToolHandler.StorageItem.ID, inputId);
                        if r == 1 then
                            statusLabel.Text = "Track added";
                            
                        elseif r == 2 then
                            statusLabel.Text = "Not enough gold";
                            
                            task.wait(1);
                            dialogWindow:Close();
                            interface:ToggleWindow("GoldMenu", true, "GoldPage");
                            return;
                            
                        elseif r == 3 then
                            statusLabel.Text = "Purchase failed";
                            
                        elseif r == 4 then
                            statusLabel.Text = "Already exist";
                            
                        elseif r == 5 then
                            statusLabel.Text = "Playlist full";
                            
                        else
                            statusLabel.Text = "Unknown error";
                        end
                        task.wait(2);
                        dialogWindow:Close();
                        window:Update();
                    end;
                };
                {
                    Style = "Cancel";
                };
            };
        };
    end)

    window.OnUpdate:Connect(function(toolHandler)
        if toolHandler then activeToolHandler = toolHandler; end;
        if window.Visible == false then return end;
        if activeToolHandler == nil then
            window:Close();
            return; 
        end;
        
        local storageItem: StorageItem = activeToolHandler.StorageItem;

        for _, obj in pairs(playList:GetChildren()) do
            if obj:IsA("GuiObject") then
                obj:Destroy();
            end
        end
        
        local songsList = storageItem.Values.Songs or {};
        local songsCount = 0;
        for songId, songName in pairs(songsList) do
            local new = templateButton:Clone();
            local buttonText = new:WaitForChild("buttonText");
            
            buttonText.Text = ("$name: $id"):gsub("$name", songName):gsub("$id", songId);
            new.MouseButton1Click:Connect(function()
                activeToolHandler.Binds.KeyFire(true, {SongId=songId});
                window:Close();
            end)
            new.Parent = playList;
            songsCount = songsCount+1;
            
            local deleteButton = new:WaitForChild("deleteButton");
            local gradient = deleteButton:WaitForChild("UIGradient");
            
            local delButtonDown = false;
            deleteButton.MouseButton1Down:Connect(function()
                delButtonDown = true;
                local colorA, colorB, colorC = Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200), Color3.fromRGB(100, 100, 100);
                local color = {
                    ColorSequenceKeypoint.new(0, colorA),
                    ColorSequenceKeypoint.new(0.001, colorA),
                    ColorSequenceKeypoint.new(0.002, colorB),
                    ColorSequenceKeypoint.new(1, colorB)
                };
                gradient.Color = ColorSequence.new(color);
                
                local deleteTick = tick();
                local deleteTime = 1;
                local deleteDebounce = false;
                RunService:BindToRenderStep("DeleteTrack", Enum.RenderPriority.Input.Value+1, function(delta)
                    if not mainFrame.Visible then RunService:UnbindFromRenderStep("DeleteTrack"); return end;
                    
                    local confirmPercent = math.clamp((tick()-deleteTick)/deleteTime, 0.001, 0.997);
                    color[2] = ColorSequenceKeypoint.new(confirmPercent, colorA);
                    color[3] = ColorSequenceKeypoint.new(confirmPercent+0.002, colorB);
                    gradient.Color = ColorSequence.new(color);
                    
                    if confirmPercent >= 0.997 and not deleteDebounce then
                        deleteDebounce = true;
                        interface:PlayButtonClick();
                        RunService:UnbindFromRenderStep("DeleteTrack");
                        
                        remoteBoomboxRemote:InvokeServer("delete", storageItem.ID, songId);
                        color[2] = ColorSequenceKeypoint.new(0.001, colorA);
                        color[3] = ColorSequenceKeypoint.new(0.002, colorC);
                        color[4] = ColorSequenceKeypoint.new(1, colorC);
                        gradient.Color = ColorSequence.new(color);
                        
                        wait(0.2);
                        window:Update();
                    end
                    if not interface.Properties.PrimaryInputDown or not delButtonDown then
                        color[2] = ColorSequenceKeypoint.new(0.001, colorA);
                        color[3] = ColorSequenceKeypoint.new(0.002, colorB);
                        gradient.Color = ColorSequence.new(color);
                        RunService:UnbindFromRenderStep("ConfirmTrade");
                    end
                end)
            end)
            
            deleteButton.MouseButton1Up:Connect(function()
                delButtonDown = false;
            end)
        end
        
        playList.CanvasSize = UDim2.new(0, 0, 0, playList.UIListLayout.AbsoluteContentSize.Y);
        label.Text = ("Add sound track to this boom box. Playlist: $songs/10"):gsub("$songs", songsCount);
        inputBox.Text = "";
        testButton.buttonText.Text = "Test Sound";
    end)

    window.OnToggle:Connect(function(visible, toolHandler)
        if toolHandler then
            activeToolHandler = toolHandler;
        end
        window:Update(activeToolHandler);
    end)
end

return interfacePackage;

