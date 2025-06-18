local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modGuitarTool = shared.require(game.ReplicatedStorage.Library.ToolsLibraryRotd.guitar);

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="GenericTool";

	ToolWindow = "InstrumentWindow";

	Animations={
		Core={Id=16983037539;};
		Use={Id=16983106503;};
		Idle={Id=16982931630;};
	};
	Audio={};
	Configurations={
		Instrument = "Flute";
		Index = 1;
		ActiveTrack = nil;
	};
	Properties={};

	TuneVolume = 1;
	TuneTracks = {
		{Id="rbxassetid://6146211836"; Name="Happy Birthday"};
		{Id="rbxassetid://6146212207"; Name="Mask Off"};
		{Id="rbxassetid://6146212525"; Name="Boohoo"};
		{Id="rbxassetid://6146712150"; Name="Golden Wind"};
		{Id="rbxassetid://6146863772"; Name="Coffin Dance"};
	};
};
--==

toolPackage.ClientPrimaryFire = modGuitarTool.ClientPrimaryFire;
toolPackage.ActionEvent = modGuitarTool.ActionEvent;

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;