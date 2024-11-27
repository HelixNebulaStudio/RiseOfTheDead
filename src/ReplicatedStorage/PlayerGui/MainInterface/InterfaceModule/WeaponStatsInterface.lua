local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface: any = {};

local SoundService = game:GetService("SoundService");
local RunService = game:GetService("RunService");
local TextService = game:GetService("TextService");

local localplayer = game.Players.LocalPlayer;
local modData = require(localplayer:WaitForChild("DataModule") :: ModuleScript);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modPseudoRandom = require(game.ReplicatedStorage.Library.PseudoRandom);
local modFormatNumber = require(game.ReplicatedStorage.Library.FormatNumber);
local modWorkbenchLibrary = require(game.ReplicatedStorage.Library.WorkbenchLibrary);

local casualPseudoRandom = modPseudoRandom.new();

local weaponStatsFrame = script.Parent.Parent:WaitForChild("WeaponStats");
local statsList = weaponStatsFrame:WaitForChild("StatsList");
local statsGridLayout = statsList:WaitForChild("UIGridLayout");
local statsLabelTemplate = script:WaitForChild("StatsLabel");
local masteryFrame = weaponStatsFrame:WaitForChild("masteryFrame");
local masteryBar = masteryFrame:WaitForChild("masteryBar");
local masteryLabel = masteryFrame:WaitForChild("masteryLabel");
local expandHint = weaponStatsFrame:WaitForChild("expandHint");

local graphView = weaponStatsFrame:WaitForChild("GraphView");
local barFrameTemplate = script:WaitForChild("barFrame");
local numLabelTemplate = script:WaitForChild("numLabel");

local postTextFunc = {
	PreModDamageAdd=function(itemClass, info, infoText, statValue)
		if itemClass and itemClass.Configurations and itemClass.Configurations.PreModDamage then
			return infoText.. " ≈(+".. modFormatNumber.Beautify(math.ceil(itemClass.Configurations.PreModDamage*statValue *100)/100, true)..")";
		end
		return infoText;
	end;	
};

local graphStatTemplates = {
	Weapon="<b>Damage:</b> $Damage      <b>Fire Rate:</b> $Rpm RPM      <b>Ammo:</b> $AmmoLimit/$MaxAmmoLimit      <b>Reload Time:</b> $ReloadSpeeds";
}

