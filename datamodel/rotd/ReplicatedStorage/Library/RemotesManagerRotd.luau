local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);

function modRemotesManager.onRequire()
	if RunService:IsServer() then
		modRemotesManager:NewFunctionRemote("EngineersPlanner", 0.1);
		modRemotesManager:NewFunctionRemote("AutoTurret", 0.1).Secure = true;
		modRemotesManager:NewFunctionRemote("NpcData", 0.1).Secure = true;
		
		modRemotesManager:NewUnreliableEventRemote("LiveFeedRemote").Secure = true;
	end
end

return modRemotesManager;