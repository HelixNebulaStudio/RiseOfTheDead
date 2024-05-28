local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local library = modLibraryManager.new();

--==
library:Add{
    Id="rain";

    CameraEffect={
        EnableScreenRain="Rain";
        Atmosphere={
            UseAmbientColor=true;
            
            Density=0.4;
            Offset=0.4;
            Haze=2.5;
        };
    }
};

library:Add{
    Id="snow";

    CameraEffect={
        EnableScreenRain="Snow";
        Atmosphere={
            UseAmbientColor=true;
            
            Density=0.3;
            Offset=0.2;
            Haze=0.5;
        };
    }
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
    }
};

library:Add{
    Id="heavyfog";

    CameraEffect={
        Atmosphere={
            UseAmbientColor=true;
            
            Density=0.8;
            Offset=0.2;
            Haze=2.5;
        };
    }
};

return library;