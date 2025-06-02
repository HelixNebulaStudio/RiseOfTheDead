local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local TeleportService = game:GetService("TeleportService");
local HttpService = game:GetService("HttpService");

local localPlayer = game.Players.LocalPlayer;

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modImageProgressBarUI = shared.require(game.ReplicatedStorage.Library.UI.ImageProgressBarUI);
local modGuiObjectTween = shared.require(game.ReplicatedStorage.Library.UI.GuiObjectTween);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
local modCameraGraphics = shared.require(game.ReplicatedStorage.PlayerScripts.CameraGraphics);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);

local HintList = {
	"Tip: You can pin and unpin a mission by right clicking it from the missions menu.";
	"Tip: If you are lagging, lower your graphic settings in Roblox settings, it can reduce/disable bullet holes!";
	"Tip: You can slide by running and crouching at the same time!";
	"Tip: If you want to get past a horde of zombies, just jump on their heads!";
	"Tip: Your F2 key doesn't work and you want to access the settings? Use /settings";
	"Tip: You can travel to a friend from the social menu, even if you haven't unlocked the area yet, but be careful!";
	"Tip: Have feedback? Found a bug? Check out our socials!";
	"Tip: You can customize your auto pick up in the settings to select what you want to pick up.";
	"Fun Fact: Rise Of The Dead (Legacy) started development back in 2014 as a passion project and still is!";
	"Fun Fact: Each safehouse has an easter egg hidden somewhere.";
	"Fun Fact: Pathoroth used to be an extreme boss in W.D. Mall.";
	"Fun Fact: R.A.T. members, also known as shopkeepers, have their own tunnels for transporting goods.";
	"Fun Fact: Tom Greyman has dialogues.";
};


local mouseEventTween = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut);
local fadeTween = TweenInfo.new(0.48);

local interfacePackage = {
    Type = "Player";
};
--==

