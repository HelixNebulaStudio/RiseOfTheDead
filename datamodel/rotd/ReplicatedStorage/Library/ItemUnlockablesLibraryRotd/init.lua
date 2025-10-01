local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local library = shared.require(game.ReplicatedStorage.Library.ItemUnlockablesLibrary);

--== Script;
function library.onRequire()
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

	library:Add{
		Id="maraudersmaskghastlyglow";
		ItemId="maraudersmask";
		Name="Ghastly Glow";
		
		BaseColor = Color3.fromRGB(0, 255, 255);
		Textures={
			["Handle"]="rbxassetid://137981872347228";
		};
		Materials={
			["Handle"]=Enum.Material.ForceField;
		};
		Effects={
			["Handle"]={
				spirits={Type="Spirits";};
			};
		};
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
		DefaultPackage=true;
		
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
			ColorMap="rbxassetid://95196813614980";
		};
		SurfaceAppearanceParent=script;
		Hidden=true;
	};

	library:Add{
		Id="ammopouchghastlyglow";
		ItemId="ammopouch";
		Name="Ghastly Glow";
		DefaultPackage=true;

		BaseColor = Color3.fromRGB(0, 255, 255);
		Materials={
			["Handle"]=Enum.Material.ForceField;
		};
		Textures={
			["Handle"]="rbxassetid://119595119577683";
		};
		Effects={
			["Handle"]={
				spirits={Type="Spirits";};
			};
		};
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
	
	library:Add{
		Id="xmassweatersnowflakeblue";
		ItemId="xmassweater";
		Name="Blue Snowflake";
		DefaultPackage=true;

		SurfaceAppearance={
			ColorMap="rbxassetid://136119813822195";
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
	
	--== MARK: militarygloves
	library:Add{
		Id="militarygloves";
		ItemId="militarygloves";
		Name="Default";
		DefaultPackage=true;
		
		SurfaceAppearance={
			ColorMap="rbxassetid://126976540991207";
		};
		SurfaceAppearanceParent=script;
	};
	
	library:Add{
		Id="militaryglovesfingerless";
		ItemId="militarygloves";
		Name="Fingerless";
		Icon="rbxassetid://113828757931793";
		PackageId="militaryglovesfingerless";
		Unlocked=true;
		
		SurfaceAppearance={
			ColorMap="rbxassetid://126976540991207";
		};
		SurfaceAppearanceParent=script;
	};

	--== MARK: scraparmor
	library:Add{
		Id="scraparmor";
		ItemId="scraparmor";
		Name="Default";
		DefaultPackage=true;
		
		Textures={
			["Handle"]="rbxassetid://8366768416";
		};
	};

	library:Add{
		Id="scraparmorcopper";
		ItemId="scraparmor";
		Name="Copper";
		Textures={
			["Handle"]="rbxassetid://7021770174";
		};
	};

	library:Add{
		Id="scraparmorbiox";
		ItemId="scraparmor";
		Name="BioX";
		Textures={
			["Handle"]="rbxassetid://8366899696";
		};
	};

	library:Add{
		Id="scraparmorcherryblossom";
		ItemId="scraparmor";
		Name="Cherry Blossom";
		Textures={
			["Handle"]="rbxassetid://12964120126";
		};
	};

	library:Add{
		Id="scraparmormissingtextures";
		ItemId="scraparmor";
		Name="Missing Textures";
		Textures={
			["Handle"]="rbxassetid://15241466985";
		};
	};

	library:Add{
		Id="scraparmorghastlyglow";
		ItemId="scraparmor";
		Name="Ghastly Glow";
		
		BaseColor = Color3.fromRGB(0, 255, 255);
		Textures={
			["Handle"]="rbxassetid://136877410416889";
		};
		Materials={
			["Handle"]=Enum.Material.ForceField;
		};
		Effects={
			["Handle"]={
				spirits={Type="Spirits";};
			};
		};
	};

	--== MARK: greytshirt
	library:Add{
		Id="greytshirt";
		ItemId="greytshirt";
		Name="Default";
		DefaultPackage=true;
		
		Textures={
			["UT"]="rbxassetid://1744912817";
			["LT"]="rbxassetid://1744912817";
			["LUA"]="rbxassetid://1744912817";
			["RUA"]="rbxassetid://1744912817";
		}
	};

	library:Add{
		Id="greytshirtblue";
		ItemId="greytshirt";
		Name="Blue Color";
		Textures={
			["UT"]="rbxassetid://6535180507";
			["LT"]="rbxassetid://6535180507";
			["LUA"]="rbxassetid://6535180507";
			["RUA"]="rbxassetid://6535180507";
		}
	};

	library:Add{
		Id="greytshirticyblue";
		ItemId="greytshirt";
		Name="Icy Blue Pattern";
		Textures={
			["UT"]="rbxassetid://8532590435";
			["LT"]="rbxassetid://8532590435";
			["LUA"]="rbxassetid://8532590435";
			["RUA"]="rbxassetid://8532590435";
		};
		Unlocked=true;
	};

	library:Add{
		Id="greytshirticyred";
		ItemId="greytshirt";
		Name="Icy Red Pattern";
		Textures={
			["UT"]="rbxassetid://8532645802";
			["LT"]="rbxassetid://8532645802";
			["LUA"]="rbxassetid://8532645802";
			["RUA"]="rbxassetid://8532645802";
		};
		Unlocked=true;
	};

	library:Add{
		Id="greytshirtcamo";
		ItemId="greytshirt";
		Name="Camo Pattern";
		Textures={
			["UT"]="rbxassetid://6534965799";
			["LT"]="rbxassetid://6534965799";
			["LUA"]="rbxassetid://6534965799";
			["RUA"]="rbxassetid://6534965799";
		}
	};

	--== MARK: prisonshirt
	library:Add{
		Id="prisonshirt";
		ItemId="prisonshirt";
		Name="Default";
		DefaultPackage=true;
		
		Textures={
			["UT"]="rbxassetid://2013710081";
			["LT"]="rbxassetid://2013710081";
			["LUA"]="rbxassetid://2013710081";
			["RUA"]="rbxassetid://2013710081";
		};
	};

	library:Add{
		Id="prisonshirtblue";
		ItemId="prisonshirt";
		Name="Blue";
		Textures={
			["UT"]="rbxassetid://6665638674";
			["LT"]="rbxassetid://6665638674";
			["LUA"]="rbxassetid://6665638674";
			["RUA"]="rbxassetid://6665638674";
		};
	};

	--== MARK: prisonpants
	library:Add{
		Id="prisonpants";
		ItemId="prisonpants";
		Name="Default";
		DefaultPackage=true;
		
		Textures={
			["LLL"]="rbxassetid://5627732537";
			["LUL"]="rbxassetid://5627732537";
			["RLL"]="rbxassetid://5627732537";
			["RUL"]="rbxassetid://5627732537";
		};
	};

	library:Add{
		Id="prisonpantsblue";
		ItemId="prisonpants";
		Name="Blue";
		Textures={
			["LLL"]="rbxassetid://6665658904";
			["LUL"]="rbxassetid://6665658904";
			["RLL"]="rbxassetid://6665658904";
			["RUL"]="rbxassetid://6665658904";
		};
	};

	--== MARK: bunnymanhead
	library:Add{
		Id="bunnymanhead";
		ItemId="bunnymanhead";
		Name="Default";
		DefaultPackage=true;
		
		Textures={
			["Handle"]="rbxassetid://50380653";
		};
	};

	library:Add{
		Id="bunnymanheadbenefactor";
		ItemId="bunnymanhead";
		Name="The Benefactor";
		Textures={
			["Handle"]="rbxassetid://6665865055";
		};
	};

	--== MARK: plankarmor
	library:Add{
		Id="plankarmor";
		ItemId="plankarmor";
		Name="Default";
		DefaultPackage=true;
		
		Textures={
			["Handle"]="rbxassetid://6952680257";
		};
	};

	library:Add{
		Id="plankarmormaple";
		ItemId="plankarmor";
		Name="Maple";
		Textures={
			["Handle"]="rbxassetid://6956425630";
		};
	};

	library:Add{
		Id="plankarmorash";
		ItemId="plankarmor";
		Name="Ash";
		Textures={
			["Handle"]="rbxassetid://6956426986";
		};
	};

	--== MARK: watch
	library:Add{
		Id="watch";
		ItemId="watch";
		Name="Default";
		DefaultPackage=true;
		
		Textures={
			["Handle"]="rbxassetid://6306893198";
		};
	};

	library:Add{
		Id="watchyellow";
		ItemId="watch";
		Name="Yellow";
		Textures={
			["Handle"]="rbxassetid://13021453507";
		};
	};

	--== MARK: inflatablebuoy
	library:Add{
		Id="inflatablebuoy";
		ItemId="inflatablebuoy";
		Name="Default";
		DefaultPackage=true;
		
		SurfaceAppearance={
			ColorMap="rbxassetid://10392911200";
		};
	};

	library:Add{
		Id="inflatablebuoyrat";
		ItemId="inflatablebuoy";
		Name="R.A.T.";
		SurfaceAppearance={
			ColorMap="rbxassetid://13021400982";
		};
	};


	--== MARK: tophat
	library:Add{
		Id="tophat";
		ItemId="tophat";
		Name="Default";
		DefaultPackage=true;
		
		Textures={
			["Handle"]="rbxassetid://7558531740";
		};
	};

	library:Add{
		Id="tophatgrey";
		ItemId="tophat";
		Name="Grey";
		Textures={
			["Handle"]="rbxassetid://7647933560";
		};
	};

	library:Add{
		Id="tophatpurple";
		ItemId="tophat";
		Name="Purple";
		Textures={
			["Handle"]="rbxassetid://7647969340";
		};
	};

	library:Add{
		Id="tophatred";
		ItemId="tophat";
		Name="Red";
		Textures={
			["Handle"]="rbxassetid://7647970841";
		};
	};

	library:Add{
		Id="tophatgold";
		ItemId="tophat";
		Name="Gold";
		Textures={
			["Handle"]="rbxassetid://7647971874";
		};
	};

	--== MARK: clownmask
	library:Add{
		Id="clownmask";
		ItemId="clownmask";
		Name="Default";
		DefaultPackage=true;
		
		Textures={
			["Handle"]="rbxassetid://7558506950";
		};
	};

	library:Add{
		Id="clownmaskus";
		ItemId="clownmask";
		Name="Star Spangled Banner";
		Textures={
			["Handle"]="rbxassetid://8367138629";
		};
	};

	library:Add{
		Id="clownmaskmissjoyful";
		ItemId="clownmask";
		Name="Miss Joyful";
		Textures={
			["Handle"]="rbxassetid://11269669005";
		};
	};

	--== MARK: disguisekit
	library:Add{
		Id="disguisekit";
		ItemId="disguisekit";
		Name="Default";
		DefaultPackage=true;
		
		Textures={
			["Handle"]="rbxassetid://8377407358";
		};
	};

	library:Add{
		Id="disguisekitxmas";
		ItemId="disguisekit";
		Name="Christmas";
		Textures={
			["Handle"]="rbxassetid://8377612797";
		};
	};

	library:Add{
		Id="disguisekitwhite";
		ItemId="disguisekit";
		Name="White";
		Textures={
			["Handle"]="rbxassetid://8377619853";
		};
	};

	--== MARK: zriceraskull
	library:Add{
		Id="zriceraskull";
		ItemId="zriceraskull";
		Name="Default";
		DefaultPackage=true;
		
		Textures={
			["Handle"]="rbxassetid://8377606395";
		};
	};

	library:Add{
		Id="zriceraskullinferno";
		ItemId="zriceraskull";
		Name="Inferno";
		Textures={
			["Handle"]="rbxassetid://8378276517";
		};
		Effects={
			["Handle"]={
				fire1={Type="Fire3"; Properties={ZOffset=0;}; AttachmentCFrame=CFrame.new(0.00879669189, -0.46296978, 0.129806519, 1, 1.75416548e-09, 4.95361885e-09, 1.75417059e-09, 0.777145982, -0.629320443, -4.95361663e-09, 0.629320443, 0.777145982)}
			}
		}
	};

	--== MARK: vexgloves
	library:Add{
		Id="vexgloves";
		ItemId="vexgloves";
		Name="Default";
		DefaultPackage=true;
		
		Textures={
			["LH"]="rbxassetid://7181335578";
			["RH"]="rbxassetid://7181335578";
		};
	};

	library:Add{
		Id="vexglovesinferno";
		ItemId="vexgloves";
		Name="Inferno";
		Textures={
			["LH"]="rbxassetid://13974317312";
			["RH"]="rbxassetid://13974317312";
		};
		Effects={
			["Handle"]={
				fire1={Type="Fire3"; Properties={ZOffset=0; LockedToPart=true; Rate=6;}; AttachmentCFrame=CFrame.new(0,0,0)}
			}
		}
	};


	--== MARK: survivorsbackpack
	library:Add{
		Id="survivorsbackpack";
		ItemId="survivorsbackpack";
		Name="Default";
		DefaultPackage=true;
		
		Textures={
			["Handle"]="rbxassetid://8948195578";
		};
	};

	library:Add{
		Id="survivorsbackpackgalaxy";
		Icon="rbxassetid://8948315976"; -- unlockable item does not exist;
		ItemId="survivorsbackpack";
		Name="Galaxy";
		Textures={
			["Handle"]="rbxassetid://8948365095";
		};
	};

	library:Add{
		Id="survivorsbackpackstreetart";
		ItemId="survivorsbackpack";
		Name="Street Art";
		Textures={
			["Handle"]="rbxassetid://17291375801";
		};
	};

	--== MARK: cultisthood

	library:Add{
		Id="cultisthood";
		ItemId="cultisthood";
		Name="Default";
		DefaultPackage=true;
		
		BaseColor=Color3.fromRGB(34, 36, 44);
	};

	library:Add{
		Id="cultisthoodnekros";
		ItemId="cultisthood";
		Name="Nekros";
		BaseColor=Color3.fromRGB(89, 0, 1);
	};

	--== MARK: skullmask

	library:Add{
		Id="skullmask";
		ItemId="skullmask";
		Name="Default";
		DefaultPackage=true;
		
		SurfaceAppearance={
			ColorMap="rbxassetid://11235294308";
		};
	};

	library:Add{
		Id="skullmaskgold";
		ItemId="skullmask";
		Name="Gold";
		SurfaceAppearance={
			ColorMap="rbxassetid://15007537005";
		};
	};
end

return library;