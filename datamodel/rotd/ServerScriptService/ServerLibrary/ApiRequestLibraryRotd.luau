local modApiRequestLibrary = require(game.ServerScriptService.ServerLibrary.ApiRequestLibrary);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

--== Script;
function modApiRequestLibrary.onRequire()
    modApiRequestLibrary:Add{
        Id="updatelog";
        
        Api="Github";
        Url=shared.gameConfig.BranchName == "Dev"
        and `https://raw.githubusercontent.com/HelixNebulaStudio/RiseOfTheDead/main/docs/DevBranch/{ modApiRequestLibrary.DevVersion }.md`
        or `https://raw.githubusercontent.com/HelixNebulaStudio/RiseOfTheDead/main/docs/LiveBranch/{ modApiRequestLibrary.GameVersion }.md`;
    }
end

return modApiRequestLibrary;
