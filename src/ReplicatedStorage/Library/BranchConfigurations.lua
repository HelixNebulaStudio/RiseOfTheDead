local Debugger = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("Debugger")).new(script);
--==
local RunService = game:GetService("RunService");

local Branches = {
	LiveBranch = {
		Name = "Live";
		GameId = 65708455;
		DataModel = 2133631077;
		Color = Color3.fromRGB(255, 60, 60);
		Worlds = {
			MainMenu=141084271;
			
			--Small Worlds
			Safehome=7021428831;
			SectorE=11627133100;
			
			TheWarehouse=464575687;
			TheUnderground=480661072;
			TheMall=4413486022;
			TheResidentials=4718770953;
			TheHarbor=5001877367;
			
			--Cutscenes;
			TheBeginning=464351538;
			AwokenTheBear=4942807832;
			VindictiveTreasure=5594212861;
			TheInvestigation=6898757722;
			DoubleCross=10098877922;
			BanditsRecruitment=11906832290;
			MedicalBreakthrough=15934332075;
			
			--Survival;
			SectorF=3735072414;
			Prison=6130274415;
			SectorD=7206473065;
			
			--Raids;
			Factory=3473383899;
			Office=4672930500;
			BanditOutpost=4942812724;
			Tombs=5515514657;
			Railways=6570550977;
			AbandonedBunker=13543270317;
			
			--Coop;
			Genesis=7825169805;
			SunkenShip=11213276767;
			
			--Events;
			EasterButchery=4861957178;
			HalloweenBasement=5894210737;
			KlawsWorkshop=8407865225;
			Slaughterfest=11319107048;
			
			BioXResearch=4861955160;
			
			--CommunityMaps;
			CommunityWaySide=11234483877;
			CommunityFissionBay=2133546838;
			CommunityRooftops=14896299784;
		};
	};
	
	DevBranch = {
		Name = "Dev";
		GameId = 11770238;
		DataModel = 6194273755; --1959869159;
		Color = Color3.fromRGB(27, 106, 23);
		Worlds = {
			MainMenu=54092940;
			
			--Small Worlds
			Safehome=7005837755;
			SectorE=5904157734;
			Destructibles=17222878528;
			
			TheWarehouse=1642290020;
			TheUnderground=1959581122;
			TheMall=4136448647;
			TheResidentials=4718358739;
			TheHarbor=4973139830;
			
			--Cutscenes;
			TheBeginning=2126368003;
			AwokenTheBear=4887155779;
			VindictiveTreasure=5556946607;
			TheInvestigation=6881018371;
			DoubleCross=9672014875;
			BanditsRecruitment=11642377451;
			MedicalBreakthrough=15877604745;
			
			--Survival;
			SectorF=3180202162;
			Prison=5919919462;
			SectorD=7121066979;
			
			--Raids;
			Factory=3413033523;
			Office=4667884778;
			BanditOutpost=4923823858;
			Tombs=5495827291;
			Railways=6491538349;
			AbandonedBunker=12858416962;
			
			--Coop;
			Genesis=7431407555;
			SunkenShip=10523367357;
			
			--Events;
			EasterButchery=4852144007;
			HalloweenBasement=5884577465;
			KlawsWorkshop=8374649741;
			Slaughterfest=11264091769;
			
			BioXResearch=289213709;
			
			--CommunityMaps;
			CommunityWaySide=10976260433;
			CommunityFissionBay=54152100;
			CommunityRooftops=14504730660;
		};
	};

	MapTest = {
		GameId = 49654535;
		Worlds = {
			CommunityRooftops=117392863;
			Base=117392863;
		}
	};
	
	
	ModBranch = {
		Name = "Mod";
		GameId = game.GameId;
		DataModel = 6194273755; --1959869159;
		Color = Color3.fromRGB(22, 50, 106);
		Worlds = {};
	};
};

if RunService:IsClient() then -- Branch Color test
	--if game.Players.LocalPlayer.UserId == 16170943 then
	--	Branches.DevBranch.Color = Color3.fromRGB(255, 60, 60);
	--end
