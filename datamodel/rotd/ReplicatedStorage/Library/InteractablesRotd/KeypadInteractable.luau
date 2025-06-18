local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local interactablePackage = {};
--==

function interactablePackage.init(super) -- Server/Client
    if RunService:IsServer() then
        modRemotesManager:NewEventRemote("KeypadInput");
    end
    local remoteKeypadInput = modRemotesManager:Get("KeypadInput");

    local Keypad = {
		Name = "Keypad";
        Type = "Keypad";

        IndicatorPresist = false;
    };

    function Keypad.new(interactable: InteractableInstance, player: Player)
        local config: Configuration = interactable.Config;

        interactable.CanInteract = true;
        interactable.Label = `Use Keypad`;
    end

    function Keypad.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Action ~= info.ActionSource.Client then return end;
        
        modClientGuis.toggleWindow("Keypad", true, interactable, info);
    end

    super.registerPackage(Keypad);

    
    if RunService:IsServer() then
        remoteKeypadInput.OnServerEvent:Connect(function(player, interactConfig, input)
            local rPacket = {};

            if interactConfig == nil or not interactConfig:IsA("Configuration") then 
                rPacket.FailMsg = `Invalid interact object.`;
                return rPacket;
            end;

            local interactable: InteractableInstance = super.getOrNew(interactConfig, player);
            local interactPart = interactable.Part;
            
            local distanceFromTrigger = player:DistanceFromCharacter(interactPart.Position) or -1;
            if interactPart == nil or distanceFromTrigger > 20 then
                Debugger:Warn(player.Name,"Too far from trigger. ("..distanceFromTrigger..")");
                rPacket.FailMsg = `Too far from object.`
                return rPacket; 
            end;
            
            shared.modEventService:ServerInvoke(
                "InteractService_OnButton", 
                {ReplicateTo={player}}, 
                interactConfig, 
                {InputCode = input;}
            );

            return;
        end)
    end
end

return interactablePackage;

