local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);

function modRemotesManager.onRequire()
	if RunService:IsServer() then

		--== Interfaces;
		modRemotesManager:NewUnreliableEventRemote("LiveFeedRemote").Secure = true;
		modRemotesManager:NewFunctionRemote("NpcData", 0.1).Secure = true;

		--== Workbench;
		modRemotesManager:NewFunctionRemote("WorkbenchService", 0.1);
		modRemotesManager:NewFunctionRemote("DeconstructItem", 0.5);
		modRemotesManager:NewFunctionRemote("TweakItem", 0.5);
		modRemotesManager:NewFunctionRemote("PolishTool", 0.5).Secure = true;
		modRemotesManager:NewFunctionRemote("BlueprintHandler", 0.1);

		--== Equipments;
		modRemotesManager:NewFunctionRemote("EngineersPlanner", 0.1);
		modRemotesManager:NewFunctionRemote("AutoTurret", 0.1).Secure = true;
		
		--== GameModes;
		modRemotesManager:NewFunctionRemote("GameModeLobbies", 1).Secure = true;
		modRemotesManager:NewFunctionRemote("GameModeRequest", 0.1).Secure = true;
		modRemotesManager:NewFunctionRemote("GameModeExit", 1);
		modRemotesManager:NewEventRemote("GameModeUpdate");
		modRemotesManager:NewEventRemote("GameModeHud");
		modRemotesManager:NewEventRemote("GameModeAssign");

	end
end

return modRemotesManager;