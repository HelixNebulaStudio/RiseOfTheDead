local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

--== Script;
local Component = {};

function Component.new(Npc)
	return function(input, comparer)
		local position;
		if typeof(input) == "Instance" then
			if input:IsA("Player") and input.Character and input.Character.PrimaryPart then
				position = input.Character.PrimaryPart.Position;
			elseif input:IsA("BasePart") then
				position = input.Position;
			end
		elseif typeof(input) == "Vector3" then
			position = input;
		end
		if position then
			local distance = (Vector2.new(position.X, position.Z) - Vector2.new(Npc.RootPart.Position.X, Npc.RootPart.Position.Z)).Magnitude;
		end
	end
end

return Component;