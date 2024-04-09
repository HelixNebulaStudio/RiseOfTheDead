local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Interactable = require(game.ReplicatedStorage.Library.Interactables);

local button = Interactable.Trigger("miaSpawn", "Oh my god, this is one of the bandits.. Looks like he is turning..");
button.Script = script;

return button;