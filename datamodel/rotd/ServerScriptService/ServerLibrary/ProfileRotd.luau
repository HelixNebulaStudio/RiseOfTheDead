local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modProfile = shared.require(game.ServerScriptService.ServerLibrary.Profile);
local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modSkillTree = shared.require(game.ServerScriptService.ServerLibrary.SkillTree);
local modTraderProfile = shared.require(game.ServerScriptService.ServerLibrary.TraderProfile);
local modItemUnlockables = shared.require(game.ServerScriptService.ServerLibrary.ItemUnlockables);
local modSafehomeData = shared.require(game.ServerScriptService.ServerLibrary.SafehomeData);
local modNpcTaskData = shared.require(game.ServerScriptService.ServerLibrary.NpcTaskData);
local modBattlePassSave = shared.require(game.ServerScriptService.ServerLibrary.BattlePassSave);

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

function modProfile.onRequire()

end

return modProfile;