end

Branches.CurrentBranch = Branches.ModBranch;

if game.GameId == Branches.LiveBranch.GameId then
	Branches.CurrentBranch = Branches.LiveBranch;
	
elseif game.GameId == Branches.DevBranch.GameId or game.GameId == Branches.MapTest.GameId then -- 49654535 = Map Test;
	Branches.CurrentBranch = Branches.DevBranch;
	
end
Branches.BranchColor = Branches.CurrentBranch.Color;

Branches.WorldTypes = {
	Menu=0;
	General=1;
	Cutscene=2;
	Slaughterfest=3;
	Custom=9;
}

local isMainBranch = Branches.CurrentBranch.Name == "Live";
Branches.WorldLibrary = {
	MainMenu={CanTravelTo=true; TimeCycleEnabled=false; Type=Branches.WorldTypes.Menu; MaxPlayers=25;};
	BioXResearch={CanTravelTo=true; PrivateWorld=true; TimeCycleEnabled=true; Type=Branches.WorldTypes.General; MaxPlayers=10; DevsOnly=isMainBranch}; -- PublicWorld=true;
	
	-- Cutscene;
	TheBeginning={CanTravelTo=false; Type=Branches.WorldTypes.Cutscene; MaxPlayers=1;};
	AwokenTheBear={CanTravelTo=false; Type=Branches.WorldTypes.Cutscene; MaxPlayers=1;};
	VindictiveTreasure={CanTravelTo=false; Type=Branches.WorldTypes.Cutscene; MaxPlayers=1;};
	TheInvestigation={CanTravelTo=false; TimeCycleEnabled=false; Type=Branches.WorldTypes.Cutscene; MaxPlayers=1;};
	DoubleCross={CanTravelTo=false; TimeCycleEnabled=false; Type=Branches.WorldTypes.Cutscene; MaxPlayers=1;};
	SectorE={CanTravelTo=false; TimeCycleEnabled=false; FreeTravels=true; Type=Branches.WorldTypes.Cutscene; MaxPlayers=1;};
	BanditsRecruitment={AC=false; CanTravelTo=false; TimeCycleEnabled=true; Type=Branches.WorldTypes.Cutscene; MaxPlayers=1;};
	MedicalBreakthrough={AC=false; CanTravelTo=false; TimeCycleEnabled=true; Type=Branches.WorldTypes.General; MaxPlayers=1;};

	-- Open world
	Safehome={CanTravelTo=true; PrivateWorld=true; TimeCycleEnabled=true; Type=Branches.WorldTypes.General; MaxPlayers=10;};
	Destructibles={CanTravelTo=true; PrivateWorld=false; TimeCycleEnabled=true; Type=Branches.WorldTypes.General; MaxPlayers=10;};
	
	TheWarehouse={CanTravelTo=true; PublicWorld=true; TimeCycleEnabled=true; Type=Branches.WorldTypes.General; MaxPlayers=12; Icon="rbxassetid://5954340695"};
	TheUnderground={CanTravelTo=true; PublicWorld=true; TimeCycleEnabled=true; Type=Branches.WorldTypes.General; Witherer=true; MaxPlayers=12; Icon="rbxassetid://5959082717"};
	TheMall={CanTravelTo=true; PublicWorld=true; TimeCycleEnabled=true; Type=Branches.WorldTypes.General; MaxPlayers=12; Icon="rbxassetid://5959095409"};
	TheResidentials={CanTravelTo=true; PublicWorld=true; TimeCycleEnabled=true; Type=Branches.WorldTypes.General; MaxPlayers=12; Icon="rbxassetid://5959099674"};
	TheHarbor={CanTravelTo=true; PublicWorld=true; TimeCycleEnabled=true; Type=Branches.WorldTypes.General; MaxPlayers=12; Icon="rbxassetid://7368989503";};
	
	--== Game Modes;
	-- Raid;
	Factory={GameMode=true; CanTravelTo=false; TimeCycleEnabled=false; Type=Branches.WorldTypes.General; MaxPlayers=1;};
	Office={GameMode=true; CanTravelTo=false; TimeCycleEnabled=false; Type=Branches.WorldTypes.General; MaxPlayers=6;};
	BanditOutpost={GameMode=true; CanTravelTo=false; TimeCycleEnabled=true; Type=Branches.WorldTypes.General; MaxPlayers=6;};
	Tombs={GameMode=true; CanTravelTo=false; TimeCycleEnabled=false; Type=Branches.WorldTypes.General; MaxPlayers=6;};
	Railways={GameMode=true; CanTravelTo=false; TimeCycleEnabled=true; Type=Branches.WorldTypes.General; MaxPlayers=6;};
	AbandonedBunker={GameMode=true; CanTravelTo=false; TimeCycleEnabled=true; Type=Branches.WorldTypes.General; MaxPlayers=6;};
	
	-- Survival;
	SectorF={GameMode=true; CanTravelTo=false; TimeCycleEnabled=false; Type=Branches.WorldTypes.General; MaxPlayers=4;};
	Prison={GameMode=true; CanTravelTo=false; TimeCycleEnabled=false; Type=Branches.WorldTypes.General; MaxPlayers=4;};
	SectorD={GameMode=true; CanTravelTo=false; TimeCycleEnabled=true; Type=Branches.WorldTypes.General; MaxPlayers=4;};
	
	-- Coop;
	Genesis={GameMode=true; CanTravelTo=false; TimeCycleEnabled=true; Type=Branches.WorldTypes.General; MaxPlayers=4;};
	SunkenShip={GameMode=true; CanTravelTo=false; TimeCycleEnabled=true; Type=Branches.WorldTypes.General; MaxPlayers=4;};
	
	--== Events;
	EasterButchery={CanTravelTo=true; PublicWorld=true; TimeCycleEnabled=true; Type=Branches.WorldTypes.General; MaxPlayers=1;};
	HalloweenBasement={GameMode=true; CanTravelTo=true; PublicWorld=true; TimeCycleEnabled=false; Type=Branches.WorldTypes.General; MaxPlayers=8;};
	KlawsWorkshop={GameMode=true; AC=true; CanTravelTo=false; TimeCycleEnabled=false; Type=Branches.WorldTypes.General; MaxPlayers=4;};
	Slaughterfest={NoPrivateServers=true; CanTravelTo=true; PublicWorld=true; FreeTravels=true; TimeCycleEnabled=true; Type=Branches.WorldTypes.Slaughterfest; MaxPlayers=16;};
	
	--== CommunityMaps;
	CommunityWaySide={GameMode=true; CanTravelTo=false; TimeCycleEnabled=true; Type=Branches.WorldTypes.General; MaxPlayers=4;};
	CommunityFissionBay={GameMode=true; CanTravelTo=false; TimeCycleEnabled=true; Type=Branches.WorldTypes.General; MaxPlayers=4;};
	CommunityRooftops={GameMode=true; CanTravelTo=false; TimeCycleEnabled=true; Type=Branches.WorldTypes.General; MaxPlayers=4;};
	
	--==
	Default={CanTravelTo=true; PublicWorld=true; TimeCycleEnabled=true; Type=Branches.WorldTypes.General; MaxPlayers=32;};
}

