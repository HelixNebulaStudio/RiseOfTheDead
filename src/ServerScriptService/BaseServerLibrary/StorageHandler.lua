local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local StorageHandler = {};
StorageHandler.__index = StorageHandler;

--== Script;
function StorageHandler:Init(super)
	function super:OnNewStorage(storage)
		Debugger:Log("OnNewStorage storage", storage.Id);
		
	end
end

return StorageHandler;
