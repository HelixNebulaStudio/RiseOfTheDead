local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local interactablePackage = {};
--==
function interactablePackage.init(super) -- Server/Client
    local ButtonRotd = {
		Name = "ButtonRotd";
        Type = "Button";
    };
    
    function ButtonRotd.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        interactable.TypePackage.BindPrompt(interactable, info);
        if RunService:IsServer() then return end;

        local clientData = info.ClientData;
        if clientData == nil then return; end;
    end

    super.registerPackage(ButtonRotd);

end

return interactablePackage;

