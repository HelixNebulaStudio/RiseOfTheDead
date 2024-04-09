local Interactable = require(game.ReplicatedStorage.Library.Interactables);
local interact = Interactable.Pickup("rope");
interact.PickUpSound = "StorageClothDrop";
return interact;