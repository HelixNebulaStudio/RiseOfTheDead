local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local localPlayer = game.Players.LocalPlayer;

local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local ResupplyStation = {
		Name = "ResupplyStation";
        Type = "ResupplyStation";

        IndicatorPresist = false;
    };

    function ResupplyStation.new(interactable: InteractableInstance, player: Player)
        local config: Configuration = interactable.Config;
        local variant = interactable.Variant;
        
        interactable.CanInteract = true;

        if variant == "AmmoBox" then
            config:SetAttribute("BoxName", "Ammo Box");
            config:SetAttribute("UseLimit", 3);
            interactable.Label = `Use Ammo Box`;

        else
            config:SetAttribute("BoxName", "Supply Crate");
            interactable.Label = `Use Supply Crate`;

        end

        interactable.Values.BoxName = config:GetAttribute("BoxName");

        interactable.Values.UseLimit = config:GetAttribute("UseLimit");
        interactable.Values.PlayerUses = {};
    end

    -- When interacting with interactable.
    function ResupplyStation.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionSource.Client then return end;

        local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
        local resupplyWindow: InterfaceWindow = modClientGuis.getWindow("ResupplyStation");
        if resupplyWindow.Visible then return end;

        resupplyWindow:Open(interactable, info);
    end
    

    -- When interactable pops up on screen.
    function ResupplyStation.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        local values = interactable.Values;

		local playerUses = values.PlayerUses and (values.PlayerUses[localPlayer.Name] or 0);
        local useLimit = values.UseLimit;

		if useLimit and playerUses >= useLimit then
			interactable.Label = "You have exhausted your uses.";
            interactable.CanInteract = false;
			
            if interactable.Variant == "AmmoBox" then
                if interactable.Part 
                and interactable.Part.Parent 
                and interactable.Part.Parent:FindFirstChild("AmmoBoxBase") then
                    for _, obj in pairs(interactable.Part.Parent:GetChildren()) do
                        if obj.Name == "Ammo" then
                            Debugger.Expire(obj, 0);
                        end
                    end
                end
            end
			
			return;
		end

		local str = `Use {values.BoxName}`;
		if useLimit then
			interactable.Label = str..` ({useLimit-playerUses}/{useLimit} Uses)`;
		else
			interactable.Label = str;
		end
        interactable.CanInteract = true;

    end

    super.registerPackage(ResupplyStation);
end

return interactablePackage;

