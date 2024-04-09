local Interactable = require(game.ReplicatedStorage.Library.Interactables);
local interact = Interactable.Pickup("nekronscales");
interact.SharedDrop = false;
interact.PickUpSound = "PickaxeMining";
interact.ItemRequired = "pickaxe";
interact.InteractDuration = 3;
interact:SetQuantity(35);
interact.Label = "Mine Nekron Scales";

return interact;
