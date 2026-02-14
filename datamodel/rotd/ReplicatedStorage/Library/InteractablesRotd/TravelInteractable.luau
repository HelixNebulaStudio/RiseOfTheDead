local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local SoundService = game:GetService("SoundService");

local localPlayer = game.Players.LocalPlayer;

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

if RunService:IsServer() then
    modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);
end
local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local Travel = super.newPackage{
		Name = "Travel";
        Type = "Travel";
    };

    function Travel.new(interactable: InteractableInstance, player: Player)
        local config: Configuration = interactable.Config;
		local worldName = config:GetAttribute("WorldName") :: string;
		local setSpawn = config:GetAttribute("SetSpawn") :: string;

        interactable.Values.WorldName = worldName;
        interactable.Values.SetSpawn = setSpawn;

        interactable.CanInteract = true;
        interactable:SetPermissions("CanInteract", true);
    end

    -- When interacting with interactable.
    function Travel.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        local config: Configuration = interactable.Config;

        local worldName = interactable.Values.WorldName;
        local setSpawn = interactable.Values.SetSpawn;
		local worldDisplayName = modBranchConfigurations.GetWorldDisplayName(worldName);

        if RunService:IsClient() then 
            if info.Action == "Client" then 
                if info.Player == nil then return end;

                local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
                local interface: Interface = modClientGuis.ActiveInterface;

                modClientGuis.promptDialogBox({
                    Title=`You are about to leave this world`;
                    Desc=`Are you sure you want to travel to {worldDisplayName}?`;
                    Buttons={
                        {
                            Text="Travel";
                            Style="Confirm";
                            OnPrimaryClick=function(dialogWindow)
                                interface:ToggleGameBlinds(false, 3);
                                
                                local characterVars = info.CharacterVars;
                                characterVars.CharacterProperties.CanMove = false;
                                characterVars.CharacterProperties.CanInteract = false;

                                interactable:InteractServer(info.Values);
                                SoundService:SetListener(Enum.ListenerType.CFrame, CFrame.new(0, 1000, 0));
                            end;
                        };
                        {
                            Text="Cancel";
                            Style="Cancel";
                        };
                    }
                });

            end
            return;
        end;
        --MARK: Server
        if not interactable:IsDebounced(`server`, 0.5) then
            Debugger:Warn(`Pickupable server is on cooldown.`, interactable);
            return;
        end

        if info.Player == nil then
            Debugger:Warn(`Player is nil for teleport.`, info);
            return;
        end

        local player: Player = info.Player;
        
        if not workspace:IsAncestorOf(config) and not game.ReplicatedStorage:WaitForChild("Replicated"):IsAncestorOf(config) then
            Debugger:Warn(`Travel config is not in valid dir.`, interactable);
            return;
        end
        if player:DistanceFromCharacter(interactable.Point) > interactable.InteractableRange then 
            shared.Notify(player, `Travel is out of range.`, "Negative");
            return 
        end;

        local profile: Profile = shared.modProfile:Get(player);
        local gameSave: GameSaveRotd? = profile and (profile:GetActiveSave() :: GameSaveRotd) or nil;

        if setSpawn and gameSave then
            gameSave.Spawn = setSpawn;
            Debugger:StudioWarn(`Set spawn from ({gameSave.Spawn}) to (Travel = {setSpawn})`);
        end

        modServerManager:Travel(player, worldName);
    end
    
    -- When interactable pops up on screen.
    function Travel.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        if RunService:IsServer() then return end;

        local canInteract = interactable:HasPermissions("CanInteract", localPlayer.Name);
        if canInteract == false then
            interactable.CanInteract = false;
            interactable.Label = `Travel door's locked`;
            return;
        end

        local worldName = interactable.Values.WorldName;
        local worldDisplayName = modBranchConfigurations.GetWorldDisplayName(worldName);
        interactable.Label = `Travel to {worldDisplayName}`;

        interactable.CanInteract = true;
    end

    super.registerPackage(Travel);
end

return interactablePackage;

