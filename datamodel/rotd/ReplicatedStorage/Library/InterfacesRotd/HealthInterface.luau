local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);

local TWEEN_DIRECTION = Enum.EasingDirection.InOut;
local TWEEN_STYLE = Enum.EasingStyle.Quad;

local interfacePackage = {
    Type = "Character";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

    local interfaceScreenGui = interface.ScreenGui;
    local hpFrame = script:WaitForChild("HealthBar"):Clone();
	hpFrame.Parent = interfaceScreenGui;
	
	local allLabel = hpFrame:WaitForChild("allLabel");
	local healthBars = hpFrame:WaitForChild("HealthBars");
	local armorBars = hpFrame:WaitForChild("ArmorBars");
    local previewBar = hpFrame:WaitForChild("HealthBars"):WaitForChild("PreBar");
	local oxygenBars = hpFrame:WaitForChild("OxygenBars");
	
	local window: InterfaceWindow = interface:NewWindow("HealthWindow", hpFrame, {
        PreviewVisible = false;
        PreviewBorderSize = 2;
        PreviewSize = previewBar.Size;
    });
	window.IgnoreHideAll = true;
	window.ReleaseMouse = false;
	interface:BindConfigKey("DisableHealthbar", {window});
	
    window.Properties.OnChanged:Connect(function(k, v, ov)
        if k == "PreviewVisible" then
            previewBar.Visible = v;
        elseif k == "PreviewBorderSize" then
            previewBar.BorderSizePixel = v;
        elseif k == "PreviewSize" then
            previewBar.Size = v;
        end
    end)

	if modConfigurations.CompactInterface then
        interface.Properties.OnChanged:Connect(function(k, v)
            if k == "IsCompactFullscreen" then
                if modConfigurations.DisableHealthbar then
                    hpFrame.Visible = false;
                else
                    if v == true then
                        hpFrame.Visible = false;
                    else
                        hpFrame.Visible = true;
                    end
                end
            end
        end)

		hpFrame:WaitForChild("UIPadding").PaddingBottom = UDim.new(0, 0);
		hpFrame.UIPadding.PaddingLeft = UDim.new(0, 0);
		hpFrame.UIPadding.PaddingRight = UDim.new(0, 0);
		hpFrame.UIPadding.PaddingTop = UDim.new(0, 0);

		hpFrame.AnchorPoint = Vector2.new(1, 1);
		hpFrame.Size = UDim2.new(0.25, 0, 0, 18);
		window:SetClosePosition(UDim2.new(0.5, -5, 1, 20), UDim2.new(0.5, -5, 1, -20));
		
		hpFrame.BackgroundTransparency = 0.5;
		hpFrame.ImageTransparency = 1;
		local uiCorner = Instance.new("UICorner");
		uiCorner.CornerRadius = UDim.new(0, 5);
		uiCorner.Parent = hpFrame;


		allLabel.TextSize = 11;
		healthBars.label.TextSize = 11;
		armorBars.label.TextSize = 11;
	end

	local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
    local healthComp: HealthComp = playerClass.HealthComp;
	local humanoid = playerClass.Humanoid;

    window.OnUpdate:Connect(function()
		local health, maxHealth = healthComp.CurHealth, healthComp.MaxHealth;
		local armor, maxArmor = healthComp.CurArmor, healthComp.MaxArmor;
		armor = armor or 0;
		maxArmor = maxArmor or 1;
		
		local maxPool = maxHealth+maxArmor;
		local healthRatio = math.clamp(health/maxHealth, 0, 1);
		local armorRatio = maxArmor > 0 and math.clamp(armor/maxArmor, 0, 1) or 0;
		
		local function refresh()
			if maxArmor > 0 then
				healthBars.Bar.Image = healthRatio < 1 and "rbxassetid://2678743976" or "rbxassetid://5639144727";
			else
				healthBars.Bar.Image = "rbxassetid://2678743976";
			end
			armorBars.Bar.Image = healthRatio < 1 and "rbxassetid://2678743976" or "rbxassetid://5639144943";
		end
		refresh();
		
		armorBars.Visible = maxArmor > 0;
		
		
		local isSwimming = humanoid:GetAttribute("IsSwimming");
		local isUnderwater = humanoid:GetAttribute("IsUnderWater");
		local oxygen = humanoid:GetAttribute("Oxygen") or 0;
		local maxOxygen = humanoid:GetAttribute("MaxOxygen") or 100;
		
		if isSwimming or oxygen < maxOxygen then
			oxygenBars.Visible = true;
			
			local oxygenRatio = math.clamp(oxygen/maxHealth, 0, 1);
			oxygenBars.Bar:TweenSize(UDim2.new(oxygenRatio, 0, 1, 0), TWEEN_DIRECTION, TWEEN_STYLE, 0.1, true, refresh);
			
		else
			oxygenBars.Visible = false;

		end
		
		healthBars.Size = UDim2.new(maxHealth/maxPool, 0, 1, 0);
		healthBars.Bar:TweenSize(UDim2.new(healthRatio, 0, 1, 0), TWEEN_DIRECTION, TWEEN_STYLE, 0.1, true, refresh);
		
		armorBars.Size = UDim2.new(maxArmor/maxPool, 0, 1, 0);
		armorBars.Bar:TweenSize(UDim2.new(armorRatio, 0, 1, 0), TWEEN_DIRECTION, TWEEN_STYLE, 0.1, true, refresh);
		
		delay(0.05, function()
			pcall(function()
				healthBars.LostBar:TweenSize(UDim2.new(healthRatio, 0, 1, 0), TWEEN_DIRECTION, TWEEN_STYLE, 0.4, true, refresh);
				armorBars.LostBar:TweenSize(UDim2.new(armorRatio, 0, 1, 0), TWEEN_DIRECTION, TWEEN_STYLE, 0.4, true, refresh);
			end)
		end);
		
		if modData.Settings.CombineHealthbars == true then
			healthBars.label.Text = "";
			armorBars.label.Text = "";
			allLabel.Text = math.max(math.ceil(health + armor), 0).."/"..math.floor(maxPool);
			
		else
			healthBars.label.Text = math.max(math.ceil(health), 0).."/"..math.ceil(maxHealth);
			armorBars.label.Text = math.max(math.floor(armor), 0).."/"..math.floor(maxArmor);
			allLabel.Text = "";
			
		end
	end)
	
    local function fireUpdate(new, old, reason)
        window:Update();
    end
    

	interface.Garbage:Tag(healthComp.OnArmorChanged:Connect(fireUpdate));
	interface.Garbage:Tag(healthComp.OnHealthChanged:Connect(fireUpdate));
	interface.Garbage:Tag(healthComp.OnIsDeadChanged:Connect(fireUpdate));

	interface.Garbage:Tag(humanoid.HealthChanged:Connect(fireUpdate));
	interface.Garbage:Tag(humanoid:GetAttributeChangedSignal("Oxygen"):Connect(fireUpdate));
	interface.Garbage:Tag(humanoid:GetAttributeChangedSignal("IsSwimming"):Connect(fireUpdate));

	window:Open();
	window:Update();

end

return interfacePackage;

