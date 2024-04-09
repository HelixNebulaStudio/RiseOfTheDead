local OnGameEvents = {};
OnGameEvents.__index = OnGameEvents;
--== Script;
function OnGameEvents:Init(super)
	for _, src in pairs(script:GetChildren()) do
		local hookId = src.Name;
		local hookFunc = require(src);

		super:ConnectEvent(hookId, hookFunc);
	end
end

return OnGameEvents;
