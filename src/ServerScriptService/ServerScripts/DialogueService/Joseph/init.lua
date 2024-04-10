local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);

return function(player, dialog, data)
	if modBranchConfigs.IsWorld("TheInvestigation") then return end;
	dialog:AddChoice("heal_request", function()
		if not dialog.InRange() then return end;
		modStatusEffects.FullHeal(player, 0.1);
	end)

	if #modMission:GetNpcMissions(player, script.Name) > 0 then
		Debugger:Warn("Joseph has missions");
		return
	end;
	
	if modMission:GetMission(player, 64) == nil then
		--== Joseph's Crossbow
		local profile = shared.modProfile:Get(player);

		local playerSave = profile:GetActiveSave();
		local playerLevel = playerSave:GetStat("Level") or 0;

		if playerLevel >= 500 then
			dialog:SetInitiateTag("josephcrossbow_init");

			local isCrossBow = false;
			if profile.EquippedTools.WeaponModels == nil then return end;

			for a=1, #profile.EquippedTools.WeaponModels do
				if profile.EquippedTools.WeaponModels[a]:IsA("Model") and profile.EquippedTools.WeaponModels[a]:GetAttribute("ItemId") == "arelshiftcross" then
					isCrossBow = true;
					break;

				end
			end

			if isCrossBow then
				dialog:AddChoice("josephcrossbow_try", function(dialog)
					modMission:StartMission(player, 64);
				end)
			end
		end
	end

end
