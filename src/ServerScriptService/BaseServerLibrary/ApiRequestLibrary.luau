local ApiRequestLibrary = {};
ApiRequestLibrary.__index = ApiRequestLibrary;

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

--== Script;
function ApiRequestLibrary:Init(super)
    super:Add{
        Id="updatelog";
        
        Api="Github";
        Url=modBranchConfigs.CurrentBranch.Name == "Dev"
        and `https://raw.githubusercontent.com/HelixNebulaStudio/RiseOfTheDead/main/DevBranch/{ super.DevVersion }.md`
        or `https://raw.githubusercontent.com/HelixNebulaStudio/RiseOfTheDead/main/LiveBranch/{ super.GameVersion }.md`;
    }
end

return ApiRequestLibrary;
