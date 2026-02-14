local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modCollectiblesLibrary = shared.require(game.ReplicatedStorage.Library.CollectiblesLibrary);

local modPlayers = shared.require(game.ReplicatedStorage.Library.Players);
--==

function modPlayers.onRequire()
	Debugger:Warn("PlayersRotd onRequire.");
	
	shared.modEventService:OnInvoked("Generic_BindItemPickup", function(eventPacket: EventPacket, ...)
		local interactable: InteractableInstance = ...;

		task.spawn(function()
			local player: Player? = eventPacket.Player;
			if player == nil then return end;
			
			local collectibleId = interactable.Values.CollectibleId;
			if collectibleId == nil then return end;

			local lib = modCollectiblesLibrary:Find(collectibleId);
			if lib == nil then return; end;
			
			local profile = shared.modProfile:Get(player);
			profile:UnlockCollectible(collectibleId);
		end)
	end)
end

shared.coreBind(modPlayers.Player, "_new", function(playerClass: PlayerClass)
    local player = playerClass:GetInstance();

	local wieldComp: WieldComp = playerClass.WieldComp;

	wieldComp.TargetableTags.Zombie = true;
	wieldComp.TargetableTags.Bandit = true;
    wieldComp.TargetableTags.Cultist = true;
	wieldComp.TargetableTags.Rat = true;

    if RunService:IsClient() then return end;
    
	local properties = playerClass.Properties;
	properties.CanOverheal = true;
end)

shared.coreBind(modPlayers.Player, "_character_added", function(playerClass: PlayerClass, character: Model)
    local characterComp = playerClass.CharacterComp;

end)

return modPlayers;