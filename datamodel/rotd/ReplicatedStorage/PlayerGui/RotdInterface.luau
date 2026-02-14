local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local StarterGui = game:GetService("StarterGui");
local GuiService = game:GetService("GuiService");
local UserInputService = game:GetService("UserInputService");
local ContextActionService = game:GetService("ContextActionService");
local TweenService = game:GetService("TweenService");
local CollectionService = game:GetService("CollectionService");

local camera = workspace.CurrentCamera;
local localPlayer = game.Players.LocalPlayer;

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
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
    
    else
        if modBranchConfigurations.IsWorld("MainMenu") or modBranchConfigurations.IsWorld("BioXResearch") then
            local mainMenuWindow: InterfaceWindow = interface:GetWindow("MainMenu");
            if mainMenuWindow then
                mainMenuWindow:Open();
            end
        end

    end
end

function RotdInterface.onRequire()

end

return RotdInterface;