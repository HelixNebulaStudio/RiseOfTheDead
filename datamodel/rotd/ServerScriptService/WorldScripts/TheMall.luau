local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
if RunService:IsServer() then

end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);
--==

function WorldCore.onRequire()
    if RunService:IsServer() then
        local modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);

        shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
            local profile: ProfileRotd = shared.modProfile:WaitForProfile(player) :: ProfileRotd;
            if profile == nil then return end;

            local giftSpawn = CFrame.new(458.299988, 74.8267899, -1165.52124, 0, 0, 1, 0, 1, 0, -1, 0, 0);
            WorldCore:SpawnGift(player, "clinicGift", giftSpawn);
            
            local mollyNpcClass = shared.modNpcs.getPlayerNpc(player, "Molly");
            if mollyNpcClass == nil then
                mollyNpcClass = shared.modNpcs.spawn2{
                    Name = "Molly";
                    Player = player;
                    ReplicateOut = true;
                };
            end
        end, 999);

        shared.modNpcs.spawn2{Name="Maverick";};
        shared.modNpcs.spawn2{Name="Danny";};

        -- Bandit Camp
        shared.modNpcs.spawn2{Name = "Patrick";};
        shared.modNpcs.spawn2{
            Name = "Loran";
            CFrame = CFrame.new(795.21051, 162.605835, -668.609192, 1, 0, 0, 0, 1, 0, 0, 0, 1);
        };

        -- Safehouse 6
        shared.modNpcs.spawn2{Name="Alice";};
        shared.modNpcs.spawn2{Name="Mike";};


        shared.modEventService:OnInvoked("Generic_BindTrigger", function(event: EventPacket, ...)
            local player: Player? = event.Player;
            if player == nil then return end;

            local triggerId: string, interactable: InteractableInstance = ...;
            
            if triggerId == "PushMallShelf" then
                task.spawn(function()
                    if interactable.CanInteract == false then return end;
                    
                    interactable.CanInteract = false;
                    interactable.Label = "";
                    interactable:Sync();

                    local interactPart = interactable.Part;
                    interactPart.Size = Vector3.new(0, 0, 0);

                    local ventInteractable: InteractableInstance = modInteractables.getById("mallSafehouseSecretVent");
                    ventInteractable.Config:SetAttribute("Locked", false);
                
                    local shelfObj = workspace.Environment.MoveableShelf;
                    TweenService:Create(shelfObj, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                        CFrame = CFrame.new(790.140137, 95.0486832, -631.332397, -0.669129193, 0, 0.743146181, 0, 1, 0, -0.743146181, 0, -0.669129193);
                    }):Play();
                    
                    task.delay(20, function()
                        interactable.CanInteract = true;
                        interactable.Label = "Push shelf outwards";
                        interactable:Sync();
                        
                        ventInteractable.Label = "Blocked by the shelf..";
                        ventInteractable.Config:SetAttribute("Locked", true);
                        ventInteractable:Sync();
                    
                        interactPart.Size = Vector3.new(0.4, 4.51, 1.38);
                        TweenService:Create(shelfObj, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                            CFrame = CFrame.new(792.342407, 95.0486832, -633.315308, 0, 0, 1, 0, 1, -0, -1, 0, 0);
                        }):Play();
                    end)
                end)

            elseif triggerId == "clinicKeycard" then
                task.spawn(function()
                    if modEvents:GetEvent(player, "clinicSecretKeycard") then return end;

                    modEvents:NewEvent(player, {Id="clinicSecretKeycard"}, true);
                    shared.Notify(player, "You found a keycard.", "Reward");
                end)
                
            end
        end)

    elseif RunService:IsClient() then

    end
end

return WorldCore;