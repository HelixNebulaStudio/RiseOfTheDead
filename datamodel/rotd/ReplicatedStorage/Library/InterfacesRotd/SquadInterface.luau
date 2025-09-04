local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local localPlayer = game.Players.LocalPlayer;

local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modTeamsManager = shared.require(game.ReplicatedStorage.Library.TeamsManager);
local modMarkers = shared.require(game.ReplicatedStorage.Library.Markers);

local modRadialImage = shared.require(game.ReplicatedStorage.Library.UI.RadialImage);

local RADIAL_CONFIG = '{"version":1,"size":128,"count":128,"columns":8,"rows":8,"images":["rbxassetid://10577973797","rbxassetid://10577974058"]}';

local interfacePackage = {
    Type = "Player";
};
--==

function interfacePackage.newInstance(interface: InterfaceInstance)
    local remoteOnInvitationsUpdate = modRemotesManager:Get("OnInvitationsUpdate");
    local remoteSquadSync = modRemotesManager:Get("SquadSync");

    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

    local templateSquadMember = script:WaitForChild("SquadMember");

    local hudFrame = script:WaitForChild("SquadHud"):Clone();
    hudFrame.Parent = interface.ScreenGui;
    
    local hudWindow: InterfaceWindow = interface:NewWindow("SquadHud", hudFrame);
    hudWindow.IgnoreHideAll = true;
    hudWindow.ReleaseMouse = false;
    
    interface:BindConfigKey("DisableSquadInterface", {hudWindow});

    local binds = hudWindow.Binds;
    binds.HudObjects = {};
    binds.HasMembers = false;

    --MARK: OnUpdate
    hudWindow.OnUpdate:Connect(function()
        local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
        local activeSquadType = playerClass.Properties.ActiveTeamType or "Party";
        local squadData: TeamClass = modTeamsManager.getTeamByPlayer(localPlayer, activeSquadType);

        local updatedMember = {};

        if squadData then
            for name, memberData in pairs(squadData.Members) do
                local hudObjects = binds.HudObjects[name];
                if hudObjects == nil or hudObjects.Guid ~= squadData.Guid then
                    hudObjects = {
                        Guid = squadData.Guid;
                    };
                    binds.HudObjects[name] = hudObjects;
                end

                local memberFrame = hudObjects.Frame;
                if memberFrame == nil then
                    memberFrame = templateSquadMember:Clone();
                    memberFrame.Name = name;
                    memberFrame.Parent = hudFrame;
                    hudObjects.Frame = memberFrame;
                end
                updatedMember[name] = true;
                memberFrame.LayoutOrder = squadData.MembersCount - memberData.Index;
                
                local radialBar = memberFrame:WaitForChild("radialBar");
                local avatarButton = memberFrame:WaitForChild("AvatarButton");

                local radialHealthBarObj = hudObjects.RadialHealthBar;

                local squadPlayerClass: PlayerClass = shared.modPlayers.getByName(name);
                if squadPlayerClass then
                    if radialHealthBarObj == nil then
                        radialHealthBarObj = modRadialImage.new(RADIAL_CONFIG, radialBar);
                        hudObjects.RadialHealthBar = radialHealthBarObj;

                        interface.Garbage:Tag(squadPlayerClass.OnIsDeadChanged:Connect(function(isDead)
                            avatarButton.ImageColor3 = isDead
                                                        and Color3.fromRGB(140, 70, 70)
                                                        or Color3.fromRGB(255, 255, 255);
                            memberFrame.BackgroundColor3 = avatarButton.ImageColor3;
                        end));
                    end

                    radialHealthBarObj.Humanoid = squadPlayerClass.Humanoid;
                    if name ~= localPlayer.Name then
                        modMarkers.SetMarker(name, name, name, modMarkers.MarkerTypes.Player);
                    end

                else
                    radialBar.Visible = false;
                end

                if memberData.Values.Color then
                    avatarButton.BackgroundColor3 = modMarkers.Colors[memberData.Values.Color];
					modMarkers.SetColor(name, memberData.Values.Color);
                end
                if avatarButton.Image == "" then
                    task.spawn(function()    
                        avatarButton.Image = shared.modPlayers.getAvatar(memberData.UserId);
                    end)
                end
            end
        end;

        for name, memberFrame in pairs(hudFrame:GetChildren()) do
            if memberFrame.Name == "SocialMenu" then continue end;
            if not memberFrame:IsA("GuiObject") or updatedMember[memberFrame.Name] then continue end;
            game.Debris:AddItem(memberFrame, 0);

            modMarkers.ClearMarker(name);
        end

        binds.HasMembers = next(updatedMember) ~= nil;
    end)
    hudWindow:Open();
    
    interface.Scheduler.OnStepped:Connect(function(tickData: TickData)
        if tickData.ms100 ~= true then return end;

        for name, hudObjects in pairs(binds.HudObjects) do
            local radialHealthBarObj = hudObjects.RadialHealthBar;
            if radialHealthBarObj == nil then continue end;

            if radialHealthBarObj.Humanoid and workspace:IsAncestorOf(radialHealthBarObj.Humanoid) then
                radialHealthBarObj.label.Visible = true;
                
                local humanoid = radialHealthBarObj.Humanoid;
                local health, maxHealth = humanoid.Health, humanoid.MaxHealth;
                radialHealthBarObj:UpdateLabel(health/maxHealth);

            else
                radialHealthBarObj.label.Visible = false;
                
            end
        end
        
        local socialWindow: InterfaceWindow = interface:GetWindow("SocialMenu");
        if socialWindow then
            local moveQuickButton = hudWindow.Visible and binds.HasMembers;
            socialWindow.QuickButton.Parent = moveQuickButton and hudFrame or interface.QuickBarButtons;
        end

        if tickData.s5 ~= true then return end;
        modTeamsManager.clientSyncRequest(function()
            hudWindow:Update();
        end);

    end)

    interface:BindEvent("TeamUpdated", function(team: TeamClass)
        if team.Type ~= "Party" then return end;
        hudWindow:Update();
    end)

end

return interfacePackage;

