local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local RunService = game:GetService("RunService");
local random = Random.new();

--== Script;
local Component = {};
Component.__index = Component;

function Component.new(Npc)
	local humanoid: Humanoid = Npc.Humanoid;
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false);

	if Npc.Garbage == nil then return end;
	Npc.Garbage:Tag(humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
		
		local seatPart = humanoid.SeatPart;
		if seatPart then
			local weld = seatPart:FindFirstChildWhichIsA("Weld");
			if weld.Name == "SeatWeld" then
				humanoid.Jump = true;
				humanoid.Sit = false;
				game.Debris:AddItem(weld, 0);
			end
		end
	end))
end

return Component;