local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Interactable = require(game.ReplicatedStorage.Library.Interactables);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local button = Interactable.Trigger("m68PickupSalvage", "Retrieve Locked Salvage");
button.Script = script;

local RunService = game:GetService("RunService");
if RunService:IsClient() then
	local player = game.Players.LocalPlayer;
	local modData = Debugger:Require(player:WaitForChild("DataModule"));
	
	button.OnSync = function(self, data)
		self.CanInteract = data.CanInteract;
		self.Label = data.Label;
	end
	button.Object = script.Parent;
	
end;

return button;