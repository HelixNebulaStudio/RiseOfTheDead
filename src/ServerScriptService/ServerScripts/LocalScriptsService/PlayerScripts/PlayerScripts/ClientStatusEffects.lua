return function()
	--== Variables;
	local localplayer = game.Players.LocalPlayer;
	--if not game:IsLoaded() then game.Loaded:Wait(); end;
	
	local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
	local modRemotesManager = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("RemotesManager"));
	local modData = require(localplayer:WaitForChild("DataModule"));
	local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);

	local remotePlayerStatusEffect = modRemotesManager:Get("PlayerStatusEffect");
	
	--== Script;
	local isReady = false;
	remotePlayerStatusEffect.OnClientEvent:Connect(function(cmd, id, ...)
		if cmd == "do" then
			if modStatusEffects[id] then
				modStatusEffects[id](localplayer, ...);
			else
				Debugger:Warn("Unknown status replication:", id);
			end
			
		elseif cmd == "isready" then
			isReady = true;
			
		end
	end)
	
	task.defer(function()
		while not isReady do
			remotePlayerStatusEffect:FireServer("ready");
			task.wait(1);
		end
	end)
end