Branches.MapOverviews = {
	BioXResearch = {
		{ImageId="rbxassetid://7365830811"; Y=-math.huge; PperStud=1; Scale=Vector2.new(1024, 1024); Center=Vector2.new(0, 0);};
	};
	
	TheWarehouse = {
		{ImageId="rbxassetid://8768538325"; Y=87; PperStud=2; Scale=Vector2.new(1942, 1942); Center=Vector2.new(334.5, 68);};
		{ImageId="rbxassetid://8768540304"; Y=68.5; PperStud=2; Scale=Vector2.new(1942, 1942); Center=Vector2.new(334.5, 68);};
		{ImageId="rbxassetid://8768541341"; Y=-math.huge; PperStud=2; Scale=Vector2.new(1942, 1942); Center=Vector2.new(334.5, 68);};
	};
	
	TheUnderground = {
		{ImageId="rbxassetid://7369480754"; Y=22.515; PperStud=2; Scale=Vector2.new(1972, 1972); Center=Vector2.new(44, 106);};
		{ImageId="rbxassetid://7369636427"; Y=20.997; PperStud=2; Scale=Vector2.new(1972, 1972); Center=Vector2.new(44, 106);};
		{ImageId="rbxassetid://7369747491"; Y=5.554; PperStud=2; Scale=Vector2.new(1972, 1972); Center=Vector2.new(44, 106);};
		{ImageId="rbxassetid://7369997134"; Y=-math.huge; PperStud=2; Scale=Vector2.new(1972, 1972); Center=Vector2.new(44, 106);};
	};
	
	TheMall = {
		{ImageId="rbxassetid://7373303939"; Y=154.75; PperStud=2; Scale=Vector2.new(1924, 1924); Center=Vector2.new(747, -815);};
		{ImageId="rbxassetid://7373337229"; Y=125.604; PperStud=2; Scale=Vector2.new(1924, 1924); Center=Vector2.new(747, -815);};
		{ImageId="rbxassetid://7373338257"; Y=92.21; PperStud=2; Scale=Vector2.new(1924, 1924); Center=Vector2.new(747, -815);};
		{ImageId="rbxassetid://7373339002"; Y=-math.huge; PperStud=2; Scale=Vector2.new(1924, 1924); Center=Vector2.new(747, -815);};
	};
	
	TheResidentials = {
		{ImageId="rbxassetid://7402042691"; Y=123.606; PperStud=2; Scale=Vector2.new(2180, 2180); Center=Vector2.new(1070, -43.5);};
		{ImageId="rbxassetid://7402043566"; Y=71.89; PperStud=2; Scale=Vector2.new(2180, 2180); Center=Vector2.new(1070, -43.5);};
		{ImageId="rbxassetid://7402044433"; Y=53.75; PperStud=2; Scale=Vector2.new(2180, 2180); Center=Vector2.new(1070, -43.5);};
		{ImageId="rbxassetid://7402045593"; Y=-math.huge; PperStud=2; Scale=Vector2.new(2180, 2180); Center=Vector2.new(1070, -43.5);};
	};
	
	TheHarbor = {
		{ImageId="rbxassetid://8712325718"; Y=124; PperStud=2; Scale=Vector2.new(2348, 2348); Center=Vector2.new(-429, 371);};
		{ImageId="rbxassetid://8712325258"; Y=99; PperStud=2; Scale=Vector2.new(2348, 2348); Center=Vector2.new(-429, 371);};
		{ImageId="rbxassetid://8712324965"; Y=78; PperStud=2; Scale=Vector2.new(2348, 2348); Center=Vector2.new(-429, 371);};
		{ImageId="rbxassetid://8712324696"; Y=52; PperStud=2; Scale=Vector2.new(2348, 2348); Center=Vector2.new(-429, 371);};
		{ImageId="rbxassetid://8712324253"; Y=-math.huge; PperStud=2; Scale=Vector2.new(2348, 2348); Center=Vector2.new(-429, 371);};
	};
	
	SectorF = {
		{ImageId="rbxassetid://12764242828"; Y=56.8; PperStud=2; Scale=Vector2.new(501, 503); Center=Vector2.new(75.293, 98.318);};
		{ImageId="rbxassetid://12764244815"; Y=-math.huge; PperStud=2; Scale=Vector2.new(501, 503); Center=Vector2.new(75.293, 98.318);};
	};

	Prison = {
		{ImageId="rbxassetid://12764755356"; Y=-math.huge; PperStud=4; Scale=Vector2.new(1441, 1441); Center=Vector2.new(87.963, -9.183);};
	};
	
	SectorD = {
		{ImageId="rbxassetid://9184249205"; Y=45.923; PperStud=2; Scale=Vector2.new(810, 810); Center=Vector2.new(-85.5, -54.5);};
		{ImageId="rbxassetid://9184249994"; Y=10.682; PperStud=2; Scale=Vector2.new(810, 810); Center=Vector2.new(-85.5, -54.5);};
		{ImageId="rbxassetid://9184250474"; Y=-math.huge; PperStud=2; Scale=Vector2.new(810, 810); Center=Vector2.new(-85.5, -54.5);};
	};
	
	CommunityWaySide = {
		{ImageId="rbxassetid://11229540571"; Y=20.8; PperStud=2; Scale=Vector2.new(1087, 1087); Center=Vector2.new(-58.6, 123.9);};
		{ImageId="rbxassetid://11229527628"; Y=-math.huge; PperStud=2; Scale=Vector2.new(1087, 1087); Center=Vector2.new(-58.6, 123.9);};
	};

	CommunityFissionBay = {
		{ImageId="rbxassetid://12466019523"; Y=-math.huge; PperStud=2; Scale=Vector2.new(1024, 1024); Center=Vector2.new(-155, 44.5);};
	};
	
}

