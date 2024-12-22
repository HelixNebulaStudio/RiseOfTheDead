local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local metaWeapons = {};
metaWeapons.__index = metaWeapons;

local Weapons = {};
setmetatable(Weapons, metaWeapons);

function AddWeapon(data)
	local module = script:WaitForChild(data.ItemId);
	local toolPackage = require(module);
	
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

function metaWeapons:LoadToolModule(module)
	if not module:IsA("ModuleScript") then return end;

	local itemId = module.Name;
	local toolPackage = require(module);

	toolPackage.ItemId = toolPackage.ItemId or itemId;
	toolPackage.Animations = toolPackage.Animations or {};
	toolPackage.Audio = toolPackage.Audio or {};
	toolPackage.Welds = toolPackage.Welds or {
		ToolGrip=(toolPackage.Generic or toolPackage.ItemId);
	};
	toolPackage.Module = module;

	toolPackage.IsWeapon = true;
	toolPackage.WeaponClass = toolPackage.WeaponClass or "Misc";
	toolPackage.Tier = toolPackage.Tier or 1;
	toolPackage.Module = module;

	local itemModel = module:FindFirstChild("itemModel");
	if itemModel then
		itemModel.Name = itemId;
		itemModel.Parent = game.ReplicatedStorage.Prefabs.Items;

		toolPackage.Prefab = itemModel;
	else
		itemModel = game.ReplicatedStorage.Prefabs.Items:FindFirstChild(itemId);
		toolPackage.Prefab = itemModel;
	end

	if toolPackage.Audio then
		for soundType, audioProperties in pairs(toolPackage.Audio) do
			if audioProperties.Preload == true then continue end;

			local audioId = tostring(audioProperties.Id);
			audioProperties.Id = audioId;
	
			local soundFile = modAudio.Get(audioId);
			if soundFile == nil then
				if game:GetService("RunService"):IsServer() then
					soundFile = Instance.new("Sound", script);
					soundFile.Name = audioId;
					soundFile.SoundId = "rbxassetid://"..audioId;
					soundFile.PlaybackSpeed = audioProperties.Pitch;
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

	Weapons[itemId] = toolPackage;
end

for _, m in pairs(script:GetChildren()) do
	if not m:IsA("ModuleScript") then continue end;
	if m.Name == "Template" then continue end;
	
	metaWeapons:LoadToolModule(m);
end

local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetModule(script.Name);
if moddedSelf then moddedSelf:Init(Weapons); end

return Weapons;