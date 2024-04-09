local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local library = modLibraryManager.new();

function library:GetTravelCost(lastTravelTime, isPremium)
	local timeLapsed = math.clamp(os.time()-lastTravelTime, 0, 300);
	local a = math.clamp(math.ceil(timeLapsed/30)/10, 0, 1);
	return math.floor(300 + (math.sqrt(1-a) * 4700)*(isPremium and 0.75 or 1));
end

library:Add{
	Id="Warehouse Safehouse";
	Image="http://www.roblox.com/asset/?id=4624586880";
	Level=0;
	WorldName="TheWarehouse";
	SetSpawn="warehouse";
};

library:Add{
	Id="Sunday's Safehouse"; 
	Image="http://www.roblox.com/asset/?id=4624775032";  
	Level=10;
	WorldName="TheWarehouse";
	SetSpawn="sundays";
};

library:Add{
	Id="Underbridge Safehouse"; 
	Image="http://www.roblox.com/asset/?id=4624775856";  
	Level=20;
	WorldName="TheUnderground";
	SetSpawn="underbridge";
};

library:Add{
	Id="Train Station Safehouse"; 
	Image="http://www.roblox.com/asset/?id=4624776422";  
	Level=30;
	WorldName="TheUnderground";
	SetSpawn="trainstation";
};

library:Add{
	Id="Mall Safehouse"; 
	Image="http://www.roblox.com/asset/?id=4626874036";  
	Level=40;
	WorldName="TheMall";
	SetSpawn="mallshop1";
};

library:Add{
	Id="Clinic Safehouse"; 
	Image="http://www.roblox.com/asset/?id=4626874290";  
	Level=50;
	WorldName="TheMall";
	SetSpawn="hacClinic1";
};

library:Add{
	Id="The Community Safehouse"; 
	Image="http://www.roblox.com/asset/?id=4723110876";  
	Level=60;
	WorldName="TheResidentials";
	SetSpawn="communitySh";
};

library:Add{
	Id="Harbor Safehouse"; 
	Image="http://www.roblox.com/asset/?id=5002082429";  
	Level=70;
	WorldName="TheHarbor";
	SetSpawn="harborSh";
};


return library;