local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);


--== When something happens;
return function(player, interactData)
	if modBranchConfigs.IsWorld("BanditOutpost") then
		local mission = modMission:GetMission(player, 33);
		if mission and mission.ProgressionPoint >= 14 then
			modMission:CompleteMission(player, 33);
		end
	end
end;
