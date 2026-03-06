local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modWorldClipsHandler = shared.require(game.ReplicatedStorage.Library.WorldClipsHandler);

local npcPackage = {
    Name = "Winter Treelum";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 50;
        AttackRange = 20;
        AttackSpeed = 4;

        MaxHealth = 100;
    };
    
    Properties = {
        IsHostile = true;

        TargetableDistance = 128;
		KnockbackResistant = 1;

        Level = 1;
        ExperiencePool = 20;
        MoneyReward = NumberRange.new(1500, 1700);
    };

    AddComponents = {
        "TargetHandler";
        "ZombieBasicMeleeAttack";
        "CrateReward";
    };
    AddBehaviorTrees = {
        "ZombieBossDefaultTree";
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    local level = math.max(properties.Level, 0);

    configurations.BaseValues.MaxHealth = 5000000;
    configurations.BaseValues.AttackDamage = 50;
    configurations.BaseValues.WalkSpeed = 16;

    properties.LastSpikeRootsTick = tick();
end

function npcPackage.Spawned(npcClass: NpcClass)
    npcClass.Character:SetAttribute("EntityHudHealth", true);
    
    modWorldClipsHandler:LoadClipId("BarbClips");
    modAudio.Play("TreelumGrowl", npcClass.RootPart);
    
    local xmasParticles = npcClass.Character:WaitForChild("LeavesCone"):WaitForChild("XmasParticles");
    xmasParticles.Enabled = true;
    xmasParticles:Emit(64);

    npcClass.HealthComp.OnIsDeadChanged:Connect(function(isDead) 
		shared.Notify(game.Players:GetPlayers(), "A Winter Treelum has been defeated!", "Important");

        local crateRewardComp = npcClass:GetComponent("CrateReward");
        if crateRewardComp then
			local deathPos = npcClass.RootPart.Position;

            local spawnCFrame = deathPos
            local _dropRayHit, dropRayPos = workspace:FindPartOnRayWithWhitelist(
                Ray.new(deathPos, Vector3.new(0, -32, 0)), 
                {workspace.Environment; workspace.Terrain}, 
                true
            );
            spawnCFrame = CFrame.new(dropRayPos) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);
                
            local cratePrefab = crateRewardComp(spawnCFrame, game.Players:GetPlayers());
            Debugger.Expire(cratePrefab, 15);
        end
    end)
end

return npcPackage;