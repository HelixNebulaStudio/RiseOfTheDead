local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
--==

local toolPackage = {
    ItemId=script.Name;
    Class="Tool";
    HandlerType="StructureTool";

    Animations={
		Core={Id=4379418967;};
		Placing={Id=4379471624};
    };
    Audio={};

    Configurations={
        WaistRotation = math.rad(0);
        PlaceOffset = CFrame.Angles(0, math.rad(-90), 0);
        
        BuildDuration = 1;
        
        Duration = 10;
        Distance = 64;
        BlastForce = 100;
    };

    Properties={};
};

function toolPackage.BuildStructure(prefab: Model, optionalPacket)
	optionalPacket = optionalPacket or {};

    local player = nil;
    if optionalPacket.CharacterClass and optionalPacket.CharacterClass.ClassName == "PlayerClass" then
        player = optionalPacket.CharacterClass:GetInstance();
    end;

    local base = prefab.PrimaryPart;
    
    local textLabel = prefab:WaitForChild("Screen"):WaitForChild("SurfaceGui"):WaitForChild("timer");
    
    local startTime = modSyncTime.GetTime() + toolPackage.Configurations.Duration;
    local clock;
    clock = modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
        textLabel.Text = math.clamp(math.floor(startTime-modSyncTime.GetTime()), 0, toolPackage.Configurations.Duration);
        modAudio.Play("ClockTick", base);
        
        if modSyncTime.GetTime() <= startTime then return end;
        
        local lastPosition = base.Position;
        
        modAudio.Play("ClockTick", base);
        modAudio.Play(math.random(1, 2) == 1 and "Explosion" or "Explosion2", base);
        
        local ex = Instance.new("Explosion");
        ex.DestroyJointRadiusPercent = 0;
        ex.BlastRadius = toolPackage.Configurations.Distance;
        ex.BlastPressure = 0;
        ex.Position = lastPosition;
        ex.Parent = workspace;
        
        for _, obj in pairs(prefab:GetChildren()) do if obj ~= base then obj:Destroy() end; end
        clock:Disconnect();
        Debugger.Expire(prefab, 6);
        
        local modExplosionHandler = shared.require(game.ReplicatedStorage.Library.ExplosionHandler);
        local hitLayers = modExplosionHandler:Cast(lastPosition, {
            Radius = toolPackage.Configurations.Distance;
        });
        
        modExplosionHandler:Process(lastPosition, hitLayers, {
            Owner = player;

            DamageRatio = 0.24;
            MinDamage = 120;
            MaxDamage = 100000;
            ExplosionStun = 10;
            TargetableEntities = modConfigurations.TargetableEntities;

            DamageOrigin = lastPosition;
            OnPartHit = modExplosionHandler.GenericOnPartHit;
        });
    end)
end;

function toolPackage.newClass()
    return modEquipmentClass.new(toolPackage);
end

return toolPackage;