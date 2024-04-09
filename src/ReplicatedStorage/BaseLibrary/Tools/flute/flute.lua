local CollectionService = game:GetService("CollectionService");

local FluteTracks = {
	{Id="rbxassetid://6146211836"; Name="Happy Birthday"};
	{Id="rbxassetid://6146212207"; Name="Mask Off"};
	{Id="rbxassetid://6146212525"; Name="Boohoo"};
	{Id="rbxassetid://6146712150"; Name="Golden Wind"};
	{Id="rbxassetid://6146863772"; Name="Coffin Dance"};
};

return function()
	local Tool = {};
	Tool.IsActive = false;
	Tool.Instrument = "Flute";
	Tool.Index = 1;
	Tool.ActiveTrack = nil;
	
	function Tool:ClientPrimaryFire()
		local player = game.Players.LocalPlayer;
		local modData = require(player:WaitForChild("DataModule"));
		local modInterface = modData:GetInterfaceModule();
		
		spawn(function()
			local track = self.Handle:WaitForChild("TuneMusic");
			if self.Handle:FindFirstChild("fluteConn") == nil then
				local newTag = Instance.new("BoolValue");
				newTag.Name = "fluteConn";
				newTag.Parent = self.Handle;

				local lastId;
				local function onChanged()
					if lastId ~= track.SoundId then
						lastId = track.SoundId;

						for a=1, #FluteTracks do
							if FluteTracks[a].Id == lastId then
								modInterface:HintWarning("Tune: "..FluteTracks[a].Name, 2, Color3.fromRGB(255, 255, 255));
								break;
							end
						end
					end
				end
				onChanged();
				track:GetPropertyChangedSignal("SoundId"):Connect(onChanged);
			end
		end)
		
	end
	
	function Tool:OnPrimaryFire(isActive)
		self.IsActive = isActive;
		
		if self.IsActive then
			for a=1, #self.Prefabs do
				local prefab = self.Prefabs[a];
				local handle = prefab.PrimaryPart;
				
				local sound = handle:FindFirstChild("TuneMusic");
				local function nextTrack()
					if self.IsActive then
						sound.SoundId = FluteTracks[Tool.Index].Id;
						sound:Play();
					end
					Tool.Index = Tool.Index == #FluteTracks and 1 or Tool.Index +1;
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
				Tool.ActiveTrack = sound;
				
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
			if Tool.ActiveTrack then
				Tool.ActiveTrack:Stop();
			end
		end
	end

	function Tool:ClientUnequip()
		local player = game.Players.LocalPlayer;
		local modData = require(player:WaitForChild("DataModule"));
		local modInterface = modData:GetInterfaceModule();
		
		modInterface:CloseWindow("InstrumentWindow");
	end
	
	function Tool:ClientItemPrompt()
		local player = game.Players.LocalPlayer;
		local modData = require(player:WaitForChild("DataModule"));
		local modInterface = modData:GetInterfaceModule();

		if modInterface:IsVisible("InstrumentWindow") then return end;
		wait(0.1);
		modInterface:ToggleWindow("InstrumentWindow", self.StorageItem, self);
	end
	
	return Tool;
end;
