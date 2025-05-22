local modApiRequestLibrary = require(game.ServerScriptService.ServerLibrary.ApiRequestLibrary);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

--== Script;
function modApiRequestLibrary.onRequire()
    modApiRequestLibrary:Add{
        Id="updatelog";
        
        Api="Github";
        Url=modBranchConfigs.CurrentBranch.Name == "Dev"
        and `https://raw.githubusercontent.com/HelixNebulaStudio/RiseOfTheDead/main/docs/DevBranch/{ modApiRequestLibrary.DevVersion }.md`
        or `https://raw.githubusercontent.com/HelixNebulaStudio/RiseOfTheDead/main/docs/LiveBranch/{ modApiRequestLibrary.GameVersion }.md`;
    }
end

return modApiRequestLibrary;
