local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local ItemUnlockablesLibrary = {};
ItemUnlockablesLibrary.__index = ItemUnlockablesLibrary;
--== Script;
function ItemUnlockablesLibrary:Init(library)

	-- MARK: brownleatherboots
	library:Add{
		Id="brownleatherboots";
		ItemId="brownleatherboots";
		Name="Default";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://89618350805668";
		};
		SurfaceAppearanceParent=script;
	};
	
	library:Add{
		Id="brownleatherbootsclassic";
		ItemId="brownleatherboots";
		Name="Classic";
		Icon="rbxassetid://4866819545";
		PackageId="brownleatherbootsclassic";
		Unlocked=true;
		
		-- SurfaceAppearance={
		-- 	ColorMap="rbxassetid://81644359023125";
		-- };
		-- SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="brownleatherbootsblack";
		ItemId="brownleatherboots";
		Name="Black";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://102039474574433";
		};
		SurfaceAppearanceParent=script;
	};
	

	--== MARK: gasmask
	library:Add{
		Id="gasmask";
		ItemId="gasmask";
		Name="Default";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://6971951196";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="gasmaskwhite";
		ItemId="gasmask";
		Name="White";
		DefaultPackage=true;
		
		SurfaceAppearance={
			ColorMap="rbxassetid://7021561911";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="gasmaskblue";
		ItemId="gasmask";
		Name="Blue";
		DefaultPackage=true;
		
		SurfaceAppearance={
			ColorMap="rbxassetid://7021611834";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="gasmaskyellow";
		ItemId="gasmask";
		Name="Yellow";
		DefaultPackage=true;
		
		SurfaceAppearance={
			ColorMap="rbxassetid://7021613643";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="gasmaskunionjack";
		ItemId="gasmask";
		Name="The Union Jack";
		DefaultPackage=true;
		
		SurfaceAppearance={
			ColorMap="rbxassetid://7021629071";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="gasmaskxmas";
		ItemId="gasmask";
		Name="Christmas";
		DefaultPackage=true;
		
		SurfaceAppearance={
			ColorMap="rbxassetid://8402317276";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="gasmasksovietfumes";
		ItemId="gasmask";
		Name="Fumes Soviet Style";
		PackageId="gasmasksoviet";

		SurfaceAppearance={
			ColorMap="rbxassetid://17190882093";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="gasmaskfumes";
		ItemId="gasmask";
		Name="Fumes";
		Icon="rbxassetid://17205785572";
		DefaultPackage=true;
		Unlocked="gasmasksovietfumes";

		SurfaceAppearance={
			ColorMap="rbxassetid://17190882093";
		};
		SurfaceAppearanceParent=script;
	};
	

	--== MARK: hardhat
	library:Add{
		Id="hardhat";
		ItemId="hardhat";
		Name="Default";
		SurfaceAppearance={
			ColorMap="rbxassetid://12438886806";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="hardhatcherryblossom";
		ItemId="hardhat";
		Name="Cherry Blossom";
		SurfaceAppearance={
			ColorMap="rbxassetid://12964038910";
		};
		SurfaceAppearanceParent=script;
	};
	
	library:Add{
		Id="hardhatorigins";
		ItemId="hardhat";
		Name="Origins";
		SurfaceAppearance={
			ColorMap="rbxassetid://13974893205";
		};
		SurfaceAppearanceParent=script;
	};
	
	library:Add{
		Id="hardhatsilver";
		ItemId="hardhat";
		Name="Silver";
		Icon="rbxassetid://17485221629";
		SurfaceAppearance={
			ColorMap="rbxassetid://17484511066";
		};
		SurfaceAppearanceParent=script;
	};
	

	--== MARK: fedora
	library:Add{
		Id="fedora";
		ItemId="fedora";
		Name="Default";

		SurfaceAppearance={
			ColorMap="rbxassetid://14506983094";
		};
		SurfaceAppearanceParent=script;
	};
	
	library:Add{
		Id="fedorauvunwrapped";
		ItemId="fedora";
		Name="UV Unwrapped";
		SurfaceAppearance={
			ColorMap="rbxassetid://17275922615";
		};
		SurfaceAppearanceParent=script;
	};
	
	library:Add{
		Id="fedoraxmasred";
		ItemId="fedora";
		Name="Xmas Red";
		SurfaceAppearance={
			ColorMap="rbxassetid://118258193267734";
		};
		SurfaceAppearanceParent=script;
	};

	


	--== MARK: maraudersmask
	library:Add{
		Id="maraudersmask";
		ItemId="maraudersmask";
		Name="Default";
		SurfaceAppearance={
			ColorMap="rbxassetid://11269231309";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="maraudersmaskblue";
		ItemId="maraudersmask";
		Name="Blue";
		SurfaceAppearance={
			ColorMap="rbxassetid://11269776200";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="maraudersmaskcbspumpkins";
		ItemId="maraudersmask";
		Name="Cute But Scary Pumpkins";
		SurfaceAppearance={
			ColorMap="rbxassetid://15016807876";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="maraudersmaskrisingsun";
		ItemId="maraudersmask";
		Name="Rising Sun";
		SurfaceAppearance={
			ColorMap="rbxassetid://17218739245";
		};
		SurfaceAppearanceParent=script;
	};

	--== MARK: clothbagmask
	library:Add{
		Id="clothbagmask";
		ItemId="clothbagmask";
		Name="Default";
		SurfaceAppearance={
			ColorMap="rbxassetid://11636792480";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="clothbagmasksuits";
		ItemId="clothbagmask";
		Name="Suits";
		SurfaceAppearance={
			ColorMap="rbxassetid://13985379493";
		};
		SurfaceAppearanceParent=script;
	};
	
	library:Add{
		Id="clothbagmaskcbsskulls";
		ItemId="clothbagmask";
		Name="Cute But Scary Skulls";
		SurfaceAppearance={
			ColorMap="rbxassetid://15016704936";
		};
		SurfaceAppearanceParent=script;
	};

	--== MARK: clothbagmask
	library:Add{
		Id="balaclava";
		ItemId="balaclava";
		Name="Default";
		SurfaceAppearance={
			ColorMap="rbxassetid://8584457052";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="balaclavasuits";
		ItemId="balaclava";
		Name="Suits";
		SurfaceAppearance={
			ColorMap="rbxassetid://15032714416";
		};
		SurfaceAppearanceParent=script;
	};
	

	--== MARK: divinggoggles
	library:Add{
		Id="divinggoggles";
		ItemId="divinggoggles";
		Name="Default";
		SurfaceAppearance={
			ColorMap="rbxassetid://10332602803";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="divinggogglesyellow";
		ItemId="divinggoggles";
		Name="Yellow";
		SurfaceAppearance={
			ColorMap="rbxassetid://10333042522";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="divinggogglesred";
		ItemId="divinggoggles";
		Name="Red";
		SurfaceAppearance={
			ColorMap="rbxassetid://15008750665";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="divinggoggleswhite";
		ItemId="divinggoggles";
		Name="White";
		SurfaceAppearance={
			ColorMap="rbxassetid://17219382397";
		};
		SurfaceAppearanceParent=script;
	};
	

	--== MARK: divingsuit
	library:Add{
		Id="divingsuit";
		ItemId="divingsuit";
		Name="Default";
		SurfaceAppearance={
			ColorMap="rbxassetid://10332602803";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="divingsuitwhite";
		ItemId="divingsuit";
		Name="White";
		SurfaceAppearance={
			ColorMap="rbxassetid://10333042522";
		};
		SurfaceAppearanceParent=script;
	};

	--== MARK: divingsuit
	library:Add{
		Id="divingfins";
		ItemId="divingfins";
		Name="Default";
		SurfaceAppearance={
			ColorMap="rbxassetid://10334654033";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="divingfinswhite";
		ItemId="divingfins";
		Name="White";
		SurfaceAppearance={
			ColorMap="rbxassetid://17219623512";
		};
		SurfaceAppearanceParent=script;
	};


	--== MARK: leathergloves
	library:Add{
		Id="leathergloves";
		ItemId="leathergloves";
		Name="Default";
		DefaultPackage=true;
		
		SurfaceAppearance={
			ColorMap="rbxassetid://16987783752";
		};
		SurfaceAppearanceParent=script;
	};
	
	library:Add{
		Id="leatherglovesfingerless";
		ItemId="leathergloves";
		Name="Fingerless";
		Icon="rbxassetid://16988497955";
		PackageId="leatherglovesfingerless";
		Unlocked=true;
		
		SurfaceAppearance={
			ColorMap="rbxassetid://16987783752";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="leatherglovesred";
		ItemId="leathergloves";
		Name="Red";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://16994290100";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="leatherglovesfingerlessred";
		ItemId="leathergloves";
		Name="Red Fingerless";
		Icon="rbxassetid://16994347845";
		PackageId="leatherglovesfingerless";
		Unlocked="leatherglovesred";

		SurfaceAppearance={
			ColorMap="rbxassetid://16994290100";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="leatherglovesxmasred";
		ItemId="leathergloves";
		Name="Christmas Red Fingerless";
		PackageId="leatherglovesfingerless";

		SurfaceAppearance={
			ColorMap="rbxassetid://17032593553";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="leatherglovesxmasgreen";
		ItemId="leathergloves";
		Name="Christmas Green Fingerless";
		PackageId="leatherglovesfingerless";

		SurfaceAppearance={
			ColorMap="rbxassetid://17032694583";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="leatherglovesxmasrgb";
		ItemId="leathergloves";
		Name="Christmas RGB Fingerless";
		PackageId="leatherglovesfingerless";

		SurfaceAppearance={
			ColorMap="rbxassetid://17032694100";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="leatherglovesultraviolet";
		ItemId="leathergloves";
		Name="Ultra Violet";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://17275581702";
		};
		SurfaceAppearanceParent=script;
	};


	--== MARK: armwraps
	library:Add{
		Id="armwraps";
		ItemId="armwraps";
		Name="Default";
		Textures={
			["Handle"]="rbxassetid://5065128803";
		};
	};

	library:Add{
		Id="armwrapsrat";
		ItemId="armwraps";
		Name="R.A.T.";
		Textures={
			["Handle"]="rbxassetid://13021416490";
		};
	};

	library:Add{
		Id="armwrapsmissingtextures";
		ItemId="armwraps";
		Name="Missing Textures";
		Textures={
			["Handle"]="rbxassetid://13207941157";
		};
	};

	library:Add{
		Id="armwrapscbsghosts";
		ItemId="armwraps";
		Name="Cute But Scary Ghosts";
		Textures={
			["Handle"]="rbxassetid://15016743537";
		};
	};
	
	--== MARK: mercskneepads
	library:Add{
		Id="mercskneepads";
		ItemId="mercskneepads";
		Name="Default";
		SurfaceAppearance={
			ColorMap="rbxassetid://11026319430";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="mercskneepadswinterfest";
		ItemId="mercskneepads";
		Name="Frostivus";
		SurfaceAppearance={
			ColorMap="rbxassetid://11812673616";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="mercskneepadscarbonfiberblack";
		ItemId="mercskneepads";
		Name="Carbon Fiber Black";
		SurfaceAppearance={
			ColorMap="rbxassetid://17218604517";
		};
		SurfaceAppearanceParent=script;
	};

	
	--== MARK: militaryboots
	library:Add{
		Id="militaryboots";
		ItemId="militaryboots";
		Name="Default";
		SurfaceAppearance={
			ColorMap="rbxassetid://17022794454";
		};
		SurfaceAppearanceParent=script;
	};
	
	library:Add{
		Id="militarybootsdesert";
		ItemId="militaryboots";
		Name="Desert";
		SurfaceAppearance={
			ColorMap="rbxassetid://17022684376";
		};
		SurfaceAppearanceParent=script;
	};
	
	library:Add{
		Id="militarybootsforest";
		ItemId="militaryboots";
		Name="Forest";
		SurfaceAppearance={
			ColorMap="rbxassetid://17022751530";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="militarybootsgold";
		ItemId="militaryboots";
		Name="Gold";
		SurfaceAppearance={
			ColorMap="rbxassetid://17275081707";
		};
		SurfaceAppearanceParent=script;
	};
	
	
	--== MARK: highvisjacket
	library:Add{
		Id="highvisjacket";
		ItemId="highvisjacket";
		Name="Default";
		Textures={
			["LLA"]="rbxassetid://12653367270";
			["LT"]="rbxassetid://12653367270";
			["LH"]="rbxassetid://12653367270";
			["LUA"]="rbxassetid://12653367270";
			["RLA"]="rbxassetid://12653367270";
			["RUA"]="rbxassetid://12653367270";
			["UT"]="rbxassetid://12653367270";
		};
	};

	library:Add{
		Id="highvisjacketgalaxy";
		ItemId="highvisjacket";
		Icon="rbxassetid://12658731830";
		Name="Galaxy";
		Textures={
			["LLA"]="rbxassetid://12653382051";
			["LT"]="rbxassetid://12653382051";
			["LH"]="rbxassetid://12653382051";
			["LUA"]="rbxassetid://12653382051";
			["RLA"]="rbxassetid://12653382051";
			["RUA"]="rbxassetid://12653382051";
			["UT"]="rbxassetid://12653382051";
		};
	};

	library:Add{
		Id="highvisjacketfallenleaves";
		ItemId="highvisjacket";
		Name="Fallen Leaves";
		Textures={
			["LLA"]="rbxassetid://12964022505";
			["LT"]="rbxassetid://12964022505";
			["LH"]="rbxassetid://12964022505";
			["LUA"]="rbxassetid://12964022505";
			["RLA"]="rbxassetid://12964022505";
			["RUA"]="rbxassetid://12964022505";
			["UT"]="rbxassetid://12964022505";
		};
	};

	library:Add{
		Id="highvisjacketsuits";
		ItemId="highvisjacket";
		Name="Suits";
		Textures={
			["LLA"]="rbxassetid://17275781912";
			["LT"]="rbxassetid://17275781912";
			["LH"]="rbxassetid://17275781912";
			["LUA"]="rbxassetid://17275781912";
			["RLA"]="rbxassetid://17275781912";
			["RUA"]="rbxassetid://17275781912";
			["UT"]="rbxassetid://17275781912";
		};
	};
	
	--== MARK: nekrostrench
	library:Add{
		Id="nekrostrench";
		ItemId="nekrostrench";
		Name="Default";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://97925970473635";
		};
		SurfaceAppearanceParent=script;
	};
	
	library:Add{
		Id="nekrostrenchhoodie";
		ItemId="nekrostrench";
		Name="Hoodie";
		Icon="rbxassetid://14423236705";
		PackageId="nekrostrenchhoodie";
		Unlocked=true;
		
		SurfaceAppearance={
			ColorMap="rbxassetid://97925970473635";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="nekrostrenchhauntedpumpkin";
		ItemId="nekrostrench";
		Name="Haunted Pumpkin";
		DefaultPackage=true;
		
		SurfaceAppearance={
			ColorMap="rbxassetid://14971087352";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="nekrostrenchblue";
		ItemId="nekrostrench";
		Name="Blue";
		DefaultPackage=true;
		
		SurfaceAppearance={
			ColorMap="rbxassetid://17275838311";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="nekrostrenchgreen";
		ItemId="nekrostrench";
		Name="Green";
		DefaultPackage=true;
		
		SurfaceAppearance={
			ColorMap="rbxassetid://17275843895";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="nekrostrenchdarkcarbon";
		ItemId="nekrostrench";
		Icon="rbxassetid://";
		Name="Dark Carbon";
		DefaultPackage=true;
		
		SurfaceAppearance={
			ColorMap="rbxassetid://129799567178229";
		};
		SurfaceAppearanceParent=script;
		Hidden=true;
	};
	
	library:Add{
		Id="nekrostrenchblaze";
		ItemId="nekrostrench";
		Name="Blaze";
		DefaultPackage=true;
		
		SurfaceAppearance={
			ColorMap="rbxassetid://72472027526657";
		};
		SurfaceAppearanceParent=script;
	};
	

	--== MARK: tirearmor
	library:Add{
		Id="tirearmor";
		ItemId="tirearmor";
		Name="Default";
		SurfaceAppearance={
			ColorMap="rbxassetid://16791444963";
		};
		SurfaceAppearanceParent=script;
	};
	
	library:Add{
		Id="tirearmorred";
		ItemId="tirearmor";
		Name="Red";
		SurfaceAppearance={
			ColorMap="rbxassetid://16791551299";
		};
		SurfaceAppearanceParent=script;
	};
	
	library:Add{
		Id="tirearmorgoldplating";
		ItemId="tirearmor";
		Name="Gold Plating";
		SurfaceAppearance={
			ColorMap="rbxassetid://17248585652";
		};
		SurfaceAppearanceParent=script;
	};
	
	library:Add{
		Id="tirearmorhaunted";
		ItemId="tirearmor";
		Name="Haunted";
		SurfaceAppearance={
			ColorMap="rbxassetid://17248585652";
		};
		SurfaceAppearanceParent=script;
	};

	
	--== MARK: dufflebag
	library:Add{
		Id="dufflebag";
		ItemId="dufflebag";
		Name="Default";
		Textures={
			["Handle"]="rbxassetid://8827951970";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="dufflebageaster1";
		ItemId="dufflebag";
		Name="Easter Colors";
		Textures={
			["Handle"]="rbxassetid://8828356403";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="dufflebageaster2";
		ItemId="dufflebag";
		Name="Easter Stripes";
		Textures={
			["Handle"]="rbxassetid://8828358153";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="dufflebagstreetart";
		ItemId="dufflebag";
		Name="Street Art";
		Textures={
			["Handle"]="rbxassetid://8828360678";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="dufflebagvintage";
		ItemId="dufflebag";
		Name="Vintage";
		Textures={
			["Handle"]="rbxassetid://8828363019";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="dufflebagarticscape";
		ItemId="dufflebag";
		Name="Artic Scape";
		Textures={
			["Handle"]="rbxassetid://8828364639";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="dufflebagfirstaidgreen";
		ItemId="dufflebag";
		Name="Green First Aid";
		Textures={
			["Handle"]="rbxassetid://8828399132";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="dufflebaggalaxy";
		ItemId="dufflebag";
		Icon="rbxassetid://12658727687";
		Name="Galaxy";
		Textures={
			["Handle"]="rbxassetid://12658706749";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="dufflebagorigins";
		ItemId="dufflebag";
		Name="Origins";
		SurfaceAppearance={
			ColorMap="rbxassetid://13975329840";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="dufflebagfancy";
		ItemId="dufflebag";
		Name="Fancy";
		SurfaceAppearance={
			ColorMap="rbxassetid://17291191122";
		};
		SurfaceAppearanceParent=script;
	};


	--== MARK: ammopouch
	library:Add{
		Id="ammopouch";
		ItemId="ammopouch";
		Name="Default";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://105803584540454";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="ammopouchlegacy";
		ItemId="ammopouch";
		Name="Legacy";
		Icon="rbxassetid://7335420098";
		PackageId="ammopouchlegacy";

		SurfaceAppearance={
			ColorMap="rbxassetid://7335387705";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="ammopouchnight";
		ItemId="ammopouch";
		Name="Night";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://85622479449999";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="ammopouchhexcamo";
		ItemId="ammopouch";
		Name="Hex Camo";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://104364493766588";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="ammopouchdarkcarbon";
		ItemId="ammopouch";
		Icon="rbxassetid://98882966031889";
		Name="Dark Carbon";
		DefaultPackage=true;
		
		SurfaceAppearance={
			ColorMap="rbxassetid://93994020837531";
		};
		SurfaceAppearanceParent=script;
		Hidden=true;
	};


	--== MARK: nvg
	library:Add{
		Id="nvg";
		ItemId="nvg";
		Name="Default";
		SurfaceAppearance={
			ColorMap="rbxassetid://18300273818";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="nvghaunted";
		ItemId="nvg";
		Name="Haunted";
		SurfaceAppearance={
			ColorMap="rbxassetid://71176524889324";
		};
		SurfaceAppearanceParent=script;
	};


	--== MARK: jackolantern
	library:Add{
		Id="jackolantern";
		ItemId="jackolantern";
		Name="Default";
		SurfaceAppearance={
			ColorMap="rbxassetid://14951625583";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="jackolanternhaunted";
		ItemId="jackolantern";
		Name="Haunted";
		SurfaceAppearance={
			ColorMap="rbxassetid://126543190548570";
		};
		SurfaceAppearanceParent=script;
	};


	--== MARK: apron
	library:Add{
		Id="apron";
		ItemId="apron";
		Name="Default";
		SurfaceAppearance={
			ColorMap="rbxassetid://17382127448";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="aproncarnage";
		ItemId="apron";
		Name="Carnage";
		SurfaceAppearance={
			ColorMap="rbxassetid://78844705064427";
		};
		SurfaceAppearanceParent=script;
	};

	--== MARK: ninjacloak
	library:Add{
		Id="ninjacloak";
		ItemId="ninjacloak";
		Name="Default";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://95622409496577";
		};
		SurfaceAppearanceParent=script;
	};
	
	library:Add{
		Id="ninjacloaksleeveless";
		ItemId="ninjacloak";
		Name="Sleeveless";
		Icon="rbxassetid://117128086199919";
		PackageId="ninjacloaksleeveless";
		Unlocked=true;
		
		SurfaceAppearance={
			ColorMap="rbxassetid://95622409496577";
		};
		SurfaceAppearanceParent=script;
	};
	

	--== MARK: ninjashroud
	library:Add{
		Id="ninjashroud";
		ItemId="ninjashroud";
		Name="Default";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://81644359023125";
		};
		SurfaceAppearanceParent=script;
	};
	
	library:Add{
		Id="ninjashroudmaskless";
		ItemId="ninjashroud";
		Name="Maskless";
		Icon="rbxassetid://99934459977878";
		PackageId="ninjashroudmaskless";
		Unlocked=true;
		
		SurfaceAppearance={
			ColorMap="rbxassetid://81644359023125";
		};
		SurfaceAppearanceParent=script;
	};

	
	--== MARK: santahat
	library:Add{
		Id="santahat";
		ItemId="santahat";
		Name="Default";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://11812457660";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="santahatwinterfest";
		ItemId="santahat";
		Name="Frostivus";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://11812462035";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="santahatred";
		ItemId="santahat";
		Name="Red";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://139295262778673";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="santahatblue";
		ItemId="santahat";
		Name="Blue";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://75462174259764";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="santahatgreen";
		ItemId="santahat";
		Name="Green";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://132942094935098";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="santahatyellow";
		ItemId="santahat";
		Name="Yellow";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://99194637710200";
		};
		SurfaceAppearanceParent=script;
	};

	
	--== MARK: portableautoturret
	library:Add{
		Id="portableautoturret";
		ItemId="portableautoturret";
		Name="Default";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://16449106091";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="portableautoturretblue";
		ItemId="portableautoturret";
		Name="Blue";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://100775055891184";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="portableautoturretcryogenics";
		ItemId="portableautoturret";
		Name="Cryogenics";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://130868205619066";
		};
		SurfaceAppearanceParent=script;
	};

	--== MARK: brownbelt
	library:Add{
		Id="brownbelt";
		ItemId="brownbelt";
		Name="Default";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://1744577580";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="brownbeltwhite";
		ItemId="brownbelt";
		Name="White";

		SurfaceAppearance={
			ColorMap="rbxassetid://13021977407";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="brownbeltxmasorange";
		ItemId="brownbelt";
		Name="Xmas Orange";

		SurfaceAppearance={
			ColorMap="rbxassetid://134899340140097";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="brownbeltxmaspink";
		ItemId="brownbelt";
		Name="Xmas Pink";

		SurfaceAppearance={
			ColorMap="rbxassetid://124525857578516";
		};
		SurfaceAppearanceParent=script;
	};


	--== MARK: xmassweater
	library:Add{
		Id="xmassweater";
		ItemId="xmassweater";
		Name="Default";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://6125956699";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="xmassweatergreen";
		ItemId="xmassweater";
		Name="Green & Red";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://6538903022";
		};
		SurfaceAppearanceParent=script;
	};
	
	library:Add{
		Id="xmassweateryellow";
		ItemId="xmassweater";
		Name="Yellow & Blue";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://6538911498";
		};
		SurfaceAppearanceParent=script;
	};
	
	library:Add{
		Id="xmassweatersnowflakered";
		ItemId="xmassweater";
		Name="Red Snowflake";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://122563060145000";
		};
		SurfaceAppearanceParent=script;
	};
	
	library:Add{
		Id="xmassweatersnowflakegreen";
		ItemId="xmassweater";
		Name="Green Snowflake";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://86867273602934";
		};
		SurfaceAppearanceParent=script;
	};

	--== MARK: snowsledge
	library:Add{
		Id="snowsledge";
		ItemId="snowsledge";
		Name="Default";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://123967756810685";
		};
		SurfaceAppearanceParent=script;
	};

	library:Add{
		Id="snowsledgexmasgreen";
		ItemId="snowsledge";
		Name="Xmas";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://119355925160865";
		};
		SurfaceAppearanceParent=script;
	};
	

end

return ItemUnlockablesLibrary;