Branches.SpawnLibrary = {
	TheWarehouse={
		warehouse={};
		sundays={};
		sewersexit={};
		warehouseComX={};
		factoryExit={};
		sewersfactoryExit={};
		officeExit={};
		harbToWarehouse={};
	};
	TheUnderground={
		sewerentrance={};
		sewerEntrance2={};
		underbridge={};
		trainstation={};
		fromMall={};
		fromMallLift={};
		maToUnMain={};
		residentialToTrain={};
		CXsecF2={};
		harbToSewers={};
		SecE={};
	};
	TheMall={
		fromTS={};
		mallshop1={};
		mallLiftTS={};
		hacClinic1={};
		unToMallKin={};
		radioStationExit={};
		patrick={};
	};
	TheResidentials={
		communitySh={};
		mallToRadio={};
		trainToResidential={};
		warehouseToResidential={};
		halloweenbasement={};
		sectorDToRes={};
	};
	TheHarbor={
		harborSh={};
		factToharbor={};
		sewersToharbor={};
	};
}

Branches.WorldDisplayNames = {
	MainMenu="Main Menu";
	BioXResearch="BioX Research Facility";
	
	Safehome="Safehome";
	
	-- Cutscene;
	TheBeginning="W.D. Bridge";
	AwokenTheBear="Mission: Awoken The Bear";
	VindictiveTreasure="Mission: Vindictive Treasure";
	TheInvestigation="Mission: The Investigation";
	DoubleCross="Mission: Double Cross";
	SectorE="Sector E";
	BanditsRecruitment="Mission: Bandits Recruitment";
	
	-- Open;
	TheWarehouse="W.D. Warehouse";
	TheUnderground="W.D. Underground";
	TheMall="W.D. Mall";
	TheResidentials="W.D. Residentials";
	TheHarbor="W.D. Harbor";
	
	-- Raid;
	Factory="Raid: Factory";
	Office="Raid: Office";
	BanditOutpost="Raid: Bandit Outpost";
	Tombs="Raid: Tombs";
	Railways="Raid: Railways";
	AbandonedBunker="Raid: Abandoned Bunker";
	
	-- Survival;
	SectorF="Survival: Sector F";
	Prison="Survival: W.D. Prison";
	SectorD="Survival: Sector D";
	
	-- Coop;
	Genesis="Coop: Genesis";
	SunkenShip="Coop: Sunken Ship";
	
	
	--Events;
	EasterButchery="Easter Event: Butchery";
	HalloweenBasement="Halloween Mission: Halloween Basement";
	KlawsWorkshop="Christmas Event: Mr. Klaws Workshop";
	Slaughterfest="Halloween Event: Slaughterfest";
	
	--CommunityMap;
	CommunityWaySide="Community: Way Side";
	CommunityFissionBay="Community: Fission Bay";
	CommunityRooftops="Community: Roof Tops";
};

