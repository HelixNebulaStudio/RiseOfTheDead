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
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modCameraGraphics = shared.require(game.ReplicatedStorage.PlayerScripts.CameraGraphics);

local RotdInterface = shared.require(game.ReplicatedStorage.Library.UI.InterfaceClass).new(script.Parent);
--==
function RotdInterface.clientGuisLoad()
    local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
    local self: Interface = RotdInterface;

    self:Init();

    if localPlayer.Character then
        if modConfigurations.Disable3DSkybox ~= true then
            modCameraGraphics.Skybox3D:SetVisible(true);
        end;
        if modConfigurations.AutoOpenBlinds then 
            self:ToggleGameBlinds(true, 3);
        end;

        self.Garbage:Tag(playerClass.OnIsAliveChanged:Connect(function(isAlive)
            if isAlive then return end;

            self:ToggleGameBlinds(false, 4);
        end))
    
    else
        if modBranchConfigs.WorldName == "MainMenu" or modBranchConfigs.WorldName == "BioXResearch" then
            local mainMenuWindow: InterfaceWindow = self:GetWindow("MainMenu");
            if mainMenuWindow then
                mainMenuWindow:Open();
            end
        end

    end

    self.Garbage:Tag(function()
        
    end)
end

function RotdInterface.onRequire()

end

return RotdInterface;