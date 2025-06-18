local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="GenericTool";

	ToolWindow = "InstrumentWindow";
	
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

	TuneVolume = 1;
	TuneTracks = {
		{Id="rbxassetid://6297207526"; Name="Brighter Day"};
		{Id="rbxassetid://6297259879"; Name="Numa numa"};
		{Id="rbxassetid://6297346365"; Name="Ievan Polkka"};
	};
};
--==

function toolPackage.ClientPrimaryFire(handler: ToolHandlerInstance)
	local handle = handler.MainToolModel.PrimaryPart;
	if handle == nil then return end;

	task.spawn(function()
		local track = handle:WaitForChild("TuneMusic");

		if handle:GetAttribute("musicConn") then return end;
		handle:SetAttribute("musicConn", true);
		
		local tuneTracks = handler.ToolPackage.TuneTracks;

		local lastId;
		local function onChanged()
			if lastId == track.SoundId then return end;
			lastId = track.SoundId;

			for a=1, #tuneTracks do
				if tuneTracks[a].Id ~= lastId then continue end;
				
				modClientGuis.hintWarning(`Tune: {tuneTracks[a].Name}`, function(element)
					element.TextColor = Color3.fromRGB(255, 255, 255);
				end);
				break;
			end
		end
		onChanged();
		track:GetPropertyChangedSignal("SoundId"):Connect(onChanged);
	end)
end


function toolPackage.ActionEvent(handler: ToolHandlerInstance, packet)
	if packet.ActionIndex ~= 1 then return end;
	local isActive = packet.IsActive == true;

	local equipmentClass: EquipmentClass = handler.EquipmentClass;
	local configurations = equipmentClass.Configurations;
	local properties = equipmentClass.Properties;

	local mainToolModel = handler.MainToolModel;
	local handle = mainToolModel.PrimaryPart;

	properties.IsActive = isActive;

	if properties.IsActive == false then
		if handle and handle:FindFirstChild("musicParticle") then
			handle.musicParticle.Enabled = false;
		end
		if configurations.ActiveTrack then
			configurations.ActiveTrack:Stop();
		end

		return;
	end

	local tuneTracks = handler.ToolPackage.TuneTracks;

	local sound = handle:FindFirstChild("TuneMusic");
	local function nextTrack()
		if properties.IsActive then
			sound.SoundId = tuneTracks[configurations.Index].Id;
			sound:Play();
		end
		configurations.Index = configurations.Index == #tuneTracks and 1 or configurations.Index +1;
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
	sound.Volume = handler.ToolPackage.TuneVolume or 1;
	sound.SoundGroup = game.SoundService:FindFirstChild("InstrumentMusic");

	if handler.CharacterClass.ClassName == "PlayerClass" then
		local player = (handler.CharacterClass :: PlayerClass):GetInstance();

		sound:SetAttribute("SoundOwner", player and player.Name or nil);
		CollectionService:AddTag(sound, "PlayerNoiseSounds");
	end
	
	sound.Parent = handle;

	nextTrack();
	configurations.ActiveTrack = sound;

	if handle:FindFirstChild("musicParticle") then
		handle.musicParticle.Enabled = true;
	end
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;