local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modCharacterInteractions = shared.require(game.ReplicatedStorage.Library.CharacterInteractions);

local interactablePackage = {};
--==
function interactablePackage.init(super) -- Server/Client
    local Mount = super.newPackage{
		Name = "Mount";
        Type = "ButtonRotd";
    };
    
    function Mount.new(interactable: InteractableInstance)
        Mount.TypePackage.new(interactable);
    end

    function Mount.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        Mount.TypePackage.BindInteract(interactable, info);
        if RunService:IsClient() then return end;

        local mountToCharacter = interactable.Config.Parent;
        if mountToCharacter == nil then return end;

        local healthComp: HealthComp? = modHealthComponent.getByModel(mountToCharacter);
        if healthComp == nil or healthComp.IsDead then return end;

        local mountToCharacterClass: CharacterClass? = healthComp.CompOwner :: CharacterClass;
        if mountToCharacterClass == nil then return end;

        local statusComp: StatusComp? = mountToCharacterClass.StatusComp;
        if statusComp == nil then return end;

        local mountByCharacterClass: CharacterClass?
        if info.NpcClass then
            mountByCharacterClass = info.NpcClass;
        elseif info.Player then
            mountByCharacterClass = shared.modPlayers.get(info.Player);
        end
        if mountByCharacterClass == nil then return end;

        mountToCharacterClass.Head.CanCollide = true;
        pcall(function()
            mountToCharacter.UpperTorso.CanCollide = true;
            mountToCharacter.LowerTorso.CanCollide = true;
        end)

        modCharacterInteractions.Mount(mountByCharacterClass.Character, mountToCharacter);
    end

    function Mount.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        Mount.TypePackage.BindPrompt(interactable, info);
    end

    super.registerPackage(Mount);

end

return interactablePackage;

