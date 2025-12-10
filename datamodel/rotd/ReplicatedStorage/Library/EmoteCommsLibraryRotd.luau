local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local library = shared.require(game.ReplicatedStorage.Library.EmoteCommsLibrary);
local modNpcProfileLibrary = shared.require(game.ReplicatedStorage.Library.NpcProfileLibrary);

library:Add{
	Id = "npc";
    Name = "Npc";
    Bubble = true;
    Arg1 = {Type="npcname"; Label="Name:"; Default="Mason"; Textbox=true; Validate=function(v) return modNpcProfileLibrary:Find(v) ~= nil end};
    Free = true;

    GetImage = function(lib, settingDict) 
        local npcLib = modNpcProfileLibrary:Find(settingDict.A1);
        if npcLib == nil then 
            return {Image="rbxassetid://15641265681"};
        end;
        return {Image=npcLib.Avatar or "rbxassetid://15641265681"};
    end
};

return library;