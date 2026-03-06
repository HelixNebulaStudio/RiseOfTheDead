local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

if RunService:IsServer() then
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);

end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);
--==

function WorldCore.onRequire()
    if RunService:IsClient() then return end;
    modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
    modCrates = shared.require(game.ReplicatedStorage.Library.Crates);

    shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
        local profile: ProfileRotd = shared.modProfile:WaitForProfile(player) :: ProfileRotd;
        if profile == nil then return end;

        local revasDoorTemplate = script:WaitForChild("RevasDoorway");
        local newRevasDoor = revasDoorTemplate:Clone();
        newRevasDoor.Parent = workspace.Interactables;
        
        local doorInteractConfig = newRevasDoor:FindFirstChild("Interactable");
        local doorInteractable: InteractableInstance = modInteractables.getOrNew(doorInteractConfig);
        doorInteractable:SetPermissions("CanInteract", false);
        
        modReplicationManager.ReplicateOut({player}, newRevasDoor);

    end, 999);

    -- Harbor Rat Safehouse
    WorldCore.CaitlinClass = shared.modNpcs.spawn2{Name="Caitlin";};
    shared.modNpcs.spawn2{Name="Greg";};
    shared.modNpcs.spawn2{Name="Cooper";};
    shared.modNpcs.spawn2{Name="Lewis";};
    shared.modNpcs.spawn2{Name="David";};

    modGameModeManager:Initialize("Boss", "Vein Of Nekron");
        

    shared.modEventService:OnInvoked("Generic_BindTrigger", function(event: EventPacket, ...)
        local player: Player? = event.Player;
        if player == nil then return end;

        local triggerId: string, interactable: InteractableInstance = ...;

        if triggerId == "HarborGiftSand" then
            task.spawn(function()
                if modEvents:GetEvent(player, "HarborGiftSand") then return end;
                modEvents:NewEvent(player, {Id="HarborGiftSand"}, true);
                modReplicationManager.UnreplicateFrom(player, interactable.Part.Parent);
            end)

        elseif triggerId == "HarborGiftEntrance" then
            task.spawn(function()
                if modEvents:GetEvent(player, "HarborGiftSand") then return end;
                        
                local profile = shared.modProfile:Get(player);
                local inventory = profile.ActiveInventory;

                local enter = false;
                if modEvents:GetEvent(player, "HarborGiftEntrance") == nil then
                    local quantity = 0;
                    local itemsList = profile.ActiveInventory:ListByItemId("cultistkey1");
                    for a=1, #itemsList do quantity = quantity +itemsList[a].Quantity; end

                    if quantity >= 1 then
                        local storageItem = inventory:FindByItemId("cultistkey1");
                        inventory:Remove(storageItem.ID, 1);
                        modEvents:NewEvent(player, {Id="HarborGiftEntrance"});
                        enter  = true;
                        
                        modAudio.Play("HeavySplash", interactable.Part).PlaybackSpeed = 2;
                    else
                        shared.Notify(player, "Shovel has to be equipped!", "Negative");
                    end
                else
                    profile:UnlockItemCodex("cultistkey1");
                    enter = true;
                end

                if enter then
                    local interactPart = interactable.Part;
                    local destination = interactPart.Destination;
                    
                    local tpCframe = CFrame.new(destination.WorldPosition) 
                        * CFrame.Angles(0, math.rad(destination.WorldOrientation.Y-90), 0);
                    
                    local playerClass: PlayerClass = shared.modPlayers.get(player);
                    playerClass:SetCFrame(tpCframe);
                    
                    local exist = false;
                    for a=1, #profile.Junk.CacheInstances do
                        if profile.Junk.CacheInstances[a] and profile.Junk.CacheInstances[a].Name == "Harbor's Gift" then
                            exist = true;
                        end
                    end
                    
                    if not exist then
                        local content = {};
                        if profile.Flags:Get("harborGift") == nil then
                            content = modCrates.GenerateRewards("harborGift");
                            profile.Flags:Add{Id="harborGift"};
                        end
                                            
                        local giftCf = CFrame.new(-520.727661, -68.5934601, 437.814148, -1, 0, 0, 0, 1, 0, 0, 0, -1);
                        profile.Garbage:Tag(modCrates.spawn("harborGift", giftCf, {player}, content, true));
                    end
                    
                    modAudio.Play("HeavyMetalDoor", interactPart.Destination).PlaybackSpeed = 0.5;
                end


            end)

        end
    end)
end


return WorldCore;