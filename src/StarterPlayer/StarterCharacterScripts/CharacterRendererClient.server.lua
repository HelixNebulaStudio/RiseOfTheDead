if not workspace:IsAncestorOf(script) then return end;

local localPlayer = game.Players.LocalPlayer;
local character = script.Parent;

local function link(side)
	local hand: BasePart = character:WaitForChild(side.."Hand");

	local indexFinger: BasePart = character:WaitForChild(side.."Point");
	local middleFinger: BasePart = character:WaitForChild(side.."Middle");
	local pinkyFinger: BasePart = character:WaitForChild(side.."Pinky");

	local function updateVisual()
		local player = game:GetService("Players"):GetPlayerFromCharacter(character);
		if player ~= localPlayer then return end;

		if hand:GetAttribute("HideHands") == true then
			hand.Transparency = 1;
			hand:SetAttribute("DefaultTransparency", 1);
			indexFinger.Transparency = 1;
			indexFinger:SetAttribute("DefaultTransparency", 1);
			middleFinger.Transparency = 1;
			middleFinger:SetAttribute("DefaultTransparency", 1);
			pinkyFinger.Transparency = 1;
			pinkyFinger:SetAttribute("DefaultTransparency", 1);

		else
			hand.Transparency = 0;
			hand:SetAttribute("DefaultTransparency", 0);
			indexFinger.Transparency = 0;
			indexFinger:SetAttribute("DefaultTransparency", 0);
			middleFinger.Transparency = 0;
			middleFinger:SetAttribute("DefaultTransparency", 0);
			pinkyFinger.Transparency = 0;
			pinkyFinger:SetAttribute("DefaultTransparency", 0);

		end

	end
	
	hand:GetAttributeChangedSignal("HideHands"):Connect(updateVisual);
	updateVisual();
end

link("Left");
link("Right");