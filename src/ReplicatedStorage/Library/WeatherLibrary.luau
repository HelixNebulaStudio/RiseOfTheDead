local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local library = modLibraryManager.new();

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
};

return library;