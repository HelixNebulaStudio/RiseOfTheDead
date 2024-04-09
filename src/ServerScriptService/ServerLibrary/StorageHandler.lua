local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));

--==
local StorageHandler = {}

local moddedSelf = modModEngineService:GetServerModule(script.Name);
if moddedSelf then
	moddedSelf:Init(StorageHandler);
end

return StorageHandler;
