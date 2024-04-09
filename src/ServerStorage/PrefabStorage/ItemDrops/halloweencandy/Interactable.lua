local Interactable = require(game.ReplicatedStorage.Library.Interactables);
local interact = Interactable.Pickup(script.Parent.Name);
interact.TouchInteract = true;
interact.ForceTouchPickup = true;

if game:GetService("RunService"):IsServer() then
	task.spawn(function()
		local primary = script.Parent:WaitForChild("Primary");

		local list = {
			primary:WaitForChild("GummyZombie");
			primary:WaitForChild("SpookyCaramel");
			primary:WaitForChild("eyeballCandy");
			primary:WaitForChild("hauntedTaffy");
		};

		local pick = list[math.random(1, #list)];
		for a=1, #list do
			if list[a] ~= pick then
				list[a]:Destroy();
			end
		end
		list = nil;
	end)
end

return interact;