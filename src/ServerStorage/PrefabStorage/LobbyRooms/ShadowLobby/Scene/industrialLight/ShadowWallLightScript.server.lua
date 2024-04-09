local lightSource = script.Parent:WaitForChild("_lightSource");
local pointLight = lightSource:WaitForChild("_lightPoint"):WaitForChild("PointLight");

function toggleOff()
    pointLight.Enabled = false;
    lightSource.Material = Enum.Material.SmoothPlastic;
end
function toggleOn()
    pointLight.Enabled = true;
    lightSource.Material = Enum.Material.Neon;
end


while true do
    wait(1);
    toggleOff();
    for a=1, 2 do
        wait(0.1);
        toggleOn();
        wait(0.1);
        toggleOff();
    end
    wait(2);
    toggleOn();
end