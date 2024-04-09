local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local modBranchConfigs = Debugger:Require(game.ReplicatedStorage.Library.BranchConfigurations);
local library = modLibraryManager.new();

library:Add{
	Id="updatelog";
	
	Api="Trello";
	Url="https://api.trello.com/1/cards/"..(modBranchConfigs.CurrentBranch.Name ~= "Dev" and "5d17591893d74746483f1606" or "5d4749d78b42667f3e0dc736");
}

local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetServerModule(script.Name);
if moddedSelf then moddedSelf:Init(library); end

return library;
