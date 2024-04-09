local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Interactable = require(game.ReplicatedStorage.Library.Interactables);

local button = Interactable.Trigger("EB2_LightBarrel", "Light fire barrel");
button.InteractDuration = 5;
button.Script = script;

return button;