Branches.LinkedWorlds = {
	TheWarehouse={"TheUnderground"; "TheResidentials"; "TheHarbor"};
	TheUnderground={"TheWarehouse"; "TheMall"; "TheResidentials"; "TheHarbor"; "SectorE"};
	TheMall={"TheUnderground"; "TheResidentials";};
	TheResidentials={"TheWarehouse"; "TheUnderground"; "TheMall";};
	TheHarbor={"TheWarehouse"; "TheUnderground";};
	SectorE={"TheUnderground"}
};

function Branches.GetInteractableLocation(interactableName)
	local interactPart = workspace.Interactables:FindFirstChild(interactableName);
	local info = Branches.NavLinks[Branches.WorldName];
	
	if interactPart and info then
		return info.In, interactPart.Position;
	end
	return;
end

function Branches.GetWorldOfSpawn(spawnId)
	for worldName, spawnData in pairs(Branches.SpawnLibrary) do
		if spawnData[spawnId] then
			return worldName;
		end
	end
	return;
end

function Branches.GetWorldDisplayName(name)
	return Branches.WorldDisplayNames[name];
end

function Branches.GetWorldName(placeId)
	for worldName, worldId in pairs(Branches.CurrentBranch.Worlds) do
		if worldId == placeId then
			return worldName;
		end
	end
	warn(script.Name..">>  Unable to find matching world with id:(",placeId,").");

	return;
