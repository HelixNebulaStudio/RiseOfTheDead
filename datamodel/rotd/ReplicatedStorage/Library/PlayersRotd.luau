local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modGpsLibrary = shared.require(game.ReplicatedStorage.Library.GpsLibrary);

local modPlayers = shared.require(game.ReplicatedStorage.Library.Players);
--==

shared.coreBind(modPlayers.Player, "_new", function(playerClass: PlayerClass)
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
						local newPrefab, interactData = modItemDrops.Spawn({
							Type="Tool"; 
							ItemId="masusplush"; 
							Quantity=1}, 
							masusPlushieSpawnAtt.WorldCFrame, 
							{player}, 
							false
						);
						interactData.CollectibleId = "masus";
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
		
		gameSave.Spawn = setSpawn;
		Debugger:StudioWarn(`Set spawn to {location} = {setSpawn}`);
	end)
end)

return modPlayers;