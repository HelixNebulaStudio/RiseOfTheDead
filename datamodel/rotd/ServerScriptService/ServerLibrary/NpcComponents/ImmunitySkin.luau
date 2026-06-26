local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Component = {};
Component.ClassName = "NpcComponent";
Component.__index = Component;

function Component.new(npcClass: NpcClass)
	local self = {};
	
	setmetatable(self, Component);
	return self;
end

-- Called after NpcClass.Setup, Spawned and Respawn;
function Component:Setup(npcClass: NpcClass)
    npcClass.Properties.OnChanged:Connect(function(k, v)
        if k ~= "Immunity" then return end;

        local char = npcClass.Character;
        for _, obj in pairs(char:GetChildren()) do
            if not obj:IsA("BasePart") then continue end;

            local defColor = obj:GetAttribute("DefaultColor");
            if defColor == nil then
                obj:SetAttribute("DefaultColor", obj.Color);
                defColor = obj.Color;
            end

			if v == nil then
				obj.Color = defColor;
				return;
			end

            obj.Color = defColor:Lerp(Color3.fromRGB(135, 67, 67), v);
        end

    end)
end

return Component;