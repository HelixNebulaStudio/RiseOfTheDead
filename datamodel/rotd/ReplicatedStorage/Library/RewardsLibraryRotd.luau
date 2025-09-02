local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibraryRotd);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);

local library = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);

local ItemDropTypes = modGlobalVars.ItemDropsTypes;

local bpItemDropChance = 1/100;
local quan2m4 = {Min=2; Max=4};
--==

function library.onRequire()
	library:Add{
		Id="RegionDrop:Mall Street";
		Rewards={
			{Type=ItemDropTypes.Tool; ItemId="wantedposter"; Values={WantedNpc="Kat";}; Chance=1/500;};
			{Type=ItemDropTypes.Tool; ItemId="wantedposter"; Values={WantedNpc="Rachel";}; Chance=1/500;};
		};
	};

	library:Add{
		Id="RegionDrop:Residential Street";
		Rewards={
			{Type=ItemDropTypes.Tool; ItemId="wantedposter"; Values={WantedNpc="Rafael";}; Chance=1/50;};
			{Type=ItemDropTypes.Tool; ItemId="wantedposter"; Values={WantedNpc="Scarlett";}; Chance=1/500;};
		};
	};

	library:Add{
		Id="RegionDrop:Harbor Crash Site";
		Rewards={
			{Type=ItemDropTypes.Tool; ItemId="wantedposter"; Values={WantedNpc="Jackie";}; Chance=1/50;};
			{Type=ItemDropTypes.Tool; ItemId="wantedposter"; Values={WantedNpc="Zoey";}; Chance=1/500;};
		};
	};


	-- MARK: Survival;
		--{Wave=13; ItemId="dualuziparts1"; Quantity=1; Chance=0.075;};
		--{Wave=13; ItemId="rechamber1216parts1"; Quantity=1; Chance=0.075;};
	library:Add{
		Id="corruptedsectorfcrate";
		Level=240;
		Rewards={
			{Wave=4; ItemId="stickygrenade"; Quantity=1; Chance=1;};
			{Wave=8; ItemId="apron"; Quantity=1; Chance=0.6;};
			{Wave=10; ItemId="skullburstmod"; Quantity=1; Chance=0.3;};
			{Wave=11; ItemId="hardhat"; Quantity=1; Chance=0.15;};
			{Wave=12; ItemId="boomerang"; Quantity=1; Chance=0.075;};
			{Wave=13; ItemId="grandgarandparts1"; Quantity=1; Chance=0.038;};
			{Wave=14; ItemId="ammopouch"; Quantity=1; Chance=0.019;};
			{Wave=15; ItemId="grandgarandbp"; Quantity=1; Chance=0.001;};
		};
		WaveBased=true;
	};

	library:Add{
		Id="corruptedprisoncrate";
		Level=300;
		Rewards={
			{Wave=4; ItemId="stickygrenade"; Quantity=1; Chance=1;};
			{Wave=8; ItemId="apron"; Quantity=1; Chance=0.6;};
			{Wave=10; ItemId="skullburstmod"; Quantity=1; Chance=0.3;};
			{Wave=11; ItemId="hardhat"; Quantity=1; Chance=0.15;};
			{Wave=12; ItemId="boomerang"; Quantity=1; Chance=0.075;};
			{Wave=13; ItemId="grandgarandparts2"; Quantity=1; Chance=0.038;};
			{Wave=14; ItemId="ammopouch"; Quantity=1; Chance=0.019;};
			{Wave=15; ItemId="grandgarandbp"; Quantity=1; Chance=0.001;};
		};
		WaveBased=true;
	};

	library:Add{
		Id="corruptedsectordcrate";
		Level=300;
		Rewards={
			{Wave=4; ItemId="stickygrenade"; Quantity=1; Chance=1;};
			{Wave=8; ItemId="apron"; Quantity=1; Chance=0.6;};
			{Wave=10; ItemId="skullburstmod"; Quantity=1; Chance=0.3;};
			{Wave=11; ItemId="hardhat"; Quantity=1; Chance=0.15;};
			{Wave=12; ItemId="boomerang"; Quantity=1; Chance=0.075;};
			{Wave=13; ItemId="grandgarandparts3"; Quantity=1; Chance=0.038;};
			{Wave=14; ItemId="ammopouch"; Quantity=1; Chance=0.019;};
			{Wave=15; ItemId="grandgarandbp"; Quantity=1; Chance=0.001;};
		};
		WaveBased=true;
	};
	

	library:Add{
		Id="npctask:foodscavenge";
		Rewards={
			{Index=1; ItemId="cannedbeans"; Quantity={Min=3; Max=6}; Chance=1;};
			{Index=1; ItemId="chocobar"; Quantity={Min=3; Max=6}; Chance=1;};
			{Index=1; ItemId="cannedfish"; Quantity=1; Chance=1/4;};
			{Index=1; ItemId="sandwich"; Quantity=1; Chance=1/4;};
			{Index=1; ItemId="bloxycola"; Quantity=1; Chance=1/8;};
			{Index=1; ItemId="annihilationsoda"; Quantity=1; Chance=1/8;};
			{Index=1; ItemId="energydrink"; Quantity=1; Chance=1/16;};
		};
	};
	

	library:Add{
		Id="npctask:componentscavenge";
		Rewards={
			{Index=1; ItemId="metalpipes"; Quantity={Min=1; Max=3}; Chance=1;};
			{Index=1; ItemId="igniter"; Quantity={Min=1; Max=3}; Chance=1;};
			{Index=1; ItemId="gastank"; Quantity={Min=1; Max=3}; Chance=1;};
			{Index=1; ItemId="gears"; Quantity={Min=1; Max=3}; Chance=1;};
			{Index=1; ItemId="battery"; Quantity=1; Chance=1/4;};
			{Index=1; ItemId="liquidmetalpolish"; Quantity=1; Chance=1/16;};
		};
	};

	--MARK: Holiday Rewards:
	library:Add{
		Id="easteregg";
		Rewards={
			{Index=1; ItemId="metal"; Quantity={Min=10; Max=20}; Chance=1;};
			{Index=1; ItemId="wood"; Quantity={Min=10; Max=20}; Chance=7/10;};
			{Index=1; ItemId="glass"; Quantity={Min=10; Max=20}; Chance=7/10;};
			
			{Index=1; ItemId="bunnyplush"; Quantity=1; Chance=7/10;};
			{Index=1; ItemId="coloreaster"; Quantity=1; Chance=1/5;};
			{Index=1; ItemId="skineaster"; Quantity=1; Chance=1/5;};
			{Index=1; ItemId="crowbar"; Quantity=1; Chance=1/5;};
			
			{Index=1; ItemId="m9legacy"; Quantity=1; Chance=4.7/100;};
		};
		SpecialEvent="Easter";
	};

	library:Add{
		Id="easteregg2021";
		Rewards={
			{Index=1; ItemId="metal"; Quantity={Min=10; Max=20}; Chance=1;};
			{Index=1; ItemId="wood"; Quantity={Min=10; Max=20}; Chance=6/10;};
			{Index=1; ItemId="glass"; Quantity={Min=10; Max=20}; Chance=6/10;};

			{Index=1; ItemId="m9legacy"; Quantity=1; Chance=6/10;};
			{Index=1; ItemId="crowbar"; Quantity=1; Chance=6/10;};
			{Index=1; ItemId="coloreaster"; Quantity=1; Chance=4/10;};
			{Index=1; ItemId="skineaster"; Quantity=1; Chance=4/10;};
			{Index=1; ItemId="dufflebageaster1"; Quantity=1; Chance=4/10;};
			{Index=1; ItemId="dufflebageaster2"; Quantity=1; Chance=4/10;};
			
			{Index=1; ItemId="chippyplush"; Quantity=1; Chance=10/100;};
		};
		SpecialEvent="Easter";
	};

	library:Add{
		Id="easteregg2023";
		Rewards={
			{Index=1; ItemId="m9legacy"; Quantity=1; Chance=1;};
			
			{Index=1; ItemId="hardhatcherryblossom"; Quantity=1; Chance=2/10;};
			{Index=1; ItemId="highvisjacketfallenleaves"; Quantity=1; Chance=2/10;};
			{Index=1; ItemId="scraparmorcherryblossom"; Quantity=1; Chance=2/10;};

			{Index=1; ItemId="liquidmetalpolish"; Quantity=1; Chance=4/10;};
			{Index=1; ItemId="skineaster2023"; Quantity=1; Chance=4/10;};
			
			{Index=1; ItemId="wantedposter"; Quantity=1; Chance=6/10;};
			{Index=1; ItemId="annihilationsoda"; Quantity=1; Chance=6/10;};

			{Index=1; ItemId="chippyplush"; Quantity=1; Chance=10/100;};
			{Index=1; ItemId="zriceraskullinferno"; Quantity=1; Chance=4/100;};
		};
		SpecialEvent="Easter";
	};

	library:Add{
		Id="xmaspresent";
		Rewards={
			{Index=1; ItemId="cloth"; Quantity={Min=10; Max=40}; Chance=1;};
			{Index=1; ItemId="gingerbreadman"; Quantity=1; Chance=1;};
			{Index=1; ItemId="eggnog"; Quantity=1; Chance=1;};
			
			{Index=1; ItemId="shotgunautomod"; Quantity=1; Chance=7/10;};
			{Index=1; ItemId="sniperpiercingmod"; Quantity=1; Chance=7/10;};
			{Index=1; ItemId="wood"; Quantity={Min=10; Max=20}; Chance=7/10;};
			{Index=1; ItemId="glass"; Quantity={Min=10; Max=20}; Chance=7/10;};
			{Index=1; ItemId="riflehyperdamagemod"; Quantity=1; Chance=1/2;};
			
			{Index=1; ItemId="m9legacy"; Quantity=1; Chance=8/100;};
		};
		SpecialEvent="Christmas";
	};

	library:Add{
		Id="xmaspresent2020";
		Rewards={
			{Index=1; ItemId="coal"; Quantity={Min=1; Max=2}; Chance=1;};
			{Index=1; ItemId="wood"; Quantity={Min=10; Max=20}; Chance=7/10;};
			{Index=1; ItemId="glass"; Quantity={Min=10; Max=20}; Chance=7/10;};
			{Index=1; ItemId="gps"; Quantity=1; Chance=7/10;};
			
			{Index=1; ItemId="gingerbreadman"; Quantity=1; Chance=1/4;};
			{Index=1; ItemId="eggnog"; Quantity=1; Chance=1/4;};

			{Index=1; ItemId="snowman"; Quantity=1; Chance=1/8;};
			{Index=1; ItemId="naughtycane"; Quantity=1; Chance=1/8;};
			{Index=1; ItemId="tomeoftweaks"; Quantity=1; Chance=1/8;};
			
			{Index=1; ItemId="xmassweater"; Quantity=1; Chance=8/100;};
			{Index=1; ItemId="santahat"; Quantity=1; Chance=8/100;};
			{Index=1; ItemId="greensantahat"; Quantity=1; Chance=1/1000;};
		};
		SpecialEvent="Christmas";
	};

	library:Add{
		Id="xmaspresent2021";
		Rewards={
			{Index=1; ItemId="coal"; Quantity={Min=1; Max=2}; Chance=1;};

			{Index=1; ItemId="snowman"; Quantity=1; Chance=1/4;};
			{Index=1; ItemId="disguisekitxmas"; Quantity=1; Chance=1/4;};
			{Index=1; ItemId="leatherglovesxmasred"; Quantity=1; Chance=1/4;};
			{Index=1; ItemId="leatherglovesxmasgreen"; Quantity=1; Chance=1/4;};
			{Index=1; ItemId="disguisekit"; Quantity=1; Chance=1/4;};
			{Index=1; ItemId="santahat"; Quantity=1; Chance=1/4;};
			
			{Index=1; ItemId="leatherglovesxmasrgb"; Quantity=1; Chance=1/8;};
			{Index=1; ItemId="gasmaskxmas"; Quantity=1; Chance=1/8;};
		};
		SpecialEvent="Christmas";
	};


	library:Add{
		Id="xmaspresent2022";
		Rewards={
			{Index=1; ItemId="snowballs"; Quantity=1; Chance=1;};
			{Index=1; ItemId="santahat"; Quantity=1; Chance=1;};
			{Index=1; ItemId="naughtycane"; Quantity=1; Chance=1;};

			{Index=1; ItemId="xmassweatergreen"; Quantity=1; Chance=1;};
			{Index=1; ItemId="xmassweateryellow"; Quantity=1; Chance=1;};
			
			{Index=1; ItemId="fotlcardgame"; Quantity=1; Chance=1/2;};
			{Index=1; ItemId="santahatwinterfest"; Quantity=1; Chance=1/2;};
			{Index=1; ItemId="mercskneepadswinterfest"; Quantity=1; Chance=1/4;};
			
		};
		SpecialEvent="Christmas";
	};

	library:Add{
		Id="xmaspresent2023";
		Rewards={
			{Index=1; ItemId="desolatorheavytoygun"; Quantity=1; Chance=1;};
			{Index=1; ItemId="czevo3asiimov"; Quantity=1; Chance=1;};
			{Index=1; ItemId="rusty48blaze"; Quantity=1; Chance=1;};
			{Index=1; ItemId="survivorsoutpostunlockpapers"; Quantity=1; Chance=1;};
			{Index=1; ItemId="bunkerunlockpapers"; Quantity=1; Chance=1;};
		};
		SpecialEvent="Christmas";
	};

	library:Add{
		Id="xmaspresent2024";
		Rewards={
			{Index=1; ItemId="santahatred"; Quantity=1; Chance=1;};
			{Index=1; ItemId="santahatblue"; Quantity=1; Chance=1;};
			{Index=1; ItemId="santahatgreen"; Quantity=1; Chance=1;};
			{Index=1; ItemId="santahatyellow"; Quantity=1; Chance=1;};
			{Index=1; ItemId="xmassweatersnowflakegreen"; Quantity=1; Chance=1;};
			{Index=1; ItemId="xmassweatersnowflakeblue"; Quantity=1; Chance=1;};
			{Index=1; ItemId="brownbeltxmaspink"; Quantity=1; Chance=1;};
			{Index=1; ItemId="ammopouchnight"; Quantity=1; Chance=1;};
			{Index=1; ItemId="ammopouchhexcamo"; Quantity=1; Chance=1;};
			{Index=1; ItemId="p250toygun"; Quantity=1; Chance=1;};
			{Index=1; ItemId="arelshiftcrossgingerbread"; Quantity=1; Chance=1;};
			{Index=1; ItemId="grandgarandornaments"; Quantity=1; Chance=1;};
			{Index=1; ItemId="portableautoturretblue"; Quantity=1; Chance=1;};
			{Index=1; ItemId="snowsledgexmasgreen"; Quantity=1; Chance=1;};
		};
		SpecialEvent="Christmas";
	};

	--MARK: Event Pass
	library:Add{
		Id="bpseason1";
		Rewards={
			{ItemId="metalpipes"; Quantity={Min=1; Max=3}; Chance=1;};
			{ItemId="wires"; Quantity={Min=1; Max=3}; Chance=1;};
			{ItemId="circuitboards"; Quantity={Min=1; Max=3}; Chance=1;};
			{ItemId="gears"; Quantity={Min=1; Max=3}; Chance=1;};
			{ItemId="rope"; Quantity={Min=1; Max=3}; Chance=1;};
			
			{ItemId="zricerahorn"; Quantity=1; Chance=0.5;};
			{ItemId="vexling"; Quantity=1; Chance=0.5;};
			{ItemId="nekronparticulatecache"; Quantity=1; Chance=0.5;};

			{ItemId="purplelemon"; Quantity=1; Chance=0.25;};
			{ItemId="tomeoftweaks"; Quantity=1; Chance=0.25;};
			
			{ItemId="clothbagmasksuits"; Quantity=1; Chance=0.125;};
		};
	};

	library:Add{
		Id="bphalloween1";
		Rewards={
			{ItemId="coal"; Quantity={Min=10; Max=15}; Chance=1;};
			{ItemId="sulfur"; Quantity={Min=10; Max=15}; Chance=1;};
			{ItemId="explosives"; Quantity=1; Chance=1;};
			{ItemId="gold"; Quantity=20; Chance=1;};

			{ItemId="divinggogglesred"; Quantity=1; Chance=0.5;};
			{ItemId="jackolantern"; Quantity=1; Chance=0.5;};
			{ItemId="sr308slaughterwoods"; Quantity=1; Chance=0.5;};
			{ItemId="nekrostrenchhauntedpumpkin"; Quantity=1; Chance=0.5;};
			{ItemId="armwrapscbsghosts"; Quantity=1; Chance=0.5;};
			{ItemId="skullmaskgold"; Quantity=1; Chance=0.5;};
			{ItemId="maraudersmaskcbspumpkins"; Quantity=1; Chance=0.5;};
			{ItemId="clothbagmaskcbsskulls"; Quantity=1; Chance=0.5;};
			{ItemId="vectorxpossession"; Quantity=1; Chance=0.5;};

			{ItemId="balaclavasuits"; Quantity=1; Chance=0.125;};
		};
	};

	library:Add{
		Id="bp5years";
		Rewards={
			{ItemId="coal"; Quantity={Min=10; Max=15}; Chance=1;};
			{ItemId="sulfur"; Quantity={Min=10; Max=15}; Chance=1;};
			{ItemId="explosives"; Quantity=1; Chance=1;};
			{ItemId="gold"; Quantity=20; Chance=1;};

			{ItemId="colorcustom"; Quantity=1; Chance=0.5; TokensAmount=2;};
			{ItemId="divinggoggleswhite"; Quantity=1; Chance=0.5; TokensAmount=2;};
			{ItemId="mercskneepadscarbonfiberblack"; Quantity=1; Chance=0.5; TokensAmount=2;};
			{ItemId="sr308horde"; Quantity=1; Chance=0.5; TokensAmount=2;};
			{ItemId="fedorauvunwrapped"; Quantity=1; Chance=0.5; TokensAmount=2;};
			{ItemId="maraudersmaskrisingsun"; Quantity=1; Chance=0.5; TokensAmount=2;};
			{ItemId="militarybootsgold"; Quantity=1; Chance=0.5; TokensAmount=2;};
			{ItemId="nekrostrenchgreen"; Quantity=1; Chance=0.5; TokensAmount=2;};
			{ItemId="nekrostrenchblue"; Quantity=1; Chance=0.5; TokensAmount=2;};

			{ItemId="highvisjacketsuits"; Quantity=1; Chance=0.125; TokensAmount=4;};
		};
	};

	library:Add{
		Id="slaughterfestcandybag";
		Rewards={
			{Index=1; ItemId="zombiejello"; Quantity={Min=1; Max=3}; Chance=1;};
			{Index=1; ItemId="eyeballgummies"; Quantity={Min=1; Max=3}; Chance=1;};
			{Index=1; ItemId="spookmallow"; Quantity={Min=1; Max=3}; Chance=1;};
			{Index=1; ItemId="cherrybloodbar"; Quantity={Min=1; Max=3}; Chance=1;};
			{Index=1; ItemId="wickedtaffy"; Quantity={Min=1; Max=3}; Chance=1;};

			{Index=2; ItemId="zombiejello"; Quantity={Min=1; Max=2}; Chance=1;};
			{Index=2; ItemId="eyeballgummies"; Quantity={Min=1; Max=2}; Chance=1;};
			{Index=2; ItemId="spookmallow"; Quantity={Min=1; Max=2}; Chance=1;};
			{Index=2; ItemId="cherrybloodbar"; Quantity={Min=1; Max=2}; Chance=1;};
			{Index=2; ItemId="wickedtaffy"; Quantity={Min=1; Max=2}; Chance=1;};

			{Index=3; ItemId="zombiejello"; Quantity=1; Chance=1;};
			{Index=3; ItemId="eyeballgummies"; Quantity=1; Chance=1;};
			{Index=3; ItemId="spookmallow"; Quantity=1; Chance=1;};
			{Index=3; ItemId="cherrybloodbar"; Quantity=1; Chance=1;};
			{Index=3; ItemId="wickedtaffy"; Quantity=1; Chance=1;};
		};
		SpecialEvent="Halloween";
	};

	library:Add{
		Id="slaughterfestcauldron";
		Rewards={
			{ItemId="skincutebutscary"; Quantity=1; Chance=1; Tier=1;};
			
			{ItemId="skincutebutscary"; Quantity=1; Chance=1; Tier=1;};
			{ItemId="clothbagmaskcbsskulls"; Quantity=1; Chance=1; Tier=1;};
			{ItemId="armwrapscbsghosts"; Quantity=1; Chance=1; Tier=1;};
			{ItemId="maraudersmaskcbspumpkins"; Quantity=1; Chance=1; Tier=1;};

			{ItemId="tophat"; Quantity=1; Chance=1; Tier=1;};
			{ItemId="clownmask"; Quantity=1; Chance=1; Tier=1;};
			{ItemId="skullmask"; Quantity=1; Chance=1; Tier=1;};
			{ItemId="maraudersmask"; Quantity=1; Chance=1; Tier=1;};

			{ItemId="sr308slaughterwoods"; Quantity=1; Chance=1; Tier=1;};
			
			{ItemId="nekrostrenchhauntedpumpkin"; Quantity=1/10; Chance=1; Tier=2;};
			{ItemId="skullmaskgold"; Quantity=1; Chance=1/10; Tier=2;};

			{ItemId="jackolantern"; Quantity=1; Chance=1/10; Tier=2;};
			{ItemId="clownmaskus"; Quantity=1; Chance=1/10; Tier=2;};
			{ItemId="clownmaskmissjoyful"; Quantity=1; Chance=1/10; Tier=2;};
			{ItemId="maraudersmaskblue"; Quantity=1; Chance=1/10; Tier=2;};
			{ItemId="tophatgrey"; Quantity=1; Chance=1/10; Tier=2;};
			{ItemId="tophatpurple"; Quantity=1; Chance=1/10; Tier=2;};
			{ItemId="tophatred"; Quantity=1; Chance=1/10; Tier=2;};
			
			{ItemId="maraudersmaskrisingsun"; Quantity=1; Chance=1/40; Tier=3;};
			{ItemId="tophatgold"; Quantity=1; Chance=1/40; Tier=3;};

			{ItemId="slaughterwoodsunlockpapers"; Quantity=1; Chance=1/100; Tier=4;};
			{ItemId="vectorxpossession"; Quantity=1; Chance=1/100; Tier=4;};

			{ItemId="skinhalloweenpixelart"; Quantity=1; Chance=1/10000; Tier=5;};
		};
		SpecialEvent="Halloween";
	};

	library:Add{
		Id="slaughterfestcandyrecipes2024";
		Rewards={
			{ItemId="jackolanternhaunted"; Quantity=1; Chance=1; Tier=1;};
			{ItemId="tirearmorhaunted"; Quantity=1; Chance=1; Tier=2;};
			{ItemId="nvghaunted"; Quantity=1; Chance=1; Tier=3;};

			{ItemId="brownleatherbootsblack"; Quantity=1; Chance=1; Tier=1;};
			{ItemId="aproncarnage"; Quantity=1; Chance=1; Tier=2;};
		};
		SpecialEvent="Halloween";
	};

	library:Add{
		Id="frostivus2024";
		Rewards={
			{ItemId="xmaspresent2024"; Quantity=1; Chance=1;}; -- TokensAmount=5;
		};
	};

	local ItemDropTypes = modGlobalVars.ItemDropsTypes;
	local SpecialEvent = modConfigurations.SpecialEvent;

	local isPrivateWorld = not modBranchConfigs.WorldInfo.PublicWorld;

	library:Add{
		Id="zombie";
		Name="Zombies";
		Rewards={
			{Type=ItemDropTypes.Metal; ItemId="metal"; Quantity=quan2m4; Chance=1/2.2;};
			{Type=ItemDropTypes.Cloth; ItemId="cloth"; Quantity=quan2m4; Chance=1/4;};
			{Type=ItemDropTypes.Tool; ItemId="cannedbeans"; Chance=1/24;};
			{Type=ItemDropTypes.Tool; ItemId="chocobar"; Chance=1/24;};
			{Type=ItemDropTypes.Blueprint; ItemId="pistolreloadspeedbp"; Chance=bpItemDropChance;};
			{Type=ItemDropTypes.Blueprint; ItemId="pistolammocapbp"; Chance=bpItemDropChance;};
			{Type=ItemDropTypes.Blueprint; ItemId="shotgunreloadspeedbp"; Chance=bpItemDropChance;};
			{Type=ItemDropTypes.Blueprint; ItemId="shotgunammocapbp"; Chance=bpItemDropChance;};
			(isPrivateWorld and {Type=ItemDropTypes.Screws; ItemId="screws"; Quantity={Min=4; Max=6}; Chance=1/3;} or nil);

			{Type=ItemDropTypes.Tool; ItemId="xm1014"; Chance=1/25; OnceOnly=true;};
			{Type=ItemDropTypes.Tool; ItemId="mp5"; Chance=1/100; OnceOnly=true;};
			
			--(SpecialEvent.Easter and {Type=ItemDropTypes.Tool; ItemId="easteregg2023"; Quantity=1; Chance=4/100;} or nil);
			--(SpecialEvent.Christmas and {Type=ItemDropTypes.Coal; Quantity=quan2m4; Chance=1/5;} or nil);
		};
	};

	library:Add{
		Id="leaperzombie";
		Name="Leaper Zombies";
		Rewards={
			{Type=ItemDropTypes.Screws; ItemId="screws"; Quantity={Min=10; Max=12}; Chance=1/4;};
			{Type=ItemDropTypes.Blueprint; ItemId="subdamagebp"; Chance=bpItemDropChance;};
			{Type=ItemDropTypes.Blueprint; ItemId="subfireratebp"; Chance=bpItemDropChance;};
			{Type=ItemDropTypes.Blueprint; ItemId="shotgundamagebp"; Chance=bpItemDropChance;};
			{Type=ItemDropTypes.Blueprint; ItemId="shotgunfireratebp"; Chance=bpItemDropChance;};
		};
	};

	library:Add{
		Id="tickszombie";
		Name="Ticks Zombies";
		Rewards={
			{Type=ItemDropTypes.Adhesive; Quantity={Min=10; Max=12}; Chance=1/4;};
			{Type=ItemDropTypes.Blueprint; ItemId="binocularsbp"; Chance=bpItemDropChance;};
			{Type=ItemDropTypes.Rope; Quantity={Min=2; Max=3}; Chance=1/100;};
			{Type=ItemDropTypes.MetalPipes; Quantity={Min=1; Max=1}; Chance=1/100;};
			{Type=ItemDropTypes.Igniter; Quantity={Min=1; Max=1}; Chance=1/100;};
			{Type=ItemDropTypes.GasTank; Quantity={Min=1; Max=1}; Chance=1/100;};
			{Type=ItemDropTypes.Tool; Quantity=1; ItemId="mk2grenade"; Chance=1/100;};
			
		};
	};

	library:Add{
		Id="heavyzombie";
		Name="Heavy Zombies";
		Rewards={
			{Type=ItemDropTypes.Blueprint; ItemId="barbedwoodenbp"; Chance=bpItemDropChance;};
			{Type=ItemDropTypes.Blueprint; ItemId="explosivedamagebp"; Chance=bpItemDropChance;};
			{Type=ItemDropTypes.Battery; Quantity={Min=1; Max=1}; Chance=1/100;};
			{Type=ItemDropTypes.Wires; Quantity={Min=1; Max=1}; Chance=1/100;};
			{Type=ItemDropTypes.Motor; Quantity={Min=1; Max=1}; Chance=1/100;};
		};
	};

	library:Add{
		Id="bloater";
		Name="Bloaters";
		Rewards={
			{Type=ItemDropTypes.Glass; Quantity={Min=10; Max=12}; Chance=1/4;};
			{Type=ItemDropTypes.Blueprint; ItemId="stickygrenadebp"; Chance=1/50;};
			{Type=ItemDropTypes.Igniter; Quantity={Min=1; Max=1}; Chance=1/100;};
		};
	};

	library:Add{
		Id="growler";
		Name="Growler";
		Rewards={
			{Type=ItemDropTypes.Wood; Quantity={Min=10; Max=12}; Chance=1/4;};
			{Type=ItemDropTypes.Tool; ItemId="molotov"; Chance=1/50;};
			{Type=ItemDropTypes.NekronScales; Quantity={Min=1; Max=2}; Chance=1/100;};
			{Type=ItemDropTypes.Battery; Quantity={Min=1; Max=1}; Chance=1/100;};
		};
	};

	library:Add{
		Id="tendrils";
		Name="Tendrils";
		Rewards={
			{Type=ItemDropTypes.Rope; Quantity={Min=3; Max=4}; Chance=1;};
			{Type=ItemDropTypes.NekronScales; Quantity={Min=10; Max=25}; Chance=1;};
		};
	};

	--== Bandits;
	library:Add{
		Id="bandit";
		Name="Bandits";
		Rewards={
			{Type=ItemDropTypes.Metal; Quantity=quan2m4; Chance=1/4;};
			{Type=ItemDropTypes.Cloth; Quantity=quan2m4; Chance=1/5;};
			{Type=ItemDropTypes.Glass; Quantity={Min=1; Max=2}; Chance=1/16;};
			{Type=ItemDropTypes.Wood; Quantity=quan2m4; Chance=1/16;};
			
			{Type=ItemDropTypes.Mod; ItemId="beltslotsmod"; Chance=1/32;};
		};
	};

	--== Crate Rewards;

	-- MARK: sundaysGift : 20
	library:Add{
		Id="sundaysGift";
		Level=20;
		Rewards={
			{Index=1; ItemId="metal"; Quantity=35; Chance=1;};
			{Index=2; ItemId="pistolhappyautomod"; Chance=1;};
		};
	};

	-- MARK: underbridgeGift : 50
	library:Add{
		Id="underbridgeGift";
		Level=50;
		Rewards={
			{Index=1; ItemId="shotgunhappyautomod"; Chance=1;};
			{Index=2; ItemId="gastank"; Quantity=1; Chance=1;};
		};
	};

	-- MARK: mallGift : 150
	library:Add{
		Id="mallGift";
		Level=150;
		Rewards={
			{Index=1; ItemId="energydrink"; Quantity=1; Chance=1;};
			{Index=2; ItemId="sniperskullcrackmod"; Chance=1;};
		};
	};

	-- MARK: clinicGift : 250
	library:Add{
		Id="clinicGift";
		Level=250;
		Rewards={
			{Index=1; ItemId="tomeoftweaks"; Quantity=1; Chance=1;};
			{Index=2; ItemId="energydrink"; Chance=1;};
		};
	};

	-- MARK: residentialGift : 300
	library:Add{
		Id="residentialGift";
		Level=300;
		Rewards={
			{Index=1; ItemId="liquidmetalpolish"; Quantity=4; Chance=1;};
			{Index=2; ItemId="fotlcardgame"; Chance=1;};
		};
	};

	-- MARK: harborGift : 380
	library:Add{
		Id="harborGift";
		Level=380;
		Rewards={
			{Index=1; ItemId="tomeoftweaks"; Quantity=1; Chance=1;};
			{Index=2; ItemId="vectorxbp"; Chance=1;};
		};
	};

	local modBpChance = 1/2;
	local weaponBpChance = 3/4;
	local componentChance = 1/3;
	local commodityChance = 1/3;

	-- MARK: prisoner : 1
	library:Add{
		Id="prisoner";
		Level=1;
		Rewards={
			{Index=1; ItemId="metal"; Quantity={Min=16; Max=25}; Chance=1;};
			{Index=1; ItemId="metalpipes"; Quantity=1; Chance=1;};
			{Index=1; ItemId="igniter"; Quantity=1; Chance=componentChance;};
			
			{Index=2; ItemId="subreloadspeedbp";  Chance=modBpChance;};
			{Index=2; ItemId="subammocapbp";  Chance=modBpChance;};
			{Index=2; ItemId="boomboxbp"; Quantity=1; Chance=commodityChance;};
			
			{Index=3; ItemId="tec9bp";  Chance=weaponBpChance;};
			{Index=3; ItemId="survivalknife";  Chance=3/10;};
			
			{Index=4; ItemId="prisonshirt"; HardMode=true; Chance=1;};
			{Index=4; ItemId="prisonpants"; HardMode=true; Chance=1;};
		};
	};

	-- MARK: tanker : 10
	library:Add{
		Id="tanker";
		Level=10;
		Rewards={
			{Index=1; ItemId="wood"; Quantity={Min=3; Max=8}; Chance=1;};
			{Index=1; ItemId="igniter"; Quantity=1; Chance=1;};
			{Index=1; ItemId="gastank"; Quantity=1; Chance=componentChance;};
			
			{Index=2; ItemId="shotgundamagebp"; Chance=modBpChance;};
			{Index=2; ItemId="shotgunfireratebp"; Chance=modBpChance;};
			{Index=2; ItemId="portablestovebp"; Quantity=1; Chance=commodityChance;};

			{Index=3; ItemId="sawedoffbp"; Chance=weaponBpChance;};

			{Index=4; ItemId="barbedmetalbp"; HardMode=true; Chance=1;};
		};
	};

	-- MARK: fumes : 20
	library:Add{
		Id="fumes";
		Level=20;
		Rewards={
			{Index=1; ItemId="glass"; Quantity={Min=3; Max=5}; Chance=1;};
			{Index=1; ItemId="gastank"; Quantity=1; Chance=1;};
			{Index=1; ItemId="battery"; Quantity=1; Chance=componentChance;};
			
			{Index=2; ItemId="subdamagebp";  Chance=modBpChance;};
			{Index=2; ItemId="subfireratebp";  Chance=modBpChance;};
			{Index=2; ItemId="lanternbp"; Quantity=1; Chance=commodityChance;};
			{Index=2; ItemId="chargerbp"; Quantity=1; Chance=commodityChance;};
			
			{Index=3; ItemId="mp7bp";  Chance=weaponBpChance;};

			{Index=4; ItemId="gasmasksovietfumes"; HardMode=true; Chance=1;};
		};
	};

	-- MARK: corrosive : 40
	library:Add{
		Id="corrosive";
		Level=40;
		Rewards={
			{Index=1; ItemId="glass"; Quantity={Min=4; Max=8}; Chance=1;};
			{Index=1; ItemId="battery"; Quantity=1; Chance=1;};
			{Index=1; ItemId="wires"; Quantity=1; Chance=componentChance;};
			
			{Index=2; ItemId="riflereloadspeedbp";  Chance=modBpChance;};
			{Index=2; ItemId="rifleammocapbp";  Chance=modBpChance;};
			
			{Index=3; ItemId="m4a4bp";  Chance=weaponBpChance;};
		};
	};

	-- MARK: zpider : 60
	library:Add{
		Id="zpider";
		Level=60;
		Rewards={
			{Index=1; ItemId="wood"; Quantity={Min=5; Max=12}; Chance=1;};
			{Index=1; ItemId="wires"; Quantity=1; Chance=1;};
			{Index=1; ItemId="motor"; Quantity=1; Chance=componentChance;};
			
			{Index=2; ItemId="sniperdamagebp";  Chance=modBpChance;};
			{Index=2; ItemId="sniperfireratebp";  Chance=modBpChance;};
			{Index=2; ItemId="sniperammocapbp";  Chance=modBpChance;};
			
			{Index=3; ItemId="awpbp";  Chance=weaponBpChance;};
		};
	};

	-- MARK: shadow : 80
	library:Add{
		Id="shadow";
		Level=80;
		Rewards={
			{Index=1; ItemId="glass"; Quantity={Min=7; Max=14}; Chance=1;};
			{Index=1; ItemId="motor"; Quantity=1; Chance=1;};
			{Index=1; ItemId="circuitboards"; Quantity=1; Chance=componentChance;};
			
			{Index=2; ItemId="handgeneratorbp";  Chance=commodityChance;};
			{Index=2; ItemId="hmgreloadspeedmod";  Chance=modBpChance;};
			{Index=2; ItemId="hmgammocapmod";  Chance=modBpChance;};
			{Index=2; ItemId="largemedkitbp";  Chance=modBpChance;};
			
			{Index=3; ItemId="minigunbp";  Chance=weaponBpChance;};
		};
	};

	-- MARK: zomborg : 110
	library:Add{
		Id="zomborg";
		Level=110;
		Rewards={
			{Index=1; ItemId="wood"; Quantity={Min=18; Max=26}; Chance=1;};
			{Index=1; ItemId="circuitboards"; Quantity=1; Chance=1;};
			{Index=1; ItemId="lightbulb"; Quantity=1; Chance=componentChance;};
			
			{Index=2; ItemId="walkietalkiebp";  Chance=commodityChance;};
			{Index=2; ItemId="pistolammomagmod";  Chance=modBpChance;};
			{Index=2; ItemId="flinchcushioning"; Chance=modBpChance;};
			
			{Index=3; ItemId="dualp250bp";  Chance=weaponBpChance;};
			{Index=3; ItemId="pickaxe";  Chance=3/10;};
		};
	};

	-- MARK: billies : 160
	library:Add{
		Id="billies";
		Level=160;
		Rewards={
			{Index=1; ItemId="glass"; Quantity={Min=14; Max=20}; Chance=1;};
			{Index=1; ItemId="lightbulb"; Quantity=1; Chance=1;};
			
			{Index=2; ItemId="spotlightbp";  Chance=commodityChance;};
			{Index=2; ItemId="explosivedamagebp";  Chance=modBpChance;};
			{Index=2; ItemId="explosiveammocapbp";  Chance=modBpChance;};
			
			{Index=3; ItemId="grenadelauncherbp";  Chance=weaponBpChance;};
			
			{Index=4; ItemId="strawhat"; HardMode=true; Chance=1;};
		};
	};

	-- MARK: hectorshot : 180
	library:Add{
		Id="hectorshot";
		Level=180;
		Rewards={
			{Index=1; ItemId="wood"; Quantity={Min=20; Max=38}; Chance=1;};
			{Index=1; ItemId="tires"; Quantity=1; Chance=1;};
			
			{Index=2; ItemId="walkietalkiebp";  Chance=commodityChance;};
			{Index=2; ItemId="labcoat";  Chance=modBpChance;};
			{Index=2; ItemId="edgeddamagebp";  Chance=modBpChance;};
			
			{Index=3; ItemId="revolver454bp";  Chance=weaponBpChance;};
			
			{Index=4; ItemId="cowboyhat"; HardMode=true; Chance=1;};
			{Index=4; ItemId="brownleatherboots"; HardMode=true; Chance=1;};
		};
	};

	-- MARK: zomborgprime : 280
	library:Add{
		Id="zomborgprime";
		Level=280;
		Rewards={
			{Index=1; ItemId="glass"; Quantity={Min=32; Max=45}; Chance=1;};
			{Index=1; ItemId="zricerahorn"; Quantity={Min=1; Max=2}; Chance=1;};
			
			{Index=2; ItemId="explosiveradiusmod"; Chance=modBpChance;};
			{Index=2; ItemId="riflecritmultimod"; Chance=modBpChance;};
			{Index=2; ItemId="sniperdmgrevmod"; Chance=modBpChance;};
			{Index=2; ItemId="circuitboards"; Quantity={Min=1; Max=3}; Chance=1;};
			
			{Index=3; ItemId="at4bp"; Chance=weaponBpChance;};
		};
	};

	library:Add{
		Id="wintertreelum";
		Rewards={
			{Index=1; ItemId="xmaspresent2022"; Quantity=1; Chance=1;};
		};
	};

	--==Extreme;

	-- MARK: zricera : 50
	library:Add{
		Id="zricera";
		Level=50;
		Rewards={
			{Index=1; Weekday="Monday"; ItemId="hmgdamagemod"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Tuesday"; ItemId="machete"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Wednesday"; ItemId="flamethrowerbp"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Thursday"; ItemId="pyroammocapbp"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Friday"; ItemId="flamethrowerbp"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Saturday"; ItemId="pyrodamagebp"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Sunday"; ItemId="pyrodamagebp"; Quantity=1; Chance=1;};

			{Index=2; ItemId="at4parts"; HardMode=true; Quantity=quan2m4; Chance=1;};
			{Index=2; ItemId="zriceraskull"; HardMode=true; Chance=1;};
		};
	};

	-- MARK: vexeron : 100
	library:Add{
		Id="vexeron";
		Level=100;
		Rewards={
			{Index=1; Weekday="Monday"; ItemId="riflehyperdamagemod"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Tuesday"; ItemId="shotgunautomod"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Wednesday"; ItemId="desolatorheavybp"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Thursday"; ItemId="smgcritmultimod"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Friday"; ItemId="desolatorheavybp"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Saturday"; ItemId="spikedbat"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Sunday"; ItemId="spikedbat"; Quantity=1; Chance=1;};
			
			{Index=2; ItemId="rifledmgrevmod"; HardMode=true; Chance=modBpChance;};
			{Index=2; ItemId="sr308parts"; HardMode=true; Quantity=quan2m4; Chance=1;};
		};
	};

	library:Add{
		Id="pathoroth";
		Rewards={
			{Type=ItemDropTypes.Tool; ItemId="annihilationsoda"; Chance=1/4;};
		};
	};

	-- MARK: mothena : 150
	library:Add{
		Id="mothena";
		Level=150;
		Rewards={
			{Index=1; Weekday="Monday"; ItemId="barbedwoodenbp"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Tuesday"; ItemId="pacifistamuletmod"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Wednesday"; ItemId="disguisekit"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Thursday"; ItemId="pacifistamuletmod"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Friday"; ItemId="disguisekit"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Saturday"; ItemId="dufflebag"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Sunday"; ItemId="dufflebag"; Quantity=1; Chance=1;};
			
			{Index=2; ItemId="vectorxparts"; Quantity=quan2m4; Chance=1;};
		};
	};

	-- MARK: banditheli : 200
	library:Add{
		Id="banditheli";
		Level=200;
		Rewards={
			{Index=1; Weekday="Monday"; ItemId="bluntdamagebp"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Tuesday"; ItemId="bluntknockbackmod"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Wednesday"; ItemId="rec21bp"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Thursday"; ItemId="shotgunslugmod"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Friday"; ItemId="rec21bp"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Saturday"; ItemId="broomspear"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Sunday"; ItemId="broomspear"; Quantity=1; Chance=1;};

			{Index=2; ItemId="shotgundeadeyemod"; HardMode=true; Chance=modBpChance;};
			{Index=2; ItemId="rusty48parts"; HardMode=true; Quantity=quan2m4; Chance=1;};
		};
	};

	-- MARK: : veinofnekron : 250
	library:Add{
		Id="veinofnekron";
		Level=250;
		Rewards={
			{Index=1; Weekday="Monday"; ItemId="shovel"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Tuesday"; ItemId="ammorecyclermod"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Wednesday"; ItemId="highvisjacket"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Thursday"; ItemId="shovel"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Friday"; ItemId="highvisjacket"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Saturday"; ItemId="smgshotsplittermod"; Quantity=1; Chance=1;};
			{Index=1; Weekday="Sunday"; ItemId="nekrosampmod"; Quantity=1; Chance=1;};
		};
	};

	--==Raid

	-- MARK: : factorycrate : 5
	library:Add{
		Id="factorycrate";
		Level=5;
		Rewards={
			{Index=1; ItemId="cannedbeans"; Quantity={Min=1; Max=2}; Chance=1;};

			{Index=2; ItemId="rifledamagebp"; Recyclable=true;  Chance=1;};
			{Index=2; ItemId="riflefireratebp"; Recyclable=true;  Chance=1;};
			{Index=2; ItemId="sniperfocusrate"; Recyclable=true;  Chance=1;};
			{Index=2; ItemId="metalpackage"; Recyclable=true;  Chance=1/8;};
		};
	};


	-- MARK: : officecrate : 30
	library:Add{
		Id="officecrate";
		Level=30;
		Rewards={
			{Index=1; ItemId="metalpipes"; Quantity=1; Chance=1;};
			{Index=1; ItemId="igniter"; Quantity=1; Chance=1;};
			{Index=1; ItemId="gastank"; Quantity=1; Chance=1;};
			
			{Index=2; ItemId="radiator"; Recyclable=true; Quantity=1; Chance=1/3;};
			{Index=2; ItemId="frostbp"; Recyclable=true; Quantity=1; Chance=0.5;};
			{Index=2; ItemId="riflehyperdamagemod"; Recyclable=true; Quantity=1; Chance=0.5;};
			{Index=2; ItemId="musicboxbp"; Recyclable=true; Quantity=1; Chance=0.5;};
		};
	};

	-- MARK: : tombschest : 120
	library:Add{
		Id="tombschest";
		Level=120;
		Rewards={
			{Index=1; ItemId="tacticalbowparts"; Quantity={Min=2; Max=3}; Chance=1;};
			
			{Index=2; ItemId="bowdamagebp"; Recyclable=true;  Chance=1;};
			{Index=2; ItemId="bowammocapbp"; Recyclable=true;  Chance=1;};
			{Index=2; ItemId="bowricochetmod"; Recyclable=true;  Chance=1/5;};
			
			{Index=3; ItemId="sledgehammer"; Recyclable=true;  Chance=1/2;};
			{Index=3; ItemId="onyxhoodie"; Recyclable=true;  Chance=1/100;};
			{Index=3; ItemId="onyxhoodiehood"; Recyclable=true;  Chance=1/1000;};
		};
	};

	-- MARK: railwayscrate : 260
	library:Add{
		Id="railwayscrate";
		Level=260;
		Rewards={
			{Index=1; ItemId="coal"; Quantity={Min=30; Max=60}; Chance=1;};
			
			{Index=2; ItemId="fnfalbp"; Recyclable=true; Chance=weaponBpChance;};
			{Index=2; ItemId="leathergloves"; Recyclable=true; Chance=weaponBpChance;};
			{Index=2; ItemId="gripmod"; Recyclable=true; Chance=modBpChance;};
			{Index=2; ItemId="swifthandsmod"; Recyclable=true; Chance=modBpChance;};
			{Index=2; ItemId="meleefurymod"; Recyclable=true; Chance=1/4;};
		};
	};

	-- MARK: banditcrate : 160
	library:Add{
		Id="banditcrate";
		Level=160;
		Rewards={
			{Index=1; ItemId="walkietalkiebp";  Chance=commodityChance;};
			
			{Index=1; ItemId="plankarmorbp"; Recyclable=true;  Chance=1;};
			{Index=1; ItemId="pointdamagebp"; Recyclable=true;  Chance=1;};
			{Index=1; ItemId="armorpointsmod"; Recyclable=true;  Chance=1/3;};
			{Index=1; ItemId="hmgrapidfiremod"; Recyclable=true;  Chance=1/3;};
			
			{Index=2; ItemId="nvg"; Recyclable=true;  Chance=1/100;};
		};
	};

	-- MARK: hbanditcrate : 360
	library:Add{
		Id="hbanditcrate";
		Level=300;
		Rewards={
			{Index=1; ItemId="scraparmorbp"; Recyclable=true; Chance=1;};

			{Index=1; ItemId="fireaxe"; Recyclable=true; Chance=1;};
			{Index=1; ItemId="warmongerscalesmod"; Recyclable=true; Chance=1/3;};
			{Index=1; ItemId="hmgrapidfiremod"; Recyclable=true; Chance=1/3;};
			{Index=1; ItemId="walkietalkiebp"; Chance=commodityChance;};

			{Index=1; ItemId="nvg"; Recyclable=true; Chance=3/100;};
		};
	};

	-- MARK: abandonedbunkercrate : 460
	library:Add{
		Id="abandonedbunkercrate";
		Level=300;
		Rewards={
			{Index=1; ItemId="rope"; Quantity={Min=1; Max=2}; Chance=1;};
			{Index=1; ItemId="abgreenkey"; Recyclable=true; Chance=1;};

			{Index=2; ItemId="arelshiftcrossbp"; Recyclable=true; Chance=weaponBpChance;};
			{Index=2; ItemId="newspaper"; Recyclable=true; Chance=1;};
			{Index=2; ItemId="bowdeadweightmod"; Recyclable=true; Chance=1;};
			{Index=2; ItemId="blacklightstick"; Recyclable=true; Chance=1;};
			
			{Index=3; ItemId="abandonedbunkermap"; Recyclable=true; Chance=1;};
		};
	};

	library:Add{
		Id="world1crates";
		Rewards={
			
		};
	};

	--== Survival;

	-- MARK: sectorfcrate : 50
	library:Add{
		Id="sectorfcrate";
		Level=50;
		Rewards={
			{Index=1; ItemId="advmedkit"; Quantity=1; Chance=1;};
			{Index=1; ItemId="battery"; Quantity=1; Chance=1;};
			{Index=1; ItemId="wires"; Quantity=1; Chance=1;};
			
			{Index=2; ItemId="toxiccontainer"; Recyclable=true; Quantity=1; Chance=0.4;};
			{Index=2; ItemId="toxicbp"; Recyclable=true; Quantity=1; Chance=0.3;};
			{Index=2; ItemId="brownbeltbp"; Recyclable=true; Quantity=1; Chance=0.3;};
			{Index=2; ItemId="subskullcrackmod"; Recyclable=true; Quantity=1; Chance=0.3;};

			{Index=3; ItemId="ak47bp"; Recyclable=true; Quantity=1; Chance=weaponBpChance;};
		};
	};

	-- MARK: ucsectorfcrate : 220
	library:Add{
		Id="ucsectorfcrate";
		Level=220;
		Rewards={
			{Index=1; ItemId="crowbar"; Recyclable=true; Quantity=1; Chance=1;};
			{Index=1; ItemId="militarybootsbp"; Recyclable=true; Quantity=1; Chance=0.7;};
			{Index=1; ItemId="gasmask"; Recyclable=true; Quantity=1; Chance=0.7;};
			{Index=1; ItemId="rifledmgcalibremod"; Recyclable=true; Quantity=1; Chance=0.7;};
			{Index=1; ItemId="subdmgcalibremod"; Recyclable=true; Quantity=1; Chance=0.7;};

			{Index=2; ItemId="czevo3bp"; Recyclable=true; Quantity=1; Chance=0.5;};
		};
	};

	-- MARK: prisoncrate : 140
	library:Add{
		Id="prisoncrate";
		Level=140;
		Rewards={
			{Index=1; ItemId="advmedkit"; Quantity=1; Chance=1;};
			{Index=1; ItemId="bloxycola"; Quantity=1; Chance=1/3;};
			{Index=1; ItemId="disguisekit"; Quantity=1; Chance=1/3;};

			{Index=2; ItemId="matchbox"; Recyclable=true; Quantity=1; Chance=1/3;};
			{Index=2; ItemId="molotov"; Recyclable=true; Quantity=1; Chance=0.4;};

			{Index=3; ItemId="mariner590bp"; Recyclable=true; Quantity=1; Chance=weaponBpChance;};
		};
	};

	-- MARK: nprisoncrate : 320
	library:Add{
		Id="nprisoncrate";
		Level=300;
		Rewards={
			{Index=1; ItemId="motor"; Quantity={Min=1; Max=2}; Chance=1;};

			{Index=2; ItemId="smgcritmultimod"; Recyclable=true; Quantity=1; Chance=1;};
			{Index=2; ItemId="thornmod"; Recyclable=true; Quantity=1; Chance=1/3;};
			{Index=2; ItemId="pyroeverlastmod"; Recyclable=true; Quantity=1; Chance=1/3;};

			{Index=3; ItemId="deaglebp"; Recyclable=true; Quantity=1; Chance=weaponBpChance;};
		};
	};

	-- MARK: sectordcrate : 240
	library:Add{
		Id="sectordcrate";
		Level=240;
		Rewards={
			{Index=1; ItemId="cannedfish"; Quantity={Min=1; Max=2}; Chance=1;};
			{Index=1; ItemId="mk2grenade"; Quantity=1; Chance=1;};
			
			{Index=2; ItemId="bluntknockoutmod"; Recyclable=true; Quantity=1; Chance=1;};
			{Index=2; ItemId="healthmod"; Recyclable=true; Quantity=1; Chance=1;};
			{Index=2; ItemId="vexling"; Recyclable=true; Quantity={Min=1; Max=2}; Chance=1;};
			{Index=2; ItemId="vexgloves"; Recyclable=true; Quantity=1; Chance=0.5;};
		};
	};


	-- MARK: ucsectordcrate : 420
	library:Add{
		Id="ucsectordcrate";
		Level=300;
		Rewards={
			{Index=1; ItemId="wires"; Quantity={Min=1; Max=2}; Chance=1;};
			
			{Index=2; ItemId="armwraps"; Recyclable=true; Quantity=1; Chance=1;};
			{Index=2; ItemId="riflecritmultimod"; Recyclable=true; Quantity=1; Chance=1;};
			{Index=2; ItemId="sr308bp"; Recyclable=true; Quantity=1; Chance=1;};
			{Index=2; ItemId="hazmathood"; Recyclable=true; Quantity=1; Chance=1/100;};
		};
	};


	--== Coop;
	-- MARK: genesiscrate : 220
	library:Add{
		Id="genesiscrate";
		Level=220;
		Rewards={
			{Index=1; ItemId="battery"; Quantity={Min=1; Max=3}; Chance=1;};

			{Index=2; ItemId="explosives"; Recyclable=true; Quantity=1; Chance=1/3;};
			{Index=2; ItemId="smgdeadeyemod"; Recyclable=true; Quantity=1; Chance=1/3;};
			{Index=2; ItemId="ticksnaretrapbp"; Recyclable=true; Quantity=1; Chance=1/3;};
			{Index=2; ItemId="chainsawbp"; Recyclable=true; Quantity=1; Chance=1;};
		};
	};

	-- MARK: ggenesiscrate : 440
	library:Add{
		Id="ggenesiscrate";
		Level=300;
		Rewards={
			{Index=1; ItemId="battery"; Quantity={Min=1; Max=3}; Chance=1;};

			{Index=2; ItemId="rusty48bp"; Recyclable=true; Quantity=1; Chance=1;};
			{Index=2; ItemId="engineersplanner"; Recyclable=true; Quantity=1; Chance=1;};
			{Index=2; ItemId="sniperpiercingmod"; Recyclable=true; Quantity=1; Chance=1/3;};
			{Index=2; ItemId="tirearmorbp"; Recyclable=true; Quantity=1; Chance=1;};
		};
	};


	-- MARK: sunkenchest : 300
	library:Add{
		Id="sunkenchest";
		Level=300;
		Rewards={
			{Index=1; ItemId="gears"; Quantity={Min=2; Max=3}; Chance=1;};
			
			{Index=2; ItemId="divingfins"; Recyclable=true; Quantity=1; Chance=1/3;};
			{Index=2; ItemId="divingsuit"; Recyclable=true; Quantity=1; Chance=1/3;};
			{Index=2; ItemId="inflatablebuoy"; Recyclable=true; Quantity=1; Chance=1/3;};
			{Index=2; ItemId="shotgundualshellmod"; Recyclable=true; Quantity=1; Chance=1/5;};

			{Index=3; ItemId="cultisthoodnekros"; Recyclable=true; Quantity=1; Chance=1/100;};
		};
	};

	-- MARK: zenithcrate : maxlevel
	library:Add{
		Id="zenithcrate";
		Level=math.round(modGlobalVars.MaxLevels-100);
		Rewards={
			{Index=1; ItemId="ziphoningserum"; Quantity=1; Chance=1;};
			{Index=1; ItemId="mendingmod"; Quantity=1; Chance=1;};
			
			{Index=2; ItemId="armwrapsmissingtextures"; Quantity=1; Chance=1/100;};
			{Index=2; ItemId="scraparmormissingtextures"; Quantity=1; Chance=1/100;};
		};
	};

	--== Special area;

	library:Add{
		Id="ab:greenroomdrop";
		Name="Abandoned Bunker: Green Room";
		Rewards={
			{Type=ItemDropTypes.Mod; ItemId="launchertriplethreatmod"; Quantity=1; Chance=1;};
		};
	};

	library:Add{
		Id="ab:darkroomdrop";
		Name="Abandoned Bunker: Dark Room";
		Rewards={
			{Type=ItemDropTypes.Mod; ItemId="rocketmanmod"; Quantity=1; Chance=1;};
			{Type=ItemDropTypes.Tool; ItemId="arelshiftcrossparts"; Chance=1;};
		};
	};

	library:Add{
		Id="ab:arelshiftpartsdrop";
		Name="Abandoned Bunker: Arelshift Cross Parts";
		Rewards={
			{Type=ItemDropTypes.Tool; ItemId="arelshiftcrossparts"; Chance=1;};
		};
	};

	library:Add{
		Id="ab:isolationdrop";
		Name="Abandoned Bunker: Isolation Room";
		Rewards={
			{Type=ItemDropTypes.Mod; ItemId="flamethrowerflameburstmod"; Quantity=1; Chance=1;};
			{Type=ItemDropTypes.Blueprint; ItemId="nekrostrenchbp"; Chance=1;};
		};
	};



	--== Community;
	library:Add{
		Id="communitycrate";
		Rewards={
			{Index=1; ItemId="advmedkit"; Quantity=1; Chance=1;};
			{Index=1; ItemId="gears"; Quantity={Min=1; Max=3}; Chance=1;};
			{Index=1; ItemId="liquidmetalpolish"; Quantity=2; Chance=1;};
			
			{Index=2; ItemId="explosives"; Recyclable=true; Quantity=1; Chance=1;};
			{Index=2; ItemId="fotlcardgame"; Recyclable=true; Quantity=1; Chance=1;};
			{Index=2; ItemId="mercskneepads"; Recyclable=true; Quantity=1; Chance=1/4;};
			{Index=2; ItemId="hardhat"; Recyclable=true; Quantity=1; Chance=1/4;};
			{Index=2; ItemId="lasso"; Recyclable=true; Quantity=1; Chance=1/100;};
		};
	};

	library:Add{
		Id="communitycrate2";
		Rewards={
			{Index=1; ItemId="advmedkit"; Quantity=1; Chance=1;};
			{Index=1; ItemId="gears"; Quantity={Min=1; Max=3}; Chance=1;};
			{Index=1; ItemId="liquidmetalpolish"; Quantity=2; Chance=1;};
			
			{Index=2; ItemId="sandwich"; Recyclable=true; Quantity=1; Chance=1/2;};
			{Index=2; ItemId="skinwindtrails"; Recyclable=true; Quantity=1; Chance=1/4;};
			{Index=2; ItemId="fedora"; Recyclable=true; Quantity=1; Chance=1/100;};
		};
	};


	--==Environment
	library:Add{ -- Randomly spawned
		Id="lootTier1";
		Name="Tier 1 Environment Loot";
		Rewards={
			{Type=ItemDropTypes.Tool; ItemId="cannedbeans"; Chance=1;};
			{Type=ItemDropTypes.Tool; ItemId="cannedfish"; Chance=1;};
			{Type=ItemDropTypes.Tool; ItemId="bloxycola"; Chance=1;};
			{Type=ItemDropTypes.PurpleLemon; ItemId="purplelemon"; Chance=1;};
			
			(SpecialEvent.AprilFools and {Type=ItemDropTypes.Tool; ItemId="rubberchicken"; Chance=1;} or nil);
			(SpecialEvent.Easter and {Type=ItemDropTypes.Tool; ItemId="easteregg2023"; Chance=1;} or nil);
		};
	};

	--== Safehome;
	library:Add{
		Id="safehomeMedic";
		Rewards={
			{Name="Nicole"; Chance=1;};
			{Name="Jackson"; Chance=1;};
			{Name="Rachel"; Chance=1/2;};
			{Name="Sullivan"; Chance=1/2;};
			{Name="Kat"; Chance=1/10;};
		};
	};

	library:Add{
		Id="safehomeNpcs";
		Rewards={
			{Name="Nicole"; Chance=1;};
			{Name="Jackson"; Chance=1;};
			{Name="Jackie"; Chance=1;};
			{Name="Berry"; Chance=1;};
			
			{Name="Rachel"; Chance=1/2;};
			{Name="Sullivan"; Chance=1/2;};
			{Name="Zoey"; Chance=1/2;};
			{Name="Rafael"; Chance=1/2;};
			
			{Name="Scarlett"; Chance=1/5;};
			
			{Name="Kat"; Chance=1/10;};
			{Name="Lydia"; Chance=1/10;};
		};
	};

	--== Misc;
	library:Add{
		Id="t1Vending";
		Name="Tier 1 Vending Machine";
		Rewards={
			{Index=1; ItemId="bloxycola"; Chance=1;};
			{Index=1; ItemId="mk2grenade"; Chance=1;};
			{Index=1; ItemId="liquidmetalpolish"; Chance=0.25;};
			{Index=1; ItemId="largemedkit"; Chance=0.75;};
			{Index=1; ItemId="fireworks"; Chance=0.5;};
			{Index=1; ItemId="beachball"; Chance=0.25;};
			{Index=1; ItemId="energydrink"; Chance=0.04;};
		};
	};

	library:Add{
		Id="michaelkills";
		Rewards={
			{Type=ItemDropTypes.Metal; Quantity={Min=1; Max=2}; Chance=1/20;};
		};
		IgnoreScan=true;
	};

	library:Add{
		Id="FallenTree";
		Name="Fallen Tree";
		Rewards={
			{Index=1; ItemId="wood"; Quantity={Min=5; Max=30}; Chance=1;};
		};
	};

	library:Add{
		Id="empty";
		Name="empty";
		Rewards={};
	};

	library:Add{
		Id="HalloweenCandyCauldron";
		Rewards={
			--{Index=1; Value=200; ItemId="clownmask"; Quantity=1; Chance=1;};
			--{Index=2; Value=500; ItemId="clownmaskmissjoyful"; Quantity=1; Chance=1;};
			--{Index=3; Value=800; ItemId="skullmask"; Quantity=1; Chance=1;};
			--{Index=4; Value=1200; ItemId="maraudersmask"; Quantity=1; Chance=1;};
			--{Index=5; Value=1500; ItemId="maraudersmaskblue"; Quantity=1; Chance=1;};
		};
	};


	--== Resource Packages
	local resourcePackagesLib = modItemsLibrary.Library:ListByKeyValue("ResourceItemId", function(v) return v ~= nil; end);
	for a=1, #resourcePackagesLib do
		local itemLib = resourcePackagesLib[a];
		local resourceItemId = itemLib.ResourceItemId;
		local resourceItemLib = modItemsLibrary:Find(resourceItemId);
		
		library:Add{
			Hidden=true;
			Id=itemLib.Id;
			Rewards={
				{Index=1; ItemId=resourceItemId; Quantity=resourceItemLib.Stackable; Chance=1;};
			};
		};
	end


	--== Define recyclable;
	for id, data in pairs(library.Library) do
		for a=1, #data.Rewards do
			if data.Rewards[a] and data.Rewards[a].ItemId and data.Rewards[a].Recyclable then
				local itemId = data.Rewards[a].ItemId;
				local itemLib = modItemsLibrary:Find(itemId);
				
				if itemLib then
					itemLib.Recyclable = true;
					if itemLib.CrateList == nil then
						itemLib.CrateList = {};
					end
					table.insert(itemLib.CrateList, id);
					
				else
					Debugger:Warn("Missing recyclable item ", itemId);
					
				end
				
			end
		end
	end
end

return library;