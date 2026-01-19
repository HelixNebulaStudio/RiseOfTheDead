local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modGpsLibrary = shared.require(game.ReplicatedStorage.Library.GpsLibrary);
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
	local wieldComp: WieldComp = playerClass.WieldComp;

	wieldComp.TargetableTags.Zombie = true;
	wieldComp.TargetableTags.Bandit = true;
    wieldComp.TargetableTags.Cultist = true;
	wieldComp.TargetableTags.Rat = true;

    if RunService:IsClient() then return end;
    
    local modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);

    local player = playerClass:GetInstance();
    local profile: ProfileRotd = shared.modProfile:Get(player) :: ProfileRotd;
	local gameSave: GameSaveRotd = profile:GetActiveSave() :: GameSaveRotd;

	task.spawn(function()
		local eventPart = workspace:WaitForChild("Event");
		local masusPlushieSpawnAtt = eventPart:FindFirstChild("MasusPlushie"); 

		local worldInfo = modBranchConfigs.WorldLibrary[modBranchConfigs.GetWorld()];
		if worldInfo and worldInfo.Index then

			local dayName = modSyncTime.GetWeekDay();
			local dayIndex = modSyncTime.WeekdayIndex[dayName];

			if worldInfo.Index == 0 or dayIndex == worldInfo.Index then
				if masusPlushieSpawnAtt and profile.Collectibles.masus == nil then
					task.spawn(function()
						game.ReplicatedStorage.Prefabs.Items:WaitForChild("masusplush");
						local dropPrefab, interactable = modItemDrops.spawn{
							ItemId = "masusplush";
							Quantity = 1;
							SpawnCFrame = masusPlushieSpawnAtt.WorldCFrame;
							Players = {player};
							DespawnDuration = false;
							Anchored = true;
						};
						interactable.Values.CollectibleId = "masus";
					end)
				end
			end
		end
	end)

	player:GetAttributeChangedSignal("Location"):Connect(function()
		if gameSave == nil then return end;

		local location = player:GetAttribute("Location");
		if location == nil then return end;

		local setSpawn = modGpsLibrary.SpawnLocationLibrary[location];
		if setSpawn == nil then return end;
		
		local oldSpawn = gameSave.Spawn;
		gameSave.Spawn = setSpawn;
		Debugger:StudioWarn(`Set spawn from ({oldSpawn}) to ({location} = {setSpawn})`);
	end)

	local properties = playerClass.Properties;
	properties.CanOverheal = true;
end)

return modPlayers;