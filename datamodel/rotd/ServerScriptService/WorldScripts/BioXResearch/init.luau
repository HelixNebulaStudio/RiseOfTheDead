local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modTeamsManager = shared.require(game.ReplicatedStorage.Library.TeamsManager);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

if RunService:IsServer() then

end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);
--==

function WorldCore.onRequire()
    Debugger:Warn(`BioXResearch core loaded.`);
    if RunService:IsServer() then

        local team = modTeamsManager.newTeam(nil, "BioXResearch");
        team.Type = "BioX Research Team";
        team.DestroyOnZeroMembers = false;

        shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
            local profile: ProfileRotd = shared.modProfile:WaitForProfile(player) :: ProfileRotd;
            if profile == nil then return end;

            WorldCore:SpawnGift(player, "sundaysGift", CFrame.new(-154.096, -18.925, 58.493));
            WorldCore:SpawnGift(player, "underbridgeGift", CFrame.new(-163.023, -18.925, 58.493));
            --WorldCore:SpawnGift(player, "mallGift", CFrame.new(-171.089, -18.925, 58.493));
            WorldCore:SpawnGift(player, "clinicGift", CFrame.new(-179.052, -18.925, 58.493));

            team:SetMember(player.Name, true);
            team:Sync();

            player.CharacterAdded:Once(function()
			    game.Players:SetAttribute("AutoRespawn", true);
            end)

        end, 999);

		shared.modEventService:OnInvoked("Dialogue_BindMedicHeal", function(event: EventPacket, ...)
			local player: Player, dialog = ...;

            Debugger:StudioLog(`Dialogue_BindMedicHeal`, event, player, dialog);

            dialog:AddDialog({
                Say = "So BindMedicHeal works.";
                Reply = "Indeed";
            }, function(dialog)
                Debugger:Warn(`Dialogue_BindMedicHeal additional dialogue callback`);
            end);
		end)

        -- MARK: sh1
        shared.modNpcs.spawn2{Name="Mason";};
        shared.modNpcs.spawn2{Name="Russell";};
        shared.modNpcs.spawn2{Name="Stephanie";};
        shared.modNpcs.spawn2{Name="Dr. Deniski";};
        shared.modNpcs.spawn2{Name="Nick";};
        shared.modNpcs.spawn2{Name="Jefferson";};
        shared.modNpcs.spawn2{Name="Jesse";};

        -- MARK: sh2
        shared.modNpcs.spawn2{Name="Carlos";};
        shared.modNpcs.spawn2{Name="Frank";};
        shared.modNpcs.spawn2{Name="Jane";};
        shared.modNpcs.spawn2{Name="Michael";};
        
        -- WorldCore.JosephClass = shared.modNpcs.spawn2{
        --     Name = "Joseph";
        --     CFrame = CFrame.new(-31.709, -13.642, 31.994);
        -- };

    elseif RunService:IsClient() then

    end

    shared.modEventService:OnInvoked("Interactables_BindDoorInteract", function(eventPacket: EventPacket, ...)
        local interactable: InteractableInstance = ...;

        Debugger:StudioLog("Interactables_BindDoorInteract", eventPacket, interactable);
    end)

    shared.modEventService:OnInvoked("Interactables_BindButtonInteract", function(eventPacket: EventPacket, ...)
        local interactable: InteractableInstance = ...;
        local variantId = interactable.Variant;

        Debugger:StudioLog("Interactables_BindButtonInteract", eventPacket, interactable);

        if variantId == "BioXResearchButton" then
            Debugger:Warn(`BioXResearchButton pressed `, interactable.Values);
            modAudio.Play("PartyPopper", interactable.Part);
        end
    end)
end

return WorldCore;