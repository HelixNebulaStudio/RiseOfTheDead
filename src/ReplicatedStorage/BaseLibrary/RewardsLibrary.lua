local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local ItemDropTypes = modGlobalVars.ItemDropsTypes;


local RewardsLibrary = {};
RewardsLibrary.__index = RewardsLibrary;
--== Script;
function RewardsLibrary:Init(super)
	
	super:Add{
		Id="RegionDrop:Mall Street";
		Rewards={
			{Type=ItemDropTypes.Tool; ItemId="wantedposter"; Values={WantedNpc="Kat";}; Chance=1/500;};
			{Type=ItemDropTypes.Tool; ItemId="wantedposter"; Values={WantedNpc="Rachel";}; Chance=1/500;};
		};
	};

	super:Add{
		Id="RegionDrop:Residential Street";
		Rewards={
			{Type=ItemDropTypes.Tool; ItemId="wantedposter"; Values={WantedNpc="Rafael";}; Chance=1/50;};
			{Type=ItemDropTypes.Tool; ItemId="wantedposter"; Values={WantedNpc="Scarlett";}; Chance=1/500;};
		};
	};

	super:Add{
		Id="RegionDrop:Harbor Crash Site";
		Rewards={
			{Type=ItemDropTypes.Tool; ItemId="wantedposter"; Values={WantedNpc="Jackie";}; Chance=1/50;};
			{Type=ItemDropTypes.Tool; ItemId="wantedposter"; Values={WantedNpc="Zoey";}; Chance=1/500;};
		};
	};


	-- MARK: Survival;
		--{Wave=13; ItemId="dualuziparts1"; Quantity=1; Chance=0.075;};
		--{Wave=13; ItemId="rechamber1216parts1"; Quantity=1; Chance=0.075;};
	super:Add{
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
			{Wave=15; ItemId="grandgarandbp"; Quantity=1; Chance=0.019;};
		};
		WaveBased=true;
	};

	super:Add{
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
			{Wave=15; ItemId="grandgarandbp"; Quantity=1; Chance=0.019;};
		};
		WaveBased=true;
	};

	super:Add{
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
			{Wave=15; ItemId="grandgarandbp"; Quantity=1; Chance=0.019;};
		};
		WaveBased=true;
	};
	

	super:Add{
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
	

	super:Add{
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
	super:Add{
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

	super:Add{
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

	super:Add{
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

	super:Add{
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

	super:Add{
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

	super:Add{
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


	super:Add{
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

	super:Add{
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

	super:Add{
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
	super:Add{
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

	super:Add{
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

	super:Add{
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

	super:Add{
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

	super:Add{
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

	super:Add{
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

	super:Add{
		Id="frostivus2024";
		Rewards={
			{ItemId="xmaspresent2024"; Quantity=1; Chance=1;}; -- TokensAmount=5;
		};
	};

end

return RewardsLibrary;