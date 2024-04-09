local Interactable = require(game.ReplicatedStorage.Library.Interactables);
local interact = Interactable.Pickup("coal");
interact.SharedDrop = false;
interact.PickUpSound = "PickaxeMining";
interact.ItemRequired = "pickaxe";
interact.InteractDuration = 1;
interact:SetQuantity(4);
interact.Label = "Mine Coal";
interact.TouchPickUp = false;

return interact;
