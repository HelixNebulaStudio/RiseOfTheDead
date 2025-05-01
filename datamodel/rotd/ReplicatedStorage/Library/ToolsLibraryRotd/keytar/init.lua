local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local BaseTracks = {
	{Id="rbxassetid://15298676220"; Name="0% Angel"};
	{Id="rbxassetid://15298676388"; Name="Faded"};
	{Id="rbxassetid://15298676523"; Name="Coffin Dance"};
};

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="MeleeTool";

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
	}
};

local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");
function toolPackage.OnInputEvent(toolHandler: ToolHandlerInstance, inputData)
	if inputData.InputType ~= "Begin" or inputData.KeyIds.KeyFire == nil then return end;

	local properties = toolHandler.EquipmentClass.Properties;
	local handle = toolHandler.Prefabs[1].PrimaryPart;

	if RunService:IsClient() then
		local player = game.Players.LocalPlayer;
		local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
		local modInterface = modData:GetInterfaceModule();

		if not modInterface:IsVisible("InstrumentWindow") then
			return;
		end

		if properties.IsActive == nil then
			properties.IsActive = false;
		end
		properties.IsActive = not properties.IsActive;
		inputData.IsActive = properties.IsActive;

		task.spawn(function()
			local track = handle:WaitForChild("TuneMusic");
			if handle:FindFirstChild("musicConn") == nil then
				local newTag = Instance.new("BoolValue");
				newTag.Name = "musicConn";
				newTag.Parent = handle;

				local lastId;
				local function onChanged()
					if lastId ~= track.SoundId then
						lastId = track.SoundId;

						for a=1, #BaseTracks do
							if BaseTracks[a].Id == lastId then
								modInterface:HintWarning("Tune: "..BaseTracks[a].Name, 2, Color3.fromRGB(255, 255, 255));
								break;
							end
						end
					end
				end
				onChanged();
				track:GetPropertyChangedSignal("SoundId"):Connect(onChanged);
			end
		end)

	else
		if properties.Index == nil then
			properties.Index = 1;
		end
		properties.IsActive = inputData.IsActive;

		if properties.IsActive then
			local sound = handle:FindFirstChild("TuneMusic");
			local function nextTrack()
				if properties.IsActive then
					sound.SoundId = BaseTracks[properties.Index].Id;
					sound.Volume = 3;
					sound:Play();
				end
				properties.Index = properties.Index == #BaseTracks and 1 or properties.Index +1;
			end

			if sound == nil then
				sound = Instance.new("Sound");
				sound.Ended:Connect(function()
					wait(1);
					nextTrack();
				end)
			end
			sound.Name = "TuneMusic";
			sound.RollOffMaxDistance = 128;
			sound.RollOffMinDistance = 20;
			sound.Volume = 1;
			sound.SoundGroup = game.SoundService:FindFirstChild("InstrumentMusic");

			sound:SetAttribute("SoundOwner", player and player.Name or nil);
			CollectionService:AddTag(sound, "PlayerNoiseSounds");
			sound.Parent = handle;

			nextTrack();
			properties.ActiveTrack = sound;

			if handle:FindFirstChild("musicParticle") then
				handle.musicParticle.Enabled = true;
			end

		else
			if handle:FindFirstChild("musicParticle") then
				handle.musicParticle.Enabled = false;
			end
				
			if properties.ActiveTrack then
				properties.ActiveTrack:Stop();
			end
		end

	end

	return true; -- submit input to server;
end

function toolPackage.ClientUnequip()
	local player = game.Players.LocalPlayer;
	local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
	local modInterface = modData:GetInterfaceModule();

	modInterface:CloseWindow("InstrumentWindow");
end

function toolPackage.ClientItemPrompt(handler: ToolHandlerInstance)
	local player = game.Players.LocalPlayer;
	local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
	local modInterface = modData:GetInterfaceModule();

	modInterface:ToggleWindow("InstrumentWindow", handler);
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;