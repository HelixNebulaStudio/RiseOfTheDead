local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
return function()
	--== Configuration;
	
	--== Variables;
	local depGameAnalytics = require(game.ReplicatedStorage.Dependencies:WaitForChild("GameAnalytics"));
	
	depGameAnalytics:initClient();
end