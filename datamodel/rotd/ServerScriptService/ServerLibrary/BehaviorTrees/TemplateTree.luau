local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modVector = require(game.ReplicatedStorage.Library.Util.Vector);

return function(self)
	local tree = modLogicTree.new{};
    return tree;
end