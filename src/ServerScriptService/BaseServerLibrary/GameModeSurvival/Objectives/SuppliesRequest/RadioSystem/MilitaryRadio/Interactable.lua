local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Interactable = require(game.ReplicatedStorage.Library.Interactables);

local button = Interactable.Trigger("ResupplyRadio", "");
button.InteractDuration = 3;
button.RadioActive = false;
button.Script = script;

local RunService = game:GetService("RunService");
if RunService:IsClient() then
	local player = game.Players.LocalPlayer;
	local modData = require(player:WaitForChild("DataModule"));
	local eventFound = false;
	
	button.Object = script.Parent;
	
	local onInteract = button.OnInteracted;
	function button:OnInteracted(library)
		if onInteract then
			onInteract(self, library);
		end
		if self.RadioActive == false then
			self.RadioActive = true;
			self.CanInteract = false;
			self.Label = "Transmitting resupply request";
			
		elseif self.CallInterupted == true then
			self.CallInterupted = false;
			self.CanInteract = false;
			self.Label = "Transmitting resupply request";
			
		end
	end

	function button:OnTrigger(library)
		if self.RadioActive == false then
			self.Label = "Signal for resupply";
			self.CanInteract = true;
			
		elseif self.CallInterupted == true then
			self.Label = "Reactivate transmission";
			self.CanInteract = true;
			
		else
			self.Label = "Transmitting resupply request";
			self.CanInteract = false;
			
		end
	end
end;

return button;