if not workspace:IsAncestorOf(script) then return end;

local localPlayer = game.Players.LocalPlayer;
local character = script.Parent;

-- local upperTorso: MeshPart = character:WaitForChild("UpperTorso");
-- local leftUpperArm: MeshPart = character:WaitForChild("LeftUpperArm");
-- local rightUpperArm: MeshPart = character:WaitForChild("RightUpperArm");

-- local leftUpperLeg: MeshPart = character:WaitForChild("LeftUpperLeg");
-- local rightUpperLeg: MeshPart = character:WaitForChild("RightUpperLeg");

-- local function characterUpdate(obj)
-- 	if obj:IsA("Shirt") then
-- 		upperTorso.TextureID = obj.ShirtTemplate;
-- 		leftUpperArm.TextureID = obj.ShirtTemplate;
-- 		rightUpperArm.TextureID = obj.ShirtTemplate;
-- 		obj.Parent = nil;
		
-- 	elseif obj:IsA("Pants") then
-- 		leftUpperLeg.TextureID = obj.PantsTemplate;
-- 		rightUpperLeg.TextureID = obj.PantsTemplate;
-- 		obj.Parent = nil;
-- 	end
-- end

-- --character.ChildAdded:Connect(characterUpdate)
-- --character.ChildRemoved:Connect(characterUpdate)

local function link(side)
	local hand: BasePart = character:WaitForChild(side.."Hand");

	local indexFinger: BasePart = character:WaitForChild(side.."Point");
	local middleFinger: BasePart = character:WaitForChild(side.."Middle");
	local pinkyFinger: BasePart = character:WaitForChild(side.."Pinky");

	local handOld: MeshPart = character:WaitForChild(side.."HandOld");
	
	local function updateColor()
		local shirt: Shirt = character:FindFirstChildWhichIsA("Shirt");
		
		local newColor = hand.Color;
		indexFinger.Color = newColor;
		middleFinger.Color = newColor;
		pinkyFinger.Color = newColor;
		
		handOld.Color = newColor;
		
		local player = game:GetService("Players"):GetPlayerFromCharacter(character);
		if player ~= localPlayer then return end;

		local useOldHands = localPlayer:GetAttribute("UseOldHands");
		
		if hand:GetAttribute("HideHands") == true then
			hand.Transparency = 1;
			hand:SetAttribute("DefaultTransparency", 1);
			indexFinger.Transparency = 1;
			indexFinger:SetAttribute("DefaultTransparency", 1);
			middleFinger.Transparency = 1;
			middleFinger:SetAttribute("DefaultTransparency", 1);
			pinkyFinger.Transparency = 1;
			pinkyFinger:SetAttribute("DefaultTransparency", 1);

			handOld.Transparency = 1;
			handOld:SetAttribute("DefaultTransparency", 1);
			
		elseif useOldHands and useOldHands > 0 then
			hand.Transparency = 1;
			hand:SetAttribute("DefaultTransparency", 1);
			indexFinger.Transparency = 1;
			indexFinger:SetAttribute("DefaultTransparency", 1);
			middleFinger.Transparency = 1;
			middleFinger:SetAttribute("DefaultTransparency", 1);
			pinkyFinger.Transparency = 1;
			pinkyFinger:SetAttribute("DefaultTransparency", 1);
			
			handOld.Transparency = 0;
			handOld:SetAttribute("DefaultTransparency", 0);
			if shirt then
				handOld.TextureID = shirt.ShirtTemplate;
			end

		else
			hand.Transparency = 0;
			hand:SetAttribute("DefaultTransparency", 0);
			indexFinger.Transparency = 0;
			indexFinger:SetAttribute("DefaultTransparency", 0);
			middleFinger.Transparency = 0;
			middleFinger:SetAttribute("DefaultTransparency", 0);
			pinkyFinger.Transparency = 0;
			pinkyFinger:SetAttribute("DefaultTransparency", 0);

			handOld.Transparency = 1;
			handOld:SetAttribute("DefaultTransparency", 1);
			
		end
		
		--if shirt then
		--	indexFinger.TextureID = shirt.ShirtTemplate;
		--	middleFinger.TextureID = shirt.ShirtTemplate;
		--	pinkyFinger.TextureID = shirt.ShirtTemplate;
		--end
	end
	
	hand:GetPropertyChangedSignal("Color"):Connect(updateColor);
	hand:GetAttributeChangedSignal("HideHands"):Connect(updateColor);
	localPlayer:GetAttributeChangedSignal("UseOldHands"):Connect(updateColor);
	
	updateColor();
end

link("Left");
link("Right");