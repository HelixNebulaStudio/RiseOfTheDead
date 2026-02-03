local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local ZScript = {};

function ZScript.Load(zScr, zEnv)
    local Rotd, RotdMeta = zScr.newLib();
    Rotd.GameVersion = modGlobalVars.GameVersion;
    Rotd.GameBuild = modGlobalVars.GameBuild;
    Rotd.BranchColor = modBranchConfigs.BranchColor;

    zEnv.RiseOfTheDead = Rotd;
end

return ZScript;