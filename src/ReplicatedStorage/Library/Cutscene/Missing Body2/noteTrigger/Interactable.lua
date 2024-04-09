local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Interactable = require(game.ReplicatedStorage.Library.Interactables);

local button = Interactable.Trigger("MB2 Note", "\"Thank you for freeing my spirit from the zombie body. My soul is no longer tormented and will no longer haunt the world.\" ~ Jack, Pick Up Note");
button.Script = script;

return button;