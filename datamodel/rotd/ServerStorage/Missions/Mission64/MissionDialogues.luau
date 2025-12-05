local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

--=
local Dialogues = {
	Joseph={};
};

local MISSION_ID = 64;
--==

-- MARK: Joseph Dialogues
Dialogues.Joseph.DialogueStrings = {
	["josephcrossbow_try"]={
		Face="Skeptical"; 
		Say="Is this crossbow what you are talking about?"; 
		Reply="Ahh yes.. I had a build for the crossbow, I've written my build somewhere near my workbench a long time ago and forgotten it, try to figure out how it's built.";
	};
	["josephcrossbow_failBuild"]={
		Face="Skeptical"; 
		Say="Is this how you built your crossbow?"; 
		Reply="Hmm, not quite, something's off. Look around my workbench to see if you can find any clues..";
	};
	["josephcrossbow_corectBuild"]={
		Face="Skeptical"; 
		Say="Is this how you built your crossbow?"; 
		Reply="Well well well, it is perfeect. Here, use this to give it a final touch.";
	};

};

if RunService:IsServer() then
	-- MARK: Joseph Handler
	Dialogues.Joseph.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		local modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);

		local profile = shared.modProfile:Get(player);
		local playerClass: PlayerClass = shared.modPlayers.get(player);

		if mission.Type == 1 then -- Active
		
			if mission.Type == 1 then
				local equipmentSiid = playerClass.WieldComp.Siid;
				if equipmentSiid == nil then return end;
				
				local storageItem = modStorage.FindIdFromStorages(equipmentSiid, player);
				if storageItem == nil then return end;
				
				local crossbowModStorage = modStorage.Get(equipmentSiid, player)
				
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
						modMission:CompleteMission(player, MISSION_ID);
					end)
					
				else
					dialog:AddChoice("josephcrossbow_failBuild");
					
				end

			end
			
		end
	end

end


return Dialogues;