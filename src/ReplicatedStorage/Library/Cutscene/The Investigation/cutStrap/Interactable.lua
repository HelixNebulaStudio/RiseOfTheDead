local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Interactable = require(game.ReplicatedStorage.Library.Interactables);

local button = Interactable.Trigger("TheInvestigation_CutStrap", "Cut Strap");
button.Script = script;

return button;