local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
--==
local LEGACY_GAME_ID = 65708455;
local LIVE_GAME_ID = 9704136497;
local DEV_GAME_ID = 11770238;

local WORLD_TYPES = {
    Menu = 0;
	General = 1;
	Cutscene = 2;
	Slaughterfest = 3;
	NekronsGambit = 4;
	Custom = 9;
    Dev = 10;
}
modBranchConfigurations.WorldTypes = WORLD_TYPES;

local WORLDS = {
    MainMenu = {
        DisplayName = "Main Menu";
        PlaceIds = {
            [LEGACY_GAME_ID] = 141084271;
            [LIVE_GAME_ID] = 95518711955879;
            [DEV_GAME_ID] = 54092940;
        };
        
        WorldType = WORLD_TYPES.Menu;
        CanTravelTo = true;
        TimeCycleEnabled = false;
        MaxPlayers = 25;
    };



    --MARK: Safe worlds
    Safehome = {
        DisplayName = "Safehome";
        PlaceIds = {
            [LEGACY_GAME_ID] = 7021428831;
            [LIVE_GAME_ID] = 7021428831;
            [DEV_GAME_ID] = 7005837755;
        };
        
        WorldType = WORLD_TYPES.General;
        PrivateWorld = true;
    };
    SectorE = {
        DisplayName = "Sector E";
        PlaceIds = {
            [LEGACY_GAME_ID] = 11627133100;
            [LIVE_GAME_ID] = 11627133100;
            [DEV_GAME_ID] = 5904157734;
        };
        
        WorldType = WORLD_TYPES.General;
        TimeCycleEnabled = false;
    };



    --MARK: Open worlds;
    TheWarehouse = {
        DisplayName = "W.D. Warehouse";
        PlaceIds = {
            [LEGACY_GAME_ID] = 464575687;
            [LIVE_GAME_ID] = 74727871207166;
            [DEV_GAME_ID] = 1642290020;
        };
        
        WorldType = WORLD_TYPES.General;
        Icon = "rbxassetid://5954340695";
        CanTravelTo = true;
        Index = 1;
        PublicWorld = true;
        LoadLeaderboard = true;
        MaxPlayers = 12;
    };
    TheUnderground = {
        DisplayName = "W.D. Underground";
        PlaceIds = {
            [LEGACY_GAME_ID] = 480661072;
            [LIVE_GAME_ID] = 126735923549685;
            [DEV_GAME_ID] = 1959581122;
        };
        
        WorldType = WORLD_TYPES.General;
        Icon = "rbxassetid://5959082717";
        CanTravelTo = true;
        Index = 2;
        PublicWorld = true;
        LoadLeaderboard = true;
        MaxPlayers = 12;
        Witherer = true;
    };
    TheMall = {
        DisplayName = "W.D. Mall";
        PlaceIds = {
            [LEGACY_GAME_ID] = 4413486022;
            [LIVE_GAME_ID] = 121856513802733;
            [DEV_GAME_ID] = 4136448647;
        };
        
        WorldType = WORLD_TYPES.General;
        Icon = "rbxassetid://5959095409";
        CanTravelTo = true;
        Index = 3;
        PublicWorld = true;
        LoadLeaderboard = true;
        MaxPlayers = 12;
    };
    TheResidentials = {
        DisplayName = "W.D. Residentials";
        PlaceIds = {
            [LEGACY_GAME_ID] = 4718770953;
            [LIVE_GAME_ID] = 95903556488607;
            [DEV_GAME_ID] = 4718358739;
        };
        
        WorldType = WORLD_TYPES.General;
        Icon = "rbxassetid://5959099674";
        CanTravelTo = true;
        Index = 4;
        PublicWorld = true;
        LoadLeaderboard = true;
        MaxPlayers = 12;
    };
    TheHarbor = {
        DisplayName = "W.D. Harbor";
        PlaceIds = {
            [LEGACY_GAME_ID] = 5001877367;
            [LIVE_GAME_ID] = 130961448163734;
            [DEV_GAME_ID] = 4973139830;
        };
        
        WorldType = WORLD_TYPES.General;
        Icon = "rbxassetid://7368989503";
        CanTravelTo = true;
        Index = 5;
        PublicWorld = true;
        LoadLeaderboard = true;
        MaxPlayers = 12;
    };
    


    --MARK: Gamemode Survival;
    SectorF = {
        DisplayName = "Survival: Sector F";
        PlaceIds = {
            [LEGACY_GAME_ID] = 3735072414;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 3180202162;
        };
        
        WorldType = WORLD_TYPES.General;
        WeatherCycle = false;
        LoadLeaderboard = true;
    };
    Prison = {
        DisplayName = "Survival: W.D. Prison";
        PlaceIds = {
            [LEGACY_GAME_ID] = 6130274415;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 5919919462;
        };
        
        WorldType = WORLD_TYPES.General;
        WeatherCycle = false;
        LoadLeaderboard = true;
    };
    SectorD = {
        DisplayName = "Survival: Sector D";
        PlaceIds = {
            [LEGACY_GAME_ID] = 7206473065;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 7121066979;
        };
        
        WorldType = WORLD_TYPES.General;
        WeatherCycle = false;
        LoadLeaderboard = true;
    };
    Swamplands = {
        DisplayName = "Survival: Swamplands";
        PlaceIds = {
            [LEGACY_GAME_ID] = 77974241048068;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 106260060051724;
        };
        
        WorldType = WORLD_TYPES.General;
        WeatherCycle = false;
        LoadLeaderboard = true;
    };



    --MARK: Gamemode Raids;
    Factory = {
        DisplayName = "Raid: Factory";
        PlaceIds = {
            [LEGACY_GAME_ID] = 3473383899;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 3413033523;
        };
        
        WorldType = WORLD_TYPES.General;
        LoadLeaderboard = true;
        MaxPlayers = 1;
    };
    Office = {
        DisplayName = "Raid: Office";
        PlaceIds = {
            [LEGACY_GAME_ID] = 4672930500;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 4667884778;
        };
        
        WorldType = WORLD_TYPES.General;
        LoadLeaderboard = true;
        MaxPlayers = 6;
    };
    BanditOutpost = {
        DisplayName = "Raid: Bandit Outpost";
        PlaceIds = {
            [LEGACY_GAME_ID] = 4942812724;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 4923823858;
        };
        
        WorldType = WORLD_TYPES.General;
        LoadLeaderboard = true;
        MaxPlayers = 6;
    };
    Tombs = {
        DisplayName = "Raid: Tombs";
        PlaceIds = {
            [LEGACY_GAME_ID] = 5515514657;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 5495827291;
        };
        
        WorldType = WORLD_TYPES.General;
        LoadLeaderboard = true;
        MaxPlayers = 6;
    };
    Railways = {
        DisplayName = "Raid: Railways";
        PlaceIds = {
            [LEGACY_GAME_ID] = 6570550977;
            [LIVE_GAME_ID] = 81205082701357;
            [DEV_GAME_ID] = 6491538349;
        };
        
        WorldType = WORLD_TYPES.General;
        LoadLeaderboard = true;
        MaxPlayers = 6;
    };
    AbandonedBunker = {
        DisplayName = "Raid: Abandoned Bunker";
        PlaceIds = {
            [LEGACY_GAME_ID] = 13543270317;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 12858416962;
        };
        
        WorldType = WORLD_TYPES.General;
        LoadLeaderboard = true;
        MaxPlayers = 6;
    };



    --MARK: Gamemode Coop
    Genesis = {
        DisplayName = "Coop: Genesis";
        PlaceIds = {
            [LEGACY_GAME_ID] = 7825169805;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 7431407555;
        };
        
        WorldType = WORLD_TYPES.General;
    };
    SunkenShip = {
        DisplayName = "Coop: Sunken Ship";
        PlaceIds = {
            [LEGACY_GAME_ID] = 11213276767;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 10523367357;
        };
    };
    CargoShip = {
        DisplayName = "Coop: Cargo Ship";
        PlaceIds = {
            [LEGACY_GAME_ID] = 81844970195036;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 18503534484;
        };
        
        WorldType = WORLD_TYPES.General;
    };



    --MARK: Cutscenes;
    TheBeginning = {
        DisplayName = "W.D. Bridge";
        PlaceIds = {
            [LEGACY_GAME_ID] = 464351538;
            [LIVE_GAME_ID] = 464351538;
            [DEV_GAME_ID] = 2126368003;
        };
        
        WorldType = WORLD_TYPES.Cutscene;
        MaxPlayers = 1;
    };
    AwokenTheBear = {
        DisplayName = "Mission: Awoken The Bear";
        PlaceIds = {
            [LEGACY_GAME_ID] = 4942807832;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 4887155779;
        };
        
        WorldType = WORLD_TYPES.Cutscene;
        MaxPlayers = 1;
    };
    VindictiveTreasure = {
        DisplayName = "Mission: Vindictive Treasure";
        PlaceIds = {
            [LEGACY_GAME_ID] = 5594212861;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 5556946607;
        };
        
        WorldType = WORLD_TYPES.Cutscene;
        MaxPlayers = 1;
    };
    TheInvestigation = {
        DisplayName = "Mission: The Investigation";
        PlaceIds = {
            [LEGACY_GAME_ID] = 6898757722;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 6881018371;
        };
        
        WorldType = WORLD_TYPES.Cutscene;
        TimeCycleEnabled = false;
        MaxPlayers = 1;
    };
    DoubleCross = {
        DisplayName = "Mission: Double Cross";
        PlaceIds = {
            [LEGACY_GAME_ID] = 10098877922;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 9672014875;
        };
        
        WorldType = WORLD_TYPES.Cutscene;
        TimeCycleEnabled = false;
        MaxPlayers = 1;
    };
    BanditsRecruitment = {
        DisplayName = "Mission: Bandits Recruitment";
        PlaceIds = {
            [LEGACY_GAME_ID] = 11906832290;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 11642377451;
        };
        
        WorldType = WORLD_TYPES.Cutscene;
        MaxPlayers = 1;
    };
    MedicalBreakthrough = {
        DisplayName = "Mission: Medical Breakthrough";
        PlaceIds = {
            [LEGACY_GAME_ID] = 15934332075;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 15877604745;
        };
        
        WorldType = WORLD_TYPES.General;
        MaxPlayers = 1;
    };



    --MARK: Events
    EasterButchery = {
        DisplayName = "Easter: Butchery";
        PlaceIds = {
            [LEGACY_GAME_ID] = 4861957178;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 4852144007;
        };
        
        WorldType = WORLD_TYPES.General;
        CanTravelTo = true;
        PublicWorld = true;
    };
    HalloweenBasement = {
        DisplayName = "Slaughterfest: Halloween Basement";
        PlaceIds = {
            [LEGACY_GAME_ID] = 5894210737;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 5884577465;
        };
        
        WorldType = WORLD_TYPES.General;
        CanTravelTo = true;
        TimeCycleEnabled = false;
        PublicWorld = true;
    };
    KlawsWorkshop = {
        DisplayName = "Winterfest: Mr. Klaw's Workshop";
        PlaceIds = {
            [LEGACY_GAME_ID] = 8407865225;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 8374649741;
        };
        
        WorldType = WORLD_TYPES.General;
    };
    Slaughterfest = {
        DisplayName = "Slaughterfest: Slaughter Woods";
        PlaceIds = {
            [LEGACY_GAME_ID] = 11319107048;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 11264091769;
        };

        WorldType = WORLD_TYPES.Slaughterfest;
        CanTravelTo = true;
        CanCreatePrivateServers = false;
        PublicWorld = true;
        MaxPlayers = 12;
    };


    
    --MARK: Experimental
    BioXResearch = {
        DisplayName = "Experimental: BioX Research Facility";
        PlaceIds = {
            [LEGACY_GAME_ID] = 4861955160;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 289213709;
        };

        WorldType = WORLD_TYPES.Dev;
        CanTravelTo = true;
        MaxPlayers = 10;
        PrivateWorld = true;
        Index = 0;
    };
    NekronsGambit = {
        DisplayName = "Arena: Nekron's Gambit";
        PlaceIds = {
            [LEGACY_GAME_ID] = 113036405627921;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 140550016869053;
        };

        WorldType = WORLD_TYPES.NekronsGambit;
        CanTravelTo = true;
        TimeCycleEnabled = false;
        MaxPlayers = 8;
        CanCreatePrivateServers = false;
        PublicWorld = true;
        WeatherCycle = false;
    };



    --MARK: Community Maps
    CommunityWaySide = {
        DisplayName = "Community: Way Side";
        PlaceIds = {
            [LEGACY_GAME_ID] = 11234483877;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 10976260433;
        };
        
        WeatherCycle = false;
        LoadLeaderboard = true;
    };
    CommunityFissionBay = {
        DisplayName = "Community: Fission Bay";
        PlaceIds = {
            [LEGACY_GAME_ID] = 2133546838;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 54152100;
        };
        
        WeatherCycle = false;
        LoadLeaderboard = true;
    };
    CommunityRooftops = {
        DisplayName = "Community: Rooftops";
        PlaceIds = {
            [LEGACY_GAME_ID] = 14896299784;
            [LIVE_GAME_ID] = 0;
            [DEV_GAME_ID] = 14504730660;
        };

        WeatherCycle = false;
        LoadLeaderboard = true;
    };
}



