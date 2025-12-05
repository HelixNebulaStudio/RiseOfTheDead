local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);

local gateTweenInfo = TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut);

local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local CargoShipGatesLever = super.newPackage{
		Name = "CargoShipGatesLever";
        Type = "Lever";
    };

    function CargoShipGatesLever.new(interactable: InteractableInstance, player: Player)
        local config: Configuration = interactable.Config;

        interactable.Label = "Toggle Gates";

        if RunService:IsClient() or config.Parent == nil then return end;

        local gates = {
            config.Parent:WaitForChild("LeftGate"); 
            config.Parent:WaitForChild("RightGate");
        };
	    
        local tracks = {};
        for a=1, #gates do
            local gate = gates[a];
            local gateAnimation = gate:WaitForChild("GateAnimation");
            local animator = gate:WaitForChild("AnimationController"):WaitForChild("Animator");

            table.insert(tracks, animator:LoadAnimation(gateAnimation));
        end
        for a=1, #tracks do
            local track = tracks[a];

            track:Play(nil, nil, 0);
            track:AdjustSpeed(0);
        end
        interactable.Values.Tracks = tracks;
    end

    -- When interacting with interactable.
    function CargoShipGatesLever.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        local config: Configuration = interactable.Config;
        if config.Parent == nil then return end;

        interactable.Values.SkipToggleReset = true;
        CargoShipGatesLever.TypePackage.BindInteract(interactable, info);

        if RunService:IsClient() then return end;
        interactable.Values.Toggling = true;
        interactable:Sync();

        local rotorMotor = config.Parent:WaitForChild("Body"):WaitForChild("Rotor");
        local tracks = interactable.Values.Tracks;
        
		modAudio.Play("HangerGateOpen", config:FindFirstChild("GateSound"));

		if interactable.Values.IsActive then
			TweenService:Create(rotorMotor, TweenInfo.new(0.7), {
                C0=CFrame.new(-0.541, 0.142, 0.038) * CFrame.Angles(math.rad(-90),0,0)
            }):Play();
		
			for a=1, #tracks do
				local track = tracks[a];
				
				track.TimePosition=0.01;
				TweenService:Create(track, gateTweenInfo, {
					TimePosition=5.99;
				}):Play();
			end

        else
			TweenService:Create(rotorMotor, TweenInfo.new(0.7), {
                C0=CFrame.new(-0.541, 0.142, 0.038)
            }):Play();
            
			for a=1, #tracks do
				local track = tracks[a];

				track.TimePosition=5.99;
				TweenService:Create(track, gateTweenInfo, {
					TimePosition=0;
				}):Play();
			end

		end
        Debugger:Warn(`CargoShipGatesLever.BindInteract {interactable.Values.IsActive}`);

        task.wait(7);
        interactable.Values.Toggling = false;
        interactable:Sync();
    end
    
    -- When interactable pops up on screen.
    function CargoShipGatesLever.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        CargoShipGatesLever.TypePackage.BindPrompt(interactable, info);
        if RunService:IsServer() then return end;
        
        if interactable:HasPermissions("CanInteract") == false then
            interactable.CanInteract = false;
            return;
        end
        
        local clientData = info.ClientData;
        if clientData == nil then return; end;

        if interactable.Values.Toggling then
            interactable.CanInteract = false;
            return;
        end
        interactable.CanInteract = true;
    end

    super.registerPackage(CargoShipGatesLever);
end

return interactablePackage;

