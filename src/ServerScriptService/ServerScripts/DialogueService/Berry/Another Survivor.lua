local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);

local generic = require(script.Parent.Parent.Survivor:WaitForChild(script.Name));
--==
return generic;