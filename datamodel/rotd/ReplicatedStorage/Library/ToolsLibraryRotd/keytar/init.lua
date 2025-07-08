local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
local modGuitarTool = shared.require(game.ReplicatedStorage.Library.ToolsLibraryRotd.guitar);

local toolPackage = {
	ItemId=script.Name;
	Class="Melee";
	HandlerType="MeleeTool";

	ToolWindow = "InstrumentWindow";

	Animations={
		Core={Id=16971537726; IdRoleplay=16971600436;};
		Load={Id=16971542912;};
		Inspect={Id=16971597553;};
		Unequip={Id=16971602144};
		PrimaryAttack={Id=16971526990;};
		HeavyAttack={Id=16971594147};
	};
	Audio={
		Load={Id=2304904662; Pitch=0.6; Volume=0.5;};
		PrimaryHit={Id=9141019032; Pitch=0.6; Volume=1;};
		PrimarySwing={Id=158037267; Pitch=0.75; Volume=1;};
		HeavySwing={Id=158037267; Pitch=0.70; Volume=1;};
	};
	
	Configurations={
		Category = "Edged";
		Type="Sword";
		EquipLoadTime=1;
		Damage=340;

		PrimaryAttackSpeed=0.8;
		PrimaryAttackAnimationSpeed=0.35;

		--HeavyAttackMultiplier=2;
		--HeavyAttackSpeed=1.2;
		HitRange=14;

		WaistRotation=math.rad(0);

		StaminaCost = 15;
		StaminaDeficiencyPenalty = 0.6;

		-- Roleplay;
		RoleplayStateWindow = "InstrumentWindow";
	};
	Properties={};

	Holster = {
		RightSwordAttachment={PrefabName="keytar"; C1=CFrame.new(0.5, 0.699999988, 0.600000024, -0.559192836, -0.829037607, -8.16161929e-08, -0.773973286, 0.522051454, -0.35836795, 0.297100574, -0.200396717, -0.933580399);}; -- C1 attribute on motor6d;
	};

	TuneVolume = 3;
	TuneTracks = {
		{Id="rbxassetid://15298676220"; Name="0% Angel"};
		{Id="rbxassetid://15298676388"; Name="Faded"};
		{Id="rbxassetid://15298676523"; Name="Coffin Dance"};
	};
};
--==

function toolPackage.InputEvent(handler: ToolHandlerInstance, inputData)
	if inputData.InputType ~= "Begin" or inputData.KeyIds.KeyFire == nil then return end;

	local properties = handler.EquipmentClass.Properties;

	if RunService:IsClient() then
		local window: InterfaceWindow = modClientGuis.getWindow("InstrumentWindow");
		if window.Visible then return end;

		if properties.IsActive == nil then
			properties.IsActive = false;
		end
		properties.IsActive = not properties.IsActive;
		inputData.IsActive = properties.IsActive;

		modGuitarTool.ClientPrimaryFire(handler);

	else
		if properties.Index == nil then
			properties.Index = 1;
		end

		modGuitarTool.ActionEvent(handler, {
			ActionIndex = 1;
			IsActive = inputData.IsActive;
		});
	end

	return true; -- submit input to server;
end


function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;