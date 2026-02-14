local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local localPlayer = game.Players.LocalPlayer;

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local interactablePackage = {};
--==
function interactablePackage.init(super) -- Server/Client
    local Generator = super.newPackage{
		Name = "Generator";
        Type = "ButtonRotd";
    };
    
    function Generator.new(interactable: InteractableInstance, player: Player)
        local config: Configuration = interactable.Config;
        
        config:SetAttribute("_Toggle", "IsPowered");
        config:SetAttribute("_ToggleAtZeroUses", true);
        config:SetAttribute("_EquipItemId", "jerrycan");
        config:SetAttribute("_Animation", "FixingWire");
        config:SetAttribute("_Label", `Add fuel into the generator ($UsesInverse/$DefaultUses)`);
        config:SetAttribute("_InteractDuration", 1);
    end

    function Generator.BindEvent(interactable: InteractableInstance, info: InteractInfo, eventName: string)
        local interactPart = interactable.Part;
        if RunService:IsClient() then return end;

        local player = info.Player;
        if player == nil then return true; end
            
        local amount = 1;
        local isFulfilled, itemsList = shared.modStorage.fulfillList(player, {
            {ItemId="jerrycan"; Amount=amount;}
        });
        if not isFulfilled then return true; end;
        
        shared.modStorage.consumeList(itemsList);
        
        modAudio.Play("PouringLiquid", interactPart);
        
        if not interactable.Values.IsPowered then return end;
        modAudio.Play("GeneratorStart", interactPart);
        
        local sound: Sound = modAudio.Play("GeneratorLoop", interactPart);
        interactable.Values.GeneratorLoopSound = sound;
        sound.Name = "GeneratorLoopSound";
        sound.Volume = 0;

        TweenService:Create(sound, TweenInfo.new(0.3), {Volume=1}):Play();

        return;
    end

    function Generator.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        Generator.TypePackage.BindPrompt(interactable, info);
        if RunService:IsServer() then return end;
    end

    function Generator.BindReset(interactable: InteractableInstance)
        local sound = interactable.Values.GeneratorLoopSound;

        if sound then
            game.Debris:AddItem(interactable.Values.GeneratorLoopSound, 0);
            interactable.Values.GeneratorLoopSound = nil;
        end
    end

    super.registerPackage(Generator);

end

return interactablePackage;

