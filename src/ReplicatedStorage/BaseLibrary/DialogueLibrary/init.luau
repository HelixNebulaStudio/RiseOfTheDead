local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local DialogueLibrary = {};
DialogueLibrary.__index = DialogueLibrary;
--== Script;
function DialogueLibrary:Init(super)
	local tarSrc = super.Script;

    for _, mS in pairs(script:GetChildren()) do
        if not mS:IsA("ModuleScript") then continue end;

        if super.Modules[mS.Name] then error("DialogueLibrary>>  Npc ("..mS.Name..") already exist."); end;
        super.Modules[mS.Name] = mS;
        
        mS.Parent = tarSrc;
    end
end

return DialogueLibrary;