local RemotesManager = {};
RemotesManager.__index = RemotesManager;
--== Script;
function RemotesManager:Init(super)
	super:NewFunctionRemote("EngineersPlanner", 0.1);
	super:NewFunctionRemote("AutoTurret", 0.1).Secure = true;
	super:NewFunctionRemote("NpcData", 0.1).Secure = true;
	
end

return RemotesManager;