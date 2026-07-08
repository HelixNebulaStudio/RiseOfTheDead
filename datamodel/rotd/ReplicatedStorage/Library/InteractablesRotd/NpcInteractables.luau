local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local interactablePackage = {};
--==

function interactablePackage.init(super) -- Server/Client
    local KnockoutNpc = super.newPackage{
		Name = "Knockout";
        Type = "ButtonRotd";

        IndicatorPresist = false;
        InteractDuration = 1;
    };

    function KnockoutNpc.new(interactable: InteractableInstance, player: Player)
        local config: Configuration = interactable.Config;

        interactable.Label = `Knockout`;
    end

    function KnockoutNpc.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        KnockoutNpc.TypePackage.BindInteract(interactable, info);
        if info.Action == "Client" then return end;


        local characterClass: CharacterClass;
        if info.NpcClass then
            characterClass = info.NpcClass;
        elseif info.Player then
            characterClass = shared.modPlayers.get(info.Player);
        end
        if characterClass == nil then return; end
        

        local character = interactable.Config.Parent;

        if not workspace.Entity:IsAncestorOf(character) then return end;
        if character:FindFirstChildWhichIsA("Humanoid") == nil then return end;

        local healthComp: HealthComp? = modHealthComponent.getByModel(character);
        if healthComp == nil or healthComp.IsDead or not healthComp:CanTakeDamageFrom(characterClass) then return; end;

        modAudio.Play("Punch", character);

        healthComp:TakeDamage(DamageData.new{
            Damage = (healthComp.CurHealth-healthComp.KillHealth)+1;
            DamageType = "IgnoreArmor";
        });
    end

    super.registerPackage(KnockoutNpc);

end

return interactablePackage;

