local Interactable = require(game.ReplicatedStorage.Library.Interactables);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local message = Interactable.Message("*Picks Up* Phone: You.. How dare you come here... LEAVE NOW OR ELSE!");

message.OnTrigger = function(self)
	if script.Parent:FindFirstChild("PhoneRinging") then
		script.Parent.PhoneRinging:Destroy();
		modAudio.Play("PhonePickUp", script.Parent);
	end
end

return message;