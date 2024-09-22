local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = require(game.ReplicatedStorage.Library.Audio);


local Weapons = {};
local totalWeapons = 0;

function AddWeapon(data)
	local module = script:WaitForChild(data.ItemId);
	
	local packet = {
		Type="GunTool";
		WeaponClass=data.WeaponClass;
		ItemId=data.ItemId;
		IsWeapon=true;
		Tier=data.Tier;
		Welds=data.Welds or {
			ToolGrip=data.ItemId;
		};
		Module=module;
	};
	packet.NewToolLib = function()
		return require(packet.Module)();
	end;
	
	Weapons[data.ItemId] = packet;
	totalWeapons = totalWeapons +1;
	
	local newToolModule = packet.NewToolLib();
	packet.PreloadAudio = newToolModule.PreloadAudio;

	for soundType, audioProperties in pairs(newToolModule.Audio or data.Audio or {}) do
		if audioProperties.Preload == true then continue end;
		local audioId = tostring(audioProperties.Id);
		audioProperties.Id = audioId;
		
		local soundFile = modAudio.Get(audioId);
		if soundFile == nil then
			if game:GetService("RunService"):IsServer() then
				soundFile = Instance.new("Sound");
				soundFile.Name = audioId;
				soundFile.SoundId = "rbxassetid://"..audioId;
				soundFile.PlaybackSpeed = audioProperties.Pitch;
				--soundFile.RollOffMode = Enum.RollOffMode.Inverse;
				soundFile.EmitterSize = 5;
				if soundType == "PrimaryFire" then
					soundFile.RollOffMaxDistance = 128;
				elseif soundType == "Empty" then
					soundFile.RollOffMaxDistance = 16;
				else
					soundFile.RollOffMaxDistance = 32;
				end
				soundFile.SoundGroup = game.SoundService.WeaponEffects;
				soundFile.Volume = audioProperties.Volume ~= nil and audioProperties.Volume or 0.5;
				soundFile.Parent = modAudio.ServerAudio;
	
				if modAudio.ModdedSelf then
					modAudio.ModdedSelf.OnWeaponAudioLoad(soundType, audioProperties, soundFile);
				end
				modAudio.Library[audioId] = soundFile;

			end
		end
		
	end
end

Weapons.Import = AddWeapon;

AddWeapon{
	ItemId="p250";
	WeaponClass="Pistol";
}

AddWeapon{
	ItemId="cz75";
	WeaponClass="Pistol";
};

AddWeapon{
	ItemId="tec9";
	WeaponClass="Pistol";
};

AddWeapon{
	ItemId="deagle";
	WeaponClass="Pistol";
	Tier=3;
};

AddWeapon{
	ItemId="xm1014";
	WeaponClass="Shotgun";
};

AddWeapon{
	ItemId="sawedoff";
	WeaponClass="Shotgun";
};

AddWeapon{
	ItemId="mp5";
	WeaponClass="Submachine gun";
};

AddWeapon{
	ItemId="mp7";
	WeaponClass="Submachine gun";
};

AddWeapon{
	ItemId="m4a4";
	WeaponClass="Rifle";
};

AddWeapon{
	ItemId="ak47";
	WeaponClass="Rifle";
};

AddWeapon{
	ItemId="awp";
	WeaponClass="Sniper";
};

AddWeapon{
	ItemId="minigun";
	WeaponClass="Heavy machine gun";
};

AddWeapon{
	ItemId="flamethrower";
	WeaponClass="Pyrotechnic";
};

AddWeapon{
	ItemId="revolver454";
	WeaponClass="Pistol";
	Tier=2;
};

AddWeapon{
	ItemId="grenadelauncher";
	WeaponClass="Explosive";
	Tier=2;
};

AddWeapon{
	ItemId="dualp250";
	WeaponClass="Pistol";
	Tier=2;
	Welds={
		LeftToolGrip="p250";
		RightToolGrip="p250";
	}
};

AddWeapon{
	ItemId="m9legacy";
	WeaponClass="Pistol";
	Tier=2;
}

AddWeapon{
	ItemId="mariner590";
	WeaponClass="Shotgun";
	Tier=2;
};

AddWeapon{
	ItemId="czevo3";
	WeaponClass="Submachine gun";
	Tier=2;
};

AddWeapon{
	ItemId="fnfal";
	WeaponClass="Rifle";
};

AddWeapon{
	ItemId="tacticalbow";
	WeaponClass="Bow";
	Tier=3;
	Welds={
		LeftToolGrip="tacticalbow";
	}
};

AddWeapon{
	ItemId="desolatorheavy";
	WeaponClass="Heavy machine gun";
};

AddWeapon{
	ItemId="rec21";
	WeaponClass="Sniper";
};

AddWeapon{
	ItemId="at4";
	WeaponClass="Explosive";
	Tier=3;
};

AddWeapon{
	ItemId="sr308";
	WeaponClass="Rifle";
	Tier=3;
};

AddWeapon{
	ItemId="vectorx";
	WeaponClass="Submachine gun";
	Tier=4;
};

AddWeapon{
	ItemId="rusty48";
	WeaponClass="Shotgun";
	Tier=4;
};

AddWeapon{
	ItemId="arelshiftcross";
	WeaponClass="Bow";
	Tier=4;
};



local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetModule(script.Name);
if moddedSelf then moddedSelf:Init(Weapons); end



local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
if modGlobalVars.MaxLevels < totalWeapons*20 then
	task.spawn(function()
		while true do
			warn("WeaponsLibrary>> Invalid GlobalVar MaxLevels "..modGlobalVars.MaxLevels..". Supposed to be "..totalWeapons*20);
			task.wait(5)
		end
	end)
end

return Weapons;