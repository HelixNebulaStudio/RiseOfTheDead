local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local StarterGui = game:GetService("StarterGui");
local GuiService = game:GetService("GuiService");
local UserInputService = game:GetService("UserInputService");
local ContextActionService = game:GetService("ContextActionService");
local TweenService = game:GetService("TweenService");
local CollectionService = game:GetService("CollectionService");
local HttpService = game:GetService("HttpService");

local camera = workspace.CurrentCamera;
local localPlayer = game.Players.LocalPlayer;

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurationsRotd);
local modCameraGraphics = shared.require(game.ReplicatedStorage.PlayerScripts.CameraGraphics);

local RotdInterface = shared.require(game.ReplicatedStorage.Library.UI.InterfaceClass).new(script.Parent);
--==
function RotdInterface.clientGuisLoad()
    local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
    local interface: InterfaceInstance = RotdInterface;

    interface:Init();

    if localPlayer.Character then
        if modConfigurations.Disable3DSkybox ~= true then
            modCameraGraphics.Skybox3D:SetVisible(true);
        end;
        if modConfigurations.AutoOpenBlinds then 
            interface:ToggleGameBlinds(true, 3);
        end;

        interface.Garbage:Tag(playerClass.OnIsDeadChanged:Connect(function(isDead)
            if not isDead then return end;

            interface:ToggleGameBlinds(false, 4);
        end))

        local function onWorldEventInfoUpdate()
            local HUD_TASK_ID = "WorldEventTask";
            local worldEventInfo = {
                Name = nil;
                Header = nil;
                Desc = nil;
                StartTime = nil;
                Duration = nil;
            };

            if workspace:GetAttribute("WorldEventInfo") then
                worldEventInfo = HttpService:JSONDecode(workspace:GetAttribute("WorldEventInfo"));
            end

            local taskHudWindow: InterfaceWindow = interface:GetWindow("TaskListHud");
            local worldEventHudTask = taskHudWindow and taskHudWindow.Binds.getOrNewTask(HUD_TASK_ID) or nil;

            local isActive = worldEventInfo.Name ~= nil;
            if not isActive then
                if worldEventHudTask then
                    taskHudWindow.Binds.destroyHudTask(HUD_TASK_ID);
                    worldEventHudTask = nil;
                end

                return;
            end

            worldEventHudTask = taskHudWindow and taskHudWindow.Binds.getOrNewTask(HUD_TASK_ID, true) or nil;
            if worldEventHudTask == nil then return end;

            worldEventHudTask.Order = 5;
            worldEventHudTask.Properties.TitleText = `World Event`;

            if worldEventInfo.Header and worldEventInfo.Header:sub(1, 13) == "rbxassetid://" then
                worldEventHudTask.Properties.HeaderText = "";
                worldEventHudTask.Properties.HeaderImg = worldEventInfo.Header;
            else
                worldEventHudTask.Properties.HeaderImg = "";
                worldEventHudTask.Properties.HeaderText = worldEventInfo.Header or worldEventInfo.Name;
            end
            
            worldEventHudTask.Properties.DescText = worldEventInfo.Desc;

            if worldEventInfo.StartTime then
                worldEventHudTask.Properties.Timers.Timer1 = {
                    Duration = worldEventInfo.Duration or math.huge;
                    StartTime = worldEventInfo.StartTime;
                };
            else
                table.clear(worldEventHudTask.Properties.Timers);
            end

            worldEventHudTask:Update();
        end
        interface.Garbage:Tag(workspace:GetAttributeChangedSignal("WorldEventInfo"):Connect(onWorldEventInfoUpdate));
        onWorldEventInfoUpdate();
    
    else
        if modBranchConfigurations.IsWorld("MainMenu") or modBranchConfigurations.IsWorld("BioXResearch") then
            interface:ToggleGameBlinds(false, 0.1);
            local mainMenuWindow: InterfaceWindow = interface:GetWindow("MainMenu");
            if mainMenuWindow then
                mainMenuWindow:Open();
            else
                Debugger:Warn(`Missing main menu window.`);
            end
        end

    end
end

function RotdInterface.onRequire()

end

return RotdInterface;