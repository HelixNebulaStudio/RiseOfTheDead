local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modFarmingSystem = shared.require(game.ReplicatedStorage.Library.FarmingSystem);

local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local Planter = super.newPackage{
		Name = "Planter";
        Type = "Planter";

        IndicatorPresist = false;
    };

    function Planter.new(interactable: InteractableInstance)
        local config: Configuration = interactable.Config;
        local interactPart = interactable.Part;
        local pos = interactPart.Position;
        local posStr = `{math.floor(pos.X)}:{math.floor(pos.Y)}:{math.floor(pos.Z)}`;

        config:SetAttribute("_Id", `Planter_{shared.WorldName}_({posStr})`);
        config:SetAttribute("_Proximity", true);

        interactable.CanInteract = false;
    end

    -- When interactable pops up on screen.
    local DRY_COLOR = Color3.fromRGB(90, 85, 83);
    local WATERED_COLOR = Color3.fromRGB(90, 54, 34);
    function Planter.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        local player = info.Player;
        if player == nil then return end;
        
        local planterId = interactable.Id;
        local water = interactable.Values.Water or 0;
        local showCrops = false;

        local shouldFetch = interactable.Values.LastFetch == nil or tick() > interactable.Values.LastFetch;
        interactable.Values.LastFetch = tick()+5;

        local curTime = workspace:GetServerTimeNow();

        local farmingData = modFarmingSystem.getFarmingData(player, shouldFetch);
        if farmingData then
            local planterData = farmingData.Planters[planterId];
            if planterData then
                water = planterData.Water or 0;
                showCrops = water >= 100;
            end
        end
        
        if water >= 100 then
            interactable.Label = `This planter is growing`;
        else
            interactable.Label = `Water: {math.round(water)}%`;
        end

        local interactPart = interactable.Part;
        local soilPart = interactPart.Parent and interactPart.Parent:FindFirstChild("Soil");
        if soilPart then
            soilPart.Color = DRY_COLOR:Lerp(WATERED_COLOR, water/100);
        end

        local cropsModel = interactPart.Parent and interactPart.Parent:FindFirstChild("crops");
        if cropsModel then
            for _, obj in pairs(cropsModel:GetChildren()) do
                if not obj:IsA("BasePart") then continue end;
                if obj.Name == "Hitbox" then continue end;
                obj.Transparency = showCrops and 0 or 1;
            end
        end

    end

    super.registerPackage(Planter);
end

return interactablePackage;

