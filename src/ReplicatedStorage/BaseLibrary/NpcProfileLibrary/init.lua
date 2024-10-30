local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
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
};

library.ClassIcons = {
	Survivor="rbxassetid://18930109253";
	RAT="rbxassetid://18930113603";
	Bandit="rbxassetid://18930113293";
	BioX="rbxassetid://18930113452";
	Military="rbxassetid://18930527891";
	Cultist="rbxassetid://18930528078";
}

-- Blank Avatar: rbxassetid://15641359355
--==
library:Add{Id="Mason"; Class="Survivor"; World="TheWarehouse"; Avatar="rbxassetid://15641265681";
	Descriptors={
		Hair="Short Grey";
		Beard="Full Brown";
		Gender="M";
		Clothing={"Brown Leather Jacket"};
	};
};
library:Add{Id="Stephanie"; Class="Survivor"; World="TheWarehouse"; Avatar="rbxassetid://15641528330";
	Descriptors={
		Hair="Long Red Brown";
		Gender="F";
		Clothing={"Black Leather Jacket"; "Black Leather Gloves"};
	};
};
library:Add{Id="Nick"; Class="Survivor"; World="TheWarehouse"; Avatar="rbxassetid://15641641112";
	Descriptors={
		Hair="Short Spikey Black";
		Gender="M";
		Clothing={"Red Flannel Shirt"; "Blue Jeans"};
	};
};
library:Add{Id="Russell"; Class="Survivor"; World="TheWarehouse"; Avatar="rbxassetid://79562631617102";
	Descriptors={
		Beard="Full Black";
		Gender="M";
		Clothing={"Green Shirt with Stains"; "Brown Belt"; "Dark Green Hat"};
	};
};
library:Add{Id="Jesse"; Class="RAT"; World="TheWarehouse"; Avatar="rbxassetid://15641530418";};
library:Add{Id="Dr. Deniski"; Class="Medic"; HeadIcon="Heal"; World="TheWarehouse"; Avatar="rbxassetid://15641529113";};

library:Add{Id="Jefferson"; Class="Hidden"; World="TheWarehouse";};
library:Add{Id="Victor"; Class="Rouge"; World="TheWarehouse"; Avatar="rbxassetid://15641532247";};

library:Add{Id="Robert"; Class="Survivor"; World="TheWarehouse"; Avatar="rbxassetid://15641321827";};
library:Add{Id="Jane"; Class="Survivor"; World="TheWarehouse"; Avatar="rbxassetid://15641421758";
	Descriptors={
		Hair="Long Black";
		Gender="F";
		Clothing={"Red Sweater"; "Demin Overalls"};
	};
};
library:Add{Id="Michael"; Class="Survivor"; World="TheWarehouse"; Avatar="rbxassetid://140050354048212";
	Descriptors={
		Hair="Short Spikey Black";
		Gender="M";
		Clothing={"White TShirt"; "Demin Jeans"};
		Scar="Red";
	};
};
library:Add{Id="Wilson"; Class="Survivor"; World="TheWarehouse"; Avatar="rbxassetid://15641529876";
	Descriptors={
		Role="Military";
		Gender="M";
		Clothing={"Desert Boots";};
	};
};
library:Add{Id="Frank"; Class="RAT"; World="TheWarehouse";};
library:Add{Id="Carlos"; Class="Medic"; HeadIcon="Heal"; World="TheWarehouse"; Avatar="rbxassetid://15641640711";};

library:Add{Id="Lennon"; Class="Medic"; HeadIcon="Heal"; World="TheUnderground"; Avatar="rbxassetid://15641639930";};

library:Add{Id="Carlson"; Class="Medic"; HeadIcon="Heal"; World="TheUnderground"; Avatar="rbxassetid://15641534044";};
library:Add{Id="Erik"; Class="Survivor"; World="TheUnderground"; Avatar="rbxassetid://15641530840";
	Descriptors={
		Hair="Short Light Brown";
		Gender="M";
		Clothing={"Black Polo Shirt"; "Beige Basketball Shoes"};
	};
};
library:Add{Id="Diana"; Class="RAT"; World="TheUnderground";};

library:Add{Id="Hilbert"; Class="BioX"; World="TheUnderground"; Avatar="rbxassetid://15641642353";};

library:Add{Id="Stan"; Class="Survivor"; World="TheUnderground"; Avatar="rbxassetid://15641420202";};
library:Add{Id="Vladimir"; Class="RAT"; World="TheUnderground";};

library:Add{Id="Maverick"; Class="RAT"; World="TheMall";};
library:Add{Id="Danny"; Class="Medic"; HeadIcon="Heal"; World="TheMall"; Avatar="rbxassetid://15641531785";};

