local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TextService = game:GetService("TextService");
local UserInputService = game:GetService("UserInputService");

local localPlayer = game.Players.LocalPlayer;

local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local interfacePackage = {
    Type = "Character";
};
--==

function interfacePackage.newInstance(interface: InterfaceInstance)
    local socialMenuWindow: InterfaceWindow;

    local branchColor = modBranchConfigs.BranchColor;

    local mailboxFrame = script:WaitForChild("MailboxFrame"):Clone();
    mailboxFrame.Parent = interface.ScreenGui;
    local mailboxList = mailboxFrame:WaitForChild("MainFrame"):WaitForChild("MailList");

	local window: InterfaceWindow = interface:NewWindow("Mailbox", mailboxFrame);
	window.CompactFullscreen = true;
    window.CloseWithInteract = true;
	window:SetClosePosition(UDim2.new(0.5, 0, -1, 0));

    local MailTemplates;
    
    local isLazyLoaded = false;
    local function lazyLoad()
        MailTemplates = {
            ["1"]={FrameType="1"; ActionType="BasicCollect"; FrameData={
                T="You have purchased perks in Rise Of The Dead Legacy!";
                D="You have purchased $Amount Perks in the old version of the game. We would like to return you the amout of perks you purchased.";
            };};
            ["2"]={FrameType="1"; ActionType="BasicCollect"; FrameData={
                T="Your friend, $Name, joined the game because of you!";
                D="You have been awarded 10 Perks because a friend of yours has joined Rise Of The Dead because of you. Invite more friends to play and get more perks!";
            };};
            ["3"]={FrameType="1"; ActionType="BasicCollect"; FrameData={
                T="You have received a gift!";
                D={
                    [1]="You have been rewarded a M9 Legacy (Pistol) for being one of the legacy players of Rise Of The Dead.";
                };
            };};
            ["4"]={FrameType="1"; ActionType="BasicCollect"; FrameData={
                T="Rewards for mastering your weapons!";
                D="Players now gain 10 Perks for every 5 mastery level reached, so you are rewarded $Amount Perks for every 5 mastery level that you gained.";
            };};
            ["5"]={FrameType="2"; ActionType="Close"; FrameData={
                T="Referral Program Complete!";
                D="Thank you so much for introducing Rise Of The Dead to 5 of your friends. Hope you all are having fun!";
                };};
            ["6"]={FrameType="1"; ActionType="BasicCollect"; FrameData={
                    T="You have received tweak points!";
                    D="Claim your $Amount tweak points for the missions you have completed. You can use them on the workbench.";
                };};
            ["99"]={FrameType="99"; ActionType="LegacyCollect"; FrameData={};};
        };

        local mailboxQuickButton = socialMenuWindow.Frame:WaitForChild("Nav"):WaitForChild("Mailbox");

        mailboxQuickButton.MouseButton1Click:Connect(function()
            interface:PlayButtonClick();
            window:Open();
        end)
        mailboxQuickButton.MouseEnter:Connect(function()
            mailboxQuickButton.ImageColor3 = branchColor;
        end)
        mailboxQuickButton.MouseLeave:Connect(function()
            mailboxQuickButton.ImageColor3 = Color3.fromRGB(255,255,255);
        end)

        if modConfigurations.CompactInterface then
            mailboxFrame.Position = UDim2.new(0.5, 0, 0.5, 0);
            mailboxFrame.Size = UDim2.new(1, 0, 1, 0);
            mailboxFrame:WaitForChild("UICorner"):Destroy();
            
            mailboxFrame:WaitForChild("touchCloseButton").Visible = true;
            mailboxFrame:WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
                window:Close();
            end)
            mailboxFrame:WaitForChild("HelpButton").Visible = false;
        end
    end

	window.OnToggle:Connect(function(visible)
		if visible then
            socialMenuWindow = interface:GetWindow("SocialMenu");
            if socialMenuWindow == nil then
                window:Close();
                return;
            end

            if isLazyLoaded == false then
                isLazyLoaded = true;
                lazyLoad();
            end

			interface:HideAll{[window.Name]=true;};
			window:Update();
		end
	end)

    local function clearListChildrens()
        for _, child in pairs(mailboxList:GetChildren()) do
            if child:IsA("GuiObject") then
                child:Destroy();
            end
        end
    end

    window.OnUpdate:Connect(function() 
        if not window.Visible then return end;

        local modData = shared.require(localPlayer:WaitForChild("DataModule"));
        if modData.GameSave == nil or modData.GameSave.Mailbox == nil then return end

        local remoteMailboxFunction = game.ReplicatedStorage.Remotes.Interface.MailboxFunction;

        clearListChildrens();

        local mailboxQuickButton = socialMenuWindow.Frame:WaitForChild("Nav"):WaitForChild("Mailbox");
        local amtLabel = mailboxQuickButton:WaitForChild("AmtFrame"):WaitForChild("AmtLabel");
        amtLabel.Text = #modData.GameSave.Mailbox > 0 and #modData.GameSave.Mailbox or "";
        for a=1, #modData.GameSave.Mailbox do
            local index = a;
            local mailData = modData.GameSave.Mailbox[index];
            local template = MailTemplates[tostring(mailData.Type)];
            local newMailFrame = script:FindFirstChild(template.FrameType);
            newMailFrame = newMailFrame and newMailFrame:Clone() or nil;
            if newMailFrame then
                local descendants = newMailFrame:GetDescendants();
                for _, obj in pairs(descendants) do
                    local labelText = template.FrameData[obj.Name];
                    if type(labelText) == "table" and mailData.Data.DescId ~= nil then
                        labelText = labelText[mailData.Data.DescId] or "Missing description. ("..(mailData.Data.DescId or "nil")..")";
                    end
                    if obj:IsA("TextLabel") and labelText and type(labelText) == "string" then
                        for dataKey, dataValue in pairs(mailData.Data) do
                            obj.Text = string.gsub(labelText, "$"..dataKey, dataValue);
                        end
                    end
                end
                
                local mailSizeHeight = 130;
                if template.ActionType == "Close" then
                    local closeButton = newMailFrame:WaitForChild("CloseButton");
                    local closeDebounce = false;
                    closeButton.MouseButton1Click:Connect(function()
                        if closeDebounce then return end;
                        closeDebounce = true;
                        newMailFrame:Destroy();
                        remoteMailboxFunction:InvokeServer(index, "Close");
                        table.remove(modData.GameSave.Mailbox, index);
                        closeDebounce = false;
                    end)
                    mailSizeHeight = 130;
                    
                elseif template.ActionType == "BasicCollect" then
                    local collectButton = newMailFrame:WaitForChild("CollectButton");
                    local collectionDebounce = false;
                    collectButton.MouseButton1Click:Connect(function()
                        if collectionDebounce then return end;
                        collectionDebounce = true;
                        collectButton.Label.Text = "Collecting..";
                        local complete = remoteMailboxFunction:InvokeServer(index, "Collect");
                        if complete then
                            newMailFrame:Destroy();
                            table.remove(modData.GameSave.Mailbox, index);
                        else
                            collectButton.Label.Text = "Collect";
                        end
                        collectionDebounce = false;
                    end)
                    mailSizeHeight = 130;
                    
                elseif template.ActionType == "LegacyCollect" then
                    mailSizeHeight = 320;
                    local buttonDebounce = false;
                    local collectButton = newMailFrame:WaitForChild("CollectButton");
                    local deleteButton = newMailFrame:WaitForChild("DeleteButton");
                    local legacyDataLabel = newMailFrame:WaitForChild("List"):WaitForChild("legacyDataLabel");
                    collectButton.MouseButton1Click:Connect(function()
                        if buttonDebounce then return end;
                        buttonDebounce = true;
                        collectButton.Label.Text = "Claiming..";
                        local complete = remoteMailboxFunction:InvokeServer(index, "Claim");
                        if complete == true then
                            newMailFrame:Destroy();
                            table.remove(modData.GameSave.Mailbox, index);
                        else
                            collectButton.Label.Text = complete or "Claim";
                            if complete then
                                delay(2, function()
                                    collectButton.Label.Text = "Claim";
                                end)
                            end
                        end
                        buttonDebounce = false;
                    end)

                    local deleteTick;
                    deleteButton.MouseButton1Down:Connect(function()
                        deleteTick = tick();
                        local deleteTime = 0.8;
                        RunService:BindToRenderStep("DeleteConfirm", Enum.RenderPriority.Input.Value+1, function(delta)
                            local deleteBar = deleteButton.bar;
                            local deletePercent = math.clamp((tick()-deleteTick)/deleteTime, 0, 1);
                            deleteBar.Size = UDim2.new(deletePercent, 0, 1, 0);
                            if deletePercent >= 1 and not buttonDebounce then
                                buttonDebounce = true;
                                RunService:UnbindFromRenderStep("DeleteConfirm");
                                
                                deleteButton.Label.Text = "Deleting legacy data..";
                                local complete = remoteMailboxFunction:InvokeServer(index, "Destroy");
                                if complete then
                                    newMailFrame:Destroy();
                                    table.remove(modData.GameSave.Mailbox, index);
                                else
                                    deleteButton.Label.Text = "Delete All";
                                end
                                
                                buttonDebounce = false;
                            else
                                deleteButton.Label.Text = "Hold To Delete";
                            end
                            if not interface.Properties.PrimaryInputDown then
                                RunService:UnbindFromRenderStep("DeleteConfirm");
                                deleteBar.Size = UDim2.new(0, 0, 1, 0);
                                delay(0.5, function()
                                    if deleteButton and deleteButton:FindFirstChild("Label") then
                                        deleteButton.Label.Text = "Delete All";
                                    end
                                end)
                            end
                        end)
                    end)
                    local listString = "";
                    if mailData.Data.Weapons then
                        listString = listString.."Weapons you have unlocked:\n";
                        for weaponName,_ in pairs(mailData.Data.Weapons) do
                            listString = listString.."\t• "..weaponName.."\n";
                        end
                        listString = listString.."\n";
                    end
                    if mailData.Data.Blueprints then
    --						listString = listString.."Blueprints you have in your inventory:\n";
    --						for bpName,_ in pairs(mailData.Data.Blueprints) do
    --							listString = listString.."\t• "..bpName.."\n";
    --						end
    --						listString = listString.."\n";
                    end
                    legacyDataLabel.Text = listString;
                    local bounds = TextService:GetTextSize(legacyDataLabel.Text, legacyDataLabel.TextSize, legacyDataLabel.Font, Vector2.new(newMailFrame.List.AbsoluteSize.X, 2000));
                    newMailFrame.List.CanvasSize = UDim2.new(0, 0, 0, bounds.Y);
                end
                
                
                if UserInputService.TouchEnabled then
                    local open = false;
                    newMailFrame.InputBegan:Connect(function(Input)
                        if Input.UserInputType == Enum.UserInputType.Touch then
                            if open then
                                open = false;
                                newMailFrame:TweenSize(UDim2.new(1, 0, 0, 40), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.2, true);
                                
                            else
                                open = true;
                                newMailFrame:TweenSize(UDim2.new(1, 0, 0, mailSizeHeight), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.2, true);
                            end
                        end
                    end)
                end
                newMailFrame.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseMovement then
                        newMailFrame:TweenSize(UDim2.new(1, 0, 0, mailSizeHeight), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.2, true);
                    end
                end)
                
                newMailFrame.InputEnded:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseMovement then
                        newMailFrame:TweenSize(UDim2.new(1, 0, 0, 40), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.2, true);
                    end
                end)
                
                newMailFrame.Parent = mailboxList;
            end
        end
    end)
end

return interfacePackage;

