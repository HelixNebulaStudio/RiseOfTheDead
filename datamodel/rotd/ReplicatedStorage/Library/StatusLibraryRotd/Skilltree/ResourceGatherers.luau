local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");

local modTeamsManager = shared.require(game.ReplicatedStorage.Library.TeamsManager);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

local statusPackage = {
    Id = "resgat";
    Icon = "rbxassetid://16380816785";
    Name = "Resource Gatherers Cooldown";
    Description = "$PlayerName helped you picked up a $ItemName.";
    Buff = true;
};

if RunService:IsServer() then
    local skillId = statusPackage.Id;

    function statusPackage.onRequire()
        warn(`Resource Gatherers onRequire.`);
        shared.modEventService:OnInvoked("Generic_BindItemPickup", function(eventPacket: EventPacket, ...)
            local player: Player? = eventPacket.Player;
            if player == nil then return end;

            local interactable: InteractableInstance = ...;

            local playerClass: PlayerClass = shared.modPlayers.get(player);
            
            local teamType = playerClass.Properties.ActiveTeamType or "Party";
            local team: TeamClass = modTeamsManager.getTeamByMemberName(playerClass.Name, teamType);
            if team == nil then return end;
            
            local itemId = interactable.Values.ItemId;
            local quantity: number = interactable.Values.Quantity or 1;
            local itemLib = modItemsLibrary:Find(itemId);

            for memberName, memberData in pairs(team.Members) do
                if memberName == player.Name then continue end;
                if memberData.IsNpc then continue end;

                local memberCharClass: CharacterClass? = team:GetMemberCharacterClass(memberName);
                if memberCharClass == nil or memberCharClass.ClassName ~= "PlayerClass" then continue end;

                local memberProfile = shared.modProfile:Find(memberName);
                if memberProfile == nil then continue end;

                local memberPlayer = memberProfile.Player;

                local skillData = memberProfile.SkillTree:GetSkill(memberPlayer, skillId);
                local level, skillStats = memberProfile.SkillTree:CalStats(skillData.Library, skillData.Points);
                if level <= 0 then continue end;

                if not interactable:HasPermissions("CanInteract", memberName) then return end;
                if memberCharClass.StatusComp:GetOrDefault(skillId) then continue end;

                local profileSettings = memberProfile.Settings or {};
                if profileSettings.AutoPickupMode == 2 then
                    return;

                elseif profileSettings.AutoPickupMode == 1 then
                    local pickUpEnabled = profileSettings.Cache.PickupCache[itemId];

                    if pickUpEnabled ~= true then
                        return;
                    end
                end

                local isSharedDrop = interactable.Values.SharedDrop == true;
                if interactable.Values.StorageItem then
                    isSharedDrop = false;
                end
    
                if isSharedDrop ~= true and interactable.Values.TakerName then
                    return;
                end;
                
                if interactable.Values.StorageItem then return end; -- Unique item; Naturally not a shared drop;

                local duration = skillStats.Cooldown.Value;

                memberCharClass.StatusComp:Apply(skillId, {
                    Expires = workspace:GetServerTimeNow() + duration;
                    Duration = duration;
                    Values = {
                        PlayerName = playerClass.Name;
                        ItemName = itemLib.Name;
                    };
                });

                local memberInventory: Storage = memberProfile.ActiveInventory;

                local rPacket = memberInventory:InsertRequest(
                    {ItemId=itemId; Quantity=quantity;} :: StorageItem,
                    {CancelIfCantFitAll=true;}
                );

                if rPacket.Success ~= true then
                    return;
                end

                local soundName;
                if interactable.Values.PickUpSound then
                    soundName = interactable.Values.PickUpSound;

                else
                    if itemLib and itemLib.Type == modItemsLibrary.Types.Resource then
                        if itemLib.Name == "Metal Scraps" then
                            soundName = "StorageMetalPickup";
                        elseif itemLib.Name == "Glass Shards" then
                            soundName = "StorageGlassPickup";
                        elseif itemLib.Name == "Wooden Parts" then
                            soundName = "StorageWoodPickup";
                        elseif itemLib.Name == "Cloth" then
                            soundName = "StorageClothPickup";
                        else
                            soundName = "StorageItemPickup";
                        end
                    elseif itemLib and itemLib.Type == modItemsLibrary.Types.Blueprint then
                        soundName = "StorageBlueprintPickup";
                    elseif itemLib and itemLib.Type == modItemsLibrary.Types.Tool then
                        soundName = "StorageWeaponPickup";
                    elseif itemLib and itemLib.Type == modItemsLibrary.Types.Clothing then
                        soundName = "StorageClothPickup";
                    else
                        soundName = "StorageItemPickup";
                    end

                end

                shared.Notify(memberPlayer, `{player.Name} picked up {itemLib.Name}{quantity > 1 and ` ({quantity})` or ``} for you.`, 
                    "Inform", nil, {
                    SndId = soundName;
                    SndSpeed = math.random(70, 120)/100;
                });
                modReplicationManager.UnreplicateFrom(memberPlayer, interactable.Config.Parent);

            end
        end)
    end
end

return modStatusClass.new(statusPackage);