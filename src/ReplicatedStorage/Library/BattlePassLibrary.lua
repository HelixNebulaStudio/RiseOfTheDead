local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);

local library = modLibraryManager.new();
--==
library.BuyLevelCost = 500;
library.PostRewardLvlFmod = 5;

local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetModule(script.Name);
if moddedSelf then moddedSelf:Init(library); end

return library;