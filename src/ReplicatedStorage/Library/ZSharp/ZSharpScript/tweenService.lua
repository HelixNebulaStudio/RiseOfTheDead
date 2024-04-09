local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local TS = game:GetService("TweenService");
--
local ZSharp = {};

function ZSharp.Load(zSS, zEnv)
	local TweenServiceMeta = {};
	TweenServiceMeta.__index = TweenServiceMeta;
	TweenServiceMeta.__metatable = "The metatable is locked";

	local TweenService = {};
	setmetatable(TweenService, TweenServiceMeta);
	
	function TweenService:GetValue(alpha, easingStyle, easingDirection)
		return TS:GetValue(alpha, easingStyle, easingDirection);
	end
	
	zEnv.TweenService = TweenService;
end

return ZSharp;