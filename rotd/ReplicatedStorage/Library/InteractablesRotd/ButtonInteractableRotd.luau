local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local interactablePackage = {};
--==
function interactablePackage.init(super) -- Server/Client
    local ButtonRotd = super.newPackage{
		Name = "ButtonRotd";
        Type = "Button";
    };
    
    function ButtonRotd.new(interactable: InteractableInstance)
        ButtonRotd.TypePackage.new(interactable);
    end

    function ButtonRotd.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        ButtonRotd.TypePackage.BindInteract(interactable, info);
    end

    function ButtonRotd.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        if interactable.Values.FactionTag and info.Action == "Client" then
            local playerFactionTag = localPlayer:GetAttribute("FactionTag");
            if playerFactionTag == nil or playerFactionTag ~= interactable.Values.FactionTag then

                interactable.CanInteract = false;
                interactable.Label = `This belongs to another faction.`;

                return;
            end
        end

        ButtonRotd.TypePackage.BindPrompt(interactable, info);
    end

    super.registerPackage(ButtonRotd);

end

return interactablePackage;

