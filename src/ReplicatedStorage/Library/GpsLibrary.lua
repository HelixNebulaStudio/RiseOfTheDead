local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local library = modLibraryManager.new();

function library:GetTravelCost(lastTravelTime, playerProfile)
	local isPremium = playerProfile and playerProfile.Premium;
	local isTravelVip = playerProfile and playerProfile.GamePass and playerProfile.GamePass.VipTraveler;
	
	local timeLapsed = math.clamp(modSyncTime.GetTime() -lastTravelTime, 0, 300);
	local a = math.clamp(math.ceil(timeLapsed/30)/10, 0, 1);

	local price = math.floor(300 + (math.sqrt(1-a) * 4700));
	
	if isTravelVip then -- Vip Traveler
		price = price * 0.25;
		
	elseif isPremium then -- Premium
		price = price * 0.75;
		
	end
	if isTravelVip and isPremium then
		price = 0;
	end
	
	if modBranchConfigs.WorldInfo and modBranchConfigs.WorldInfo.FreeTravels then
		price = 0;
	end
	return price
end

--library:Add{
--	Id="w0test";
--	Name="Test Room";
--	Image="http://www.roblox.com/asset/?id=5954340695";

--	WorldName="BioXResearch";
--	Position=Vector3.new(-50.63, -15.95, -0.12);
--	SetSpawn="warehouse";

--	Locations = {
--		"Room";
--	};
--};

if game:GetService("RunService"):IsStudio() then
	library:Add{
		Id="w0test";
		Name="BioXResearch Lab";
		Image="http://www.roblox.com/asset/?id=5954340695";

		WorldName="BioXResearch";
		Position=Vector3.new(-53.255, -14.355, 0);
		SetSpawn="SpawnLocation";

		Locations = {
			"Room";
		};
		
		FactionBanner=true;
	};

	library:Add{
		Id="w0test2";
		Name="BioXResearch Lab 2";
		Image="http://www.roblox.com/asset/?id=5954340695";

		WorldName="BioXResearch";
		Position=Vector3.new(-53.255, -14.355, 0);
		SetSpawn="SpawnLocation2";

		Locations = {
			"Room";
		};
	};
	
end

library:Add{
	Id="pwsafehome";
	Name="Safehome";
	Image="http://www.roblox.com/asset/?id=7030452840";
	
	WorldName="Safehome";
	UnlockedByDefault=true;
	FreeTravel=true;
	Locations = {};
};

library:Add{
	Id="w1";
	Name="World: W.D. Warehouse";
	WorldName="TheWarehouse";
};

library:Add{
	Id="w1sh1";
	Name="Warehouse Safehouse";
	Image="http://www.roblox.com/asset/?id=5954340695";
	
	WorldName="TheWarehouse";
	Position=Vector3.new(12.16, 58.25, 10.09);
	SetSpawn="warehouse";
	UnlockedByDefault=true;
	
	FreeTravel=true;
	Locations = {
		"Warehouse Bedroom";
		"Warehouse Safehouse";
		"Warehouse Second Floor";
	};
	
	FactionBanner=true;
};

library:Add{
	Id="w1sh2";
	Name="Sunday's Safehouse";
	Image="http://www.roblox.com/asset/?id=5954371576";

	WorldName="TheWarehouse";
	Position=Vector3.new(636.432, 58.35, -14.34);
	SetSpawn="sundays";
	UnlockedByDefault=true;

	Locations = {
		"Sunday's Safehouse";
		"Sunday's Second Floor";
		"Sunday's Roof";
	};

	FactionBanner=true;
};

library:Add{
	Id="w1bloxmart";
	Name="Bloxmart";
	Image="http://www.roblox.com/asset/?id=5954369114";

	WorldName="TheWarehouse";
	Position=Vector3.new(300.902, 58.4, 11.538);
	SetSpawn="warehouse";

	Locations = {
		"Bloxmart";
	};
};

library:Add{
	Id="w1park";
	Name="Park";
	Image="http://www.roblox.com/asset/?id=5954370507";

	WorldName="TheWarehouse";
	Position=Vector3.new(352.02, 60.4, 222.46);
	SetSpawn="sundays";

	Locations = {
		"Park";
	};
};

library:Add{
	Id="w1bank";
	Name="Bank";
	Image="http://www.roblox.com/asset/?id=5954372781";

	WorldName="TheWarehouse";
	Position=Vector3.new(632.182, 58.3, 50.988);
	SetSpawn="sundays";

	Locations = {
		"Bank";
	};
};

library:Add{
	Id="w1factory";
	Name="Factory";
	Image="http://www.roblox.com/asset/?id=5954374975";

	WorldName="TheWarehouse";
	Position=Vector3.new(65.672, 58.61, 185.688);
	SetSpawn="factoryExit";

	Locations = {
		"Factory";
	};
};

library:Add{
	Id="w1office";
	Name="Office";
	Image="http://www.roblox.com/asset/?id=5954376382";

	WorldName="TheWarehouse";
	Position=Vector3.new(637.31, 58.35, 255.72);
	SetSpawn="officeExit";

	Locations = {
		"Office";
	};
};

