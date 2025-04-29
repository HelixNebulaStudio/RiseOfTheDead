local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local TuneTracks = {
	{Id="rbxassetid://6297207526"; Name="Brighter Day"};
	{Id="rbxassetid://6297259879"; Name="Numa numa"};
	{Id="rbxassetid://6297346365"; Name="Ievan Polkka"};
};

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="GenericTool";

	Animations={
		Core={Id=6297114327;};
		Use={Id=6297131484};
	};
	Audio={};
	Configurations={
		Instrument = "Guitar";
		Index = 1;
		ActiveTrack = nil;
	};
	Properties={};
};

function toolPackage.ClientPrimaryFire(handler)
	local player = game.Players.LocalPlayer;
	local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
	local modInterface = modData:GetInterfaceModule();
	
	spawn(function()
		local handle = handler.Prefabs[1].PrimaryPart;
		local track = handle:WaitForChild("TuneMusic");
		if handle:FindFirstChild("musicConn") == nil then
			local newTag = Instance.new("BoolValue");
			newTag.Name = "musicConn";
			newTag.Parent = handle;

			local lastId;
			local function onChanged()
				if lastId ~= track.SoundId then
					lastId = track.SoundId;

					for a=1, #TuneTracks do
						if TuneTracks[a].Id == lastId then
							modInterface:HintWarning("Tune: "..TuneTracks[a].Name, 2, Color3.fromRGB(255, 255, 255));
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

function toolPackage.OnClientUnequip()
	local player = game.Players.LocalPlayer;
	local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
	local modInterface = modData:GetInterfaceModule();

	modInterface:CloseWindow("InstrumentWindow");
end

function toolPackage.ClientItemPrompt(handler)
	local player = game.Players.LocalPlayer;
	local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
	local modInterface = modData:GetInterfaceModule();

	if modInterface:IsVisible("InstrumentWindow") then return end;
	modInterface:ToggleWindow("InstrumentWindow", nil, handler);
end

function toolPackage.OnActionEvent(handler, packet)
	if packet.ActionIndex ~= 1 then return end;
	local isActive = packet.IsActive == true;

	handler.IsActive = isActive;

	local equipmentClass = handler.EquipmentClass;
	local configurations = equipmentClass.Configurations;

	if handler.IsActive then
		for a=1, #handler.Prefabs do
			local prefab = handler.Prefabs[a];
			local handle = prefab.PrimaryPart;

			local sound = handle:FindFirstChild("TuneMusic");
			local function nextTrack()
				if handler.IsActive then
					sound.SoundId = TuneTracks[configurations.Index].Id;
					sound:Play();
				end
				configurations.Index = configurations.Index == #TuneTracks and 1 or configurations.Index +1;
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

			sound:SetAttribute("SoundOwner", handler.Player and handler.Player.Name or nil);
			CollectionService:AddTag(sound, "PlayerNoiseSounds");
			sound.Parent = handle;

			nextTrack();
			configurations.ActiveTrack = sound;

			if handle:FindFirstChild("musicParticle") then
				handle.musicParticle.Enabled = true;
			end

			break;
		end
	else
		for a=1, #handler.Prefabs do
			local prefab = handler.Prefabs[a];
			local handle = prefab.PrimaryPart;

			if handle:FindFirstChild("musicParticle") then
				handle.musicParticle.Enabled = false;
			end
		end
		if configurations.ActiveTrack then
			configurations.ActiveTrack:Stop();
		end
	end
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;