local Interactable = require(game.ReplicatedStorage.Library.Interactables);
local interactable = Interactable.Travel("VindictiveTreasure");

local RunService = game:GetService("RunService");
if RunService:IsClient() then
	interactable.InteractableRange = 0;
else
	interactable.InteractableRange = 50;
end
return interactable;