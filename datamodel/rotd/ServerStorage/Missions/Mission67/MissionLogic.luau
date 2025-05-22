local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local missionId = 67;

if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	local modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
	modOnGameEvents:ConnectEvent("OnEventPoint", function(pointName, packet)
		if pointName ~= "ShopService_Sell" then return end;
 
		local player = packet.Player;
		local finalPrice = packet.FinalPrice;

		if modMission:IsComplete(player, missionId) then return end;

		modMission:Progress(player, missionId, function(mission)
			mission.SaveData.Money = mission.SaveData.Money +finalPrice;
			if mission.SaveData.Money >= mission.SaveData.MaxMoney then
				modMission:CompleteMission(player, missionId);
			end
		end)
	end)
end

return MissionLogic;