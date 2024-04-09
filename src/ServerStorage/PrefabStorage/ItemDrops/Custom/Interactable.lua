local Interactable = require(game.ReplicatedStorage.Library.Interactables);
local interact = Interactable.Pickup(script.Parent.Name, script:GetAttribute("Quantity"));
return interact;