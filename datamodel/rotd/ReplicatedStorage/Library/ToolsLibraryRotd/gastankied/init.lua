local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modExplosionHandler = shared.require(game.ReplicatedStorage.Library.ExplosionHandler);
--==

local toolPackage = {
    ItemId = script.Name;
    Class = "Tool";
    HandlerType = "StructureTool";

    Animations = {
		Core={Id=4379418967;};
		Placing={Id=4379471624};
    };
    Audio = {};

    Configurations = {
        WaistRotation = math.rad(0);
        PlaceOffset = CFrame.Angles(0, math.rad(-90), 0);
        
        BuildDuration = 1;
        
        Duration = 10;
        Distance = 64;
        BlastForce = 100;
    };

    Properties = {};
};

function toolPackage.BuildStructure(prefab: Model, optionalPacket)
	optionalPacket = optionalPacket or {};

    local characterClass: CharacterClass;
    if optionalPacket.CharacterClass and optionalPacket.CharacterClass.ClassName == "PlayerClass" then
        characterClass = optionalPacket.CharacterClass;
    end;

    local base = prefab.PrimaryPart;
    
    local ledScreenSurfacecGui = prefab:WaitForChild("Screen"):WaitForChild("SurfaceGui");
    local timerLabel = ledScreenSurfacecGui:WaitForChild("timer");
    
    local duration = toolPackage.Configurations.Duration;
    local explodeTime = workspace:GetServerTimeNow() + duration;

    task.spawn(function() 
        ledScreenSurfacecGui.Enabled = true;
        for t=duration, 0, -1 do
            task.wait(1);
            if not workspace:IsAncestorOf(prefab) then return end;

            timerLabel.Text = math.clamp(
                math.floor(explodeTime-workspace:GetServerTimeNow()), 
                0, 
                duration
            );

            modAudio.Play("ClockTick", base);
            
            if workspace:GetServerTimeNow() <= explodeTime then continue end;
            local lastPosition = base.Position;
            
            modAudio.Play("ClockTick", base);
            modAudio.Play(math.random(1, 2) == 1 and "Explosion" or "Explosion2", base);
            
            base:ClearAllChildren();
            prefab.Parent = workspace.Debris;
            Debugger.Expire(prefab, 6);

            for _, part in pairs(prefab:GetChildren()) do
                if not part:IsA("BasePart") or part == base then continue end;
                part.CanCollide = true;

                local rngVec = Vector3.new(
                    math.random(-100, 100)/100, 
                    math.random(0, 50)/100, 
                    math.random(-100, 100)/100
                ).Unit;
                local dir = (part.Position-(lastPosition + rngVec)).Unit
                part:ApplyImpulse(dir * part.AssemblyMass * 150);
            end
            
            local hitLayers = modExplosionHandler:Cast(lastPosition, {
                Radius = toolPackage.Configurations.Distance;
            });
            
            modExplosionHandler:Process(lastPosition, hitLayers, {
                ExplosionBy = characterClass;

                DamageRatio = 0.24;
                MinDamage = 120;
                MaxDamage = 100000;
                ExplosionStun = 10;

                DamageOrigin = lastPosition;
                OnPartHit = modExplosionHandler.GenericOnPartHit;
            });
        end
    end)

end;

function toolPackage.newClass()
    return modEquipmentClass.new(toolPackage);
end

return toolPackage;