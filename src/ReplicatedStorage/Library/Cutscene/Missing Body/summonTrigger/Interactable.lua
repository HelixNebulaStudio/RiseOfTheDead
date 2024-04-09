local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Interactable = require(game.ReplicatedStorage.Library.Interactables);

local button = Interactable.Trigger("Summon JackReap", "Point Voodoo Doll at Totem");
button.Script = script;

--local RunService = game:GetService("RunService");
--if RunService:IsClient() then
--	local player = game.Players.LocalPlayer;
--	local modData = require(player:WaitForChild("DataModule"));
--	local eventFound = false;
	
--	button.OnSync = function(self, data)
--		self.CanInteract = data.CanInteract;
--		self.Label = data.Label;
--	end
--	button.Object = script.Parent;
	
--	button.OnTrigger = function(self) -- OnMouseOver
--		if eventFound then return end;
--		self.Label = "Burnt lift controller, requires 1 circuitboard to repair";
		
--		local event = modData:GetEvent("lift1Shortcut");
--		if event then
--			self.CanInteract = false;
--			self.Label = nil;
--			eventFound = true;
--		end
--	end
--end;

return button;