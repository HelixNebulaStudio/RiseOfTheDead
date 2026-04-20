local accessoryPackage = {};

local TweenService = game:GetService("TweenService");
local TWEEN_INFO = TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true, 0);

local RED1, RED2 = Color3.fromRGB(68, 45, 45), Color3.fromRGB(150, 78, 78);
local BLACK1, BLACK2 = Color3.fromRGB(173, 100, 100), Color3.fromRGB(35, 35, 35);


function accessoryPackage.BindAttach(player, prefabs)
    for _, accessory in ipairs(prefabs) do
        local handle = accessory:WaitForChild("Handle");

        for _, obj in ipairs(handle:GetChildren()) do
            if obj.Name == "LVein" then
                obj.Material = Enum.Material.Neon;
                obj.Color = RED1;
                TweenService:Create(obj, TWEEN_INFO, {
                    Color = RED2;
                }):Play();

            elseif obj.Name == "RVein" then
                obj.Material = Enum.Material.Neon;
                obj.Color = BLACK1;
                TweenService:Create(obj, TWEEN_INFO, {
                    Color = BLACK2;
                }):Play();

            end
        end

    end
end

return accessoryPackage;