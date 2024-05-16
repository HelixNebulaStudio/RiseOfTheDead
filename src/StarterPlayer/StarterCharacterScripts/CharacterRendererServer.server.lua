if not workspace:IsAncestorOf(script) then return end;

local character = script.Parent;

local function link(side)
	local hand: BasePart = character:WaitForChild(side.."Hand");

	local indexFinger: BasePart = character:WaitForChild(side.."Point");
	local middleFinger: BasePart = character:WaitForChild(side.."Middle");
	local pinkyFinger: BasePart = character:WaitForChild(side.."Pinky");

	local function updateColor()
		local newColor = hand.Color;
		indexFinger.Color = newColor;
		middleFinger.Color = newColor;
		pinkyFinger.Color = newColor;
		
	end
	
	hand:GetPropertyChangedSignal("Color"):Connect(updateColor);
	updateColor();
end

link("Left");
link("Right");