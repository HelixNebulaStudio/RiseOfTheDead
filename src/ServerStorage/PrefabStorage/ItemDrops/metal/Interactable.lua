local Interactable = require(game.ReplicatedStorage.Library.Interactables);
local interact = Interactable.Pickup("metal");
interact.PickUpSound = "StorageMetalPickup";
return interact;