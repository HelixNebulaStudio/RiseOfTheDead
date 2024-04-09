local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

local modBlueprints = require(game.ServerScriptService.ServerLibrary.Blueprints);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);


--==
return function(player, dialog, data, mission)
	local profile = shared.modProfile:Get(player);
	
	if mission.Type == 2 then -- Available
		-- Secret mission, no available
		
	elseif mission.Type == 1 then -- Active
		if profile.EquippedTools.WeaponModels == nil then return end;

		local crossBowId = nil;
		for a=1, #profile.EquippedTools.WeaponModels do
			if profile.EquippedTools.WeaponModels[a]:IsA("Model") and profile.EquippedTools.WeaponModels[a]:GetAttribute("ItemId") == "arelshiftcross" then
				crossBowId = profile.EquippedTools.WeaponModels[a]:GetAttribute("StorageItemId");
				break;

			end
		end
		if crossBowId == nil then return end;
		
		local storageItem, storage = modStorage.FindIdFromStorages(crossBowId, player);
		if storageItem == nil then return end;
		
		local crossbowModStorage = modStorage.Get(crossBowId, player)
		
		
		local listOfMods = {
			bowdamagemod=false;
			bowricochetmod=false;
			bowdeadweightmod=false;
			electricmod=false;
			bowammocapmod=false;
		}

		local correctBuild = true;
		if crossbowModStorage == nil then
			correctBuild = false;
			
		else
			for id, item in pairs(crossbowModStorage.Container) do
				if listOfMods[item.ItemId] ~= nil then
					listOfMods[item.ItemId] = true;
				end
			end

			for k, v in pairs(listOfMods) do
				if v == false then
					correctBuild = false;
					break;
				end
			end
			
		end
		
		if correctBuild then
			dialog:AddChoice("josephcrossbow_corectBuild", function(dialog)
				modMission:CompleteMission(player, 64);
			end)
			
		else
			dialog:AddChoice("josephcrossbow_failBuild");
			
		end
		

	elseif mission.Type == 3 then
		
		
	end
end