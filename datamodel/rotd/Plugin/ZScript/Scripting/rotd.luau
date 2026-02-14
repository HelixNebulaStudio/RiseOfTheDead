local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local ZScript = {};

function ZScript.Load(zScr, zEnv)
    local Rotd, RotdMeta = zScr.newLib();
    Rotd.GameVersion = modGlobalVars.GameVersion;
    Rotd.GameBuild = modGlobalVars.GameBuild;
    Rotd.BranchColor = modBranchConfigurations.BranchColor;

    zEnv.RiseOfTheDead = Rotd;
end

return ZScript;