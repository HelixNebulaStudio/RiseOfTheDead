return function()
	--== Variables;
	local localplayer = game.Players.LocalPlayer;
	--if not game:IsLoaded() then game.Loaded:Wait(); end;
	
	local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
	local modRemotesManager = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("RemotesManager"));
	local modData = require(localplayer:WaitForChild("DataModule"));

	local remoteConVarService = modRemotesManager:Get("ConVarService");
	
	--== Script;
	local localConVars = {
		["setconfig"] = {
			Exec=function(returnPacket, ...)
				local configId, value = ...;

				local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
				modConfigurations.Set(configId, value);
				
				returnPacket.Returns = {configId; modConfigurations[configId]};
				return true;
			end;
		};
	}
	
	function remoteConVarService.OnClientInvoke(conVar, params)
		local rP = {Success=false;};
		
		if localConVars[conVar] then
			local conVarLib = localConVars[conVar];
			if conVarLib.Exec then
				rP.Success = conVarLib.Exec(rP, unpack(params));
			end
			
		else
			rP.Error = "Unknown ConVar.";
			
		end
		
		return rP;
	end
end