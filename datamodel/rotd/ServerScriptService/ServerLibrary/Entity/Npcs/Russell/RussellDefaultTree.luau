local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

local treePackage = {
    Logic = {
        EquipSequence={"And"; "EquipWeapon";};
    }
};

function treePackage.ProcessStatus(tree, npcClass: NpcClass)
    return tree.Pass;
end

function treePackage.HasEnemy(tree, npcClass: NpcClass)
    
    return tree.Success or tree.Failure;
end


return treePackage;

---@tree 