local Interactable = require(game.ReplicatedStorage.Library.Interactables);
local interact = Interactable.Pickup(script.Parent.Name);
interact.PickUpSound = "StorageMetalPickup";
return interact;