local statTemplates = {
	--MARK: Melee stats;
	Melee={
		{Category="Configurations"; Tag="Damage"; Text="<b>Damage:</b>    $stat"; Type="3dp"};
		{Category="Configurations"; Tag="PrimaryAttackSpeed"; Text="<b>Attack Speed:</b>    $stat"; Type="3dp"};
		{Category="Configurations"; Tag="StaminaCost"; Text="<b>Stamina Cost:</b>    $stat"; Type="2dp"};
		{Category="Configurations"; Tag="HitRange"; Text="<b>Melee Range:</b>    $stat units"; Type="2dp"};

		{Category="Configurations"; Tag="Dps"; Text="<b>DPS:</b>    $stat"; Type="3dp"; OrderOffset=99;};
		-- Heavy attacks melee;
		{Category="Configurations"; Tag="HeavyAttackMultiplier"; Text="<b>Heavy Attack Multiplier:</b>    $stat%"; Type="percent";};
		{Category="Configurations"; Tag="HeavyAttackSpeed"; Text="<b>Heavy Attack Speed:</b>    $stat"; Type="3dp";};

		-- Blunt melee;
		{Category="Configurations"; Tag="Knockback"; Text="<b>Knockback:</b>    $stat"; Type="2dp";};
		{Category="Configurations"; Tag="KnockoutDuration"; Text="<b>Knockout Duration:</b>    $stats"; Type="2dp";};

		-- Throwing melee;
		{Category="Configurations"; Tag="ThrowDamagePercent"; Text="<b>Throw Damage Percent:</b>    $stat%"; Type="percent";};
		{Category="Configurations"; Tag="ThrowStaminaCost"; Text="<b>Throwing Stamina Cost:</b>    $stat"; Type="2dp";};

		{Category="Configurations"; Tag="Velocity"; Text="<b>Throw Velocity:</b>    $stat u/s"; Type="2dp";};
		{Category="Configurations"; Tag="VelocityBonus"; Text="<b>Charge Velocity Bonus:</b>    $stat u/s"; Type="2dp";};
		{Category="Configurations"; Tag="ChargeDuration"; Text="<b>Charge Time:</b>    $stats"; Type="2dp";};

		{Category="Configurations"; Tag="BleedDamagePercent"; Text="<b>Bleed Damage Percent:</b>    $stat%"; Type="percent";};
		{Category="Configurations"; Tag="BleedSlowPercent"; Text="<b>Bleed Slow Percent:</b>    $stat%"; Type="percent";};
	};
	--MARK: Weapon stats;
	Weapon={
		{Category="Properties"; Tag="Potential"; Text="<b>Mastery:</b>    $stat%"; Type="percent2dp"};

		{Category="Configurations"; Tag="PreModDamage"; Text="<b>PreModDamage:</b>    $stat"; Type="3dp"};
		{Category="Configurations"; Tag="Damage"; Text="<b>Damage:</b>    $stat"; Type="3dp"};
		{Category="Configurations"; Tag="CritMulti"; Text="<b>Crit Multiplier:</b>    $stat%"; Type="percent";
			PostText=postTextFunc.PreModDamageAdd;
		};
		{Category="Configurations"; Tag="HeadshotMultiplier"; Text="<b>Headshot Multiplier:</b>    $stat%"; Type="percent"; OnlyExpand=true;
			PostText=postTextFunc.PreModDamageAdd;
		};
		{Category="Configurations"; Tag="DamageRev"; Text="<b>Damage Rev:</b>    $stat%"; Type="percent";
			PostText=postTextFunc.PreModDamageAdd;
		};
		--{Category="Configurations"; Tag="DamageCalibre"; Text="<b>Damage Calibre Shift:</b>    $stat"; Type="2dp"; OnlyExpand=true;
		--	PostText=postTextFunc.PreModDamageAdd;
		--};
		{Category="Configurations"; Tag="CritChance"; Text="<b>Crit Chance:</b>    $stat%"; Type="percent2dp"};
		
		{Category="Properties"; Tag="Rpm"; Text="<b>Fire Rate:</b>    $stat RPM"; Type="int"};
		{Category="Properties"; Tag="ReloadSpeed"; Text="<b>Reload Time:</b>    $stats"; Type="3dp"};
		{Category="Configurations"; Tag="AmmoLimit"; Text="<b>Magazine Size:</b>    $stat"; Type="int"};
		{Category="Configurations"; Tag="MaxAmmoLimit"; Text="<b>Ammo Capacity:</b>    $stat"; Type="int"};
		{Category="Properties"; Tag="Multishot"; Text="<b>Multishot:</b>    $stat"; Type="int"};
		{Category="Properties"; Tag="Piercing"; Text="<b>Piercing:</b>    $stat"; Type="int"};
		
		
		{Category="Configurations"; Tag="Inaccuracy"; Text="<b>Inaccuracy:</b>    $stat"; Type="2dp"; OnlyExpand=true;};
		{Category="Configurations"; Tag="InaccDecaySpeed"; Text="<b>Inaccuracy Decay Speed:</b>    $stat"; Type="2dp"; OnlyExpand=true;};
		
		{Category="Configurations"; Tag="FocusDuration"; Text="<b>Focus Time:</b>    $stat"; Type="2dp"; OnlyExpand=true;};
		{Category="Configurations"; Tag="FocusWalkSpeedReduction"; Text="<b>Focus Movespeed:</b>    $stat%"; Type="percent"; OnlyExpand=true;};
		{Category="Configurations"; Tag="ChargeDamagePercent"; Text="<b>Focused Multiplier:</b>    $stat%"; Type="percent"; OnlyExpand=true;};

		
		
		{Category="Configurations"; Tag="RapidFire"; Text="<b>Rapid Fire:</b>    $stats"; Type="2dp"; };
		
		{Category="Configurations"; Tag="TriggerMode"; Text="<b>Trigger Mode:</b>    $stat"; Type="trigger"; OnlyExpand=true;};
		{Category="Configurations"; Tag="BulletMode"; Text="<b>Bullet Type:</b>    $stat"; Type="bullet"; OnlyExpand=true;};
		
		{Category="Configurations"; Tag="ProjectileId"; Text="<b>Projectile:</b>    $stat"; Type="string"; OnlyExpand=true;};
		
		{Category="Configurations"; Tag="ExplosionRadius"; Text="<b>Explosion Radius:</b>    $statu"; Type="int";};
		{Category="Configurations"; Tag="ExplosionStun"; Text="<b>Explosion Stun:</b>    $stats"; Type="2dp";};
		
		
		{Category="Configurations"; Tag="Element"; Text="<b>Element:</b>    $stat"; Type="string"};
		{Category="Configurations"; Tag="Tad"; Text="<b>TAD:</b>    $stat"; Type="int"; OnlyExpand=true;};
		{Category="Configurations"; Tag="Dps"; Text="<b>DPS:</b>    $stat"; Type="3dp"};
		{Category="Configurations"; Tag="Dpm"; Text="<b>DPM:</b>    $stat"; Type="2dp"};
		{Category="Configurations"; Tag="Md"; Text="<b>MD:</b>    $stat"; Type="int"};
		
		
	};
	--MARK: Clothing stats;
	Clothing={
		{Category="ModArmorPoints"; Text="<b>Armor Points:</b>    $stat"; Type="int"};
		{Category="ModHealthPoints"; Text="<b>Health Points:</b>    $stat"; Type="int"};
		{Category="DamageReflection"; Text="<b>Damage Reflection:</b>    $stat%"; Type="percent"};
		{Category="BulletProtection"; Text="<b>Bullet Protection:</b>    $stat%"; Type="percent"};
		
		{Category="HotEquipSlots"; Text="<b>Additional Hotbar Slots:</b>    $stat"; Type="int"};

		{Category="BaseMoveSpeed"; Text="<b>Base MoveSpeed:</b>    $stat"; Type="int"};
		{Category="BaseSprintSpeed"; Text="<b>Base SprintSpeed:</b>    $stat"; Type="int"};
		{Category="SprintDelay"; Text="<b>Sprint Delay:</b>    $stats"; Type="int"};
		
		{Category="TickRepellent"; Text="<b>Ticks Protection:</b>    $stat"; Type="2dp"};
		{Category="ModNekrosisHeal"; Text="<b>Nekrosis Heal:</b>    $stat hp/s"; Type="2dp"};
		{Category="GasProtection"; Text="<b>Gas Protection:</b>    $stat%"; Type="percent"};
		
		
		{Category="UnderwaterVision"; Text="<b>Underwater Vision:</b>    $stat%"; Type="percent"};
		{Category="OxygenDrainReduction"; Text="<b>Oxygen Drain Reduction:</b>    $stat%"; Type="percent"};
		{Category="OxygenRecoveryIncrease"; Text="<b>Oxygen Recovery Increase:</b>    $stat%"; Type="percent"};
		
		
		{Category="MoveImpairReduction"; Text="<b>Movement Impair Reduction:</b>    $stat%"; Type="percent"};
		{Category="EquipTimeReduction"; Text="<b>Equip Time Reduction:</b>    $stat%"; Type="percent"};
		{Category="AdditionalStamina"; Text="<b>Stamina:</b>    +$stat"; Type="int"};
		{Category="Warmth"; Text="<b>Warmth:</b>    $stat°C"; Type="int"};

		{Category="FlinchProtection"; Text="<b>Flinch Protection:</b>    $stat%"; Type="percent"};
		{Category="SplashReflection"; Text="<b>Splash Reflection:</b>    $stat%"; Type="percent"};
		
	}
};

