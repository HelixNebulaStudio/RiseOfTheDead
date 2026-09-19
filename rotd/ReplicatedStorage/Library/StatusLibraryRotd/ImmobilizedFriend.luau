local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");

local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

local statusPackage = {
    Id = "ImmobilizedFriend";
    Icon = shared.Const.PlaceholderIcon;
    Name = "ImmobilizedFriend";
    Description = "";
    Buff = false;
};

function statusPackage.init()
	shared.modEventService:OnInvoked("Character_BindDismount", function(eventPacket: EventPacket, ...)
		local packet = ...;
		local mountChar = packet.MountCharacter;
		local passengerChar = packet.PassengerCharacter;
		local mountStyle = packet.MountStyle;

        local healthComp: HealthComp? = modHealthComponent.getByModel(passengerChar);
        if healthComp == nil or healthComp.IsDead then return end;

        local statusComp: StatusComp? = healthComp.CompOwner.StatusComp;
        if statusComp == nil then return end;

        local statusClass: StatusClassInstance = statusComp:GetOrDefault(statusPackage.Name);
        if statusClass == nil then return end;

        statusClass.BindUpdate(statusClass);
        statusClass.Values.MountInteractConfig.Name = `Interactable`;
	end)

	shared.modEventService:OnInvoked("Character_BindMount", function(eventPacket: EventPacket, ...)
		local packet = ...;
		local mountChar = packet.MountCharacter;
		local passengerChar = packet.PassengerCharacter;
		local mountStyle = packet.MountStyle;

        local healthComp: HealthComp? = modHealthComponent.getByModel(passengerChar);
        if healthComp == nil or healthComp.IsDead then return end;

        local statusComp: StatusComp? = healthComp.CompOwner.StatusComp;
        if statusComp == nil then return end;

        local statusClass: StatusClassInstance = statusComp:GetOrDefault(statusPackage.Name);
        if statusClass == nil then return end;

        statusClass.Values.MountInteractConfig.Name = `MountActive`;
	end)
end

function statusPackage.BindApply(statusClass: StatusClassInstance)
    statusClass.Values.StrongRoot = true;
    statusPackage.BindUpdate(statusClass);
end

function statusPackage.BindUpdate(statusClass: StatusClassInstance)
    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;

    local carryInteractConfig = statusClass.Values.MountInteractConfig;
    if carryInteractConfig == nil then
        carryInteractConfig = modInteractables.createInteractable("Mount");

        carryInteractConfig:SetAttribute("_Label", `Carry {characterClass.Name}`);
        carryInteractConfig:SetAttribute("_Animation", "pickupcharacter");
        carryInteractConfig:SetAttribute("_InteractDuration", 2.95);

        statusClass.Values.MountInteractConfig = carryInteractConfig;
    end
    
    carryInteractConfig.Parent = characterClass.Character;

    if characterClass.ClassName == "NpcClass" then
        local npcClass: NpcClass = characterClass :: NpcClass;

        if npcClass.Interactable then
            npcClass:ToggleInteractable(false);
        end
    end
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;

    if characterClass.ClassName == "NpcClass" then
        local npcClass: NpcClass = characterClass :: NpcClass;

        if npcClass.Interactable then
            npcClass:ToggleInteractable(true);
        end
    end
end

return modStatusClass.new(statusPackage);