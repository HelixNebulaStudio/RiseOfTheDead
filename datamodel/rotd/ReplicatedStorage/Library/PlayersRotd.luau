local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modCollectiblesLibrary = shared.require(game.ReplicatedStorage.Library.CollectiblesLibrary);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManagerRotd);

local modPlayers = shared.require(game.ReplicatedStorage.Library.Players);
--==

function modPlayers.onRequire()
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
	
	task.spawn(InitDuelSystem);
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

	if RunService:IsServer() then return end;

	task.spawn(function()
		local modMeleeToolHandler = shared.require(game.ReplicatedStorage.Library.ToolHandler.MeleeTool);
		modMeleeToolHandler.Init();
	end)
end)

function InitDuelSystem()
	if RunService:IsClient() then return end;

	local duelStatusPackage = shared.require(game.ReplicatedStorage.Library.StatusLibraryRotd.Duel);

	local remoteDuelRequest = modRemotesManager:Get("DuelRequest");
	remoteDuelRequest.OnServerEvent:Connect(function(player, requestType, targetName)
		if requestType == "request" then
			duelStatusPackage.sendAndHandleRequest(player, targetName, 1);
		end
	end)

    shared.modCommandsLibrary.bind{
		["pvp"]={
			Permission = shared.modCommandsLibrary.PermissionLevel.All;
			Description = [[Request a player to a duel.]];

			RequiredArgs = 0;
			UsageInfo = "/pvp playerName [damageMultiplier]";
			Function = function(speaker: Player, args)
				local player = speaker;
				local targetName = args[1];
				local dmgMulti = args[2] or 1;

				duelStatusPackage.sendAndHandleRequest(player, targetName, dmgMulti);
			end
		};
    };
end

return modPlayers;