end

function Branches.GetWorldId(name)
	if Branches.CurrentBranch.Worlds[name] then
		return Branches.CurrentBranch.Worlds[name];
	end
	return;
end

function Branches.GetWorld()
	return game.ReplicatedFirst:WaitForChild("PlaceName").Value;
end

function Branches.IsWorld(worldName)
	if game.PlaceId == 289213709 and Branches.GetWorld() == worldName then
		return true;
	end;
	if game.PlaceId == Branches.CurrentBranch.Worlds[worldName] then
		return true;
	end
	return false;
end

function Branches.InDev(v)
	local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
	if Branches.CurrentBranch.Name ~= "Live" then return false; end;
	
	if modGlobalVars.GameVersion ~= v then
		return true;
	end
	return false;
end


Branches.WorldName = Branches.GetWorld();
Branches.WorldId = Branches.GetWorldId(Branches.GetWorld()) or game.PlaceId;
Branches.WorldInfo = Branches.WorldLibrary[Branches.WorldName];

local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
if Branches.WorldInfo == nil then
	Branches.WorldInfo = Branches.WorldLibrary.Default;
	
	local moddedSelf = modModEngineService:GetModule(script.Name);
	if moddedSelf then 
		moddedSelf:Init(Branches); 
	else
		Debugger:Warn("Unable to get world info. ("..tostring(game.PlaceId)..") ("..tostring(Branches.WorldName)..")");
	end
	
