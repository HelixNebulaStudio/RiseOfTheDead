local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Interactable = require(game.ReplicatedStorage.Library.Interactables);

local button = Interactable.Trigger("SafetySafehouse:Add", "Build");
button.Script = script;

local RunService = game:GetService("RunService");
if RunService:IsClient() then
	local player = game.Players.LocalPlayer;
	local modData = require(player:WaitForChild("DataModule"));
	
	button.OnSync = function(self, data)
		self.CanInteract = data.CanInteract;
		self.Label = data.Label;
	end
	button.Object = script.Parent;
	
--	button.OnTrigger = function(self) -- OnMouseOver
--		self.Label = "This is missing a light bulb.";
--		
--		local event = modData:GetEvent("secretSpotlightFix");
--		if event then
--			self.CanInteract = false;
--			self.Label = nil;
--		end
--	end
end;

return button;