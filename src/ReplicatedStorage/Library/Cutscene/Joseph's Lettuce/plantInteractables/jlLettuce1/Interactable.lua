local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Interactable = require(game.ReplicatedStorage.Library.Interactables);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local button = Interactable.Trigger(script.Parent.Name);
button.Script = script;
button.InteractDuration = 5;
button.ItemRequired = "wateringcan";

local RunService = game:GetService("RunService");
if RunService:IsClient() then
	local player = game.Players.LocalPlayer;
	local modData = require(player:WaitForChild("DataModule"));
	
	button.OnSync = function(self, data)
		self.CanInteract = data.CanInteract;
		self.Label = data.Label;
	end
	button.Object = script.Parent;
	
	button.OnTrigger = function(self)
		local character = player.Character;
		local event = modData:GetEvent(script.Parent.Name);
		local lastTime = event and event.Time or nil;
		if lastTime == nil or modSyncTime.GetTime() >= lastTime then
			if character:FindFirstChild("wateringcan") then
				self.CanInteract = true;
				self.Label = "Water lettuce";
				
			else
				self.CanInteract = false;
				self.Label = "Requires holding a watering can";
			end
			
		else
			self.CanInteract = false;
			self.Label = "You have watered these plants.";
			
		end
	end
end;

return button;