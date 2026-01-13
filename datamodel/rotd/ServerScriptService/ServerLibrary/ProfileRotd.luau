local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);

local modProfile = shared.require(game.ServerScriptService.ServerLibrary.Profile);
local modSkillTree = shared.require(game.ServerScriptService.ServerLibrary.SkillTree);
local modTraderProfile = shared.require(game.ServerScriptService.ServerLibrary.TraderProfile);
local modItemUnlockables = shared.require(game.ServerScriptService.ServerLibrary.ItemUnlockables);
local modSafehomeData = shared.require(game.ServerScriptService.ServerLibrary.SafehomeData);
local modNpcTaskData = shared.require(game.ServerScriptService.ServerLibrary.NpcTaskData);
local modBattlePassSave = shared.require(game.ServerScriptService.ServerLibrary.BattlePassSave);
local modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);
local modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);

--==
shared.coreBind(modProfile, "_new", function(profile: ProfileRotd, player: Player)
    profile.SkillTree = modSkillTree.new(player);
    profile.ItemUnlockables = modItemUnlockables.new(player);
    profile.Trader = modTraderProfile.new(player);

    profile.Safehome = modSafehomeData.new(player); profile.Safehome:Init();
    profile.BattlePassSave = modBattlePassSave.new(profile, function() profile:Sync("BattlePassSave"); end);
    
    profile.NpcTaskData = modNpcTaskData.new(player);
    
    --== Faction Integration
    profile.Faction = {
        FactionTitle="n/a";
        FactionIcon="9890634236";
        FactionColor="c8c8c8";
    }
end)

shared.coreBind(modProfile, "_key_load", function(profile: ProfileRotd, key: string, data: any, loadOverwrite: anydict?)
    if key == "SkillTree" then
        profile[key]:Load(data);
        return true;
    end

    return false;
end)

shared.coreBind(modProfile, "_save", function(profile: ProfileRotd, overrideData: any?, force: boolean?)
    
	if modBranchConfigs.IsWorld("Safehome") then
		if profile.Safehome then
			profile.Safehome.LastActive = os.time();
		end 
	end

	if profile.Trader then
		profile.Trader:SaveTrades();
	end
end)

shared.coreBind(modProfile, "_reset_save", function(profile: ProfileRotd)
	profile.SkillTree:ClearTrees();
end)

shared.coreBind(modProfile, "_sync", function(profile: ProfileRotd, hierarchyKey: string?, paramPacket: anydict?)
    if hierarchyKey == nil then
		if profile.Trader then
			profile.Trader:SyncGold();
		end
	    profile:Sync("SkillTree");
    end
end)

shared.coreBind(modProfile, "_sync_public", function(profile: ProfileRotd, publicData: anydict, caller: Player)
	local activeSave = profile.ActiveGameSave;

	if profile.Premium then
		activeSave:AwardAchievement("premem", false);
	end
	if profile.GamePass.PortableWorkbench then
		activeSave:AwardAchievement("theeng", false);
	end
	if profile.GamePass.VipTraveler then
		activeSave:AwardAchievement("theeng", false);
	end
	if profile.GamePass.DbTinker then
		activeSave:AwardAchievement("dbtinker", false);
	end
    
	local playerLevel = activeSave:GetStat("Level") or 0;
	local focusLevel = modGlobalVars.GetLevelToFocus(playerLevel);
	publicData.Stats["FocusLevel"] = focusLevel;

	local completedMissions = 0;
	for a=1, #activeSave.Missions do
		if activeSave.Missions[a].Type == 3 then
			completedMissions = completedMissions + 1;
		end
	end
	publicData.Stats["MissionsCompleted"] = completedMissions;

	publicData.Stats["TraderRep"] = math.floor(profile.Trader:CalRep()*100).."%";
end)

shared.coreBind(modProfile, "_unload", function(profile: ProfileRotd)
    profile.Safehome:Destroy();
end)


function modProfile.onRequire()
	local remoteProfileService = modRemotesManager:Get("ProfileService");

	local enterCampaignDebounce = {};
	function remoteProfileService.OnServerInvoke(player, action, ...)
		local playerClass: PlayerClass = shared.modPlayers.get(player);

		if action == "menu/solo" then
			if enterCampaignDebounce[player.Name] and tick()-enterCampaignDebounce[player.Name] <= 1 then return end;
			enterCampaignDebounce[player.Name] = tick();
			
			local rPacket = {
				Success = false;
			};
			
			local profile = modProfile:Get(player);
			if profile == nil then
				modServerManager:TeleportToPrivateServer("MainMenu", modServerManager:CreatePrivateServer("MainMenu"), {player});
				return rPacket;
			end

			local isGameOnline = false;
			local s, e = pcall(function()
				isGameOnline = game:GetService("DataStoreService"):GetDataStore("LiveConfig"):GetAsync("Online") ~= false
			end)
			if not s then
				Debugger:Warn("LiveConfig>>  ", e);
			end

			if not isGameOnline then
				if profile == nil or (profile.GroupRank or 0) < 100 then
					profile:GuiAction("promptwarning", "Servers are currently under maintenance, please wait.", true);
					return rPacket;
				else
					shared.Notify(player, "Joining maintenance servers as Rank:"..(profile.GroupRank or 0), "Inform");
				end
			end
			
			local saveData = profile:GetActiveSave();
			if saveData == nil then
				warn("Player(",player.Name,") does not have any savedata.");
				return rPacket;
			end

			if modBranchConfigs.WorldName ~= "MainMenu" then
				rPacket.Success = true;
				rPacket.Index = 3;

				task.delay(1, function()
					playerClass = shared.modPlayers.get(player);
					playerClass:Spawn();
				end)
				return rPacket;
			end

			local beginningMission = saveData.Missions:Get(1);
			if beginningMission and beginningMission.Type == 3 then
				-- if followName and followName ~= "/solo" then
				-- 	local success = modServerManager:TravelToPlayer(player, followName);
				-- 	if success then return end;
				-- end
				local spawnId = saveData.Spawn;
				local worldId = modBranchConfigs.GetWorldOfSpawn(spawnId);
				
				if worldId == nil then
					shared.Notify(player, "Invalid SpawnId ("..spawnId.."), spawning in the warehouse.", "Negative");
					worldId = "TheWarehouse";
				end
				modServerManager:Travel(player, worldId);
				rPacket.Index = 2;
				
			else
				modAnalyticsService:LogOnBoarding{
					Player=player;
					OnBoardingStep=modAnalyticsService.OnBoardingSteps.ClickPlay;
				};
				saveData.Missions:Start(1);
				
				modServerManager:Teleport(player, "TheBeginning");
				rPacket.Index = 1;
			end

			rPacket.Success = true;
			
			return rPacket;
		end

		return;
	end

end

return modProfile;