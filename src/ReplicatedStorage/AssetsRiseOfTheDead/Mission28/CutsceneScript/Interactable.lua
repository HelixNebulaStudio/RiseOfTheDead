local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Interactable = require(game.ReplicatedStorage.Library.Interactables);

local button = Interactable.Trigger("SafetySafehouse:Add", "Build");
button.Script = script;
button.InteractDuration = 3;

local RunService = game:GetService("RunService");
if RunService:IsClient() then
	button.OnSync = function(self, data)
		self.CanInteract = data.CanInteract;
		self.Label = data.Label;
	end
	button.Object = script.Parent;
end;

return button;