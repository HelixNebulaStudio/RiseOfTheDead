while shared.MasterScriptInit  ~= true do task.wait() end;
--==
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modRotdCore = require(game.ReplicatedStorage.RotdCore :: ModuleScript);