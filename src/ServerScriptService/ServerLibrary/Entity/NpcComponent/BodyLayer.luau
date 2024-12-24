local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local bodyLayerPrefabs = script:WaitForChild("LayerTypes");
--== Script;
local Component = {};
Component.__index = Component;

function Component.new(Npc)
	local self = {};
	
    function Component:AddLayer(typeName)
        local bodyTypeLayers = bodyLayerPrefabs:FindFirstChild(typeName);
        if bodyTypeLayers then
            for _, obj in pairs(bodyTypeLayers:GetChildren()) do
                local bodyPart = Npc.Prefab:FindFirstChild(obj.Name);
                if bodyPart == nil then continue end;

                local new = obj:Clone();
                new.Name = `{new.Name}Layer`;
                new:SetAttribute("BodyLayer", true);
                new.Parent = Npc.Prefab;

                local weld = Instance.new("Weld");
                weld.Parent = new;
                weld.Part0 = new;
                weld.Part1 = bodyPart;
            end
        end
    end
	
	setmetatable(self, Component);
	return self;
end

return Component;