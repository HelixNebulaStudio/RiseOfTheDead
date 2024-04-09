local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);

return function(self)
	local tree = modLogicTree.new{
		Root={"Or"; "AggroLogic"};
		
		AggroLogic={"Or"; "CanMove";};
		CanMove={"Or"; "CanAttack";};
		CanAttack={"Or"; "CanDash";};
	};
	
	local cache = {};
	
	tree:Hook("CanMove", function() 
		if true then
			return modLogicTree.Status.Success;
		end
		return modLogicTree.Status.Failure;
	end)
	
	
	return tree;
end
