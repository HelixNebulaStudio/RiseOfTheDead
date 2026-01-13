local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");

local camera = workspace.CurrentCamera;
local localPlayer = game.Players.LocalPlayer;

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);

local interfacePackage = {
    Type = "Character";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

    local frame = script:WaitForChild("MechanicsBar"):Clone();
    frame.Parent = interface.ScreenGui;

    local barImageLabel = frame:WaitForChild("Bar");
    local barTextLabel = frame:WaitForChild("label");

    if modConfigurations.CompactInterface then
        frame:WaitForChild("UIPadding").PaddingBottom = UDim.new(0, 0);
        frame.UIPadding.PaddingLeft = UDim.new(0, 0);
        frame.UIPadding.PaddingRight = UDim.new(0, 0);
        frame.UIPadding.PaddingTop = UDim.new(0, 0);
        frame.AnchorPoint = Vector2.new(0, 1);
        frame.Position = UDim2.new(0.5, 5, 1, -20);
        frame.Size = UDim2.new(0.25, 0, 0, 18);
        barTextLabel.TextSize = 9;
        
		frame.BackgroundTransparency = 0.5;
		frame.ImageTransparency = 1;
		local uiCorner = Instance.new("UICorner");
		uiCorner.CornerRadius = UDim.new(0, 5);
		uiCorner.Parent = frame;
    end

    local element: InterfaceElement = interface:GetOrDefaultElement("MechanicsBar", {
        ProgressValue = 0;
        ProgressType = "";
        ProgressText = "";
    });
    element.Layers = {"CharacterHud"; "CompactHidden";};
    
    local progressionPoint = 0;
    local barText = "";

    element.OnChanged:Connect(function(k, v, ov)
        if k == "ProgressType" then
            local barType = v;
            if barType == "Heal" then
                barText = "Healing: $value/100%";
                
            elseif barType == "Throw" then
                barText = "Throw Strength: $value/100%";
                
            elseif barType == "Building" then
                barText = "Building: $value/100%";
                
            elseif barType == "Eating" then
                barText = "Consuming: $value/100%";
                
            elseif barType == "WeaponLevel" then
                barText = "Weapon Level: $text"

            elseif barType == "MeleeStamina" then
                barText = "Melee Stamina: $text";

            else
                local statsData = modData.GameSave and modData.GameSave.Stats;
                if statsData == nil then
                    barText = "";
                else
                barText = `Mastery Level: {statsData.Level or 0}`;
                end
                progressionPoint = 0;
            end

        elseif k == "ProgressValue" then
            local progress = v or 0;
            if progress > 0 then 
                barImageLabel.BorderSizePixel = 2; 
            end
            progressionPoint = progress;

        elseif k == "ProgressText" then

        elseif k == "Visible" then
            if modConfigurations.DisableExperiencebar == true then
                frame.Visible = false;
            else
                frame.Visible = v;
            end
        end
    end)

    interface.Garbage:Tag(function()
        RunService:UnbindFromRenderStep("ProgressionBarRender");
    end)

    local prevProgressionValue = progressionPoint;
    RunService:BindToRenderStep("ProgressionBarRender", Enum.RenderPriority.Last.Value, function(delta)
        if frame.Visible == false then return end;
        prevProgressionValue = math.clamp(prevProgressionValue + 0.1 * (progressionPoint - prevProgressionValue), 0, 1);
        barImageLabel.Size = UDim2.new(prevProgressionValue, 0, 1, 0);
        
        barTextLabel.Text = barText:gsub("$value", string.format("%.1f", element.ProgressValue*100))
                                    :gsub("$text", element.ProgressText or "");

        if barImageLabel.AbsoluteSize.X >= 1 then
            barImageLabel.BorderSizePixel = 2;
        else
            barImageLabel.BorderSizePixel = 0;
        end
    end)

    element.Visible = true;
    interface:BindConfigKey("DisableExperiencebar", nil, {frame});
end

return interfacePackage;

