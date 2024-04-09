local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Interactable = require(game.ReplicatedStorage.Library.Interactables);

local button = Interactable.Trigger("RevasEnvelope", "Take Letter");
button.Script = script;

local RunService = game:GetService("RunService");
if RunService:IsClient() then

	function button.TriggerEffect(self)
		local prefab = button.Object;
		
		prefab.Transparency = 1;
		delay(1, function()
			prefab.Transparency = 0;
		end)
	end
	
	--local player = game.Players.LocalPlayer;
	--local modData = require(player:WaitForChild("DataModule"));
	--local eventFound = false;
	
	--button.OnSync = function(self, data)
	--	self.CanInteract = data.CanInteract;
	--	self.Label = data.Label;
	--end
	--button.Object = script.Parent;
	
	--button.OnTrigger = function(self) -- OnMouseOver
	--	if eventFound then return end;
	--	self.Label = "Burnt lift controller, requires 1 circuitboard to repair";
		
	--	local event = modData:GetEvent("lift1Shortcut");
	--	if event then
	--		self.CanInteract = false;
	--		self.Label = nil;
	--		eventFound = true;
	--	end
	--end
end;

return button;