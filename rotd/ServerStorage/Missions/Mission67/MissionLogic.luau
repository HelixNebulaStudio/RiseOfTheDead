local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");

local MISSION_ID = 67;

if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	shared.modEventService:OnInvoked("Generic_BindTrigger", function(event: EventPacket, ...) 
		local player = event.Player;
		if player == nil then return end;

		local triggerId, packet = ...;
		if triggerId ~= "ShopService_Sell" then return end;

		local finalPrice = packet.FinalPrice;

		if modMission:IsComplete(player, MISSION_ID) then return end;

		modMission:Progress(player, MISSION_ID, function(mission)
			mission.SaveData.Money = mission.SaveData.Money +finalPrice;
			if mission.SaveData.Money >= mission.SaveData.MaxMoney then
				modMission:CompleteMission(player, MISSION_ID);
			end
		end)
	end)
end

return MissionLogic;