function interfacePackage.Get()
	local seed = workspace:GetAttribute("DayOfYear") or 0;
	local random = Random.new(seed);
	return HintList[random:NextInteger(1, #HintList)];
end

function interfacePackage.newInstance(interface: InterfaceInstance)
	local remoteProfileService = modRemotesManager:Get("ProfileService");
    local branchColor = modBranchConfigs.BranchColor;


    --== Credits Window
    local creditsFrame = script:WaitForChild("CreditsFrame"):Clone();
    creditsFrame.Parent = interface.ScreenGui;

    local creditsWindow: InterfaceWindow = interface:NewWindow("CreditsWindow", creditsFrame);
    creditsWindow.CompactFullscreen = true;
    creditsWindow.CloseWithInteract = true;
    creditsWindow:SetClosePosition(UDim2.new(0.5, 0, -0.5, 0));

    local creditsFrameTemplate = script:WaitForChild("FrameTemplate");
    local creditsRoleTemplate = script:WaitForChild("RoleTemplate");
    local creditsNameTemplate = script:WaitForChild("NameTemplate");
    local contentFrame = creditsFrame:WaitForChild("Frame"):WaitForChild("Content");
    local pauserFrame = creditsFrame:WaitForChild("Frame"):WaitForChild("PauserFrame");

    local pause = false;
    local peak, timer = 0, tick();
    local function autoscroll(delta)
        if pause then return end;
        if contentFrame.CanvasPosition.Y > peak then 
            peak = contentFrame.CanvasPosition.Y; 
            timer=tick();
        end;
        if tick()-timer > 2 then 
            peak=0; 
            timer=tick(); 
            contentFrame.CanvasPosition = Vector2.new(0, 0); 
        end;
        contentFrame.CanvasPosition = Vector2.new(0, contentFrame.CanvasPosition.Y+delta*35);
    end

    pauserFrame.MouseEnter:Connect(function()
        pause = true;
    end)
    pauserFrame.MouseMoved:Connect(function()
        pause = true;
    end)

    pauserFrame.MouseLeave:Connect(function()
        peak, timer = 0, tick();
        pause = false;
    end)

    creditsWindow.OnToggle:Connect(function(visible)
        if visible then
			interface:HideAll{[creditsWindow.Name]=true;};
            RunService:BindToRenderStep("CreditsAutoScroll", Enum.RenderPriority.Camera.Value, autoscroll);
        else
            RunService:UnbindFromRenderStep("CreditsAutoScroll");
        end
    end)
    interface.Garbage:Tag(function()
        RunService:UnbindFromRenderStep("CreditsAutoScroll");
    end)

    task.spawn(function()
        local creditsJson = workspace:GetAttribute("CreditsJson");
        for a=1, 5 do
            if creditsJson then
                continue;
            end
            creditsJson = workspace:GetAttribute("CreditsJson");
            task.wait(10);
        end
        local creditsTable = HttpService:JSONDecode(creditsJson or {LoadingError={}});

        local totalY = 340;
        for a=1, #creditsTable do
            for title, credits in pairs(creditsTable[a]) do
                local newFrame = creditsFrameTemplate:Clone();
                local titleLabel = newFrame:WaitForChild("Title");
                titleLabel.Text = title;
                local nameList = titleLabel:WaitForChild("NameList");
                local creditList = titleLabel:WaitForChild("CreditList");
                local frameTotalSize = 45;
                local order = 1;
                local success, e = pcall(function()
                    for b=1, #credits do
                        local memberCredits = credits[b].Credits;
                        local memberName = credits[b].Name;
                        for c=1, #memberCredits do
                            local newName = creditsNameTemplate:Clone();
                            newName.LayoutOrder = order;
                            newName.Parent = nameList;
                            if c == 1 then
                                newName.Text = memberName;
                            else
                                newName.Text = "";
                            end
                            local newRole = creditsRoleTemplate:Clone();
                            newRole.LayoutOrder = order;
                            newRole.Text = memberCredits[c];
                            newRole.Parent = creditList;
                            frameTotalSize = frameTotalSize +25
                            order = order +1;
                        end
                    end
                end)
                if not success then 
                    titleLabel.Text = title.."Error loading..";
                    error(e);
                end
                newFrame.LayoutOrder = a;
                newFrame.Size = UDim2.new(1, 0, 0, frameTotalSize);
                newFrame.Parent = contentFrame;
                totalY = totalY + newFrame.AbsoluteSize.Y+40;
            end
        end
        contentFrame.CanvasSize = UDim2.new(0, 0, 0, totalY+340)
    end)
    --== Credits Window


    if not (modBranchConfigs.WorldName == "MainMenu" or modBranchConfigs.WorldName == "BioXResearch") then return end;
    local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
	local enteredCampaign = false;

    local frame = script:WaitForChild("MainMenu"):Clone();
    frame.Parent = interface.ScreenGui;
    
    local loadLabel = frame:WaitForChild("LoadLabel");
    loadLabel.TextColor3 = branchColor;
    modGuiObjectTween.FadeTween(loadLabel, modGuiObjectTween.FadeDirection.Out, TweenInfo.new(0.01));

    local loadingBarObject = modImageProgressBarUI.new(frame:WaitForChild("TitleLogo"));
    loadingBarObject.Color = branchColor;

    local frontPageFrame = frame:WaitForChild("FrontPage");
    

    local menuWindow: InterfaceWindow = interface:NewWindow("MainMenu", frame);
    menuWindow.IgnoreHideAll = true;
    menuWindow.CompactFullscreen = true;
    menuWindow.ReleaseMouse = true;
    menuWindow.DisableHotKeysHint = true;

    local mainTheme;
    --MARK: OnToggle
    menuWindow.OnToggle:Connect(function(visible)
        if visible then
            interface:ToggleGameBlinds(true, 3);

            modGuiObjectTween.FadeTween(frontPageFrame, modGuiObjectTween.FadeDirection.In, fadeTween);
            local sceneModel, focusPart, cameraBlur;
            local spinTick = tick()+3;
            local lastBlur = 20;
            modCameraGraphics:Bind("menucamera", {
                RenderStepped=function(camera)
                    if menuWindow.Visible == false then
                        modCameraGraphics:Unbind("menucamera");
                        return;
                    end
                    if sceneModel == nil then
	                    sceneModel = workspace:WaitForChild("Environment"):FindFirstChild("Scene");
                        return;
                    end

                    local camDistance = sceneModel:GetAttribute("CameraDistance") or 50;
                    local camAngle = sceneModel:GetAttribute("CameraAngle") or -15;
                    
                    if focusPart == nil then
                        focusPart = sceneModel:FindFirstChild("FocusPart");
                    end
                    
                    camera.FieldOfView = sceneModel:GetAttribute("CustomFov") or 45;
                    local spin = tick()-spinTick;
                    camera.CFrame = ((focusPart and focusPart.CFrame) or CFrame.new(0, 6, 0)) * CFrame.Angles(0, spin > 0 and spin/8 or 0, 0) 
                        * CFrame.Angles(math.rad(camAngle), 0, 0) * CFrame.new(0, 0, camDistance);
                    camera.Focus = camera.CFrame;
                    
                    cameraBlur = camera:FindFirstChild("Blur");
                    if cameraBlur == nil then
                        cameraBlur = Instance.new("BlurEffect");
                        interface.Garbage:Tag(cameraBlur);
                    end
                    cameraBlur.Parent = camera;
                    cameraBlur.Size = 4;	
                    lastBlur = cameraBlur.Size;
                end;
            }, 2);

            task.spawn(function()
                modAudio.Preload("MainTheme", true);
                mainTheme = modAudio.Play("MainTheme", interface.ScreenGui);
            end)
        else
            modCameraGraphics:Unbind("menucamera");
            if mainTheme then
                mainTheme:Destroy();
                mainTheme = nil;
            end
        end
    end)
    interface.Garbage:Tag(function()
        modCameraGraphics:Unbind("menucamera");
        if mainTheme then
            mainTheme:Destroy();
            mainTheme = nil;
        end
    end)

    game.ReplicatedFirst:RemoveDefaultLoadingScreen();
    game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false);
    localPlayer.PlayerGui:SetTopbarTransparency(1);

    local function showFrontPage()
        frontPageFrame.Visible = true;
        modGuiObjectTween.FadeTween(frontPageFrame, modGuiObjectTween.FadeDirection.In, fadeTween);
    end

    local startLoadTick = tick();
    local loadBeatConn; 
    loadBeatConn = RunService.Heartbeat:Connect(function()
        local timeLapse = tick()-startLoadTick;
        local timeAlpha = math.clamp(timeLapse/10, 0, 1);

        local loadAlpha = 0;
        if timeLapse > 1 and game:IsLoaded() then
            loadAlpha = 1;
        end

        local finalAlpha = math.max(loadAlpha, timeAlpha);

        if finalAlpha >= 1 then
            loadBeatConn:Disconnect();
            loadBeatConn = nil;

            loadingBarObject:Update(1);
            TweenService:Create(loadingBarObject.Image, TweenInfo.new(1), {ImageTransparency=1}):Play();
            task.wait(1);
            showFrontPage();
        else
            loadingBarObject:Update(finalAlpha);
        end
    end)
    interface.Garbage:Tag(loadBeatConn);

    interface.Garbage:Tag(TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
        modClientGuis.promptWarning(`Error: {errorMessage}`);
		modGuiObjectTween.FadeTween(loadLabel, modGuiObjectTween.FadeDirection.Out, TweenInfo.new(0.48));

		task.wait(0.5);

        frontPageFrame.Visible = true;
		modGuiObjectTween.FadeTween(frontPageFrame, modGuiObjectTween.FadeDirection.In, TweenInfo.new(0.48));
	end))


    local function onIsGameOnlineUpdate()
        pcall(function()
            frontPageFrame.ButtonList:WaitForChild("MainCampaign"):WaitForChild("MaintenanceLabel").Visible = workspace:GetAttribute("IsGameOnline") == false;
        end)
    end
    workspace:GetAttributeChangedSignal("IsGameOnline"):Connect(onIsGameOnlineUpdate);
    onIsGameOnlineUpdate();
    
    local buttons = frontPageFrame.ButtonList:GetChildren();
    table.insert(buttons, frontPageFrame.MainCredits);

    local buttonDebounce = false;
    for _, imageButton: ImageButton in pairs(buttons) do
        if not imageButton:IsA("ImageButton") then continue end;

        imageButton.MouseEnter:Connect(function()
            TweenService:Create(imageButton, mouseEventTween, {
                ImageColor3 = branchColor;
            }):Play();
        end)

        imageButton.MouseLeave:Connect(function() 
            TweenService:Create(imageButton, mouseEventTween, {
                ImageColor3 = Color3.fromRGB(255, 255, 255);
            }):Play();
        end)
        
        imageButton.MouseButton1Click:Connect(function() 
            if buttonDebounce then return end;
            buttonDebounce = true;

            interface:PlayButtonClick();

            if imageButton.Name == "MainCampaign" then

                modGuiObjectTween.FadeTween(frontPageFrame, modGuiObjectTween.FadeDirection.Out, TweenInfo.new(0.48));
                loadLabel.Visible = true;
                loadLabel.Text = "Searching for server...";
                wait(0.5);
                modGuiObjectTween.FadeTween(loadLabel, modGuiObjectTween.FadeDirection.In, TweenInfo.new(0.48));
                
                local rPacket = remoteProfileService:InvokeServer("menu/solo");
                if rPacket and rPacket.Success then
                    if rPacket.Index == 3 then
                        loadLabel.Text = "More bugs needs to be squashed...";
                    elseif rPacket.Index == 2 then
                        loadLabel.Text = "The survivors are gleeful of your return...";
                    else
                        loadLabel.Text = "You hear the sound of thunder...";
                    end
                end
                enteredCampaign = true;


            elseif imageButton.Name == "MainUpdates" then
                local updateWindow: InterfaceWindow = interface:GetWindow("UpdateWindow");
                if updateWindow then
                    if updateWindow.Binds.initMenu == nil then
                        updateWindow.Binds.initMenu = true;
                        updateWindow.Frame.AnchorPoint = Vector2.new(0.5, 0);
                        updateWindow.Frame.Size = UDim2.new(1, 0, 0.5, 0);
                        updateWindow:SetClosePosition(UDim2.new(0.5, 0, -0.6, 0), UDim2.new(0.5, 0, 0.3, 0));
                    end

                    if updateWindow.Visible then
                        updateWindow:Close();
                    else
                        updateWindow:Open();
                    end
                end


            elseif imageButton.Name == "MainCredits" then
                if creditsWindow.Visible then
                    creditsWindow:Close();
                else
                    creditsWindow:Open();
                end


            elseif imageButton.Name == "MainFriends" then
                local socialWindow: InterfaceWindow = interface:GetWindow("SocialMenu");
                if socialWindow then
                    if socialWindow.Binds.initMenu == nil then
                        socialWindow.Binds.initMenu = true;
                        socialWindow.Frame.AnchorPoint = Vector2.new(0.5, 0);
                        socialWindow.Frame.Size = UDim2.new(0.8, 0, 0.5, 0);
                        socialWindow:SetClosePosition(UDim2.new(0.5, 0, -0.6, 0), UDim2.new(0.5, 0, 0.3, 0));
                    end

                    if socialWindow.Visible then
                        socialWindow:Close();
                    else
                        socialWindow:Open();
                    end
                end


            end
            
            buttonDebounce = false;
        end)
    end

end

return interfacePackage;

