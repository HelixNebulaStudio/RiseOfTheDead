local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Interactable = require(game.ReplicatedStorage.Library.Interactables);

local button = Interactable.Trigger("MB2_TakeScythe", "Take Jack's Scythe");
button.Script = script;

return button;