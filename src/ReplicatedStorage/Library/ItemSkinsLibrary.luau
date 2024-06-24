local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--=
local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local library = modLibraryManager.new();
library.Script = script;

library.SkinType = {
    Pattern="Pattern";
    Texture="Texture";
}

library.ItemSkinIdList = {};
--==

function library:GetSurfaceAppearance(skinId, variantId)
    local folder = script:FindFirstChild(skinId);
    if folder then
        variantId = string.gsub(variantId, skinId, "");
        return folder:FindFirstChild(variantId);
    end

    return;
end

function library:GetItemSkinIdList(itemId)
    return library.ItemSkinIdList[itemId];
end

library:SetOnAdd(function(data)
    if data.Type ~= library.SkinType.Texture then return end;

    for itemId, lib in pairs(data.Textures) do
        local itemSkinIdList = library.ItemSkinIdList[itemId];
        if itemSkinIdList == nil then
            itemSkinIdList = {};
            library.ItemSkinIdList[itemId] = itemSkinIdList;
        end

        table.insert(itemSkinIdList, data.Id);
    end
end)

--==

library:Add{
	Id="skinbasic";
    Type=library.SkinType.Pattern;
    OldId="Basic";

	Name="Basic";
    Icon="rbxassetid://17635624550";

    Patterns={
        {Id="grids"; Name="Grids"; Image="rbxassetid://2686209243"; DefaultScale=Vector2.new(0.1, 0.1); };
        {Id="dots"; Name="Dots"; Image="rbxassetid://2686209162"; DefaultScale=Vector2.new(0.05, 0.05); };
        {Id="checkers"; Name="Checkers"; Image="rbxassetid://2692783156"; DefaultScale=Vector2.new(0.1, 0.1); };
    };
};

local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetModule(script.Name);
if moddedSelf then moddedSelf:Init(library); end

return library;