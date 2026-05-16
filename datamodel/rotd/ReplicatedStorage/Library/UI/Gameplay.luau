local RunService = game:GetService("RunService");

local modItemModsLibrary = shared.require(game.ReplicatedStorage.Library.ItemModsLibrary);
local modKeyBindsHandler = shared.require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);

local modMath = shared.require(game.ReplicatedStorage.Library.Util.Math);

local GameplayUI = {};

function GameplayUI.RenderWeaponStatusHud(weaponStatusHud, config: ConfigVariable, props: PropertiesVariable<anydict>)
    local statusDictTable = props.StatusDisplay;
    if statusDictTable == nil then return end;

    for k, statusInfo in pairs(statusDictTable) do
        local statusLabel = weaponStatusHud:FindFirstChild(k);
        if statusLabel == nil then
            statusLabel = script:WaitForChild("WeaponStatusTemplate"):Clone();
            statusLabel.Name = k;
            statusLabel.LayoutOrder = statusInfo.Order;
            statusLabel.Parent = weaponStatusHud;

            if statusInfo.ModItemId then
                local modLib = modItemModsLibrary.Get(statusInfo.ModItemId);
                statusLabel:SetAttribute("Icon", modLib.Icon);
                if modLib.Color then
                    statusLabel:SetAttribute("Color", modLib.Color:ToHex());
                end
            end
        end

        statusLabel.Visible = statusInfo.Hide ~= true;
        statusLabel.Text = statusInfo.Text;

        local statusIcon = statusLabel:WaitForChild("Icon");
        local iconStr = statusInfo.Icon or statusLabel:GetAttribute("Icon");
        if iconStr then
            statusIcon.Visible = true;
            statusIcon.Image = iconStr;
        else
            statusIcon.Visible = false;
        end

        local hotKeyFrame = statusLabel:WaitForChild("hotKey");
        if statusInfo.KeyString then
            hotKeyFrame.Visible = true;
            local hotKeyLabel = hotKeyFrame:WaitForChild("button");
            hotKeyLabel.Text = modKeyBindsHandler:ToString(statusInfo.KeyString);
        else
            hotKeyFrame.Visible = false;
        end

        local uiGradient = statusIcon:WaitForChild("UIGradient") :: UIGradient;
        local colorHex = statusInfo.Color or statusLabel:GetAttribute("Color");
        local newColor = colorHex and Color3.fromHex(colorHex) or Color3.fromRGB(255, 255, 255);
        local cHue, cSaturation, cValue = newColor:ToHSV();
        if colorHex then
            local baseColor = Color3.fromRGB(255, 255, 255);
            uiGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, baseColor);
                ColorSequenceKeypoint.new(0.499, baseColor);
                ColorSequenceKeypoint.new(0.5, newColor);
                ColorSequenceKeypoint.new(1, newColor);
            });
        end

        if statusInfo.ColorPercent then
            if statusInfo.ColorPercent <= 0 then
                uiGradient.Offset = Vector2.new(0, 0.5);
            elseif statusInfo.ColorPercent >= 1 then
                uiGradient.Offset = Vector2.new(0, -0.5);
            else
                uiGradient.Offset = Vector2.new(0, modMath.MapNum(statusInfo.ColorPercent, 0, 1, 0.4, -0.4, true));
            end
        else
            uiGradient.Offset = Vector2.new(0, 0.5);
        end

        if statusInfo.Glow ~= nil then
            if statusLabel:GetAttribute("Glow") == nil then
                local newGlow = modItemInterface.newGlowEffect();
                newGlow.Name = "Glow";
                newGlow.ImageColor3 = Color3.new(1,1,1):Lerp(Color3.fromHSV(cHue, cSaturation, 1), statusInfo.ColorPercent);
                newGlow.ImageTransparency = 0.65;
                newGlow.Size = UDim2.new(1.5, 0, 1.5, 0);
                local rayLabel = newGlow:WaitForChild("Rays");
                rayLabel.Size = UDim2.new(1.5, 0, 1.5, 0);
                rayLabel.Visible = false;
                if colorHex then
                    local c = Color3.fromHex(colorHex);
                    local cH, cS, cV = c:ToHSV();
                    rayLabel.ImageColor3 = Color3.fromHSV(cH, cS*0.5, 1);
                end
                newGlow.Parent = statusIcon;
                statusLabel:SetAttribute("Glow", true);
            else
                local glowLabel = statusIcon:FindFirstChild("Glow");
                if glowLabel then
                    glowLabel.Visible = true;

                    local rayLabel = glowLabel:WaitForChild("Rays");
                    if statusInfo.Rays == false then
                        rayLabel.Visible = false;
                    else
                        rayLabel.Visible = true;
                    end
                end
            end
        else
            if statusLabel:GetAttribute("Glow") then
                local glowLabel = statusIcon:FindFirstChild("Glow");
                if glowLabel then
                    glowLabel.Visible = false;
                end
            end
        end

        if statusInfo.ModifierId then
            local modifierInstance: ConfigModifier? = config:GetModifier(statusInfo.ModifierId);
            if modifierInstance == nil or modifierInstance.Enabled == false then
                statusDictTable[k] = nil;
                statusLabel.Visible = false;
            end
        end
    end

    local wStatusHudVisible = false;
    for _, obj in pairs(weaponStatusHud:GetChildren()) do
        if not obj:IsA("GuiObject") then continue end;
        if statusDictTable[obj.Name] == nil then
            obj.Visible = false;
            game.Debris:AddItem(obj, 0);
        else
            if obj.Visible then
                wStatusHudVisible = true;
            end
        end
    end

    weaponStatusHud.Visible = wStatusHudVisible;
end

return GameplayUI;