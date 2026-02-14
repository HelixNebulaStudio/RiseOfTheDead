local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local interactablePackage = {};
--==

function interactablePackage.init(super) -- Server/Client
    local ResupplyRadio = super.newPackage{
		Name = "ResupplyRadio";
        Type = "Button";
    };

    function ResupplyRadio.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        ResupplyRadio.TypePackage.BindInteract(interactable, info);
        if info.Action == "Client" then return end;
    end
    
    function ResupplyRadio.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        if RunService:IsServer() then return end;

        if interactable.Values.RadioActive ~= true then
			interactable.Label = "Signal for resupply";
			interactable.CanInteract = true;
			
		elseif interactable.Values.CallInterupted == true then
			interactable.Label = "Reactivate transmission";
			interactable.CanInteract = true;
			
		else
			interactable.Label = "Transmitting resupply request";
			interactable.CanInteract = false;
			
		end
    end


    super.registerPackage(ResupplyRadio);

end

return interactablePackage;

