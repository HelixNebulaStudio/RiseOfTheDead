local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local ZSharp = {};

function ZSharp.Load(zSS, zEnv)
	zEnv.Random = Random;
end

return ZSharp;