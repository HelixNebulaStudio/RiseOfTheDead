local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modGeneralCrate = require(script.Parent.crate);

return function(handler) return modGeneralCrate(handler, script.Name, "sectordcrate"); end;
