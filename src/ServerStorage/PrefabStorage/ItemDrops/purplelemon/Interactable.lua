local Interactable = require(game.ReplicatedStorage.Library.Interactables);
local interact = Interactable.Pickup(script.Parent.Name);
interact.OnSuccessfulPickup = function(self)
	if script:FindFirstChild("OnceOnly") == nil then return end;
	for _, obj in pairs(workspace.Interactables:GetChildren()) do
		if obj and obj.Name == self.ItemId then
			obj:Destroy();
		end
	end
end
return interact;