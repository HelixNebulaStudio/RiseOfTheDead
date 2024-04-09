local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
repeat task.wait() until shared.MasterScriptInit == true;

--== Variables;
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

--== Script;
for eventName, value in pairs(modConfigurations.SpecialEvent) do
	if value == true then
		if script:FindFirstChild(eventName) then
			require(script[eventName]);
			Debugger:Log("Enabling Special Event(",eventName,").");
		end
	end
end