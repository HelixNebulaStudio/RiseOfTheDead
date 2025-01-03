local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");
local TweenService = game:GetService("TweenService");

--==
local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local library = modLibraryManager.new();

--==
function RainPuddleTick(WeatherService)
    if math.random(1, 2) ~= 1 then return end
    
    local rngOrigins = {};
    local entities = workspace.Entity:GetChildren();
    local players = game.Players:GetPlayers();

    for a=1, #players do
        if #entities <= 0 then break end;

        local rngEntity = table.remove(entities, math.random(1, #entities));
        table.insert(rngOrigins, rngEntity);
    end

    for _, player in pairs(players) do
        if player.Character == nil then continue end;
        table.insert(rngOrigins, player.Character);
    end
    if #rngOrigins <= 0 then return end;

    local rngEntity = rngOrigins[math.random(1, #rngOrigins)];
    if rngEntity == nil or not workspace:IsAncestorOf(rngEntity) then return end;
    local entityPart = rngEntity:FindFirstChildWhichIsA("BasePart");
    if entityPart == nil then return end;

    local rayParam = RaycastParams.new();
    rayParam.FilterType = Enum.RaycastFilterType.Include;
    rayParam.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain};

    local origin = entityPart.Position;

    local range = 32*10;
    local rayResult = workspace:Raycast(origin + Vector3.new(math.random(-range, range)/10, 400, math.random(-range, range)/10), Vector3.yAxis * -800, rayParam);
    if rayResult == nil then return end;
    if rayResult.Normal:Dot(Vector3.yAxis) <= 0.97 then return end;

    local landPart = rayResult.Instance;
    local landPartSize = landPart.Size/2;
    local landPartCf = landPart.CFrame;
    
    local topMin = landPartCf * -landPartSize;
    local topMax = landPartCf * landPartSize;

    local maxSize = math.min(math.max(topMin.X, topMax.X)-math.min(topMin.X, topMax.X), math.max(topMin.Z, topMax.Z)-math.min(topMin.Z, topMax.Z));
    if maxSize <= 16 then return end;

    local landPoint = rayResult.Position;
    if maxSize < 64 then
        landPoint = Vector3.new(landPartCf.X, landPoint.Y, landPartCf.Z);
    end

    local existingWaterPuddles = CollectionService:GetTagged("WaterPuddle");
    local isOverlap = false;
    local modVector = require(game.ReplicatedStorage.Library.Util.Vector);

    for a=1, #existingWaterPuddles do
        local puddle: BasePart = existingWaterPuddles[a];

        local puddleHalfSize = puddle.Size/2;

        local minVec3 = puddle.CFrame * -puddleHalfSize;
        local maxVec3 = puddle.CFrame * puddleHalfSize;

        local minVec2 = Vector2.new(math.min(minVec3.X, maxVec3.X), math.min(minVec3.Z, maxVec3.Z));
        local maxVec2 = Vector2.new(math.max(minVec3.X, maxVec3.X), math.max(minVec3.Z, maxVec3.Z));

        if modVector.WithinRegion2(Vector2.new(landPoint.X, landPoint.Z), minVec2, maxVec2, 2) then
            isOverlap = true;
            break;
        end
    end
    if isOverlap then return end;

    local waterPuddles = script:WaitForChild("WaterPuddle"):GetChildren();
    local new: MeshPart = waterPuddles[math.random(1, #waterPuddles)]:Clone();
    new.Transparency = 1;
    new:AddTag("WaterPuddle");

    local newSize = math.random(16 *100, math.min(maxSize, 64) *100)/100;
    new.Size = Vector3.new(newSize, 0, newSize);
    new.CFrame = CFrame.new(landPoint+(Vector3.yAxis*0.1)) *CFrame.Angles(0, math.rad(math.random(0, 3600)/10), 0);
    new.Parent = workspace.Debris;
    
    TweenService:Create(new, TweenInfo.new(math.random(40, 120)/10), {
        Transparency = 0.15;
    }):Play();
end
--==
library:Add{
    Id="rain";

    CameraEffect={
        Atmosphere={
            UseAmbientColor=true;
            
            Density=0.4;
            Offset=0.4;
            Haze=2.5;
        };
        
        EnableScreenRain=true;
        ScreenRainRate=5;

        ScreenParticles={
            {Id="WeatherRain"};
        };
    };

    WeatherSounds={
        {Id="Weather:Rain";};
    };

    FadeTime=5;

    OnSeverTick=RainPuddleTick;
};

library:Add{
    Id="snow";

    CameraEffect={
        Atmosphere={
            UseAmbientColor=true;
            
            Density=0.3;
            Offset=0.2;
            Haze=0.5;
        };

        ScreenParticles={
            {Id="WeatherSnow"};
        };
    };

    FadeTime=20;
};

library:Add{
    Id="fog";

    CameraEffect={
        Atmosphere={
            UseAmbientColor=true;
            
            Density=0.6;
            Offset=0.4;
            Haze=2.5;
        };
    };

    FadeTime=20;
};

library:Add{
    Id="heavyfog";

    CameraEffect={
        Atmosphere={
            UseAmbientColor=true;
            
            Density=0.8;
            DensityIndoors=0.6;
            Offset=0.2;
            Haze=2.5;
        };
        
        SunRaysIntensity = 0;
    };

    FadeTime=10;
};

library:Add{
    Id="heavyrain";

    CameraEffect={
        Atmosphere={
            UseAmbientColor=true;
            
            Density=0.7;
            DensityIndoors=0.5;
            Offset=0.5;
            Haze=3;
        };
        
        SunRaysIntensity = 0;

        EnableScreenRain=true;
        ScreenRainRate=10;

        ScreenParticles={
            {Id="WeatherRain"};
            {Id="WeatherHeavyRain"};
        };
    };

    FadeTime=3;

    WeatherSounds={
        {Id="Weather:Rain";};
        {Id="Weather:Thunder";};
    };

    OnSeverTick=RainPuddleTick;
};

return library;