elseif Branches.WorldInfo.Type == Branches.WorldTypes.General or Branches.WorldInfo.Type == Branches.WorldTypes.Safehome then
	--warn(script.Name..">>  Initializing [General] world configurations.");
	--== Client;
	modConfigurations.Set("AllowFreecam", true);
	modConfigurations.Set("DisableHotbar", false);
	modConfigurations.Set("DisableWeaponInterface", false);
	modConfigurations.Set("DisableInventory", false);
	modConfigurations.Set("DisableHealthbar", false);
	modConfigurations.Set("DisableMailbox", false);
	modConfigurations.Set("DisableFactionsMenu", false);
	modConfigurations.Set("DisableMissions", false);
	modConfigurations.Set("DisablePinnedMission", false);
	modConfigurations.Set("DisableWorkbench", false);
	modConfigurations.Set("DisableReportMenu", false);
	modConfigurations.Set("DisableMasteryMenu", false);
	modConfigurations.Set("DisableExperiencebar", false);
	modConfigurations.Set("DisableGeneralStats", false);
	modConfigurations.Set("CanQuickEquip", true);
	modConfigurations.Set("DisableInventoryHotkey", false);
	modConfigurations.Set("DisableSquadInterface", false);
	modConfigurations.Set("DisableMajorNotifications", false);
	modConfigurations.Set("DisableDialogue", false);
	modConfigurations.Set("DisableWaypointers", false);
	modConfigurations.Set("DisableSocialMenu", false);
	modConfigurations.Set("DisableEmotes", false);
	modConfigurations.Set("DisableSettingsMenu", false);
	modConfigurations.Set("DisableInfoBubbles", false);
	modConfigurations.Set("DisableMapMenu", false);
	modConfigurations.Set("DisableGoldMenu", false);
	modConfigurations.Set("DisableStatusHud", false);
	modConfigurations.Set("NotificationViewPos", 1);
	modConfigurations.Set("DisableSafehomeMenu", true);
	
	if Branches.WorldInfo.PublicWorld then
		modConfigurations.Set("DisableUpdateLogs", false);
		modConfigurations.Set("SpawnProtectionTimer", 120);
		modConfigurations.Set("DisableMapItems", false);
		modConfigurations.Set("ExpireDeployables", true);
		modConfigurations.Set("NaturalSpawnLimit", 85);
		workspace:SetAttribute("RecomputePathThreshold", 1);
		
	else
		modConfigurations.Set("SpectateEnabled", true);
		
	end
	
	--== Server;
	modConfigurations.Set("DisableItemDrops", false);
	modConfigurations.Set("DisableExperienceGain", false);
	
	if Branches.WorldInfo.Witherer == true then
		modConfigurations.Set("WithererSpawnLogic", true);
		
	end

elseif Branches.WorldInfo.Type == Branches.WorldTypes.Cutscene then
	--warn(script.Name..">>  Initializing [Cutscene] world configurations.");
	modConfigurations.Set("AllowFreecam", true);
	modConfigurations.Set("DisableHotbar", true);
	modConfigurations.Set("CanQuickEquip", false);
	modConfigurations.Set("DisableSquadInterface", true);
	modConfigurations.Set("DisableMajorNotifications", true);
	modConfigurations.Set("DisableDialogue", true);
	modConfigurations.Set("DisableMapMenu", true);
	modConfigurations.Set("DisableGoldMenu", true);
	modConfigurations.Set("ShowNameDisplays", false);
	modConfigurations.Set("DisableStatusHud", true);
	modConfigurations.Set("NotificationViewPos", 2);
	modConfigurations.Set("DisableMissions", false);
	
elseif Branches.WorldInfo.Type == Branches.WorldTypes.Menu then
	modConfigurations.Set("AllowFreecam", true);
	modConfigurations.Set("DisableLeaderboard", true);
	

elseif Branches.WorldInfo.Type == Branches.WorldTypes.Slaughterfest then
	modConfigurations.Set("DisableHealthbar", false);
	modConfigurations.Set("DisableHotbar", true);
	modConfigurations.Set("CanQuickEquip", false);

	modConfigurations.Set("DisableSettingsMenu", false);
	modConfigurations.Set("DisableSocialMenu", false);
	modConfigurations.Set("DisableSquadInterface", false);
	modConfigurations.Set("DisableMajorNotifications", false);
	modConfigurations.Set("DisableDialogue", true);
	modConfigurations.Set("DisableMapMenu", true);
	modConfigurations.Set("DisableGoldMenu", false);
	modConfigurations.Set("DisableStatusHud", false);
	modConfigurations.Set("DisableEmotes", false);
	modConfigurations.Set("DisableMissions", false);
	
	modConfigurations.Set("DisableExperiencebar", false);
	modConfigurations.Set("RemoveForceFieldOnWeaponFire", true);
	modConfigurations.Set("DisableGearMods", true);
	
	modConfigurations.Set("PvpMode", true);
	
	modConfigurations.Set("SpawnProtectionTimer", 5);
	modConfigurations.Set("TargetableEntities", {
		Humanoid=1;
		Zombie=1;
	});
	
	--== Server;
	modConfigurations.Set("DisableItemDrops", false);
	modConfigurations.Set("DisableNonMockEquip", true);
	modConfigurations.Set("DisableMasterySkills", true);
	