library:Add{
	Id="w2";
	Name="World: W.D. Underground";
	WorldName="TheUnderground";
};

library:Add{
	Id="w2sectorf";
	Name="Sector F";
	Image="http://www.roblox.com/asset/?id=5959080979";

	WorldName="TheUnderground";
	Position=Vector3.new(2.41, 16.5, -78.652);
	SetSpawn="sewerentrance";

	Locations = {
		"Sector F";
	};
};

library:Add{
	Id="w2sh3";
	Name="Underbridge Community";
	Image="http://www.roblox.com/asset/?id=5959082717";

	WorldName="TheUnderground";
	Position=Vector3.new(-94.475, 11.182, 287.995);
	SetSpawn="underbridge";

	Locations = {
		"Underbridge Safehouse";
		"Underbridge Second Floor";
		"Underbridge Top Floor";
	};

	FactionBanner=true;
};

library:Add{
	Id="w2sectore";
	Name="Sector E";
	Image="http://www.roblox.com/asset/?id=5959083723";

	WorldName="TheUnderground";
	Position=Vector3.new(136.217, 12.691, -9.244);
	SetSpawn="SecE";

	Locations = {
		"Sector E";
	};
};

library:Add{
	Id="w2sh4";
	Name="Train Station Safehouse";
	Image="http://www.roblox.com/asset/?id=5959092587";

	WorldName="TheUnderground";
	Position=Vector3.new(251.851, 10.2, -8.623);
	SetSpawn="trainstation";

	Locations = {
		"Train Station Safehouse";
	};

	FactionBanner=true;
};

library:Add{
	Id="w3";
	Name="World: W.D. Mall";
	WorldName="TheMall";
};

library:Add{
	Id="w3sh5";
	Name="Mall Safehouse";
	Image="http://www.roblox.com/asset/?id=5959094120";

	WorldName="TheMall";
	Position=Vector3.new(736.13, 95.575, -672.074);
	SetSpawn="mallshop1";

	Locations = {
		"Mall Safehouse";
	};
};

library:Add{
	Id="w3banditcamp";
	Name="Bandit Camp";
	Image="http://www.roblox.com/asset/?id=5959095409";

	WorldName="TheMall";
	Position=Vector3.new(797.523, 163.268, -728.326);
	SetSpawn="patrick";

	Locations = {
		"Bandit Camp";
	};
};

library:Add{
	Id="w3preschool";
	Name="Preschool";
	Image="http://www.roblox.com/asset/?id=5959096400";

	WorldName="TheMall";
	Position=Vector3.new(440.112, 97.981, -664.022);
	SetSpawn="unToMallKin";

	Locations = {
		"Preschool";
	};
};

library:Add{
	Id="w3sh6";
	Name="Clinic Safehouse";
	Image="http://www.roblox.com/asset/?id=5959098284";

	WorldName="TheMall";
	Position=Vector3.new(525.705, 97.735, -1102.795);
	SetSpawn="hacClinic1";

	Locations = {
		"Clinic Safehouse";
	};

	FactionBanner=true;
};

library:Add{
	Id="w4";
	Name="World: W.D. Residentials";
	WorldName="TheResidentials";
};

library:Add{
	Id="w4sh7";
	Name="Community Safehouse";
	Image="http://www.roblox.com/asset/?id=5959099674";

	WorldName="TheResidentials";
	Position=Vector3.new(1152.655, 57.415, -31.126);
	SetSpawn="communitySh";

	Locations = {
		"Community Safehouse";
	};

	FactionBanner=true;
};

library:Add{
	Id="w4radio";
	Name="Radio Station";
	Image="http://www.roblox.com/asset/?id=5959100518";

	WorldName="TheResidentials";
	Position=Vector3.new(1104.75, 71.233, -481.696);
	SetSpawn="mallToRadio";

	Locations = {
		"Radio Station";
	};
};

library:Add{
	Id="w4insurance";
	Name="Insurance Firm";
	Image="http://www.roblox.com/asset/?id=5959101749";

	WorldName="TheResidentials";
	Position=Vector3.new(878.742, 58.486, 256.586);
	SetSpawn="warehouseToResidential";

	Locations = {
		"Insurance Firm";
	};
};

library:Add{
	Id="w4bunkerinc";
	Name="Bunker Inc. Base";
	Image="http://www.roblox.com/asset/?id=13787134613";

	WorldName="TheResidentials";
	Position=Vector3.new(920.135, 58.327, -88.057);
	SetSpawn="bunkerInc";

	Locations = {
		"Bunker Inc. Base";
	};
};


library:Add{
	Id="w5";
	Name="World: W.D. Harbor";
	WorldName="TheHarbor";
};

library:Add{
	Id="w5harborsafehouse";
	Name="Harbor Safehouse";
	Image="rbxassetid://8816108529";

	WorldName="TheHarbor";
	Position=Vector3.new(-322.035, 81.768, 223.737);
	SetSpawn="harborSh";

	Locations = {
		"Harbor Safehouse";
		"Harbor Safehouse Floor 2";
		"Harbor Safehouse Top Floor";
	};
};

return library;