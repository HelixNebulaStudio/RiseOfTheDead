local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local library = modLibraryManager.new();
library.ClassColors = {
	Survivor=Color3.fromRGB(84, 141, 166);
	Medic=Color3.fromRGB(73, 120, 69);
	RAT=Color3.fromRGB(120, 71, 111);
	Bandit=Color3.fromRGB(99, 67, 53);
	Military=Color3.fromRGB(157, 79, 59);
	Enemy=Color3.fromRGB(200, 75, 75);
	Hidden=Color3.fromRGB(25, 25, 25);
	BioX=Color3.fromRGB(140, 208, 187);
	Rouge=Color3.fromRGB(140, 82, 82);
	
	FortuneTeller=Color3.fromRGB(119, 115, 166);
	Recycler=Color3.fromRGB(113, 139, 71);
	Trader=Color3.fromRGB(255, 205, 79);
	
	TomGreyman=Color3.fromRGB(208, 208, 208);
}

library:Add{Id="Mason"; Class="Survivor"; World="TheWarehouse"; Avatar="rbxassetid://15641265681";};
library:Add{Id="Stephanie"; Class="Survivor"; World="TheWarehouse"; Avatar="rbxassetid://15641528330";};
library:Add{Id="Nick"; Class="Survivor"; World="TheWarehouse"; Avatar="rbxassetid://15641641112";};
library:Add{Id="Russell"; Class="Survivor"; World="TheWarehouse";};
library:Add{Id="Jesse"; Class="RAT"; World="TheWarehouse"; Avatar="rbxassetid://15641530418";};
library:Add{Id="Dr. Deniski"; Class="Medic"; HeadIcon="Heal"; World="TheWarehouse"; Avatar="rbxassetid://15641529113";};

library:Add{Id="Jefferson"; Class="Hidden"; World="TheWarehouse";};
library:Add{Id="Victor"; Class="Rouge"; World="TheWarehouse"; Avatar="rbxassetid://15641532247";};

library:Add{Id="Robert"; Class="Survivor"; World="TheWarehouse"; Avatar="rbxassetid://15641321827";};
library:Add{Id="Jane"; Class="Survivor"; World="TheWarehouse"; Avatar="rbxassetid://15641421758";};
library:Add{Id="Michael"; Class="Survivor"; World="TheWarehouse";};
library:Add{Id="Wilson"; Class="Survivor"; World="TheWarehouse"; Avatar="rbxassetid://15641529876";};
library:Add{Id="Frank"; Class="RAT"; World="TheWarehouse";};
library:Add{Id="Carlos"; Class="Medic"; HeadIcon="Heal"; World="TheWarehouse"; Avatar="rbxassetid://15641640711";};

library:Add{Id="Lennon"; Class="Medic"; HeadIcon="Heal"; World="TheUnderground"; Avatar="rbxassetid://15641639930";};

library:Add{Id="Carlson"; Class="Medic"; HeadIcon="Heal"; World="TheUnderground"; Avatar="rbxassetid://15641534044";};
library:Add{Id="Erik"; Class="Survivor"; World="TheUnderground"; Avatar="rbxassetid://15641530840";};
library:Add{Id="Diana"; Class="RAT"; World="TheUnderground";};

library:Add{Id="Hilbert"; Class="BioX"; World="TheUnderground"; Avatar="rbxassetid://15641642353";};

library:Add{Id="Stan"; Class="Survivor"; World="TheUnderground"; Avatar="rbxassetid://15641420202";};
library:Add{Id="Vladimir"; Class="RAT"; World="TheUnderground";};

library:Add{Id="Maverick"; Class="RAT"; World="TheMall";};
library:Add{Id="Danny"; Class="Medic"; HeadIcon="Heal"; World="TheMall"; Avatar="rbxassetid://15641531785";};

library:Add{Id="Patrick"; Class="Bandit"; World="TheMall"; Avatar="rbxassetid://15641420747";};
library:Add{Id="Alice"; Class="RAT"; World="TheMall";};
library:Add{Id="Molly"; Class="Medic"; HeadIcon="Heal"; World="TheMall";};
library:Add{Id="Mike"; Class="Survivor"; World="TheMall"; Avatar="rbxassetid://15641532613";};

library:Add{Id="Larry"; Class="RAT"; World="TheResidentials";};
library:Add{Id="Joseph"; Class="Medic"; HeadIcon="Heal"; World="TheResidentials"; Avatar="rbxassetid://15641421273";};
library:Add{Id="Nate"; Class="Survivor"; World="TheResidentials";};
library:Add{Id="Dallas"; Class="Survivor"; World="TheResidentials";};
library:Add{Id="Zep"; Class="Survivor"; World="TheResidentials";};
library:Add{Id="Kelly"; Class="Survivor"; World="TheResidentials";};

library:Add{Id="David"; Class="RAT"; World="TheHarbor"; Avatar="rbxassetid://15944948446";};
library:Add{Id="Cooper"; Class="RAT"; World="TheHarbor";};
library:Add{Id="Lewis"; Class="RAT"; World="TheHarbor"; Avatar="rbxassetid://15944933279";};
library:Add{Id="Greg"; Class="RAT"; World="TheHarbor";};
library:Add{Id="Caitlin"; Class="Medic"; HeadIcon="Heal"; World="TheHarbor";};

library:Add{Id="Zark"; Class="Bandit"; World="BanditCamp";};
library:Add{Id="Loran"; Class="Bandit"; World="BanditCamp";};
library:Add{Id="Jason"; Class="Bandit"; World="BanditCamp";};

library:Add{Id="Walter"; Class="Military"; World="TheWarehouse";};
library:Add{Id="Mysterious Engineer"; Class="Rouge"; World="SunkenShip"; Avatar="rbxassetid://16537592997";};



library:Add{Id="Bandit"; Class="Bandit";};


--== Safehome
library:Add{Id="Kat"; Class="Medic"; World="Safehome";};
library:Add{Id="Nicole"; Class="Medic"; World="Safehome";};
library:Add{Id="Sullivan"; Class="Medic"; World="Safehome";};
library:Add{Id="Jackson"; Class="Medic"; World="Safehome";};
library:Add{Id="Rachel"; Class="Medic"; World="TheUnderground"; Avatar="rbxassetid://15944916590";};

library:Add{Id="Zoey"; Class="RAT"; World="Safehome";};
library:Add{Id="Jackie"; Class="RAT"; World="Safehome";};
library:Add{Id="Berry"; Class="RAT"; World="Safehome";};

library:Add{Id="Scarlett"; Class="Recycler"; World="Safehome";};
library:Add{Id="Rafael"; Class="Recycler"; World="Safehome";};

library:Add{Id="Lydia"; Class="FortuneTeller"; World="Safehome";};

--== Wanderer
library:Add{Id="Icarus"; Class="Trader"; Avatar="rbxassetid://13192700114"};

--== Cutscene
library:Add{Id="Revas"; Class="RAT"; World="TheHarbor";};
library:Add{Id="Eugene"; Class="BioX"; World="SectorE"};



function library:GetProperties(name)
	local lib = self:Find(name);
	local module = script:FindFirstChild(name);
	if lib and module then
		lib.Properties=require(module);
		return lib.Properties;
	end
end

return library;
