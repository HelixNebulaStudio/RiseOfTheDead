local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--=
local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local library = modLibraryManager.new();

--==
library.SkinType = {
    Pattern="Pattern";
    Texture="Texture";
}

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