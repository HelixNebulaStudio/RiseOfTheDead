local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Interactable = require(game.ReplicatedStorage.Library.Interactables);

local button = Interactable.Trigger("QA2_Radio", "Broadcast \"Hello?! Does anyone copy on this frequency?\"");
button.InteractDuration = 5;
button.Script = script;

local RunService = game:GetService("RunService");
if RunService:IsClient() then
	local player = game.Players.LocalPlayer;
	local ChatService = game:GetService("Chat");
	local modData = require(player:WaitForChild("DataModule"));
	local modAudio = require(game.ReplicatedStorage.Library:WaitForChild("Audio"));
	
	button.OnSync = function(self, data)
		self.CanInteract = data.CanInteract;
		self.Label = data.Label;
	end
	button.Object = script.Parent;
	
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