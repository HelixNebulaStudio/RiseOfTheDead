local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

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
        ButtonRotd.TypePackage.BindPrompt(interactable, info);
    end

    super.registerPackage(ButtonRotd);

end

return interactablePackage;