local specialStatsTemplates = {
	["IgnitionChance"] = {Text="<b>Ignition Chance:</b>    $stat%"; Type="percent"};
}

local mouseOverDescription = {
	--MARK: Weapon desc;
	Potential={
		Desc="Weapon mastery scales the damage output. When your mastery is at 100%, you will deal 100% of the damage the weapon can output. At weapon level 0, the mastery will generally scale the DPS to roughly 100 DPS or higher.\n\n(Higher is better)";
	};
	PreModDamage={
		Desc="This the damage after weapon mastery and tweaks and before mods are applied.\n\n(Higher is better)";
	};
	Damage={
		Desc="Damage is the damage per shot on an enemy target.\n\nStacks additionally with additional damage mods.\n\n(Higher is better)";
	};
	Rpm={
		Desc="Fire Rate is how many shots it can fire in a minute.\n\n(Higher is better)";
	};
	--FireRate={
	--	Desc="Fire Rate is how many shots it can do in a minute.\n\nNon-stackable stat, higher tier mods will overwrite this value.\n\n(Higher is better)";
	--};
	ReloadSpeed={
		Desc="Reload Time the time it takes to complete a reload.\n\nNon-stackable stat, higher tier mods will overwrite this value.\n\n(Lower is better)";
	};
	AmmoLimit={
		Desc="Magazine Size is the amount of bullets you can shoot before having to reload.\n\nStacks additionally with additional magazine size mods.\n\n(Higher is better)";
	};
	MaxAmmoLimit={
		Desc="Ammo Capacity is the amount of total bullets you can shoot before having to restock in ammo.\n\nStacks additionally with additional ammo capacity mods.\n\n(Higher is better)";
	};
	Multishot={
		Desc="Multishot is the amount of pellets that comes out when shot, for example shotguns usually have more than 1 multishot.\n\nNon-stackable stat, higher tier mods will overwrite this value.\n\n(Higher is better)";
	};
	Piercing={
		Desc="Piercing is the number of enemies a bullet can shoot through.\n\nNon-stackable stat, higher tier mods will overwrite this value.\n\n(Higher is better)";
	};
	Inaccuracy={
		Desc="Inaccuracy is the max inaccuracy that a pellet is angled excluding factors that increases/decreases max inaccuracy like moving, ads and crouching. This value is an angle in between 0 to 90 degrees. \n\n(Lower is better)";
	};
	InaccDecaySpeed={
		Desc="The time in seconds for the inaccuracy to reset back to 0 degrees after a shot. Every first shot after reset is always 0 degrees inaccuracy. \n\n(Lower is better)";
	};
	HeadshotMultiplier={
		Desc="Headshot Multiplier is the additional premod damage multiplier when shooting enemies in the head. \n\n(Higher is better)";
	};
	TriggerMode={
		Desc="Trigger Mode is how the weapon operates when holding the fire button.";
	};
	BulletMode={
		Desc="Bullet Mode is what projectile type the weapon fires.\n  Hitscan is a normal bullet trajectory.\n  Projectile is physically based bullet.";
	};
	Element={
		Desc="Element determines the active elemental mod attached to the weapon.";
	};
	FocusDuration={
		Desc="The time in seconds it takes to fully charge a shot.";
	};
	FocusWalkSpeedReduction={
		Desc="Your movement speed is reduced by to the percent when focused. \n\n(Higher is better)";
	};
	ChargeDamagePercent={
		Desc="The additional premod damage multiplier when you fully focused a shot. \n\n(Higher is better)";
	};
	CritChance={
		Desc="The chance to deal critical damage that multiplies your damage with the Crit Multiplier. \n\n(Higher is better)";
	};
	CritMulti={
		Desc="The additional premod damage multiplier when a crit is proced. \n\n(Higher is better)";
	};
	Dps={
		Desc="DPS also known as Damage Per Second, is the amount of damage on average the weapon can do in a second. The value does not take reload time and magazine size in to theoretical calculations. \n\n(Higher is better)";
	};
	Dpm={
		Desc="DPM also known as Damage Per Minute, is the amount of damage on average the weapon can do in a minute, reload time and magazine size is taken into theoretical calculations. \n\n(Higher is better)";
	};
	Tad={
		Desc="TAD also known as Total Ammo Damage, is the amount of damage the weapon can totally output with all your ammo.";
	};
	Md={
		Desc="MD also known as Magazine Damage, is the amount of damage the weapon can output with a single magazine.";
	};
	Knockback={
		Desc="The velocity the target will be knocked back. \n\n(Higher is better)";
	};
	KnockoutDuration={
		Desc="The duration of zombies being disabled. \n\n(Higher is better)";
	};
	RapidFire={
		Desc="Seconds it takes to reach max fire rate. Increases rate of fire the longer you fire until it reaches rate fire cap.\n\n(Lower is better)";
	};
	ExplosionRadius={
		Desc="Increase the explosion range.";
	};
	DamageRev={
		Desc="Your damage revs up and does more damage the less ammo you got in your magazine.\n\n(Value is the multipler of the additional premod damage in the final bullet)";
	};
	ExplosionStun={
		Desc="The duration in which the enemy ragdolls. Enemies are only stunned if they take more than 40% of their max health as damage.\n\n(Higher is better)";
	};
	

	--MARK: Melee desc;
	ThrowDamagePercent={
		Desc="Throwing does percent max health damage on impact, minimal damage is half of melee's damage.\n\n(Higher is better)";
	};
	HeavyAttackMultiplier={
		Desc="The damage muliplier for when charging your attacks with focus.\n\n(Higher is better)";
	};
	HeavyAttackSpeed={
		Desc="The time it takes to max heavy attack charge with focus.\n\n(Lower is better)";
	};
	StaminaCost={
		Desc="The cost of stamina when swinging your melee.\n\n(Lower is better)";
	};
	ThrowStaminaCost={
		Desc="The cost of stamina when throwing your melee, your melee can not be throw when you are out of stamina.\n\n(Lower is better)";
	};
	Velocity={
		Desc="The travel speed of your melee throws.\n\n(Higher is better)";
	};
	VelocityBonus={
		Desc="The extra speed of your throws by charging.\n\n(Higher is better)";
	};
	ChargeDuration={
		Desc="The time it takes to fully charge your throws.\n\n(Lower is better)";
	};
	BleedDamagePercent={
		Desc="Edged melee applies a bleed debuff on hit. Bleed damage is a percentage of the melee damage.";
	};
	BleedSlowPercent={
		Desc="Bleed debuff applies a slow by percentage.";
	};

	--MARK: Clothings desc;
	HotEquipSlots={
		Desc="The number of additional slots on your hotbar after the default 5.";
	};
	
	TickRepellent={
		Desc="The time you will be invunerable to tick blursts after one already blurst.\n\n(In seconds)";
	};
	GasProtection={
		Desc="The damage dealt from gas attacks are reduced by this percent.\n\n(Sorted by Largest)";
	};
	ModArmorPoints={
		Desc="Additional armor points added to your max armor.";
	};
	ModNekrosisHeal={
		Desc="Additional heal per second during Nekrosis.";
	};
	
	BulletProtection={
		Desc="Reduces damage from hitscan projectiles from enemy by this percent.";
	};
	MoveImpairReduction={
		Desc="Multiplied, reduction to the duration of movement impairment debuffs.";
	};
	EquipTimeReduction={
		Desc="Multiplied, reduction to the time it takes to equip a tool.";
	};
	AdditionalStamina={
		Desc="Additional stamina added to your maximum stamina.";
	};
	Warmth={
		Desc="Maintaining a temperature between 10 to 40 degree Celsius is important to prevent negative effects. Temperature below 0°C or above 50°C will be lethal. This stat is additional.";
	};
	UnderwaterVision={
		Desc="Underwater vision range is improved by this percent. This stat is sorted by the highest.";
	};
	OxygenDrainReduction={
		Desc="Oxygen drain while swimming is reduced by this percent. This stat is sorted by the highest.";
	};
	OxygenRecoveryIncrease={
		Desc="Oxygen recovery while swimming improved by this percent. This stat is sorted by the highest.";
	};
	FlinchProtection={
		Desc="Reduces the flinch strength when getting damaged.\n\n(Higher is better)";
	};
	SplashReflection={
		Desc="Splash effects of enemies such as Ticks' Detonation are reflected."
	};
	BaseMoveSpeed={
		Desc="Set your base movement speed. (Default is 18)";
	};
	BaseSprintSpeed={
		Desc="Set your base sprinting speed. (Default is 22)";
	};
};

