local Interactable = require(game.ReplicatedStorage.Library.Interactables);
local message = Interactable.Message();
message.OnTrigger = function(self)
	local exitSign = script.Parent:FindFirstChild("ExitSign", true);
	if exitSign and exitSign.Material == Enum.Material.Neon then
		message.Label = "Looks like this is the exit.";
	else
		message.Label = "The light on the sign is off.";
	end
end

return message;
