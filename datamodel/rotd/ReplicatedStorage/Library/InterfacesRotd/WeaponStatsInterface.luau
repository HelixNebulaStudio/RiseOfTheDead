local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TextService = game:GetService("TextService");

local localPlayer = game.Players.LocalPlayer;

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = shared.require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modPseudoRandom = shared.require(game.ReplicatedStorage.Library.PseudoRandom);
local modFormatNumber = shared.require(game.ReplicatedStorage.Library.FormatNumber);
local modWorkbenchLibrary = shared.require(game.ReplicatedStorage.Library.WorkbenchLibrary);

local postTextFunc = {
	PreModDamageAdd=function(config, info, infoText, statValue)
		if config.PreModDamage == nil then return infoText end;
        local v = modFormatNumber.Beautify(math.ceil(config.PreModDamage*statValue *100)/100, true);
        return `{infoText} ≈(+{v})`;
	end;
};

local graphStatTemplates = {
	Gun="<b>Damage:</b> $Damage      <b>Fire Rate:</b> $Rpm RPM      <b>Ammo:</b> $MagazineSize/$AmmoCapacity      <b>Reload Time:</b> $ReloadTimes";
}

local initCharStats;
local statTemplates = {
	--MARK: Melee stats;
    Character={
		{Key="MaxHealth"; Text="<b>Max Health:</b>    $stat"; Type="int"};
		{Key="MaxArmor"; Text="<b>Max Armor:</b>    $stat"; Type="int"};
		{Key="HealRate"; Text="<b>Healing Rate:</b>    $stat"; Type="2dp"};
		{Key="ArmorRate"; Text="<b>Armor Regeneration Rate:</b>    $stat"; Type="2dp"};
        
		{Key="Oxygen"; Text="<b>Max Oxygen:</b>    $stat"; Type="int"};
    };
	Melee={
		{Key="Damage"; Text="<b>Damage:</b>    $stat"; Type="3dp"};
		{Key="PrimaryAttackSpeed"; Text="<b>Attack Speed:</b>    $stat"; Type="3dp"};
		{Key="StaminaCost"; Text="<b>Stamina Cost:</b>    $stat"; Type="2dp"};
		{Key="HitRange"; Text="<b>Melee Range:</b>    $stat units"; Type="2dp"};

		{Key="Dps"; Text="<b>DPS:</b>    $stat"; Type="3dp"; OrderOffset=99;};
		-- Heavy attacks melee;
		{Key="HeavyAttackMultiplier"; Text="<b>Heavy Attack Multiplier:</b>    $stat%"; Type="percent";};
		{Key="HeavyAttackSpeed"; Text="<b>Heavy Attack Speed:</b>    $stat"; Type="3dp";};

		-- Blunt melee;
		{Key="Knockback"; Text="<b>Knockback:</b>    $stat"; Type="2dp";};
		{Key="KnockoutDuration"; Text="<b>Knockout Duration:</b>    $stats"; Type="2dp";};

		-- Throwing melee;
		{Key="ThrowDamagePercent"; Text="<b>Throw Damage Percent:</b>    $stat%"; Type="percent";};
		{Key="ThrowStaminaCost"; Text="<b>Throwing Stamina Cost:</b>    $stat"; Type="2dp";};

		{Key="Velocity"; Text="<b>Throw Velocity:</b>    $stat u/s"; Type="2dp";};
		{Key="VelocityBonus"; Text="<b>Charge Velocity Bonus:</b>    $stat u/s"; Type="2dp";};
		{Key="ChargeDuration"; Text="<b>Charge Time:</b>    $stats"; Type="2dp";};

		{Key="BleedDamagePercent"; Text="<b>Bleed Damage Percent:</b>    $stat%"; Type="percent";};
		{Key="BleedSlowPercent"; Text="<b>Bleed Slow Percent:</b>    $stat%"; Type="percent";};

		{Key="ThrowRange"; Text="<b>Throwing Range:</b>    $stat u"; Type="2dp";};

        {Key="DamageBlock"; Text="<b>[Melee Dampening] Additional Damage Block:</b>    $stat"; Type="2dp"; OnlyExpand=true;};
	};
	--MARK: Weapon stats;
	Gun={
		{Key="Potential"; Text="<b>Mastery:</b>    $stat%"; Type="percent2dp"};

		{Key="PreModDamage"; Text="<b>PreModDamage:</b>    $stat"; Type="3dp"};
		{Key="Damage"; Text="<b>Damage:</b>    $stat"; Type="3dp"};
		{Key="CritMulti"; Text="<b>Crit Multiplier:</b>    $stat%"; Type="percent";
			PostText=postTextFunc.PreModDamageAdd;
		};
		{Key="HeadshotMultiplier"; Text="<b>Headshot Multiplier:</b>    $stat%"; Type="percent"; OnlyExpand=true;
			PostText=postTextFunc.PreModDamageAdd;
		};
		{Key="DamageRev"; Text="<b>Damage Rev:</b>    $stat%"; Type="percent";
			PostText=postTextFunc.PreModDamageAdd;
		};
		--{Key="DamageCalibre"; Text="<b>Damage Calibre Shift:</b>    $stat"; Type="2dp"; OnlyExpand=true;
		--	PostText=postTextFunc.PreModDamageAdd;
		--};
		{Key="CritChance"; Text="<b>Crit Chance:</b>    $stat%"; Type="percent2dp"};
		
		{Key="Rpm"; Text="<b>Fire Rate:</b>    $stat RPM"; Type="int"};
		{Key="ReloadTime"; Text="<b>Reload Time:</b>    $stats"; Type="3dp"};
		{Key="MagazineSize"; Text="<b>Magazine Size:</b>    $stat"; Type="int"};
		{Key="AmmoCapacity"; Text="<b>Ammo Capacity:</b>    $stat"; Type="int"};
		{Key="Multishot"; Text="<b>Multishot:</b>    $stat"; Type="int"};
		{Key="Piercing"; Text="<b>Piercing:</b>    $stat"; Type="int"};
		
		
		{Key="Inaccuracy"; Text="<b>Inaccuracy:</b>    $stat"; Type="2dp"; OnlyExpand=true;};
		{Key="InaccDecaySpeed"; Text="<b>Inaccuracy Decay Speed:</b>    $stat"; Type="2dp"; OnlyExpand=true;};
		
		{Key="FocusDuration"; Text="<b>Focus Time:</b>    $stat"; Type="2dp"; OnlyExpand=true;};
		{Key="FocusWalkSpeedReduction"; Text="<b>Focus Movespeed:</b>    $stat%"; Type="percent"; OnlyExpand=true;};
		{Key="ChargeDamagePercent"; Text="<b>Focused Multiplier:</b>    $stat%"; Type="percent"; OnlyExpand=true;};

		
		
		{Key="RapidFire"; Text="<b>Rapid Fire:</b>    $stats"; Type="2dp"; };
		
		{Key="TriggerMode"; Text="<b>Trigger Mode:</b>    $stat"; Type="trigger"; OnlyExpand=true;};
		{Key="BulletMode"; Text="<b>Bullet Type:</b>    $stat"; Type="bullet"; OnlyExpand=true;};
		
		{Key="ProjectileId"; Text="<b>Projectile:</b>    $stat"; Type="string"; OnlyExpand=true;};
		
		{Key="ExplosionRadius"; Text="<b>Explosion Radius:</b>    $statu"; Type="int";};
		{Key="ExplosionStun"; Text="<b>Explosion Stun:</b>    $stats"; Type="2dp";};
		
		-- Knockout Trigger
		{Key="KnockoutDistance"; Text="<b>Knockout Distance:</b>    $statu"; Type="2dp"};
		{Key="KnockoutDuration"; Text="<b>Knockout Duration:</b>    $stats"; Type="2dp"};
		-- Ricochet Rifling
		{Key="BulletRicochetCount"; Text="<b>Ricochet Count:</b>    $stat"; Type="int";};
		{Key="BulletRicochetDistance"; Text="<b>Ricochet Distance:</b>    $statu"; Type="2dp"};
		
		{Key="PassiveModifiers"; Text="<b>Passives:</b>    $stat"; Type="string"; OnlyExpand=true;};
		
		{Key="Element"; Text="<b>Element:</b>    $stat"; Type="string"};
		{Key="Tad"; Text="<b>TAD:</b>    $stat"; Type="int"; OnlyExpand=true;};
		{Key="Dps"; Text="<b>DPS:</b>    $stat"; Type="3dp"};
		{Key="Dpm"; Text="<b>DPM:</b>    $stat"; Type="2dp"};
		{Key="Md"; Text="<b>MD:</b>    $stat"; Type="int"};
		
		
	};
	--MARK: Clothing stats;
	Clothing={
		{Key="ArmorPoints"; Text="<b>Armor Points:</b>    $stat"; Type="int"};
		{Key="HealthPoints"; Text="<b>Health Points:</b>    $stat"; Type="int"};
		{Key="DamageReflection"; Text="<b>Damage Reflection:</b>    $stat%"; Type="percent"};
		{Key="BulletProtection"; Text="<b>Bullet Protection:</b>    $stat%"; Type="percent"};
		
		{Key="HotEquipSlots"; Text="<b>Hotbar Slots:</b>    $stat"; Type="int"};

		{Key="MoveSpeed"; Text="<b>Base MoveSpeed:</b>    $stat"; Type="int"};
		{Key="SprintSpeed"; Text="<b>Base SprintSpeed:</b>    $stat"; Type="int"};
		{Key="SprintDelay"; Text="<b>Sprint Delay:</b>    $stats"; Type="int"};
		
		{Key="TickRepellent"; Text="<b>Ticks Protection:</b>    $stat"; Type="2dp"};
		{Key="NekrosisHeal"; Text="<b>Nekrosis Heal:</b>    $stat hp/s"; Type="2dp"};
		{Key="GasProtection"; Text="<b>Gas Protection:</b>    $stat%"; Type="percent"};
		
		
		{Key="UnderwaterVision"; Text="<b>Underwater Vision:</b>    $stat%"; Type="percent"};
		{Key="OxygenDrainReduction"; Text="<b>Oxygen Drain Reduction:</b>    $stat%"; Type="percent"};
		{Key="OxygenRecoveryIncrease"; Text="<b>Oxygen Recovery Increase:</b>    $stat%"; Type="percent"};
		
		
		{Key="MoveImpairReduction"; Text="<b>Movement Impair Reduction:</b>    $stat%"; Type="percent"};
		{Key="EquipTimeReduction"; Text="<b>Equip Time Reduction:</b>    $stat%"; Type="percent"};
		{Key="AdditionalStamina"; Text="<b>Stamina:</b>    +$stat"; Type="int"};
		{Key="Warmth"; Text="<b>Warmth:</b>    $stat°C"; Type="int"};

		{Key="FlinchProtection"; Text="<b>Flinch Protection:</b>    $stat%"; Type="percent"};
		{Key="SplashReflection"; Text="<b>Splash Reflection:</b>    $stat%"; Type="percent"};
		
        {Key="EnemyDetectionRange"; Text="<b>Enemy Detection Range:</b>    $stat radius"; Type="int";};
		{Key="PassiveModifiers"; Text="<b>Passives:</b>    $stat"; Type="string"; OnlyExpand=true;};

		{Key="BlockChance"; Text="<b>[Melee Dampening] Chance:</b>    $stat%"; Type="percent";};
        {Key="DamageBlock"; Text="<b>[Melee Dampening] Damage Block:</b>    $stat"; Type="2dp";};
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
	MagazineSize={
		Desc="Magazine Size is the amount of bullets you can shoot before having to reload.\n\nStacks additionally with additional magazine size mods.\n\n(Higher is better)";
	};
	AmmoCapacity={
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
		Desc="<b>[Crit Receiver]</b> The additional premod damage multiplier when you fully focused a shot. \n\n(Higher is better)";
	};
	CritChance={
		Desc="<b>[Crit Receiver]</b> The chance to deal critical damage that multiplies your damage with the Crit Multiplier. \n\n(Higher is better)";
	};
	CritMulti={
		Desc="<b>[Crit Receiver]</b> The additional premod damage multiplier when a crit is proced. \n\n(Higher is better)";
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
	KnockoutDistance={
		Desc="<b>[Knockout Trigger]</b> Enemies taking a headshot within this distance will be knocked out.\n\n(Higher is better)";
	};
	BulletRicochetCount={
		Desc="<b>[Ricochet Rifling]</b> The amount of times a shot can ricochet between targets.\n\n(Higher is better)";
	};
	BulletRicochetDistance={
		Desc="<b>[Ricochet Rifling]</b> The distance which a ricochet shot will search for a next target.\n\n(Higher is better)";
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
    ThrowRange={
		Desc="The range of accurate melee throws.";
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
	ArmorPoints={
		Desc="Additional armor points added to your max armor.";
	};
	NekrosisHeal={
		Desc="Additional heal per second during Nekrosis.";
	};
	
	BulletProtection={
		Desc="Reduces damage from hitscan projectiles from enemy by this percent.";
	};
	MoveImpairReduction={
		Desc="Reduction to the duration of movement impairment debuffs.";
	};
	EquipTimeReduction={
		Desc="Reduction to the time it takes to equip a tool.";
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
	MoveSpeed={
		Desc="Set your base movement speed. (Default is 18)";
	};
	SprintSpeed={
		Desc="Set your base sprinting speed. (Default is 22)";
	};
    BlockChance={
        Desc="The chance for the passive <b>Melee Dampening</b> to activate.\n\n(Higher is better)";
    };
    DamageBlock={
        Desc="The amount of damage additionally blocked for <b>Melee Dampening</b>.\n\n(Higher is better)";
    };
};

local triggerModes = {"Semi-automatic"; "Bolt-action"; "Full-automatic"; "Burstfire"; "Spin-up";};
local bulletTypes = {"Hitscan"; "Projectile"; "Contact";};


local interfacePackage = {
    Type = "Character";
};
--==

function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));
    local playerClass: PlayerClass, wieldComp: WieldComp;

    local casualPseudoRandom = modPseudoRandom.new();

    local weaponStatsFrame = script:WaitForChild("WeaponStats"):Clone();
    weaponStatsFrame.Parent = interface.ScreenGui;


    local titleLabel = weaponStatsFrame:WaitForChild("Title");
    local statsList = weaponStatsFrame:WaitForChild("StatsList");
    local statsLabelTemplate = script:WaitForChild("StatsLabel");
    local masteryFrame = weaponStatsFrame:WaitForChild("masteryFrame");
    local masteryBar = masteryFrame:WaitForChild("masteryBar");
    local masteryLabel = masteryFrame:WaitForChild("masteryLabel");
    local expandHint = weaponStatsFrame:WaitForChild("expandHint");
    local templateDescLabel = script:WaitForChild("TagDesc");

    local statsTabs = weaponStatsFrame:WaitForChild("StatsTabs");
    local statLayerButton = statsTabs:WaitForChild("Layer1Button");
    local modifierLayerButton = statsTabs:WaitForChild("Layer2Button");

    local graphView = weaponStatsFrame:WaitForChild("GraphView");
    local barFrameTemplate = script:WaitForChild("barFrame");
    local numLabelTemplate = script:WaitForChild("numLabel");

    local isExpanded = false;
    local activeDescLabel;
    local currentClass;

    local function refreshLabels()
        for _, obj in pairs(statsList:GetChildren()) do
            if obj:IsA("TextLabel") then
                local found = false;
                for toolType, _ in pairs(statTemplates) do
                    for a=1, #statTemplates[toolType] do
                        local statInfo = statTemplates[toolType][a];
                        if statInfo.Key == obj.Name then
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
            if graphStatTemplates[currentClass] then
                graphView.Visible = false;
                statsList.Visible = true;
                statsTabs.Visible = true;
            end
            refreshLabels();
            if modConfigurations.CompactInterface then
                weaponStatsFrame:TweenSize(UDim2.new(0.5, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true);
            else
                weaponStatsFrame:TweenSize(UDim2.new(0, xSize, 0, 300), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true);
            end
            expandHint.Text = "Click to shrink";
        else
            if graphStatTemplates[currentClass] then
                graphView.Visible = true;
                statsList.Visible = false;
                statsTabs.Visible = false;
            else
                graphView.Visible = false;
                statsList.Visible = true;
                statsTabs.Visible = true;
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

    local statPage = "Stats";

	local weaponStatsWindow: InterfaceWindow = interface:NewWindow("WeaponStats", weaponStatsFrame);
    weaponStatsWindow.BoolStringWhenActive = {String="!Hotbar"; Priority=2;};
	weaponStatsWindow.CompactFullscreen = true;
    weaponStatsWindow.ReleaseMouse = true;
	
	if modConfigurations.CompactInterface then
		weaponStatsFrame.AnchorPoint = Vector2.new(0, 1);
		weaponStatsFrame.Size = UDim2.new(0.5, 0, 0.5, 0);
		weaponStatsFrame.Position = UDim2.new(0, 0, 1, 0);
		weaponStatsWindow:SetClosePosition(UDim2.new(0, 0, 1.5, 0), UDim2.new(0, 0, 1, 0));
		weaponStatsFrame:WaitForChild("UICorner").CornerRadius = UDim.new(0, 0);
	else
		weaponStatsWindow:SetClosePosition(UDim2.new(0.5, 0, 1.5, -145));
	end
	
	weaponStatsWindow.ReleaseMouse = false;
    --MARK: OnToggle
	weaponStatsWindow.OnToggle:Connect(function(visible, storageItem)
		if visible then
            statPage = "Stats";

			refreshFrameSize();
            weaponStatsWindow:Update(storageItem);
		end

        if modConfigurations.CompactInterface then
            local workbenchWindow: InterfaceWindow = interface:GetWindow("Workbench");
            local inspectWindow: InterfaceWindow = interface:GetWindow("ItemInspect");
            if workbenchWindow and workbenchWindow.Visible and inspectWindow then
                if visible then
                    inspectWindow.Binds.SetStyle("QuadTopLeft");
                else
                    inspectWindow.Binds.SetStyle("LeftHalf");
                end
            end
        end
	end)


    local function formatValue(valueType, rawValue)
        local statString = rawValue or "n/a";

        if typeof(rawValue) == "string" then
        elseif type(rawValue) == "table" then
            if rawValue.Min and rawValue.Max then
                statString = ("["..
                    (valueType == "int" and math.ceil(rawValue.Min) or rawValue.Min)
                    ..", "..
                    (valueType == "int" and math.ceil(rawValue.Max) or rawValue.Max).."]");
            else
                statString = ("["..table.concat(rawValue,", ").."]");
            end
        else
            statString = (
                valueType == "int" and modFormatNumber.Beautify(math.ceil(rawValue))
                    or valueType == "string" and rawValue
                    or valueType == "4dp" and modFormatNumber.Beautify(math.ceil(rawValue*10000)/10000, true)
                    or valueType == "3dp" and modFormatNumber.Beautify(math.ceil(rawValue*1000)/1000, true)
                    or valueType == "2dp" and modFormatNumber.Beautify(math.ceil(rawValue*100)/100, true)
                    or valueType == "Rpm" and modFormatNumber.Beautify(math.ceil(60/rawValue*100)/100)
                    or valueType == "percent" and math.floor(rawValue*100)
                    or valueType == "percent2dp" and math.floor(rawValue*1000)/10
                    or valueType == "trigger" and triggerModes[rawValue]
                    or valueType == "bullet" and bulletTypes[rawValue]
                    or valueType == "bool" and tostring(rawValue)
                    or valueType == "rawnum" and modFormatNumber.Beautify(rawValue, true)
                    or rawValue)
        end

        return statString;
    end

    if initCharStats == nil then
        initCharStats = true;

        for class, dict in pairs(statTemplates) do
            if class == "Character" then continue end;
            for k, v in pairs(dict) do
                statTemplates.Character[k] = v;
            end
        end
    end

    local isFirstRun = nil;
    --MARK: Render Stats
    local function renderStats(configOwner: EquipmentClass | CharacterClass, storageItem: StorageItem?)
        local equipmentClass: EquipmentClass;
        local classType = nil;

        local configurations: ConfigVariable = configOwner.Configurations;
        if configOwner.ClassName ~= "PlayerClass" then
            equipmentClass = configOwner :: EquipmentClass;
            classType = equipmentClass.Class;

        else
            classType = "Character";

        end
        currentClass = classType;

        local statsTemplate = statTemplates[classType];
        local newShortHandLabel = graphStatTemplates[classType];

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
            local statString = formatValue(info.Type, statValue);

            infoText = string.gsub(infoText, "$stat", statString);
            if info.PostText then
                infoText = info.PostText(configurations, info, infoText, statValue);
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
                        activeDescLabel = templateDescLabel:Clone();
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

            local key = info.Key;
            local statValue = configurations[key];

            if statValue ~= nil then
                if typeof(statValue) ~= "table" or (statValue.Potential == nil and statValue.Tad == nil) then
                    local infoKey = info.Key;

                    createLabel(infoKey, info, statValue);
                end
            end	
        end
        
        -- TODO; Special stats
        -- if itemClass.Configurations and itemClass.Configurations.SpecialStats then
        --     for infoKey, statValue in pairs(itemClass.Configurations.SpecialStats) do
        --         local info = specialStatsTemplates[infoKey];
        --         layoutOrder = layoutOrder +1;
        --         createLabel(infoKey, info, statValue);
        --     end
        -- end

        -- TODO; Registered properties
        -- if itemClass.RegisteredProperties then
        --     Debugger:StudioWarn("itemClass.RegisteredProperties", itemClass.RegisteredProperties);
        --     for k, v in pairs(itemClass.RegisteredProperties) do
        --         createLabel(k, {
        --             Text="<b>+ Passive:</b>    $stat"; 
        --             Type="string";
        --         }, k);
        --         layoutOrder = layoutOrder +1;
        --     end
        -- end
        
        local itemId = storageItem and storageItem.ItemId or "~";
        if classType == "Gun" then
            if isFirstRun == nil then
                isFirstRun = true;
                task.wait(0.1);
            end
            graphView.shortStatLabel.Text = newShortHandLabel;
            
            local sizeRef = graphView.graphs.sizeRef.AbsoluteSize;
            graphView.graphs.nums:ClearAllChildren();
            graphView.graphs.bars:ClearAllChildren();
            
            
            local preModDamage = configurations.PreModDamage;
            local moddedDamage = configurations.Damage;
            local ammoMag = configurations.MagazineSize;
            
            local columnSize = sizeRef.X/ammoMag;
            local columnPoint = columnSize/2;
            
            local dmgRev = configurations.DamageRev;
            local critMulti = configurations.CritMulti;

            local ammoCost = configurations.AmmoCost or 1;
            local multishot = configurations.Multishot;

            local hsMulti = configurations.HeadshotMultiplier;
            local chargeMulti = configurations.ChargeDamagePercent;
            
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
                    local critChance = configurations.CritChance;
                    if a == ammoMag or casualPseudoRandom:FairCrit(itemId, critChance) then -- math.fmod(a, math.floor(1/critChance)) == 0
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
                    
                    if configurations.Triplethreat then
                        mutishotMulti = ammoCost;
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
                        activeDescLabel = templateDescLabel:Clone();
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
        
        local workbenchUpgradesLib = modWorkbenchLibrary.ItemUpgrades[itemId];
        if workbenchUpgradesLib then
            -- local conditionRange = workbenchUpgradesLib.SkinWear and workbenchUpgradesLib.SkinWear.Wear or {Min=0.000001; Max=0.999999;};
            
            -- layoutOrder = 9999;
            -- local newLabel = createLabel("ToolCondition", {
            -- 	Text="<b>Condition Range:</b>    $stat"; Type="rawnum";
            -- }, conditionRange);
        end
    end

    --MARK: Render Modifiers
    local function renderModifiers(configOwner: EquipmentClass | CharacterClass, storageItem: StorageItem?)
        local equipmentClass: EquipmentClass;
        local classType = nil;

        local configurations: ConfigVariable = configOwner.Configurations;

        if configOwner.ClassName ~= "PlayerClass" then
            equipmentClass = configOwner :: EquipmentClass;
            classType = equipmentClass.Class;

        else
            classType = "Character";

        end
        currentClass = classType;

        local modificationDict = {};
        
        -- BaseValues={};
        -- SetValues={};
        -- SumValues={};
        -- ProductValues={};
        -- MaxValues={};
        -- MinValues={};

        for a=1, #configurations.Modifiers do
            local modifier: ItemModifierInstance = configurations.Modifiers[a] :: ItemModifierInstance;

            local modifierName = modifier.Name or modifier.Id;
            if wieldComp and wieldComp.Siid == modifier.Id then
                modifierName = `{modifierName} (Equipped)`;
            end
            if modifier.ModLibrary and modifier.ModLibrary.Name then
                modifierName = modifier.ModLibrary.Name;
            end
            if modifier.Tags.Base then
                modifierName = `{modifierName} (Base)`;
            end

            local function newM(k)
                if modificationDict[k] == nil then
                    modificationDict[k] = {};
                end
            end
            for k, v in pairs(modifier.SetValues) do
                newM(k);
                table.insert(modificationDict[k], {Name=modifierName; Value=v; ConfigType="set";});
            end
            for k, v in pairs(modifier.SumValues) do
                newM(k);
                table.insert(modificationDict[k], {Name=modifierName; Value=v; ConfigType="sum";});
            end
            for k, v in pairs(modifier.ProductValues) do
                newM(k);
                table.insert(modificationDict[k], {Name=modifierName; Value=v; ConfigType="product";});
            end
            for k, v in pairs(modifier.MaxValues) do
                newM(k);
                table.insert(modificationDict[k], {Name=modifierName; Value=v; ConfigType="max";});
            end
            for k, v in pairs(modifier.MinValues) do
                newM(k);
                table.insert(modificationDict[k], {Name=modifierName; Value=v; ConfigType="min";});
            end
            for k, v in pairs(modifier.ArrayValues) do
                newM(k);
                table.insert(modificationDict[k], {Name=modifierName; Value=v; ConfigType="array";});
            end
        end

        if #configurations.Modifiers <= 0 then
            local newLabel: TextLabel = statsLabelTemplate:Clone();
            newLabel.LayoutOrder = 0;
            newLabel.Name = "NoModifiers";
            newLabel.Text = "No modifiers";
            newLabel.AutomaticSize = Enum.AutomaticSize.Y;
            newLabel.LineHeight = 1.4;
            newLabel.Parent = statsList;

            local padding = Instance.new("UIPadding");
            padding.PaddingBottom = UDim.new(0, 10);
            padding.Parent = newLabel;
        end
        
        local statsTemplate = statTemplates[classType];
        local dupStatsDebounce = {};
        for a=1, #statsTemplate do
            local info = statsTemplate[a];
            local key = info.Key;

            if dupStatsDebounce[key] then continue end;
            dupStatsDebounce[key] = true;

            local modifyList = modificationDict[key];
            if modifyList == nil then continue end;

            local bValues = configurations.BaseValues[key] or "~";
            local str = `<b>{(info.Text:gmatch("<b>(.-)</b>")() or key)}</b>  {formatValue(info.Type, bValues)}`;
            for a=1, #modifyList do
                local modifyData = modifyList[a];

                local modifyValue = formatValue(info.Type, modifyData.Value);
                if modifyData.ConfigType == "sum" then
                    modifyValue = `+{modifyValue}`;
                elseif modifyData.ConfigType == "product" then
                    modifyValue = `*{modifyValue}`;
                elseif modifyData.ConfigType == "max" then
                    modifyValue = `max({modifyValue})`;
                elseif modifyData.ConfigType == "min" then
                    modifyValue = `min({modifyValue})`;
                elseif modifyData.ConfigType == "array" then
                    modifyValue = `{modifyValue}`;
                end
                str = str..`\n∟ <b>[{modifyData.Name}]</b>  {modifyValue}`;
            end
            str = str..`\n<font size="18">=  <b>{formatValue(info.Type, configurations[key])}</b></font>`;

            local newLabel: TextLabel = statsLabelTemplate:Clone();
            newLabel.LayoutOrder = a;
            newLabel.Name = key;
            newLabel.Text = str;
            newLabel.AutomaticSize = Enum.AutomaticSize.Y;
            newLabel.LineHeight = 1.4;
            newLabel.Parent = statsList;

            local padding = Instance.new("UIPadding");
            padding.PaddingBottom = UDim.new(0, 10);
            padding.Parent = newLabel;
        end

    end

    -- MARK: OnUpdate
    weaponStatsWindow.OnUpdate:Connect(function(storageItem: StorageItem)
        for _, obj in pairs(statsList:GetChildren()) do
            if obj:IsA("GuiObject") then
                obj:Destroy();
            end
        end
        barFrameTemplate.BackgroundColor3 = modBranchConfigurations.BranchColor;

        playerClass = shared.modPlayers.get(localPlayer);
        wieldComp = playerClass.WieldComp;

        local configOwner;
        local siid;
        local classType = "Character";
        if not (storageItem == nil or typeof(storageItem) ~= "table") then
            siid = storageItem.ID;

            local equipmentClass: EquipmentClassRotd = wieldComp:GetEquipmentClass(siid);
            if equipmentClass == nil then
                classType = equipmentClass.Class;
                Debugger:Warn(`EquipmentClass not found for siid:{siid}`);
                return;
            end

            weaponStatsWindow.Binds.LastStorageItem = storageItem;

            titleLabel.Text = `Item Stats`;
            configOwner = equipmentClass;

        else
            playerClass.Configurations:Calculate();
            configOwner = playerClass;
            titleLabel.Text = `Character Stats`;

        end

        currentClass = classType;

        local statsTemplate = statTemplates[classType];
        if statsTemplate == nil then
            weaponStatsWindow:Close();
            
            if statsTemplate == nil then
                Debugger:Warn("Missing stats template.");
            else
                Debugger:Warn("Missing itemClass.");
            end
            return;
        end
        
        for a=1, #statsTemplate do
            local info = statsTemplate[a];
            if info.Index then continue end;
            info.Index = a;
        end

        if classType == "Gun" then
            modData.OnAmmoUpdate:Fire(storageItem.ID);
        end
        
        refreshFrameSize();

        if weaponStatsWindow.Binds.StatPage ~= statPage then
            for _, obj in pairs(statsList:GetChildren()) do
                if not obj:IsA("GuiObject") then continue end;
                obj:Destroy();
            end
        end
        if statPage == "Stats" then
            renderStats(configOwner, storageItem);
        elseif statPage == "Modifiers" then
            renderModifiers(configOwner, storageItem);
        end;
        
        statLayerButton.BackgroundColor3 = statPage == "Stats" and modBranchConfigurations.BranchColor or Color3.fromRGB(100,100,100);
        modifierLayerButton.BackgroundColor3 = statPage == "Modifiers" and modBranchConfigurations.BranchColor or Color3.fromRGB(100,100,100);
    end)

    weaponStatsFrame.MouseButton1Click:Connect(function()
        isExpanded = not isExpanded;
        refreshFrameSize();
    end)

    modifierLayerButton.MouseButton1Click:Connect(function()
        statPage = "Modifiers";
        interface:PlayButtonClick();
        weaponStatsWindow:Update(weaponStatsWindow.Binds.LastStorageItem);
    end)
    statLayerButton.MouseButton1Click:Connect(function()
        statPage = "Stats";
        interface:PlayButtonClick();
        weaponStatsWindow:Update(weaponStatsWindow.Binds.LastStorageItem);
    end)
    
    
end

return interfacePackage;

