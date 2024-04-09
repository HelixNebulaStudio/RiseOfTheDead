local Interactable = require(game.ReplicatedStorage.Library.Interactables);
local door = Interactable.GameMode(script:GetAttribute("Mode"), script:GetAttribute("Stage"), script:GetAttribute("Label"));
return door;