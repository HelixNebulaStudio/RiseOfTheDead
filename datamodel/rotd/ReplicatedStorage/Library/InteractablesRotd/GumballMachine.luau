local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modDropRateCalculator = shared.require(game.ReplicatedStorage.Library.DropRateCalculator);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);

if RunService:IsServer() then
    modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
    modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);

end

local interactablePackage = {};
--==

function interactablePackage.init(super) -- Server/Client
    local GumballMachine = super.newPackage{
		Name = "GumballMachine";
        Type = "Button";
    };

    function GumballMachine.new(interactable: InteractableInstance, player: Player)
    end

    function GumballMachine.BindDestroy(interactable: InteractableInstance, player: Player)
    end

    function GumballMachine.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        GumballMachine.TypePackage.BindInteract(interactable, info);
        if info.Action == "Client" then return end;
    end
    
    -- When interactable pops up on screen.
    function GumballMachine.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        if RunService:IsServer() then return end;
        
        local clientData = info.ClientData;
        if clientData == nil then return end;

        interactable.CanInteract = true;
        interactable.Label = "Out of Service";
    end


    super.registerPackage(GumballMachine);

end

return interactablePackage;

