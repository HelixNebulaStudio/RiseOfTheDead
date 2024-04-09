local Interactable = require(game.ReplicatedStorage.Library.Interactables);
local interact = Interactable.Pickup("sulfur");
interact.SharedDrop = false;
interact.PickUpSound = "PickaxeMining";
interact.ItemRequired = "pickaxe";
interact.InteractDuration = 2;
interact:SetQuantity(6);
interact.Label = "Mine Sulfur";
interact.TouchPickUp = false;

return interact;
