local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local ItemSkinsLibrary = {};
ItemSkinsLibrary.__index = ItemSkinsLibrary;

--== Script;
function ItemSkinsLibrary:Init(super)

    --== MARK: Pattern Skins
    super:Add{
        Id="skincamo";
        Type=super.SkinType.Pattern;

        Name="Camo";
        Icon="rbxassetid://17635624742";
    
        Patterns={
            {Id="v1"; Name="Variant 1"; Image="rbxassetid://4386335941"; DefaultScale=Vector2.new(1, 1); };
            {Id="v2"; Name="Variant 2"; Image="rbxassetid://4386336507"; DefaultScale=Vector2.new(1, 1); };
            {Id="v3"; Name="Varient 3"; Image="rbxassetid://4386337276"; DefaultScale=Vector2.new(1, 1); };
            {Id="v4"; Name="Varient 4"; Image="rbxassetid://4386480680"; DefaultScale=Vector2.new(1, 1); };
            {Id="v5"; Name="Varient 5"; Image="rbxassetid://4386479893"; DefaultScale=Vector2.new(1, 1); };
            {Id="v6"; Name="Varient 6"; Image="rbxassetid://4386481250"; DefaultScale=Vector2.new(1, 1); };
        };
    };

end

--[[
SkinData = {
    Designs={
        {};
    };
    Parts={
        {L=0; };
    }
}
]]

return ItemSkinsLibrary;