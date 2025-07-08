local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local interactablePackage = {};
--==

function interactablePackage.init(super) -- Server/Client
    local PowerBox = {
		Name = "PowerBox";
        Type = "Button";

        IndicatorPresist = false;
        InteractableRange = 5;
    };

    function PowerBox.new(interactable: InteractableInstance, player: Player)
        local config: Configuration = interactable.Config;
		local isPowered = config:GetAttribute("IsPowered") :: string;
        local powerGroupId = config:GetAttribute("PowerGroupId") :: string;

        interactable.CanInteract = true;
        interactable.Label = `Toggle Power`;

        interactable.Values.IsPowered = isPowered;
        interactable.Values.PowerGroupId = powerGroupId;

        if isPowered then
            interactable.Animation = "UnpullLever";
        else
            interactable.Animation = "PullLever";
        end
    end

    -- When interacting with interactable.
    function PowerBox.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action == "Server" then return; end;

        interactable.CanInteract = false;

        interactable.Config:SetAttribute("IsPowered", not interactable.Values.IsPowered);
        local isEnabled = interactable.Values.IsPowered;

        local lightSources;
        if lightSources == nil then
            lightSources = {};
            local lightsFolder = workspace.Environment[interactable.Values.PowerGroupId]:GetDescendants();
            for a=1, #lightsFolder do
                if lightsFolder[a].Name == "_lightSource" then
                    local lightTable = {Source=lightsFolder[a]; OriginalColor=lightsFolder[a].Color; LightObjects={}};
                    local lights = lightsFolder[a]:GetDescendants();
                    for b=1, #lights do
                        if lights[b]:IsA("Light") then
                            table.insert(lightTable.LightObjects, {Light=lights[b]; OriginalColor=lights[b].Color});
                        end
                    end
                    table.insert(lightSources, lightTable);
                end
            end
        end
        modAudio.Play("LeverPull", script.Parent).PlaybackSpeed = math.random(14, 16)/10;

        if isEnabled then
            interactable.Animation = "UnpullLever";
            for a=1, #lightSources do
                lightSources[a].Source.Material = Enum.Material.Neon;
                for b=1, #lightSources[a].LightObjects do
                    lightSources[a].LightObjects[b].Light.Enabled = true;
                end
            end
        else
            interactable.Animation = "PullLever";
            for a=1, #lightSources do
                lightSources[a].Source.Material = Enum.Material.SmoothPlastic;
                for b=1, #lightSources[a].LightObjects do
                    lightSources[a].LightObjects[b].Light.Enabled = false;
                end
            end
        end

        task.wait(1);
        interactable.CanInteract = true;
    end
    
    -- When interactable pops up on screen.
    function PowerBox.BindPrompt(interactable: InteractableInstance, info: InteractInfo)

    end

    super.registerPackage(PowerBox);
end

return interactablePackage;