local triggerModes = {"Semi-automatic"; "Bolt-action"; "Full-automatic"; "Burstfire"; "Spin-up";};
local bulletTypes = {"Hitscan"; "Projectile"; "Contact";};

local isExpanded = false;
local activeDescLabel;
--== Script;
local function refreshLabels()
	for _, obj in pairs(statsList:GetChildren()) do
		if obj:IsA("TextLabel") then
			local found = false;
			for toolType, _ in pairs(statTemplates) do
				for a=1, #statTemplates[toolType] do
					local statInfo = statTemplates[toolType][a];
					if statInfo.Tag == obj.Name then
						if isExpanded then
							obj.Visible = true;
						else
							obj.Visible = statInfo.OnlyExpand ~= true;
						end
						
						found = true;
						break;
					end
				end
			end
			
			if not found then
				if isExpanded then
					obj.Visible = true;
				else
					obj.Visible = false;
				end
			end
		end
	end
end

local function refreshFrameSize()
	local xSize = math.clamp(workspace.CurrentCamera.ViewportSize.X-(350*2), 0, 580);
	if isExpanded then
		if graphStatTemplates[Interface.CurrentClass] then
			graphView.Visible = false;
			statsList.Visible = true;
		end
		refreshLabels();
		if modConfigurations.CompactInterface then
			weaponStatsFrame:TweenSize(UDim2.new(0.5, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true);
		else
			weaponStatsFrame:TweenSize(UDim2.new(0, xSize, 0, 300), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true);
		end
		expandHint.Text = "Click to shrink";
	else
		if graphStatTemplates[Interface.CurrentClass] then
			graphView.Visible = true;
			statsList.Visible = false;
		else
			graphView.Visible = false;
			statsList.Visible = true;
		end
		refreshLabels();
		if modConfigurations.CompactInterface then
			weaponStatsFrame:TweenSize(UDim2.new(0.5, 0, 0.5, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.1, true);
		else
			weaponStatsFrame:TweenSize(UDim2.new(0, xSize, 0, 160), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.1, true);
		end
		expandHint.Text = "Click to expand";
	end
end

function Interface.init(modInterface)
	setmetatable(Interface, modInterface);

	local weaponStatsWindow = Interface.NewWindow("WeaponStats", weaponStatsFrame);
	weaponStatsWindow.CompactFullscreen = true;
	
	if modConfigurations.CompactInterface then
		weaponStatsFrame.AnchorPoint = Vector2.new(0, 1);
		weaponStatsFrame.Size = UDim2.new(0.5, 0, 0.5, 0);
		weaponStatsFrame.Position = UDim2.new(0, 0, 1, 0);
		weaponStatsWindow:SetOpenClosePosition(UDim2.new(0, 0, 1, 0), UDim2.new(0, 0, 1.5, 0));
		weaponStatsFrame:WaitForChild("StatsList"):WaitForChild("UIGridLayout").FillDirection = Enum.FillDirection.Horizontal;
		weaponStatsFrame:WaitForChild("UICorner").CornerRadius = UDim.new(0, 0);
	else
		weaponStatsWindow:SetOpenClosePosition(UDim2.new(0.5, 0, 1, -145), UDim2.new(0.5, 0, 1.5, -145));
	end
	
	weaponStatsWindow.ReleaseMouse = false;
	weaponStatsWindow.OnWindowUpdate:Connect(Interface.Update)
	weaponStatsWindow.OnWindowToggle:Connect(function(visible, storageItem)
		if visible then
			refreshFrameSize()
			Interface.Update(storageItem);
		end
	end)
	
	return Interface;
end;

function Interface.Update(storageItem)
	if storageItem == nil or typeof(storageItem) ~= "table" then return end;
	for _, obj in pairs(statsList:GetChildren()) do
		if obj:IsA("GuiObject") then
			obj:Destroy();
		end
	end
	
	local itemClass, classType = modData:GetItemClass(storageItem.ID);
	if itemClass == nil then return end;
	barFrameTemplate.BackgroundColor3 = modBranchConfigs.BranchColor;
	
	modData.OnAmmoUpdate:Fire(storageItem.ID);
	
	Interface.CurrentClass = itemClass.Class;
	local statsTemplate = statTemplates[itemClass.Class];
	
	refreshFrameSize();
	
	local newShortHandLabel = graphStatTemplates[itemClass.Class];
	
	if itemClass == nil or statsTemplate == nil then

		Interface:CloseWindow("WeaponStats");
		if statsTemplate == nil then
			Debugger:Warn("Missing stats template.");
		else
			Debugger:Warn("Missing itemClass.");
		end
		return;
	end
	

	local layoutOrder=1;
	local function createLabel(infoKey, info, statValue)
		for _, obj in pairs(statsList:GetChildren()) do
			if obj.Name == infoKey then
				game.Debris:AddItem(obj, 0);
			end
		end
		
		local newLabel = statsLabelTemplate:Clone();
		newLabel.LayoutOrder = layoutOrder + (info.OrderOffset or 0);
		newLabel.Name = infoKey;

		
		if isExpanded then
			newLabel.Visible = true;
		else
			newLabel.Visible = info.OnlyExpand ~= true;
		end

		local infoText = info.Text;
		local statString = "n/a";

		if type(statValue) == "table" then
			if statValue.Min and statValue.Max then
				statString = ("["..
					(info.Type == "int" and math.ceil(statValue.Min) or statValue.Min)
					..", "..
					(info.Type == "int" and math.ceil(statValue.Max) or statValue.Max).."]");
			else
				statString = ("["..table.concat(statValue,", ").."]");
			end
		else
			statString = (
				info.Type == "int" and modFormatNumber.Beautify(math.ceil(statValue))
					or info.Type == "string" and statValue
					or info.Type == "4dp" and modFormatNumber.Beautify(math.ceil(statValue*10000)/10000, true)
					or info.Type == "3dp" and modFormatNumber.Beautify(math.ceil(statValue*1000)/1000, true)
					or info.Type == "2dp" and modFormatNumber.Beautify(math.ceil(statValue*100)/100, true)
					or info.Type == "Rpm" and modFormatNumber.Beautify(math.ceil(60/statValue*100)/100)
					or info.Type == "percent" and math.floor(statValue*100)
					or info.Type == "percent2dp" and math.floor(statValue*1000)/10
					or info.Type == "trigger" and triggerModes[statValue]
					or info.Type == "bullet" and bulletTypes[statValue]
					or info.Type == "bool" and tostring(statValue)
					or info.Type == "rawnum" and modFormatNumber.Beautify(statValue, true)
					or statValue)
		end

		infoText = string.gsub(infoText, "$stat", statString);
		if info.PostText then
			infoText = info.PostText(itemClass, info, infoText, statValue);
		end
		newLabel.Text = infoText;
		newLabel.Parent = statsList;
		
		local sizeConstraint = Instance.new("UISizeConstraint");
		sizeConstraint.MinSize = Vector2.new(200, 15);
		sizeConstraint.Parent = newLabel;
		newLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
			sizeConstraint.MinSize = newLabel.TextBounds;
		end)
		
		if newShortHandLabel then
			local strVal = statValue;
			if type(statValue) ~= "table" then
				if info.Type == "Rpm" then
					strVal = modFormatNumber.Beautify(math.ceil(60/statValue))
				elseif info.Type == "int"
					or info.Type == "2dp"
					or info.Type == "3dp"
					or info.Type == "4dp" then
					strVal = modFormatNumber.Beautify(math.ceil(statValue*10)/10, true);
				end
			end
			newShortHandLabel = string.gsub(newShortHandLabel, "$"..infoKey, strVal);
		end

		local mouseOverInfo = mouseOverDescription[infoKey];
		if mouseOverInfo then
			newLabel.MouseMoved:Connect(function()
				if activeDescLabel == nil then
					activeDescLabel = script:WaitForChild("TagDesc"):Clone();
					activeDescLabel.Parent = weaponStatsFrame;
					
					local newDesc = mouseOverInfo.Desc;
					
					newDesc = newDesc:gsub("Additional", "<b>Additional</b>");
					newDesc = newDesc:gsub("Multiplied", "<b>Multiplied</b>");
					
					activeDescLabel.Text = newDesc;

					local textBound = TextService:GetTextSize(activeDescLabel.Text, activeDescLabel.TextSize, activeDescLabel.Font, Vector2.new(300, 1000));
					activeDescLabel.Size = UDim2.new(0, textBound.X+22, 0, textBound.Y+22);

					local statAbsPos = newLabel.AbsolutePosition - weaponStatsFrame.AbsolutePosition;
					activeDescLabel.Position = UDim2.new(0, statAbsPos.X-5, 0, statAbsPos.Y+30);
				end
			end)
			newLabel.MouseLeave:Connect(function()
				if activeDescLabel then
					activeDescLabel:Destroy();
					activeDescLabel = nil;
				end
			end)
		end
		
		return newLabel;
	end
	
	for a=1, #statsTemplate do
		layoutOrder = a;
		local info = statsTemplate[a];
		local statValue = nil;
		if info.Category and info.Tag then
			statValue = itemClass[info.Category][info.Tag];

		elseif info.Category then
			statValue = itemClass[info.Category];
		end
		
		if statValue ~= nil then
			if typeof(statValue) ~= "table" or (statValue.Potential == nil and statValue.Tad == nil) then
				local infoKey = info.Tag or info.Category;

				createLabel(infoKey, info, statValue);
			end
		end	
	end
	
	if itemClass.Configurations and itemClass.Configurations.SpecialStats then
		for infoKey, statValue in pairs(itemClass.Configurations.SpecialStats) do
			local info = specialStatsTemplates[infoKey];
			layoutOrder = layoutOrder +1;
			createLabel(infoKey, info, statValue);
		end
	end

	if itemClass.RegisteredProperties then
		Debugger:StudioWarn("itemClass.RegisteredProperties", itemClass.RegisteredProperties);
		for k, v in pairs(itemClass.RegisteredProperties) do
			createLabel(k, {
				Text="<b>+ Passive:</b>    $stat"; 
				Type="string";
			}, k);
			layoutOrder = layoutOrder +1;
		end
	end
	
	if itemClass.Class == "Weapon" then
		if Interface.FirstRun == nil then
			Interface.FirstRun = true;
			task.wait(0.1);
		end
		graphView.shortStatLabel.Text = newShortHandLabel;
		
		local sizeRef = graphView.graphs.sizeRef.AbsoluteSize;
		graphView.graphs.nums:ClearAllChildren();
		graphView.graphs.bars:ClearAllChildren();
		
		
		local preModDamage = itemClass.Configurations.PreModDamage;
		local moddedDamage = itemClass.Configurations.Damage;
		local ammoMag = itemClass.Configurations.AmmoLimit;
		
		local columnSize = sizeRef.X/ammoMag;
		local columnPoint = columnSize/2;
		
		local dmgRev = itemClass.Configurations.DamageRev;
		local critMulti = itemClass.Configurations.CritMulti;
		local multishot = itemClass.Properties.Multishot;
		local hsMulti = itemClass.Configurations.HeadshotMultiplier;
		local chargeMulti = itemClass.Configurations.ChargeDamagePercent;
		
		local maxDmg = 0;
		local newBarFrames = {};
		
		for a=1, ammoMag do
			local barFrame = barFrameTemplate:Clone();
			
			if a == 1 or a == ammoMag
				or (ammoMag >= 128 and math.fmod(a, 16) == 0) 
				or (ammoMag >= 64 and ammoMag < 128 and math.fmod(a, 4) == 0)
				or (ammoMag >= 20 and ammoMag < 64 and math.fmod(a, 2) == 0)
				or ammoMag < 20 then
				
				local numLabel = numLabelTemplate:Clone();
				numLabel.Text = a;
				numLabel.Position = UDim2.new(0, columnSize*a -columnPoint, 1, -7);
				numLabel.Parent = graphView.graphs.nums;
			end
			
			barFrame.BackgroundTransparency = 1;
			barFrame.Size = UDim2.new(0, math.ceil(columnPoint/2)*2, 1, 0);
			barFrame.Position = UDim2.new(0, columnSize*a -columnPoint, 1, 0);
			
			local damage = moddedDamage;
			
			local revBonus = nil;
			if dmgRev then
				if a ~= 1 then
					revBonus = (moddedDamage * dmgRev) * math.clamp((a/ammoMag), 0, 1);
					damage = damage + revBonus;
				end
			end
			
			local critBonus = nil;
			if critMulti then
				local critChance = itemClass.Configurations.CritChance;
				if a == ammoMag or casualPseudoRandom:FairCrit(storageItem.ItemId, critChance) then -- math.fmod(a, math.floor(1/critChance)) == 0
					critBonus = preModDamage * critMulti;
					damage = damage + critBonus;
				end
			end
			
			local hsDmg = nil;
			if hsMulti and (a == 1 or a == ammoMag or math.fmod(a, 5) == 0) then
				hsDmg = preModDamage * hsMulti;
				damage = damage + hsDmg;
			end

			local chargeDmg = nil;
			if chargeMulti and (a == 1 or a == ammoMag or math.fmod(a, 6) == 0) then
				chargeDmg = preModDamage * chargeMulti;
				damage = damage + chargeDmg;
			end
			
			
			local mutishotMulti = nil;
			if typeof(multishot) == "table" or (typeof(multishot) == "number" and multishot > 1) then
				mutishotMulti = multishot;
				if typeof(multishot) == "table" then
					mutishotMulti = math.random(multishot.Min, multishot.Max);
				end
				
				damage = damage * mutishotMulti;
			end
			
			local weakpointDmg = nil;
			local _level, skillStats = modData:GetSkillTree("weapoi");
			if skillStats and (a == ammoMag or math.fmod(a, 6) == 0) then
				local weapoiMulti = (skillStats.Percent.Default + skillStats.Percent.Value)/100
				
				weakpointDmg = preModDamage * weapoiMulti;
				
				damage = damage + weakpointDmg;
			end
			
			local dmgBar = barFrameTemplate:Clone();
			dmgBar.Parent = barFrame;
			table.insert(newBarFrames, {Frame=dmgBar; Value=damage});
			
			maxDmg = math.max(maxDmg, damage);
			barFrame.MouseMoved:Connect(function()
				if activeDescLabel == nil then
					activeDescLabel = script:WaitForChild("TagDesc"):Clone();
					activeDescLabel.Parent = weaponStatsFrame;
					local descString = a == 1 and '1st' 
									or a == 2 and '2nd' 
									or a == 3 and '3rd'
									or a >= 4 and a..'th'
					
					descString = "<b>"..descString.." shot:</b>\n   <b>Base:</b>  "..modFormatNumber.Beautify(math.ceil(moddedDamage*10)/10);
					
					if mutishotMulti then
						descString = descString.."\n   <b>Multishot:</b>  "..mutishotMulti;
					end
					
					if revBonus then
						descString = descString.."\n   <b>Rev:</b>  "..modFormatNumber.Beautify(math.ceil(revBonus*10)/10);
					end
					
					if critBonus then
						descString = descString.."\n   <b>Critical:</b>  "..modFormatNumber.Beautify(math.ceil(critBonus*10)/10);
					end
					
					if hsDmg then
						descString = descString.."\n   <b>Headshot:</b>  "..modFormatNumber.Beautify(math.ceil(hsDmg*10)/10);
					end

					if chargeDmg then
						descString = descString.."\n   <b>Focused:</b>  "..modFormatNumber.Beautify(math.ceil(chargeDmg*10)/10);
					end
					
					if weakpointDmg then
						descString = descString.."\n   <b>Weakpoint:</b>  "..modFormatNumber.Beautify(math.ceil(weakpointDmg*10)/10);
					end
					
					descString = descString.."\n   <b>Total:</b>  "..modFormatNumber.Beautify(math.ceil(damage*10)/10);
					
					
					activeDescLabel.Text = descString;
					
					local textBound = TextService:GetTextSize(activeDescLabel.Text, activeDescLabel.TextSize, activeDescLabel.Font, Vector2.new(300, 1000));
					activeDescLabel.Size = UDim2.new(0, textBound.X+22, 0, textBound.Y+22);
					
					local statAbsPos = barFrame.AbsolutePosition - weaponStatsFrame.AbsolutePosition;
					activeDescLabel.Position = UDim2.new(0, statAbsPos.X-5, 0, statAbsPos.Y+30);
				end
			end)
			barFrame.MouseLeave:Connect(function()
				if activeDescLabel then
					activeDescLabel:Destroy();
					activeDescLabel = nil;
				end
			end)
			
			barFrame.Parent = graphView.graphs.bars;
		end
		
		for a=1, #newBarFrames do
			local barInfo = newBarFrames[a];
			barInfo.Frame.Size = UDim2.new(1, 0, math.clamp(barInfo.Value/maxDmg, 0.01, 1), 0)
		end
	end
	
	if classType == "Weapon" then
		local weaponLevel = storageItem.Values.L or 0;
		local wExp = storageItem.Values.E or 0;
		local wExpGoal = storageItem.Values.EG or 0;
		masteryBar.Size = UDim2.new(math.clamp(wExp/wExpGoal, 0, 1), 0, 1, 0);
		masteryLabel.Text = ("Weapon Level: $Lvl/$Mvl"):gsub("$Lvl", tostring(math.floor(weaponLevel))):gsub("$Mvl", tostring(20));
		masteryFrame.Visible = true;
		
	else
		masteryFrame.Visible = false;
		
	end
	
	local workbenchUpgradesLib = modWorkbenchLibrary.ItemUpgrades[storageItem.ItemId];
	if workbenchUpgradesLib then
		-- local conditionRange = workbenchUpgradesLib.SkinWear and workbenchUpgradesLib.SkinWear.Wear or {Min=0.000001; Max=0.999999;};
		
		-- layoutOrder = 9999;
		-- local newLabel = createLabel("ToolCondition", {
		-- 	Text="<b>Condition Range:</b>    $stat"; Type="rawnum";
		-- }, conditionRange);
		
	end
end

weaponStatsFrame.MouseButton1Click:Connect(function()
	isExpanded = not isExpanded;
	statsGridLayout.FillDirectionMaxCells = isExpanded and 0 or 7;
	refreshFrameSize();
end)

function Interface.disconnect()
	
end

script.AncestryChanged:Connect(function(c, p)
	if c == script and p == nil and Interface.disconnect then
		Interface.disconnect();
	end
end)
return Interface;