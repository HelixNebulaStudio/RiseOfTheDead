local Interactable = require(game.ReplicatedStorage.Library.Interactables);
local interact = Interactable.Pickup("screws");
interact.PickUpSound = "StorageMetalPickup";
return interact;