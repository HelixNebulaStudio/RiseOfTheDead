local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Interactable = require(game.ReplicatedStorage.Library.Interactables);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local button = Interactable.Trigger("VendingMachine1");

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
		local event = modData:GetEvent("VendingMachine1");
		local lastTime = event and event.Time or nil;
		if lastTime == nil or modSyncTime.GetTime() >= lastTime then
			self.CanInteract = true;
			self.Label = "Insert $500 into vending machine and see what you get.";
			
		else
			self.CanInteract = false;
			local timeLapsed = modSyncTime.ToString(math.clamp(lastTime-modSyncTime.GetTime(), 0, 60))
			self.Label = ("Cooldown: $s"):gsub("$s", timeLapsed);
			
		end
	end
end;

return button;