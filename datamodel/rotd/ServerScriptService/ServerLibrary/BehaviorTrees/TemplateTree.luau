local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modLogicTree = shared.require(game.ReplicatedStorage.Library.LogicTree);

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

return function(self)
	local tree = modLogicTree.new{};
    return tree;
end