local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local ItemUnlockablesLibrary = {};
ItemUnlockablesLibrary.__index = ItemUnlockablesLibrary;
--== Script;
function ItemUnlockablesLibrary:Init(library)

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
			ColorMap="rbxassetid://14506983094";
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
			ColorMap="rbxassetid://14506983094";
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
end

return ItemUnlockablesLibrary;