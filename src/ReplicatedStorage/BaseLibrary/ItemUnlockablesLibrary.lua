local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local ItemUnlockablesLibrary = {};
ItemUnlockablesLibrary.__index = ItemUnlockablesLibrary;
--== Script;
function ItemUnlockablesLibrary:Init(library)

	--== gasmask
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
	

	--== hardhat
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

	--== clothbagmask
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

	--== clothbagmask
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
	
	--== leathergloves
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
	
	--== armwraps
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
	
	
	--== militaryboots
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
	
	
	
	--== nekrostrench

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
		
		SurfaceAppearance={
			ColorMap="rbxassetid://14971087352";
		};
		SurfaceAppearanceParent=script;
	};
	
	
	--== tirearmor
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
end

return ItemUnlockablesLibrary;