local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;
local CollectionService = game:GetService("CollectionService");
local RunService = game:GetService("RunService");

local BaseTracks = {
	{Id="rbxassetid://15298676220"; Name="0% Angel"};
	{Id="rbxassetid://15298676388"; Name="Faded"};
	{Id="rbxassetid://15298676523"; Name="Coffin Dance"};
};

local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);
--==

return function()
	local Melee = {};
	Melee.Class = "Melee";

	Melee.Holster = {
		RightSwordAttachment={PrefabName="keytar"; C1=CFrame.new(0.5, 0.699999988, 0.600000024, -0.559192836, -0.829037607, -8.16161929e-08, -0.773973286, 0.522051454, -0.35836795, 0.297100574, -0.200396717, -0.933580399);}; -- C1 attribute on motor6d;
	}

	Melee.Configurations = {
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

	Melee.Properties = {
		Attacking=false;
	}
	
	--== Roleplay
	Melee.RoleplayStateWindow = "InstrumentWindow";
	Melee.IsActive = false;
	Melee.Instrument = "Keytar";
	Melee.Index = 1;
	Melee.ActiveTrack = nil;
	

	function Melee:OnInputEvent(inputData)
		if inputData.InputType ~= "Begin" or inputData.KeyIds.KeyFire == nil then return end;
		
		if RunService:IsClient() then
			local player = game.Players.LocalPlayer;
			local modData = require(player:WaitForChild("DataModule"));
			local modInterface = modData:GetInterfaceModule();
			
			if not modInterface:IsVisible("InstrumentWindow") then
				return;
			end
			
			self.IsActive = not self.IsActive;
			inputData.IsActive = self.IsActive;
			
			task.spawn(function()
				local track = self.Handle:WaitForChild("TuneMusic");
				if self.Handle:FindFirstChild("musicConn") == nil then
					local newTag = Instance.new("BoolValue");
					newTag.Name = "musicConn";
					newTag.Parent = self.Handle;

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
			self.IsActive = inputData.IsActive;

			if self.IsActive then
				for a=1, #self.Prefabs do
					local prefab = self.Prefabs[a];
					local handle = prefab.PrimaryPart;

					local sound = handle:FindFirstChild("TuneMusic");
					local function nextTrack()
						if self.IsActive then
							sound.SoundId = BaseTracks[Melee.Index].Id;
							sound.Volume = 3;
							sound:Play();
						end
						Melee.Index = Melee.Index == #BaseTracks and 1 or Melee.Index +1;
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

					sound:SetAttribute("SoundOwner", self.Player and self.Player.Name or nil);
					CollectionService:AddTag(sound, "PlayerNoiseSounds");
					sound.Parent = handle;

					nextTrack();
					Melee.ActiveTrack = sound;

					if handle:FindFirstChild("musicParticle") then
						handle.musicParticle.Enabled = true;
					end

					break;
				end
			else
				for a=1, #self.Prefabs do
					local prefab = self.Prefabs[a];
					local handle = prefab.PrimaryPart;

					if handle:FindFirstChild("musicParticle") then
						handle.musicParticle.Enabled = false;
					end
				end
				if Melee.ActiveTrack then
					Melee.ActiveTrack:Stop();
				end
			end
			
		end
		
		return true; -- submit input to server;
	end
	
	function Melee:ClientUnequip()
		local player = game.Players.LocalPlayer;
		local modData = require(player:WaitForChild("DataModule"));
		local modInterface = modData:GetInterfaceModule();

		modInterface:CloseWindow("InstrumentWindow");
	end

	function Melee:ClientItemPrompt()
		local player = game.Players.LocalPlayer;
		local modData = require(player:WaitForChild("DataModule"));
		local modInterface = modData:GetInterfaceModule();

		if modInterface:IsVisible("InstrumentWindow") then return end;
		wait(0.1);
		modInterface:ToggleWindow("InstrumentWindow", self.StorageItem, self);
	end
	
	return modMeleeProperties.new(Melee);
end;


--return function()
--	local Tool = {};
--	Tool.IsActive = false;
--	Tool.Instrument = "Keytar";
--	Tool.Index = 1;
--	Tool.ActiveTrack = nil;
	
--	function Tool:ClientPrimaryFire()
--		local player = game.Players.LocalPlayer;
--		local modData = require(player:WaitForChild("DataModule"));
--		local modInterface = modData:GetInterfaceModule();
		
--		spawn(function()
--			local track = self.Handle:WaitForChild("TuneMusic");
--			if self.Handle:FindFirstChild("musicConn") == nil then
--				local newTag = Instance.new("BoolValue");
--				newTag.Name = "musicConn";
--				newTag.Parent = self.Handle;

--				local lastId;
--				local function onChanged()
--					if lastId ~= track.SoundId then
--						lastId = track.SoundId;

--						for a=1, #BaseTracks do
--							if BaseTracks[a].Id == lastId then
--								modInterface:HintWarning("Tune: "..BaseTracks[a].Name, 2, Color3.fromRGB(255, 255, 255));
--								break;
--							end
--						end
--					end
--				end
--				onChanged();
--				track:GetPropertyChangedSignal("SoundId"):Connect(onChanged);
--			end
--		end)
		
--	end
	
--	function Tool:OnPrimaryFire(isActive)
--		self.IsActive = isActive;
		
--		if self.IsActive then
--			for a=1, #self.Prefabs do
--				local prefab = self.Prefabs[a];
--				local handle = prefab.PrimaryPart;
				
--				local sound = handle:FindFirstChild("TuneMusic");
--				local function nextTrack()
--					if self.IsActive then
--						sound.SoundId = BaseTracks[Tool.Index].Id;
--						sound.Volume = 3;
--						sound:Play();
--					end
--					Tool.Index = Tool.Index == #BaseTracks and 1 or Tool.Index +1;
--				end
				
--				if sound == nil then
--					sound = Instance.new("Sound");
--					sound.Ended:Connect(function()
--						wait(1);
--						nextTrack();
--					end)
--				end
--				sound.Name = "TuneMusic";
--				sound.RollOffMaxDistance = 128;
--				sound.RollOffMinDistance = 20;
--				sound.Volume = 1;
--				sound.SoundGroup = game.SoundService:FindFirstChild("InstrumentMusic");
				
--				sound:SetAttribute("SoundOwner", self.Player and self.Player.Name or nil);
--				CollectionService:AddTag(sound, "PlayerNoiseSounds");
--				sound.Parent = handle;
				
--				nextTrack();
--				Tool.ActiveTrack = sound;
				
--				if handle:FindFirstChild("musicParticle") then
--					handle.musicParticle.Enabled = true;
--				end
				
--				break;
--			end
--		else
--			for a=1, #self.Prefabs do
--				local prefab = self.Prefabs[a];
--				local handle = prefab.PrimaryPart;

--				if handle:FindFirstChild("musicParticle") then
--					handle.musicParticle.Enabled = false;
--				end
--			end
--			if Tool.ActiveTrack then
--				Tool.ActiveTrack:Stop();
--			end
--		end
--	end

--	function Tool:ClientUnequip()
--		local player = game.Players.LocalPlayer;
--		local modData = require(player:WaitForChild("DataModule"));
--		local modInterface = modData:GetInterfaceModule();
		
--		modInterface:CloseWindow("InstrumentWindow");
--	end
	
--	function Tool:ClientItemPrompt()
--		local player = game.Players.LocalPlayer;
--		local modData = require(player:WaitForChild("DataModule"));
--		local modInterface = modData:GetInterfaceModule();

--		if modInterface:IsVisible("InstrumentWindow") then return end;
--		wait(0.1);
--		modInterface:ToggleWindow("InstrumentWindow", self.StorageItem, self);
--	end
	
--	return Tool;
--end;