--MARK: Linked Worlds
local LINKED_WORLDS = {
	TheWarehouse = {"TheUnderground"; "TheResidentials"; "TheHarbor"};
	TheUnderground = {"TheWarehouse"; "TheMall"; "TheResidentials"; "TheHarbor"; "SectorE"};
	TheMall = {"TheUnderground"; "TheResidentials";};
	TheResidentials = {"TheWarehouse"; "TheUnderground"; "TheMall"; "TheHarbor";};
	TheHarbor = {"TheWarehouse"; "TheUnderground"; "TheResidentials";};
	SectorE = {"TheUnderground"}
};


--MARK: Spawn Library
local SPAWN_LIBRARY = {
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
		ratTunnelHarbor={};
	};
	TheHarbor={
		harborSh={};
		factToharbor={};
		sewersToharbor={};
		ratTunnelResdientials={};
	};
};


--MARK: Map Overviews
local MAP_OVERVIEWS = {
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


--MARK: Pathfinding Nav Links
local PATHFINDING_NAV_LINKS = {
	TheWarehouse={
		NavSundaySafehouse={
			Entrance="sundaysEntrance";
			Exit="sundaysExit";

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
}


--MARK: OnRequire
function modBranchConfigurations.onRequire()
	modBranchConfigurations.Live = {
		Name = "Live";
		Color = Color3.fromRGB(255, 60, 60);
	};
	
	modBranchConfigurations.Dev = {
		Name = "Dev";
		Color = Color3.fromRGB(27, 106, 23);
	};

    local SpecialEvent = modConfigurations.SpecialEvent;
    if SpecialEvent.Easter then
        SPAWN_LIBRARY.EasterButchery={
            EasterButchery2={};
        };
    end

    modBranchConfigurations.Worlds = WORLDS;
    modBranchConfigurations.SpawnLibrary = SPAWN_LIBRARY;
    modBranchConfigurations.LinkedWorlds = LINKED_WORLDS;
    modBranchConfigurations.MapOverviews = MAP_OVERVIEWS;
    modBranchConfigurations.PathfindingNavLinks = PATHFINDING_NAV_LINKS;

    local curWorldName = modBranchConfigurations.WorldName;
    local curWorldInfo = modBranchConfigurations.WorldInfo;

    if curWorldName == "BioXResearch" then
        PATHFINDING_NAV_LINKS.BioXResearch={
			NavSafehouse={ -- CurrentNav;
				Safehouse=true;

				Entrance="bioxMainExit";
				Exit="bioxMainExit";
			};
		};
    end

    if curWorldInfo.WorldType == WORLD_TYPES.General or curWorldInfo.WorldType == WORLD_TYPES.Dev then
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
        modConfigurations.Set("DisableReportMenu", true);
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
        modConfigurations.Set("DisableHurtFlinch", false);
        
        if curWorldInfo.PublicWorld then
            modConfigurations.Set("DisableUpdateLogs", false);
            modConfigurations.Set("SpawnProtectionTimer", 120);
            modConfigurations.Set("DisableMapItems", false);
            modConfigurations.Set("ExpireDeployables", true);
            modConfigurations.Set("NaturalSpawnLimit", 60);
            workspace:SetAttribute("RecomputePathThreshold", 1);
            
        else
            modConfigurations.Set("SpectateEnabled", true);
            
        end
        
        --== Server;
        modConfigurations.Set("DisableItemDrops", false);
        modConfigurations.Set("DisableExperienceGain", false);
        
        if curWorldInfo.Witherer == true then
            modConfigurations.Set("WithererSpawnLogic", true);
            
        end
        if curWorldInfo.WeatherCycle == false then
            modConfigurations.Set("DisableWeatherCycle", true);
        end
        if curWorldName == "Safehome" then
            modConfigurations.Set("AutoMarkEnemies", true);
        end

    elseif curWorldInfo.WorldType == WORLD_TYPES.Cutscene then
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
        modConfigurations.Set("DisableHurtFlinch", false);
        
    elseif curWorldInfo.WorldType == WORLD_TYPES.Menu then
        modConfigurations.Set("AllowFreecam", true);
        modConfigurations.Set("DisableLeaderboard", true);
        

    elseif curWorldInfo.WorldType == WORLD_TYPES.Slaughterfest then
        modConfigurations.Set("DisableHealthbar", false);
        modConfigurations.Set("DisableHotbar", true);
        modConfigurations.Set("CanQuickEquip", false);

        modConfigurations.Set("DefaultSprintMode", 2);
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
        modConfigurations.Set("DisablePinnedMission", false);
        
        modConfigurations.Set("DisableExperiencebar", false);
        modConfigurations.Set("RemoveForceFieldOnWeaponFire", true);
        modConfigurations.Set("DisableGearMods", true);
        modConfigurations.Set("DisableHurtFlinch", false);
        
        modConfigurations.Set("PvpMode", true);
        
        modConfigurations.Set("SpawnProtectionTimer", 5);
        modConfigurations.Set("TargetableEntities", {
            Humanoid=1;
            Zombie=1;
        });
        
        --== Server;
        modConfigurations.Set("DisableItemDrops", false);
        modConfigurations.Set("DisableNonMockEquip", true);
        modConfigurations.Set("DisableSkillTrees", true);
        
    elseif curWorldInfo.WorldType == WORLD_TYPES.NekronsGambit then
        modConfigurations.Set("DisableHealthbar", false);
        modConfigurations.Set("DisableHotbar", true);
        modConfigurations.Set("CanQuickEquip", false);

        modConfigurations.Set("DefaultSprintMode", 3);
        modConfigurations.Set("DisableSettingsMenu", false);
        modConfigurations.Set("DisableSocialMenu", false);
        modConfigurations.Set("DisableSquadInterface", false);
        modConfigurations.Set("DisableMajorNotifications", false);
        modConfigurations.Set("DisableDialogue", true);
        modConfigurations.Set("DisableMapMenu", true);
        modConfigurations.Set("DisableGoldMenu", false);
        modConfigurations.Set("DisableStatusHud", false);
        modConfigurations.Set("DisableEmotes", false);
        modConfigurations.Set("DisablePinnedMission", false);
        modConfigurations.Set("DisableInfoBubbles", false);
        
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
        modConfigurations.Set("DisableSkillTrees", true);
    end
        
    if curWorldName == "BioXResearch" then
        modConfigurations.Set("PvpMode", true);
        modConfigurations.Set("BaseWoundedDuration", 10);
        modConfigurations.Set("SpectateEnabled", true);
        modConfigurations.Set("DisableMapItems", false);
        --modConfigurations.Set("NaturalSpawnLimit", 10);
        
    elseif curWorldName == "Safehome" then
        modConfigurations.Set("DisableSafehomeMenu", false);
        modConfigurations.Set("DisableMapItems", false);
        
    elseif curWorldName == "SunkenShip" or curWorldName == "CargoShip" then
        local skyPhaseColors = modConfigurations.SkyPhaseColor;

        skyPhaseColors.Day = Color3.fromRGB(195, 219, 243);
        skyPhaseColors.Night = Color3.fromRGB(61, 66, 95);
        
        modConfigurations.FogRange.Start = 200;
        modConfigurations.FogRange.End = 1200;

    elseif curWorldName == "Slaughterfest" then
        local skyPhaseColors = modConfigurations.SkyPhaseColor;
        skyPhaseColors.Night = Color3.fromRGB(38, 47, 94);

    end

    modConfigurations.Set("AllowAimAssist", true);
end

return modBranchConfigurations;