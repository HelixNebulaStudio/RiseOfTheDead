local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local BattlePassLibrary = {};
BattlePassLibrary.__index = BattlePassLibrary;
--==

local function newTree(list)
	local lastLvl = list[#list].Index;

	local emptyTable = {Empty=true;};
	local tree = table.create(lastLvl, emptyTable);

	for a=1, #list do
		local index = list[a].Index;
		tree[index] = list[a];
	end

	return tree;
end
local function leaf(index, data)
	data = data or {};

	data.Index = index;

	return data;
end

function BattlePassLibrary:Init(library)
	library.Active = "bp5years";
	
	-- MARK: BP Season 1
	library:Add{
		Id="bpseason1";
		EndUnixTime=1693526400;

		Title="Apocalypse Origins";
		Icon="rbxassetid://13890447995";
		Desc="Unlock the Apocalypse Origin Mission Pass to claim more rewards!";
		
		PremiumPrice=1250;
		Price=2490;
		
		Tree = newTree{
			leaf(0, {
				Reward={ItemId="survivorsoutpostunlockpapers"; PassOwner=true;};
			});
			leaf(3, {
				Reward={ItemId="metal"; Quantity=100;};
			});
			leaf(6, {
				Reward={ItemId="fotlcardgame";};
			});
			leaf(9, {
				Reward={ItemId="tomeoftweaks"; RequiresPremium=true;};
			});
			leaf(12, {
				Reward={ItemId="brownbeltwhite";};
			});
			leaf(15, {
				Reward={ItemId="woodpackage";};
			});
			leaf(18, {
				Reward={ItemId="divinggogglesyellow"; PassOwner=true;};
			});
			leaf(21, {
				Reward={ItemId="skinstreetart";};
			});
			leaf(24, {
				Reward={ItemId="leatherglovesred";};
			});
			leaf(27, {
				Reward={ItemId="tomeoftweaks"; RequiresPremium=true;};
			});
			leaf(30, {
				Reward={ItemId="annihilationsoda";};
			});
			leaf(33, {
				Reward={ItemId="fireworks"; Quantity=3;};
			});
			leaf(36, {
				Reward={ItemId="watchyellow"; PassOwner=true;};
			});
			leaf(39, {
				Reward={ItemId="glasspackage";};
			});
			leaf(42, {
				Reward={ItemId="energydrink";};
			});
			leaf(45, {
				Reward={ItemId="disguisekitwhite"; PassOwner=true;};
			});
			leaf(48, {
				Reward={ItemId="tomeoftweaks";};
			});
			leaf(51, {
				Reward={ItemId="woodpackage";};
			});
			leaf(54, {
				Reward={ItemId="rusty48blaze"; RequiresPremium=true;};
			});
			leaf(57, {
				Reward={ItemId="armwrapsrat";};
			});
			leaf(60, {
				Reward={ItemId="glasspackage";};
			});
			leaf(63, {
				Reward={ItemId="tomeoftweaks"; PassOwner=true;};
			});
			leaf(66, {
				Reward={ItemId="liquidmetalpolish"; Quantity=3;};
			});
			leaf(69, {
				Reward={ItemId="fireworks"; Quantity=3;};
			});
			leaf(72, {
				Reward={ItemId="tomeoftweaks"; RequiresPremium=true;};
			});
			leaf(75, {
				Reward={ItemId="hardhatorigins";};
			});
			leaf(78, {
				Reward={ItemId="energydrink";};
			});
			leaf(81, {
				Reward={ItemId="tomeoftweaks"; PassOwner=true;};
			});
			leaf(84, {
				Reward={ItemId="fireworks"; Quantity=3;};
			});
			leaf(87, {
				Reward={ItemId="energydrink";};
			});
			leaf(90, {
				Reward={ItemId="clothbagmask"; RequiresPremium=true;};
			});
			leaf(93, {
				Reward={ItemId="liquidmetalpolish"; Quantity=3;};
			});
			leaf(96, {
				Reward={ItemId="militarybootsforest";};
			});
			leaf(99, {
				Reward={ItemId="dufflebagorigins"; PassOwner=true;};
			});
			leaf(100, {
				Reward={ItemId="vexglovesinferno";};
			});
		};
	};
	
	-- MARK: BP Halloween 1
	library:Add{
		Id="bphalloween1";
		EndUnixTime=1698796800;

		Title="Slaughter Fest 2023";
		Icon="rbxassetid://15034446263";
		Desc="Unlock the Slaughter Fest Pass to claim more rewards!";

		PremiumPrice=250;
		Price=250;

		Tree = newTree{
			leaf(0, {
				Reward={ItemId="slaughterwoodsunlockpapers"; PassOwner=true;};
			});
			--
			leaf(3, {
				Reward={ItemId="metal"; Quantity=100;};
			});
			leaf(6, {
				Reward={ItemId="divinggogglesred";};
			});
			leaf(9, {
				Reward={ItemId="tomeoftweaks"; RequiresPremium=true;};
			});
			leaf(12, {
				Reward={ItemId="jackolantern";};
			});
			leaf(15, {
				Reward={ItemId="woodpackage";};
			});
			leaf(18, {
				Reward={ItemId="ammobox"; PassOwner=true;};
			});
			leaf(21, {
				Reward={ItemId="colorhellsfire";};
			});
			leaf(24, {
				Reward={ItemId="skullmask";};
			});
			leaf(27, {
				Reward={ItemId="tomeoftweaks"; RequiresPremium=true;};
			});
			leaf(30, {
				Reward={ItemId="sr308slaughterwoods";};
			});
			leaf(33, {
				Reward={ItemId="annihilationsoda";};
			});
			leaf(36, {
				Reward={ItemId="nekrostrenchhauntedpumpkin"; PassOwner=true;};
			});
			leaf(39, {
				Reward={ItemId="glasspackage";};
			});
			leaf(42, {
				Reward={ItemId="energydrink";};
			});
			leaf(45, {
				Reward={ItemId="tomeoftweaks"; PassOwner=true;};
			});
			leaf(48, {
				Reward={ItemId="skincutebutscary";};
			});
			leaf(51, {
				Reward={ItemId="woodpackage";};
			});
			leaf(54, {
				Reward={ItemId="armwrapscbsghosts"; RequiresPremium=true;};
			});
			leaf(57, {
				Reward={ItemId="sandwich";};
			});
			leaf(60, {
				Reward={ItemId="glasspackage";};
			});
			leaf(63, {
				Reward={ItemId="skullmaskgold"; PassOwner=true;};
			});
			leaf(66, {
				Reward={ItemId="liquidmetalpolish"; Quantity=3;};
			});
			leaf(69, {
				Reward={ItemId="fireworks"; Quantity=3;};
			});
			leaf(72, {
				Reward={ItemId="tomeoftweaks"; RequiresPremium=true;};
			});
			leaf(75, {
				Reward={ItemId="sandwich";};
			});
			leaf(78, {
				Reward={ItemId="energydrink";};
			});
			leaf(81, {
				Reward={ItemId="maraudersmaskcbspumpkins"; PassOwner=true;};
			});
			leaf(84, {
				Reward={ItemId="fireworks"; Quantity=3;};
			});
			leaf(87, {
				Reward={ItemId="energydrink";};
			});
			leaf(90, {
				Reward={ItemId="clothbagmask"; RequiresPremium=true;};
			});
			leaf(93, {
				Reward={ItemId="liquidmetalpolish"; Quantity=3;};
			});
			leaf(96, {
				Reward={ItemId="clothbagmaskcbsskulls";};
			});
			leaf(99, {
				Reward={ItemId="vectorxpossession"; PassOwner=true;};
			});
			leaf(100, {
				Reward={ItemId="gold"; Quantity=250;};
			});
		};
	};

	-- MARK: BP 5 Years Anniversary
	library:Add{
		Id="bp5years";
		EndUnixTime=1722470400;

		Title="5 Years Anniversary";
		Icon="rbxassetid://17271606182";
		Desc="Unlock the 5 Years Anniversary Pass to claim more rewards!";

		PremiumPrice=250;
		Price=500;

		Tree = newTree{
			leaf(0, {
				Reward={
					ItemId="wantedposter";
					ItemNameOverwrite = "Lydia Wanted Poster";
					ItemDescriptionOverwrite = "A poster for when you are looking for Lydia. This item can be given to Patrick to guarantee her as the next survivor in \"Another Survivor\".";
					Data={Values={WantedNpc="Lydia";}};
					PassOwner=true;
				};
			});
			--
			leaf(3, {
				Reward={ItemId="metal"; Quantity=100;};
			});
			leaf(6, {
				Reward={ItemId="divinggoggleswhite";};
			});
			leaf(9, {
				Reward={ItemId="leatherglovesultraviolet"; RequiresPremium=true;};
			});
			leaf(12, {
				Reward={ItemId="sr308horde";};
			});
			leaf(15, {
				Reward={ItemId="ammobox";};
			});
			leaf(18, {
				Reward={ItemId="tomeoftweaks"; PassOwner=true;};
			});
			leaf(21, {
				Reward={ItemId="tirearmorred";};
			});
			leaf(24, {
				Reward={
					ItemId="colorcustom";
					Data={Values={Color="ff3c3c";}};
					ItemNameOverwrite = "Rise of the Dead: Red Color";
				};
			});
			leaf(27, {
				Reward={ItemId="tomeoftweaks"; RequiresPremium=true;};
			});
			leaf(30, {
				Reward={ItemId="maraudersmask";};
			});
			leaf(33, {
				Reward={ItemId="annihilationsoda";};
			});
			leaf(36, {
				Reward={ItemId="militarybootsgold"; PassOwner=true;};
			});
			leaf(39, {
				Reward={ItemId="mercskneepadscarbonfiberblack";};
			});
			leaf(42, {
				Reward={ItemId="energydrink";};
			});
			leaf(45, {
				Reward={ItemId="tomeoftweaks"; PassOwner=true;};
			});
			leaf(48, {
				Reward={ItemId="maraudersmaskrisingsun";};
			});
			leaf(51, {
				Reward={ItemId="woodpackage";};
			});
			leaf(54, {
				Reward={ItemId="divingfinswhite"; RequiresPremium=true;};
			});
			leaf(57, {
				Reward={ItemId="sandwich";};
			});
			leaf(60, {
				Reward={ItemId="glasspackage";};
			});
			leaf(63, {
				Reward={ItemId="divingsuitwhite"; PassOwner=true;};
			});
			leaf(66, {
				Reward={ItemId="liquidmetalpolish"; Quantity=3;};
			});
			leaf(69, {
				Reward={ItemId="fireworks"; Quantity=3;};
			});
			leaf(72, {
				Reward={ItemId="tomeoftweaks"; RequiresPremium=true;};
			});
			leaf(75, {
				Reward={ItemId="sandwich";};
			});
			leaf(78, {
				Reward={ItemId="energydrink";};
			});
			leaf(81, {
				Reward={ItemId="deaglecryogenics"; PassOwner=true;};
			});
			leaf(84, {
				Reward={ItemId="fireworks"; Quantity=3;};
			});
			leaf(87, {
				Reward={ItemId="energydrink";};
			});
			leaf(90, {
				Reward={ItemId="fedora"; RequiresPremium=true;};
			});
			leaf(93, {
				Reward={ItemId="liquidmetalpolish"; Quantity=3;};
			});
			leaf(96, {
				Reward={ItemId="flamethrowerblaze";};
			});
			leaf(99, {
				Reward={ItemId="tirearmorgoldplating"; PassOwner=true;};
			});
			leaf(100, {
				Reward={ItemId="gold"; Quantity=250;};
			});
		};
	};
	
end


return BattlePassLibrary;