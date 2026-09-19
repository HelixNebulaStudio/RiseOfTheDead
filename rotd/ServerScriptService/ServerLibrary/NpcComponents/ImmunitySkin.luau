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
    local function update()
        local char = npcClass.Character;

        local immunity = npcClass.Properties.Immunity;

        for _, obj in pairs(char:GetChildren()) do
            if not obj:IsA("BasePart") then continue end;

            local defColor = obj:GetAttribute("DefaultColor");
            if defColor == nil then
                obj:SetAttribute("DefaultColor", obj.Color);
                defColor = obj.Color;
            end

			if  immunity and immunity > 0 then
                obj.Color = Color3.fromRGB(127, 87, 87):Lerp(Color3.fromRGB(148, 61, 61), immunity);
            else
				obj.Color = defColor;
			end
        end
    end

    npcClass.Properties.OnChanged:Connect(function(k, v)
        if k ~= "Immunity" then return end;
        update();
    end)

    task.defer(function()
        task.wait();
        update();
    end);
end

return Component;