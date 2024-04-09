local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modSkillTree = require(game.ServerScriptService.ServerLibrary.SkillTree);


--== When user equips a equippable item;
return function(player, storageItem)
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local inventory = activeSave and activeSave.Inventory or nil;
	
	if storageItem.ItemId == "entityleash" then
		local mission53 = modMission:GetMission(player, 53);
		if mission53 and mission53.Type == 1 then
			modMission:Progress(player, 53, function(mission)
				if mission.ProgressionPoint == 4 then
					mission.ProgressionPoint = 5;
				end
			end)
		end
	end
	
	modSkillTree:TriggerSkills(player, script.Name, storageItem);
end;
