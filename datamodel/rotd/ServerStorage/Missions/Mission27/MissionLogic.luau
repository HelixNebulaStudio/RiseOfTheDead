local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");

local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);
local modGuiHighlight = shared.require(game.ReplicatedStorage.Library.UI.GuiHighlight);

local MISSION_ID = 27;

-- MARK: IsServer()
if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	shared.modEventService:OnInvoked("Npcs_BindDeath", function(eventPacket: EventPacket, ...)
		local npcClass: NpcClass = ...;
		if npcClass == nil or npcClass.HumanoidType ~= "Zombie" then return end;
	
		local playerTags = modDamageTag:Get(npcClass.Character, "Player");
		for a=1, #playerTags do
			local playerTag = playerTags[a];
			local player: Player = playerTag.Player;
			if player == nil or not game.Players:IsAncestorOf(player) then continue end;

			if modMission:IsComplete(player, MISSION_ID) then continue end

			local profile = shared.modProfile:Get(player);
			local gameSave = profile:GetActiveSave();
			
			local rawProperties: anydict = npcClass.Properties.Values;
			local npcLevel = rawProperties.Level;

			local levelKey = `LevelKills-{npcLevel}`;

			local levelKills = gameSave:GetStat(levelKey) or 0;
			local playerLevel = gameSave:GetStat("Level") or 0;
			if levelKills > 0 and math.fmod(levelKills, modGlobalVars.GetFocusLevel(playerLevel, npcLevel)) == 0 then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 2 then
						modMission:CompleteMission(player, MISSION_ID);
					end;
				end)
			end

		end
	end)
end

-- MARK: IsClient()
if RunService:IsClient() then
	local player = game.Players.LocalPlayer;
	
	function MissionLogic.ProgressionPoint1()
		local highlight = modGuiHighlight.Set("MainInterface", "QuickButtons", "SocialMenu");
	end

	function MissionLogic.ProgressionPoint2()
		local highlight = modGuiHighlight.Set("MainInterface", "SocialMenu", "RightBackground", "ProfileFrame", "focusLevels");
	end

	function MissionLogic.Cancel()
		modGuiHighlight.Set();
	end
end

return MissionLogic;