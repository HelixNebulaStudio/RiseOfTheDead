local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modSkillTree = require(game.ServerScriptService.ServerLibrary.SkillTree);

--== When user equips a equippable item;
return function(player, storageItem)
	local profile = modProfile:Get(player);
	local activeSave = profile and profile:GetActiveSave();
	local inventory = activeSave and activeSave.Inventory or nil;
	
	modSkillTree:TriggerSkills(player, script.Name, storageItem);
end;
