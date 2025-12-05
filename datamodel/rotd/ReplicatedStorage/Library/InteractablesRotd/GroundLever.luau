local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local interactablePackage = {};
local tweenInfo = TweenInfo.new(3);

function interactablePackage.init(super) -- Server/Client
    local GroundLever = super.newPackage{
		Name = "GroundLever";
        Type = "Hold";

        InteractDuration = 0.5;
    };

    function GroundLever.new(interactable: InteractableInstance, player: Player)
        local config: Configuration = interactable.Config;
        
        interactable.CanInteract = true;
        interactable.Label = `Pull Lever`;

        config:SetAttribute("_Toggle", "IsPowered");
    end

    function GroundLever.BindHold(interactable: InteractableInstance, info: InteractInfo)
        GroundLever.TypePackage.BindHold(interactable, info);

        local config: Configuration = interactable.Config;
        local stickBaseMotor = interactable.Part:WaitForChild("stickBase");

        if interactable.Values.IsHolding then
            TweenService:Create(stickBaseMotor, tweenInfo, {
                C1=CFrame.Angles(0, 0, 0);
            }):Play();
        else
            TweenService:Create(stickBaseMotor, tweenInfo, {
                C1=CFrame.Angles(math.rad(90), 0, 0);
            }):Play();
        end
    end

    super.registerPackage(GroundLever);
end

return interactablePackage;

