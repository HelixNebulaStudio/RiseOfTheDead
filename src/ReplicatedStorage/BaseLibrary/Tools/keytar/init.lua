local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="Melee";
	Animations={
		Core={Id=16971537726; IdRoleplay=16971600436;};
		Load={Id=16971542912;};
		--RoleplayCore={Id=16971600436};
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
};

--==
local CollectionService = game:GetService("CollectionService");
local RunService = game:GetService("RunService");

local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);

local BaseTracks = {
	{Id="rbxassetid://15298676220"; Name="0% Angel"};
	{Id="rbxassetid://15298676388"; Name="Faded"};
	{Id="rbxassetid://15298676523"; Name="Coffin Dance"};
};

function toolPackage.NewToolLib(handler)
	local Tool = {};
	Tool.Class = "Melee";

	Tool.Holster = {
		RightSwordAttachment={PrefabName="keytar"; C1=CFrame.new(0.5, 0.699999988, 0.600000024, -0.559192836, -0.829037607, -8.16161929e-08, -0.773973286, 0.522051454, -0.35836795, 0.297100574, -0.200396717, -0.933580399);}; -- C1 attribute on motor6d;
	}

	Tool.Configurations = {
		Type="Sword";
		EquipLoadTime=1;
		BaseDamage=340;

		PrimaryAttackSpeed=0.8;
		PrimaryAttackAnimationSpeed=0.35;

		--HeavyAttackMultiplier=2;
		--HeavyAttackSpeed=1.2;
		HitRange=14;

		WaistRotation=math.rad(0);

		StaminaCost = 15;
		StaminaDeficiencyPenalty = 0.6;
	};

	Tool.Properties = {
		Attacking=false;
	}

	--== Roleplay
	Tool.RoleplayStateWindow = "InstrumentWindow";
	Tool.IsActive = false;
	Tool.Instrument = "Keytar";
	Tool.Index = 1;
	Tool.ActiveTrack = nil;


	function Tool.OnInputEvent(toolHandler, inputData)
		if inputData.InputType ~= "Begin" or inputData.KeyIds.KeyFire == nil then return end;

		local toolConfig = toolHandler.ToolConfig;
		if RunService:IsClient() then
			local player = game.Players.LocalPlayer;
			local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
			local modInterface = modData:GetInterfaceModule();

			if not modInterface:IsVisible("InstrumentWindow") then
				return;
			end

			toolConfig.IsActive = not toolConfig.IsActive;
			inputData.IsActive = toolConfig.IsActive;

			task.spawn(function()
				local track = toolConfig.Handle:WaitForChild("TuneMusic");
				if toolConfig.Handle:FindFirstChild("musicConn") == nil then
					local newTag = Instance.new("BoolValue");
					newTag.Name = "musicConn";
					newTag.Parent = toolConfig.Handle;

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
			toolConfig.IsActive = inputData.IsActive;

			if toolConfig.IsActive then
				for a=1, #toolHandler.Prefabs do
					local prefab = toolHandler.Prefabs[a];
					local handle = prefab.PrimaryPart;

					local sound = handle:FindFirstChild("TuneMusic");
					local function nextTrack()
						if toolConfig.IsActive then
							sound.SoundId = BaseTracks[Tool.Index].Id;
							sound.Volume = 3;
							sound:Play();
						end
						Tool.Index = Tool.Index == #BaseTracks and 1 or Tool.Index +1;
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

					sound:SetAttribute("SoundOwner", toolHandler.Player and toolHandler.Player.Name or nil);
					CollectionService:AddTag(sound, "PlayerNoiseSounds");
					sound.Parent = handle;

					nextTrack();
					Tool.ActiveTrack = sound;

					if handle:FindFirstChild("musicParticle") then
						handle.musicParticle.Enabled = true;
					end

					break;
				end
			else
				for a=1, #toolHandler.Prefabs do
					local prefab = toolHandler.Prefabs[a];
					local handle = prefab.PrimaryPart;

					if handle:FindFirstChild("musicParticle") then
						handle.musicParticle.Enabled = false;
					end
				end
				if Tool.ActiveTrack then
					Tool.ActiveTrack:Stop();
				end
			end

		end

		return true; -- submit input to server;
	end

	function Tool:ClientUnequip()
		local player = game.Players.LocalPlayer;
		local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
		local modInterface = modData:GetInterfaceModule();

		modInterface:CloseWindow("InstrumentWindow");
	end

	function Tool:ClientItemPrompt()
		local player = game.Players.LocalPlayer;
		local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
		local modInterface = modData:GetInterfaceModule();

		if modInterface:IsVisible("InstrumentWindow") then return end;
		wait(0.1);
		modInterface:ToggleWindow("InstrumentWindow", self.StorageItem, self);
	end
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return modMeleeProperties.new(Tool);
end

return toolPackage;