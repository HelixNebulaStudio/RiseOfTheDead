local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Interactable = require(game.ReplicatedStorage.Library.Interactables);

local button = Interactable.Trigger("WinterTreelumSapling", "Dig");
button.InteractDuration = 5;
button.Script = script;
button.ItemRequired = "shovel";
button.Animation = "shoveling";

local RunService = game:GetService("RunService");
if RunService:IsClient() then
	local player = game.Players.LocalPlayer;
	local modData = require(player:WaitForChild("DataModule"));
	local eventFound = false;
	
	button.OnSync = function(self, data)
		self.CanInteract = data.CanInteract;
		self.Label = data.Label;
	end
	button.Object = script.Parent;
	
	button.OnTrigger = function(self) -- OnMouseOver
	end
end;

return button;