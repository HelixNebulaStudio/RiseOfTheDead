local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local StorageHandler = {};
StorageHandler.__index = StorageHandler;

--== Script;
function StorageHandler:Init(super)
	function super:OnNewStorage(storage)
		
		
	end
end

return StorageHandler;