end
	
if Branches.WorldName == "BioXResearch" then
	modConfigurations.Set("PvpMode", true);
	modConfigurations.Set("BaseWoundedDuration", 10);
	modConfigurations.Set("SpectateEnabled", true);
	modConfigurations.Set("DisableMapItems", false);
	--modConfigurations.Set("NaturalSpawnLimit", 10);
	
elseif Branches.WorldName == "Safehome" then
	modConfigurations.Set("DisableSafehomeMenu", false);
	modConfigurations.Set("DisableMapItems", false);
	
end

local SpecialEvent = modConfigurations.SpecialEvent;
if SpecialEvent.Easter then
	Branches.SpawnLibrary.EasterButchery={
		EasterButchery2={};
	};
end

-- CurrentNav>> NavSafehouse, NavResidentialsSet, Nil, NavSkyRoom, NavPurpleRoom <<TargetNav
Branches.NavLinks = {
	BioXResearch=(Branches.WorldName == "BioXResearch" and {
		NavSafehouse={ -- CurrentNav;
			Safehouse=true;

			Entrance="bioxMainExit";
			Exit="bioxMainExit";
		};
	} or nil);

	TheWarehouse={
		NavSundaySafehouse={
			Entrance="safehouse2Entrance";
			Exit="safehouse2Exit";

			Safehouse=true;
			Shop="Shop_Sundays";
		};

		NavWarehouseSafehouse={
			Parent="NavWarehouseRegion";

			Entrance="warehouseEntrance";
			Exit="warehouseExit";

			Safehouse=true;
			Shop="Shop_Warehouse";
		};
		NavWarehouseRegion={
			Entrance="warehouseFenceEntrance";
			Exit="warehouseFenceExit";
		};

		NavOffice={
			Entrance="officeEntrance";
			Exit="officeExit";
		};
	};

	TheUnderground={
		NavUnderbridgeSafehouse={
			Entrance="safehouse3Door";
			Exit="safehouse3Exit";

			Safehouse=true;
			Shop="Shop_Underbridge";
		};


		NavTrainStationSafehouse={
			Entrance="safehouse4Entrance";
			Exit="safehouse4Exit";

			Safehouse=true;
			Shop="Shop_TrainStation";
		};

	};


	TheMall={
		NavMallSafehouse={
			Parent="NavMall";

			Entrance="safehouse5Entrance";
			Exit="safehouse5MainDoor";

			Safehouse=true;
			Shop="Shop_Mall";
		};
		NavMall={
			Entrance="mallGlassDoorEntrance";
			Exit="mallGlassDoorExit";
		};

		NavClinicSafehouse={
			Entrance="safehouse6Entrance";
			Exit="safehouse6Exit";

			Safehouse=true;
			Shop="Shop_Clinic";
		};
	};



	TheResidentials={
		NavCommunitySafehouse={
			Parent="NavCommunityRegion";

			Entrance="SafehouseEntranceFront";
			Exit="SafehouseExitFront";

			Safehouse=true;
			Shop="Shop_Residentials";
		};
		NavCommunityRegion={
			Entrance="CommunityEntrance";
			Exit="CommunityExit";
		};

		NavRadioStation={
			Entrance="radiostationentrance";
			Exit="radiostationexit";

			Safehouse=true;
		};
	};

	TheHarbor={
		NavRatSafehouse={
			Entrance="BridgeToSafehouseEntrance";
			Exit="SafehouseToBridgeExit";

			Safehouse=true;
		};

		NavPowerStation={
			Entrance="PowerstationEntrance";
			Exit="PowerstationExit";

			Safehouse=true;
		};
	};

};

--==
Branches.Wanderer = nil;

return Branches;
