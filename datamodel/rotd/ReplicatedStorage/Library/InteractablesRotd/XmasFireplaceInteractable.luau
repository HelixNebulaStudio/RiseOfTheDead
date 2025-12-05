local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local XmasFireplace = super.newPackage{
		Name = "XmasFireplace";
        Type = "Button";

        InteractDuration = 1;
    };

    function XmasFireplace.new(interactable: InteractableInstance, player: Player)
        local config: Configuration = interactable.Config;
        
        config:SetAttribute("_Toggle", "IsLit");
    end

    -- When interacting with interactable.
    function XmasFireplace.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        XmasFireplace.TypePackage.BindInteract(interactable, info);
        if RunService:IsServer() then return end;
    end
    
    -- When interactable pops up on screen.
    function XmasFireplace.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        if RunService:IsServer() then return end;
        local config: Configuration = interactable.Config;

        local player = game.Players.LocalPlayer;
        local modData = Debugger:Require(player:WaitForChild("DataModule"));

        local missionData = modData:GetMission(46);
        if missionData == nil then 
            interactable.Label = `Requires mission "Warming Up".`;
            interactable.CanInteract = false;
            return;
        end;

        if missionData.Type == 3 then
            local isLit = config:GetAttribute("IsLit") == true;
            
            interactable.Label = isLit and "Extinguish fireplace" or "Light fireplace";

            local lightSource = script.Parent:FindFirstChild("_lightSource")
            if lightSource then
                lightSource._lightPoint.PointLight.Enabled = isLit;
                lightSource.firePoint.Fire.Enabled = isLit;
            end

            return;
        end

        if missionData.Type == 1 and missionData.ProgressionPoint == 1 then
            interactable.Label = "Requires 5 Coal";
            interactable.CanInteract = true;
            
        elseif missionData.Type == 1 and missionData.ProgressionPoint == 2 then
            interactable.CanInteract = true;
            
        elseif missionData.Type == 2 then
            interactable.Label = "Talk to Mr. Klaws.";
            interactable.CanInteract = false;
            
        end
    end

    super.registerPackage(XmasFireplace);
end

return interactablePackage;

