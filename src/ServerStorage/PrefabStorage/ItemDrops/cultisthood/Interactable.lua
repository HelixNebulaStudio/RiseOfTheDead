local Interactable = require(game.ReplicatedStorage.Library.Interactables);
local interact = Interactable.Pickup("cultisthood");
interact.OnSuccessfulPickup = function(self)
	local name = self.ItemId;
	for _, obj in pairs(workspace.Interactables:GetChildren()) do
		if obj and obj.Name == name then
			obj:Destroy();
		end
	end
end
return interact;