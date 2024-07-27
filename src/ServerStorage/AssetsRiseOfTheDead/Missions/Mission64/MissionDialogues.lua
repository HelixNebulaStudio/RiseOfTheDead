local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

--=
local Dialogues = {
	Joseph={};
};

local missionId = 64;
--==

-- MARK: Joseph Dialogues
Dialogues.Joseph.Dialogues = function()
	return {
		{Tag="josephcrossbow_init"; Face="Suspicious"; 
			Reply="If you ever come across a crossbow, please show it to me.";};
		{Tag="josephcrossbow_try"; Face="Skeptical"; 
			Dialogue="Is this crossbow what you are talking about?"; 
			Reply="Ahh yes.. I had a build for the crossbow, I've written my build somewhere near my workbench a long time ago and forgotten it, try to figure out how it's built."};
		{Tag="josephcrossbow_failBuild"; Face="Skeptical"; 
			Dialogue="Is this how you built your crossbow?"; 
			Reply="Hmm, not quite, something's off. Look around my workbench to see if you can find any clues.."};
		{Tag="josephcrossbow_corectBuild"; Face="Skeptical"; 
			Dialogue="Is this how you built your crossbow?"; 
			Reply="Well well well, it is perfeect. Here, use this to give it a final touch."};

	};
end

if RunService:IsServer() then
	-- MARK: Joseph Handler
	if modBranchConfigs.IsWorld("TheInvestigation") then
		Dialogues.Joseph.DialogueHandler = function(player, dialog, data, mission)
			local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
			local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
			local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
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
							modMission:StartMission(player, missionId);
						end)
					end
				end
			end
		end
	end
end


return Dialogues;