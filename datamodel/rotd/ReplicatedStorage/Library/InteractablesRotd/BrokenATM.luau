local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

if RunService:IsServer() then
    modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
    modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);

end

local interactablePackage = {};
--==

function interactablePackage.init(super) -- Server/Client
    local BrokenAtm = {
		Name = "BrokenATM";
        Type = "Button";

        LevelRequired = 15;
        InteractDuration = 10;
    };

    function BrokenAtm.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        interactable.TypePackage.BindInteract(interactable, info);
        if info.Action ~= "Server" then return end;

        local player = info.Player;
        if player == nil then return end;

        local profile: ProfileRotd = shared.modProfile:Get(player) :: ProfileRotd;
        local gameSave: GameSaveRotd = profile:GetActiveSave() :: GameSaveRotd;

        local event = modEvents:GetEvent(player, "bankAtm");
        local playerLevel = gameSave:GetStat("Level");
        
        if playerLevel >= 15 and event == nil then
			modEvents:NewEvent(player, {Id="bankAtm"}, true);
			gameSave:AddStat("Money", 2000);

			shared.Notify(player, "You found $2000 in the ATM machine.", "Reward");
		end

        modEvents:SyncEvent(player, "bankAtm");
    end
    
    -- When interactable pops up on screen.
    function BrokenAtm.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        if RunService:IsServer() then return end;
        
        local clientData = info.ClientData;
        if clientData == nil then return end;

		local localplayerStats = clientData.GetStats();
		if localplayerStats == nil or localplayerStats.Level == nil or localplayerStats.Level < 15 then
            interactable.CanInteract = false;
			interactable.Label = "Needs Mastery Level 15";
			return;
		end

		local event = clientData:GetEvent("bankAtm");
        if event then
            interactable.CanInteract = false;
            interactable.Label = "Broken ATM machine";
        else
            interactable.CanInteract = true;
            interactable.Label = "Steal from ATM machine";
        end
    end


    super.registerPackage(BrokenAtm);

end

return interactablePackage;

