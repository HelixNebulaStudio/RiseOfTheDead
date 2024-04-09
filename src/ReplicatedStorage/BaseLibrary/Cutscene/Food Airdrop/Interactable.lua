local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Interactable = require(game.ReplicatedStorage.Library.Interactables);

local button = Interactable.Trigger("mission35FoodScavenge", "Extract food package");
button.InteractDuration = 3;
button.Script = script;

local RunService = game:GetService("RunService");
if RunService:IsClient() then
	local player = game.Players.LocalPlayer;
	button.CanInteract = true;
	
	button.OnSync = function(self, data)
		self.CanInteract = data.CanInteract;
		self.Label = data.Label;
	end
	button.Object = script.Parent;
	
	--button.OnTrigger = function(self) -- OnMouseOver
	--	if not self.CanInteract and self.TrainSpeed then
	--		self.Label = "nil";
	--	end
	--end
end;

return button;