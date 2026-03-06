local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local GIFT_SPAWNCF = CFrame.new(-59.9, 36.3, 286.4, 0, 0, -1, 0, 1, 0, 1, 0, 0);

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);
--==

function WorldCore.onRequire()
    if RunService:IsClient() then return end;
    modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
    
    shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
        local profile: ProfileRotd = shared.modProfile:WaitForProfile(player) :: ProfileRotd;
        if profile == nil then return end;

        WorldCore:SpawnGift(player, "underbridgeGift", GIFT_SPAWNCF);

    end, 999);

    -- 
    shared.modNpcs.spawn2{Name="Lennon";};

    -- Safehouse 4
    shared.modNpcs.spawn2{Name="Vladimir";};
    shared.modNpcs.spawn2{Name="Rachel";};

    shared.modEventService:OnInvoked("Generic_BindTrigger", function(event: EventPacket, ...)
        local player: Player? = event.Player;
        if player == nil then return end;

        local triggerId: string, interactable: InteractableInstance = ...;

        if triggerId == "RepairTSLift" then
            task.spawn(function() 
                if modEvents:GetEvent(player, "lift1Shortcut") then return end;

                local item, storage = shared.modStorage.FindItemIdFromStorages("circuitboards", player);
                if item == nil then
                    shared.Notify(player, "You need a circuit board to repair this.", "Negative");
                    return;
                end

                storage:Remove(item.ID);
                shared.Notify(player, "A circuit board has been removed from your Inventory.", "Negative");
                
                modAudio.Play("Repair", interactable.Part);

                modEvents:NewEvent(player, {Id="lift1Shortcut"}, true);
            end)

        elseif triggerId == "RepairTunnelSpotlight" then
            task.spawn(function() 
                if modEvents:GetEvent(player, "secretSpotlightFix") then return end;

                local item, storage = shared.modStorage.FindItemIdFromStorages("lightbulb", player);
                if item == nil then
                    shared.Notify(player, "You need a light bulb to repair this.", "Negative");
                    return;
                end

                storage:Remove(item.ID);
			    shared.Notify(player, "A light bulb has been removed from your Inventory.", "Negative");
                
                modAudio.Play("Repair", interactable.Part);

                modEvents:NewEvent(player, {Id="secretSpotlightFix"}, true);
            end)

        end
    end)

end


return WorldCore;