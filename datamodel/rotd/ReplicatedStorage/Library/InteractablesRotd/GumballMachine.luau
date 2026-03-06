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

        local player: Player? = info.Player;
        if player == nil then return end;

		local event = modEvents:GetEvent(player, "GumballMachine");
		local timer = event and event.Time;

		if timer == nil or workspace:GetServerTimeNow() >= timer then
			modEvents:NewEvent(player, {Id="GumballMachine"; Time=workspace:GetServerTimeNow()+180;}, true);
			modAudio.Play("SuperCharge", interactable.Part);
			
			local statusList = {};
			
			table.insert(statusList, function()
				-- modStatusEffects.ForceField(player, 120);
				-- shared.Notify(player, "You recieved Forcefield for 2 minutes.", "Reward");
			end)
			
			table.insert(statusList, function()
				-- modStatusEffects.Reinforcement(player, 120);
				-- shared.Notify(player, "You recieved Reinforcement for 2 minutes.", "Reward");
			end)
			
			table.insert(statusList, function()
				-- modStatusEffects.Superspeed(player, 120);
				-- shared.Notify(player, "You recieved Superspeed for 2 minutes.", "Reward");
			end)
			
			table.insert(statusList, function()
				-- modStatusEffects.Lifesteal(player, 120);
				-- shared.Notify(player, "You recieved Lifesteal for 2 minutes.", "Reward");
			end)
			
			statusList[math.random(1, #statusList)]();
		end

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

