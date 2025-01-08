local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

local tweenDirection = Enum.EasingDirection.InOut;
local tweenStyle = Enum.EasingStyle.Quad;
--== Variables;
local Interface = {};

local RunService = game:GetService("RunService");

local localplayer = game.Players.LocalPlayer;
local PlayerGui = localplayer.PlayerGui;
local modData = require(localplayer:WaitForChild("DataModule"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modAudio = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("Audio"));
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));

--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);

	local interfaceScreenGui = localplayer.PlayerGui:WaitForChild("MainInterface");
	
	local hpFrame = script:WaitForChild("HealthBar"):Clone();
	hpFrame.Parent = interfaceScreenGui;
	
	local allLabel = hpFrame:WaitForChild("allLabel");
	local healthBars = hpFrame:WaitForChild("HealthBars");
	local armorBars = hpFrame:WaitForChild("ArmorBars");
	
	local window = Interface.NewWindow("HealthWindow", hpFrame);
	window.IgnoreHideAll = true;
	window.ReleaseMouse = false;
	window:Open();
	window:SetConfigKey("DisableHealthbar");
	
	local classPlayer = shared.modPlayers.Get(localplayer);
	
	Interface.Frame = hpFrame;
	Interface.PreviewBar = hpFrame:WaitForChild("HealthBars"):WaitForChild("PreBar");
	
	function Interface:OnToggleHuds(value)
		if modConfigurations.CompactInterface then
			hpFrame.Visible = (not modConfigurations.DisableHealthbar) and value;
		end
	end
	
	function Interface.Update()
		classPlayer = shared.modPlayers.Get(localplayer);
		RunService.Heartbeat:Wait();
		if not PlayerGui:IsAncestorOf(hpFrame) then return end;
		
		local health, maxHealth = classPlayer.Humanoid.Health, classPlayer.Humanoid.MaxHealth;
		local armor, maxArmor = classPlayer.Humanoid:GetAttribute("Armor"), classPlayer.Humanoid:GetAttribute("MaxArmor");
		armor = armor or 0;
		maxArmor = maxArmor or 1;
		
		local maxPool = maxHealth+maxArmor;
		local healthRatio = math.clamp(health/maxHealth, 0, 1);
		local armorRatio = maxArmor > 0 and math.clamp(armor/maxArmor, 0, 1) or 0;
		
		local function refresh()
			if not PlayerGui:IsAncestorOf(healthBars) then return end;
			
			if maxArmor > 0 then
				healthBars.Bar.Image = healthRatio < 1 and "rbxassetid://2678743976" or "rbxassetid://5639144727";
			else
				healthBars.Bar.Image = "rbxassetid://2678743976";
			end
			armorBars.Bar.Image = healthRatio < 1 and "rbxassetid://2678743976" or "rbxassetid://5639144943";
		end
		refresh();
		
		armorBars.Visible = maxArmor > 0;
		
		
		local isSwimming = classPlayer.Humanoid:GetAttribute("IsSwimming");
		local isUnderwater = classPlayer.Humanoid:GetAttribute("IsUnderWater");
		local oxygen = classPlayer.Humanoid:GetAttribute("Oxygen");
		
		if isSwimming then
			healthBars.Bar.ImageColor3 = Color3.fromRGB(35, 140, 114);
			healthRatio = math.clamp(oxygen/maxHealth, 0, 1);
		else
			healthBars.Bar.ImageColor3 = Color3.fromRGB(36, 140, 49);
		end
		
		healthBars.Size = UDim2.new(maxHealth/maxPool, 0, 1, 0);
		healthBars.Bar:TweenSize(UDim2.new(healthRatio, 0, 1, 0), tweenDirection, tweenStyle, 0.2, true, refresh);
		
		armorBars.Size = UDim2.new(maxArmor/maxPool, 0, 1, 0);
		armorBars.Bar:TweenSize(UDim2.new(armorRatio, 0, 1, 0), tweenDirection, tweenStyle, 0.2, true, refresh);
		delay(0.05, function()
			pcall(function()
				healthBars.LostBar:TweenSize(UDim2.new(healthRatio, 0, 1, 0), tweenDirection, tweenStyle, 0.5, true, refresh);
				armorBars.LostBar:TweenSize(UDim2.new(armorRatio, 0, 1, 0), tweenDirection, tweenStyle, 0.5, true, refresh);
			end)
		end);
		
		if isSwimming then
			healthBars.label.Text = math.max(math.ceil(oxygen), 0).."/"..math.ceil(maxHealth);
			armorBars.label.Text = math.max(math.floor(armor), 0).."/"..math.floor(maxArmor);
			allLabel.Text = "";
			
		else
			if modData.Settings.CombineHealthbars == true then
				healthBars.label.Text = "";
				armorBars.label.Text = "";
				allLabel.Text = math.max(math.ceil(health + armor), 0).."/"..math.floor(maxPool);
				
			else
				healthBars.label.Text = math.max(math.ceil(health), 0).."/"..math.ceil(maxHealth);
				armorBars.label.Text = math.max(math.floor(armor), 0).."/"..math.floor(maxArmor);
				allLabel.Text = "";
				
			end
			
		end
	end
	
	task.spawn(function()
		local character = localplayer.Character;
		local humanoid = character:WaitForChild("Humanoid");
		
		Interface.Garbage:Tag(humanoid.HealthChanged:Connect(Interface.Update));
		Interface.Garbage:Tag(humanoid:GetAttributeChangedSignal("Armor"):Connect(Interface.Update));
		Interface.Garbage:Tag(humanoid:GetAttributeChangedSignal("MaxArmor"):Connect(Interface.Update));
		Interface.Garbage:Tag(humanoid:GetAttributeChangedSignal("Oxygen"):Connect(Interface.Update));
		Interface.Garbage:Tag(humanoid:GetAttributeChangedSignal("IsSwimming"):Connect(Interface.Update));

		Interface.Update();
	end)
	
	classPlayer:OnNotIsAlive(function(character)
		Interface.Update();
	end)
	
	if modConfigurations.CompactInterface then
		hpFrame.Position = UDim2.new(0.5, 0, 1, -20);
		hpFrame.Size = UDim2.new(0.55, 0, 0, 14);
		hpFrame:WaitForChild("UIPadding").PaddingBottom = UDim.new(0, 0);
		hpFrame.UIPadding.PaddingLeft = UDim.new(0, 0);
		hpFrame.UIPadding.PaddingRight = UDim.new(0, 0);
		hpFrame.UIPadding.PaddingTop = UDim.new(0, 0);
		
		allLabel.TextSize = 11;
		healthBars.label.TextSize = 11;
		armorBars.label.TextSize = 11;
	end
	
	return Interface;
end;


return Interface;