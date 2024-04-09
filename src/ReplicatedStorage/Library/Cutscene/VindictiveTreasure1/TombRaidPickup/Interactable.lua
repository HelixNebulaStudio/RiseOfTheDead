local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Interactable = require(game.ReplicatedStorage.Library.Interactables);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local button = Interactable.Trigger("Tombs NekronMask", "What.. Nekron Mask.. Why do the cultists have this?");
button.Script = script;

function button:TriggerEffect()
	modAudio.Play("Collectible", nil, nil, false);
end

return button;