library:Add{Id="Patrick"; Class="Bandit"; World="TheMall"; Avatar="rbxassetid://15641420747";};
library:Add{Id="Alice"; Class="RAT"; World="TheMall";};
library:Add{Id="Molly"; Class="Medic"; HeadIcon="Heal"; World="TheMall";};
library:Add{Id="Mike"; Class="Survivor"; World="TheMall"; Avatar="rbxassetid://15641532613";
	Descriptors={
		Role="Inmate";
		Gender="M";
	};
};

library:Add{Id="Larry"; Class="RAT"; World="TheResidentials";};
library:Add{Id="Joseph"; Class="Medic"; HeadIcon="Heal"; World="TheResidentials"; Avatar="rbxassetid://15641421273";};
library:Add{Id="Nate"; Class="Survivor"; World="TheResidentials"; Avatar="rbxassetid://79078550661090";
	Descriptors={
		Hair="Short Yellow";
		Role="FBI";
		Gender="M";
	};
};
library:Add{Id="Dallas"; Class="Survivor"; World="TheResidentials"; Avatar="rbxassetid://79182460537916";
	Descriptors={
		Hair="Short Black";
		Gender="M";
		Clothing={"Red Baseball Jacket"; "Brown Pants"};
	};
};
library:Add{Id="Zep"; Class="Survivor"; World="TheResidentials"; Avatar="rbxassetid://110229481480464";
	Descriptors={
		Hair="Short Blonde";
		Clothing={"Black and White Stripes"; "Neck Chain"; "Black Beanie"};
	};
};
library:Add{Id="Kelly"; Class="Survivor"; World="TheResidentials"; Avatar="rbxassetid://131391159298964";
	Descriptors={
		Hair="Curly Black";
		Gender="F";
		Clothing={"Red Hoodie with Stripes"; "Black Baseball Cap";};
	};
};

library:Add{Id="David"; Class="RAT"; World="TheHarbor"; Avatar="rbxassetid://15944948446";};
library:Add{Id="Cooper"; Class="RAT"; World="TheHarbor";};
library:Add{Id="Lewis"; Class="RAT"; World="TheHarbor"; Avatar="rbxassetid://15944933279";};
library:Add{Id="Greg"; Class="RAT"; World="TheHarbor";};
library:Add{Id="Caitlin"; Class="Medic"; HeadIcon="Heal"; World="TheHarbor";};

library:Add{Id="Zark"; Class="Bandit"; World="BanditCamp"; Avatar="rbxassetid://18932927518"; };
library:Add{Id="Loran"; Class="Bandit"; World="BanditCamp";};
library:Add{Id="Jason"; Class="Bandit"; World="BanditCamp";};

library:Add{Id="Walter"; Class="Military"; World="TheWarehouse";};
library:Add{Id="Mysterious Engineer"; Class="Rouge"; World="SunkenShip"; Avatar="rbxassetid://16537592997";};


library:Add{Id="Bandit"; Class="Bandit";};


--== Safehome
library:Add{Id="Kat"; Class="Medic"; World="Safehome"; SafehomeNpc=true;};
library:Add{Id="Nicole"; Class="Medic"; World="Safehome"; SafehomeNpc=true;};
library:Add{Id="Sullivan"; Class="Medic"; World="Safehome"; SafehomeNpc=true;};
library:Add{Id="Jackson"; Class="Medic"; World="Safehome"; SafehomeNpc=true;};
library:Add{Id="Rachel"; Class="Medic"; World="TheUnderground"; Avatar="rbxassetid://15944916590"; SafehomeNpc=true;};

library:Add{Id="Zoey"; Class="RAT"; World="Safehome"; SafehomeNpc=true;};
library:Add{Id="Jackie"; Class="RAT"; World="Safehome"; SafehomeNpc=true;};
library:Add{Id="Berry"; Class="RAT"; World="Safehome"; SafehomeNpc=true;};

library:Add{Id="Scarlett"; Class="Recycler"; World="Safehome"; SafehomeNpc=true;};
library:Add{Id="Rafael"; Class="Recycler"; World="Safehome"; SafehomeNpc=true;};

library:Add{Id="Lydia"; Class="FortuneTeller"; World="Safehome"; SafehomeNpc=true;};


--== Wanderer
library:Add{Id="Icarus"; Class="Trader"; Avatar="rbxassetid://13192700114"};

--== Cutscene
library:Add{Id="Revas"; Class="RAT"; World="TheHarbor"; Avatar="rbxassetid://18932917905"; };
library:Add{Id="Eugene"; Class="BioX"; World="SectorE"; };



function library:GetProperties(name)
	local lib = self:Find(name);
	local module = script:FindFirstChild(name);
	if lib and module then
		lib.Properties=require(module);
		return lib.Properties;
	end
	return;
end

return library;