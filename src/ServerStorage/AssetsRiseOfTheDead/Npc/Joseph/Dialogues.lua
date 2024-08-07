local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="These crops can keep us going for years.";
	};
	["init2"]={
		Reply="Christ.. I forgot to water the crops..";
	};
	["init3"]={
		Reply="One step closer to becoming self sustainable..";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["heal_request"]={
		Face="Confident";
		Say="Can you heal me please?";
		Reply="Cmon' closer and I'll patch you up.";
	};
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
		local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
		
		if modBranchConfigs.IsWorld("TheInvestigation") then return end;
		dialog:AddChoice("heal_request", function()
			if not dialog.InRange() then return end;
			modStatusEffects.FullHeal(player, 0.1);
			modOnGameEvents:Fire("OnMedicHeal", player, dialog.Name);
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
				dialog:InitDialog{
					Reply="If you ever come across a crossbow, please show it to me.";
					Face="Suspicious";
				}
	
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
end

return Dialogues;