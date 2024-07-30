local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local modBranchConfigs = Debugger:Require(game.ReplicatedStorage.Library.BranchConfigurations);

--
local library = modLibraryManager.new();

library.BranchName = modBranchConfigs.BranchName;
library.GameVersion = string.match(modGlobalVars.GameVersion, "%d.%d");
library.DevVersion = string.match(modGlobalVars.DevVersion, "%d.%d");

local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetServerModule(script.Name);
if moddedSelf then moddedSelf:Init(library); end

return library;
