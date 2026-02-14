local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local camera = workspace.CurrentCamera;
local localPlayer = game.Players.LocalPlayer;

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local interfacePackage = {
    Type = "Player";
};
--==

function interfacePackage.newInstance(interface: InterfaceInstance)
    local branchColor = modBranchConfigurations.BranchColor;
    local remoteHudNotification = modRemotesManager:Get("HudNotification");
    
    local frame: Frame = Instance.new("Frame");
    frame.Name = "HeaderNotificationFrame";
    frame.BackgroundTransparency = 1;
    frame.AnchorPoint = Vector2.new(0.5, 0.5);
    frame.Size = UDim2.new(0, 0, 0, 0);
    frame.Position = UDim2.new(0.5, 0, 0.5, 0);
    frame.Parent = interface.ScreenGui;

    local window: InterfaceWindow = interface:NewWindow("HeaderNotificationsWindow", frame);
	window.IgnoreHideAll = true;
	window.ReleaseMouse = false;
    window:Open();
    
    -- MARK: Major Notifications
    local majorFrame = script:WaitForChild("headerFrame");
    local majorNotificitionQueue = {}; 
    local flushingMajorNotifications = false; 
    local displayingMasteryLevel = true;

    local function MajorNotification(Type, notificationData)
        local modItemLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
        
        table.insert(majorNotificitionQueue, function(timerOveride)
            if not modConfigurations.DisableMajorNotifications then
                local values = notificationData;
                local displayFrame = majorFrame:Clone();
                local titleImage = displayFrame:WaitForChild("Title");
                local titleLabel = displayFrame:WaitForChild("Label");
                local titleText = "";
                TweenService:Create(titleImage, TweenInfo.new(0), {ImageTransparency=1}):Play();
                TweenService:Create(titleLabel, TweenInfo.new(0), {TextTransparency=1; TextStrokeTransparency=1;}):Play();
                if Type == "Levelup" then
                    titleImage.Image = "rbxassetid://2048330360";
                    titleText = ("You are now mastery level $Level!"):gsub("$Level", values.Level or "NIL");

                    local masteryInterfaceClass: InterfaceWindow = interface:GetWindow("MasteryInterface");
                    if masteryInterfaceClass then
                        masteryInterfaceClass:Update();
                    end
                    modAudio.Preload("LevelUp", 5);
                    modAudio.Play("LevelUp");
                    
                elseif Type == "Unlocked" then
                    titleImage.Image = "rbxassetid://2696762854";
                    titleText = ("You have unlocked $Name!"):gsub("$Name", values.Name or "NIL");
                    modAudio.Preload("Unlocked", 5);
                    modAudio.Play("Unlocked");
                    
                elseif Type == "MissionFail" then
                    titleImage.Image = "rbxassetid://3376501069";
                    titleText = ("You have failed $Name!"):gsub("$Name", values.Name or "NIL");
                    modAudio.Preload("MissionFail", 5);
                    modAudio.Play("MissionFail");
                    
                elseif Type == "MissionComplete" then
                    titleImage.Image = "rbxassetid://2740686675";
                    titleText = ("You have completed $Name!"):gsub("$Name", values.Name or "NIL");
                    modAudio.Preload("MissionComplete", 5);
                    modAudio.Play("MissionComplete");
                    
                elseif Type == "MissionStart" then
                    titleImage.Image = "rbxassetid://2741993719";
                    titleText = ("You have started $Name!"):gsub("$Name", values.Name or "NIL");
                    modAudio.Preload("MissionStart", 5);
                    modAudio.Play("MissionStart");
                
                elseif Type == "HordeAttack" then
                    titleImage.Image = "rbxassetid://4473237759";
                    titleText = ("The horde is attacking $Name!"):gsub("$Name", values.Name or "NIL");
                    modAudio.Preload("HordeGrowl", 5);
                    modAudio.Play("HordeGrowl");	

                elseif Type == "Breach" then
                    titleImage.Image = "rbxassetid://4473237759";
                    titleText = "There's a breach in a safehome!";
                    modAudio.Preload("TerrorAlert", 5);
                    modAudio.Play("TerrorAlert");
                    
                    
                elseif Type == "PremiumAward" then
                    titleImage.Image = "rbxassetid://3235348619";
                    titleText = ("$PlayerName have been upgrade to Premium!"):gsub("$PlayerName", localPlayer.Name);
                    modAudio.Preload("Ascended", 5);
                    modAudio.Play("Ascended");

                elseif Type == "WeaponLevelup" then
                    local storageItem = values.StorageItem;
                    
                    local itemLib = modItemLibrary:Find(storageItem.ItemId);
                    
                    titleImage.Image = "rbxassetid://2048330360";
                    titleText = itemLib.Name.." leveled up to "..values.Level.."! Weapon mastery+ Weapon damage+"
                    modAudio.Preload("WeaponLevelUp", 5);
                    modAudio.Play("WeaponLevelUp");
                    
                elseif Type == "BattlePassLevelUp" then
                    titleImage.Image = "rbxassetid://2048330360";
                    titleText = `{values.Title or "Event"} leveled up to `.. values.Level .."!".. (values.HasRewards and " Check your missions menu for rewards!" or "");
                    modAudio.Preload("Collectible", 5);
                    modAudio.Play("Collectible");
                    
                elseif Type == "BattlePassComplete" then
                    titleImage.Image = "rbxassetid://2740686675";
                    titleText = "You have completed Event Pass: ".. values.Title .."!";
                    modAudio.Preload("Ascended", 5);
                    modAudio.Play("Ascended");

                    
                end
                
                titleLabel.TextColor3 = branchColor;
                titleLabel.Text = titleText;
                titleImage.Size = UDim2.new(1, 0, 0.4, 0);
                displayFrame.Parent = interface.ScreenGui;
                displayFrame.Visible = true;
                TweenService:Create(
                    titleImage, 
                    TweenInfo.new(timerOveride*3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
                    {
                        Size = UDim2.new(1, 0, 0.8, 0);
                    }
                ):Play();
                TweenService:Create(
                    titleImage, 
                    TweenInfo.new(timerOveride, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), 
                    {
                        ImageTransparency=0;
                    }
                ):Play();
                TweenService:Create(titleLabel, TweenInfo.new(timerOveride, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {TextTransparency=0; TextStrokeTransparency=0.7;}):Play();
                wait(timerOveride*5);
                TweenService:Create(titleImage, TweenInfo.new(timerOveride, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {ImageTransparency=1}):Play();
                TweenService:Create(titleLabel, TweenInfo.new(timerOveride, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {TextTransparency=1; TextStrokeTransparency=1;}):Play();
                wait(timerOveride);
                displayFrame.Visible = false;
                game.Debris:AddItem(displayFrame, 0.1);
            end
        end);
        if not flushingMajorNotifications then
            flushingMajorNotifications = true;
            repeat
                majorNotificitionQueue[1](1/#majorNotificitionQueue);
                table.remove(majorNotificitionQueue, 1);
            until #majorNotificitionQueue <= 0;
            flushingMajorNotifications = false;
        end
    end
    remoteHudNotification.OnClientEvent:Connect(MajorNotification)
end

return interfacePackage;