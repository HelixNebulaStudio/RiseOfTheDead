local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = require(game.ReplicatedStorage.Library.Audio);


local Weapons = {};
local totalWeapons = 0;

function AddWeapon(data)
	local module = script:WaitForChild(data.ItemId);
	
	local packet = {
		Type="GunTool";
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
}

AddWeapon{
	ItemId="cz75";
};

AddWeapon{
	ItemId="tec9";
};

AddWeapon{
	ItemId="deagle";
	Tier=3;
};

AddWeapon{
	ItemId="xm1014";
};

AddWeapon{
	ItemId="sawedoff";
};

AddWeapon{
	ItemId="mp5";
};

AddWeapon{
	ItemId="mp7";
};

AddWeapon{
	ItemId="m4a4";
};

AddWeapon{
	ItemId="ak47";
};

AddWeapon{
	ItemId="awp";
};

AddWeapon{
	ItemId="minigun";
};

AddWeapon{
	ItemId="flamethrower";
};

AddWeapon{
	ItemId="revolver454";
	Tier=2;
};

AddWeapon{
	ItemId="grenadelauncher";
	Tier=2;
};

AddWeapon{
	ItemId="dualp250";
	Tier=2;
	Welds={
		LeftToolGrip="p250";
		RightToolGrip="p250";
	}
};

AddWeapon{
	ItemId="m9legacy";
	Tier=2;
}

AddWeapon{
	ItemId="mariner590";
	Tier=2;
};

AddWeapon{
	ItemId="czevo3";
	Tier=2;
};

AddWeapon{
	ItemId="fnfal";
};

AddWeapon{
	ItemId="tacticalbow";
	Tier=3;
	Welds={
		LeftToolGrip="tacticalbow";
	}
};

AddWeapon{
	ItemId="desolatorheavy";
};

AddWeapon{
	ItemId="rec21";
};

AddWeapon{
	ItemId="at4";
	Tier=3;
};

AddWeapon{
	ItemId="sr308";
	Tier=3;
};

AddWeapon{
	ItemId="vectorx";
	Tier=4;
};

AddWeapon{
	ItemId="rusty48";
	Tier=4;
};

AddWeapon{
	ItemId="arelshiftcross";
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