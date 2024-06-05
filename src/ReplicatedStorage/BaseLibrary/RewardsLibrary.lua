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

end

return RewardsLibrary;