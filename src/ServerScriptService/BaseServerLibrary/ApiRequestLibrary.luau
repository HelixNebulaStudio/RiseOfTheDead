local ApiRequestLibrary = {};
ApiRequestLibrary.__index = ApiRequestLibrary;

--== Script;
function ApiRequestLibrary:Init(super)
    super:Add{
        Id="updatelog";
        
        Api="Github";
        Url=`https://raw.githubusercontent.com/HelixNebulaStudio/RiseOfTheDead/main/LiveBranch/{super.GameVersion}.md`;
    }
end

return ApiRequestLibrary;
