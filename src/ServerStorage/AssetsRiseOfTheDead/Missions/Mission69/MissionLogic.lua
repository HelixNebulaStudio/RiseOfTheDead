local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");

local missionId = 69;

if RunService:IsServer() then
	local modWorkbenchLibrary = require(game.ReplicatedStorage.Library.WorkbenchLibrary);
	local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
	modOnGameEvents:ConnectEvent("OnNpcDamaged", function(player, damageSource)
		local npcModule = damageSource.NpcModule;
		local storageItem = damageSource.ToolStorageItem;
		local humanoid = npcModule.Humanoid;

		if humanoid.Name ~= "Zombie" or damageSource.Killed ~= true or npcModule.IsDead ~= true then return end;
		if modMission:IsComplete(player, missionId) then return end;

		local toolWorkbenchLib = storageItem and modWorkbenchLibrary.ItemUpgrades[storageItem.ItemId] or nil;

		local mission = modMission:GetMission(player, missionId);
		if mission and mission.Type == 1 and toolWorkbenchLib and (mission.SaveData.WeaponItemId or table.find(toolWorkbenchLib.Type, mission.SaveData.WeaponType) ~= nil) then
			modMission:Progress(player, missionId, function(mission)
				mission.SaveData.Kills = mission.SaveData.Kills -1;
				if mission.SaveData.Kills <= 0 then
					modMission:CompleteMission(player, missionId);
				end
			end)
		end

	end)
end

return MissionLogic;