local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);
local modWeaponsLibrary = shared.require(game.ReplicatedStorage.Library.WeaponsLibrary);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);

local modProfile = shared.require(game.ServerScriptService.ServerLibrary.Profile);

local remoteHudNotification;

--==
local Experience = {
	BaseExp = 100;
	GoalExp = 4000;
};

--==
function Experience.onRequire()
	remoteHudNotification = modRemotesManager:Get("HudNotification");

	shared.modEventService:OnInvoked("Mission_BindMissionComplete", function(event: EventPacket, ...)
		local player = event.Player;
		if player == nil then return end;

		local mission = ...;
		task.spawn(function()
			if mission == nil then return end;
			local missionLib = mission.Library;

			local duration = 180;
			
			if missionLib.Tier then
				if missionLib.Tier == "Easy" then
					duration = 180;
				elseif missionLib.Tier == "Normal" then
					duration = 300;
				elseif missionLib.Tier == "Hard" then
					duration = 600;
				else
					duration = 600;
				end
			end

			local playerClass: PlayerClass = shared.modPlayers.get(player);
			
			playerClass.StatusComp:Apply("XpConfidence", {
				Expires = workspace:GetServerTimeNow() + duration;
				Duration = duration;
			})
		end)
	end)
end

function Experience.CalculateExpGoal(itemLevel, weaponLib)
	if weaponLib == nil then return end;

	local baseExp = Experience.BaseExp;
	local goalExp = Experience.GoalExp;

	local itemTier = (weaponLib.Tier or 1);

	local rate = math.clamp(itemLevel/20, 0, 1)^2;
	local goal = goalExp* rate^(1 + (0.1*(itemTier-1)));
	local swingOffset = goal*0.25;

	return math.ceil(baseExp + goal + (math.fmod(itemLevel, 2) == 0 and swingOffset or -swingOffset));
end

function Experience.Add(storageItem: StorageItem, exp: number)
	if modConfigurations.DisableExperienceGain then Debugger:Warn("Experience gain is disabled."); return end;

	local initialExp = exp;
	local itemId = storageItem.ItemId;
	local weaponLib = modWeaponsLibrary[itemId];

	local player = storageItem.Player;
	if player == nil then return end;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local configurations = playerClass.Configurations;

	local playerProfile = modProfile:Get(player);
	local gameSave: GameSaveRotd = playerProfile and playerProfile:GetActiveSave() or nil;
	local playerKey = tostring(player.UserId);
	

	local playerLevel = gameSave and gameSave:GetStat("Level") or 0;
	if playerLevel > 0 then
		local lvlBonusRatio = math.clamp(playerLevel/modGlobalVars.MaxLevels, 0, 1)^(1/2);

		local bonusLvlExp = math.floor(initialExp * lvlBonusRatio);
		exp += bonusLvlExp;
	end
	
	local xpConfidenceStatus: StatusClassInstance = playerClass.StatusComp:GetOrDefault("XpConfidence");
	if xpConfidenceStatus then
		local xpRatio = math.clamp((xpConfidenceStatus.Expires - workspace:GetServerTimeNow())/xpConfidenceStatus.Duration, 0, 1);
		exp += math.ceil(initialExp * xpRatio);
	end

	local xpBoostStatus: StatusClassInstance = playerClass.StatusComp:GetOrDefault("XpBoost");
	if xpBoostStatus then
		exp = exp *2;
	end


	if weaponLib == nil then
		return;
	end
	
	if gameSave == nil or gameSave.GetMasteries == nil then return end;
	
	local itemLevel = storageItem:GetValues("L") or 0;
	local currentExp = (storageItem:GetValues("E") or 0);
	
	local experienceGoal = Experience.CalculateExpGoal(itemLevel, weaponLib);
	local remainingExp = math.clamp(math.ceil(currentExp+exp-experienceGoal), 0, math.huge);
	
	local function AddExp(addExp)
		addExp = math.floor(addExp);
		
		if currentExp+addExp >= experienceGoal then
			if itemLevel < 20 then
				itemLevel = math.clamp(itemLevel +1, 0, 20);
				
				local owners = storageItem:GetValues("OwnersList");
				if owners and owners[playerKey] then
					owners[playerKey] = owners[playerKey] +1;
				end
				
				remoteHudNotification:FireClient(player, "WeaponLevelup", {StorageItem=storageItem; Level=itemLevel;});
				
				remainingExp = math.clamp(math.ceil(currentExp+addExp-experienceGoal), 0, math.huge);

				experienceGoal = Experience.CalculateExpGoal(itemLevel, weaponLib);
				currentExp = 0;

				if remainingExp > 0 then
					AddExp(remainingExp);
				end

			else
				currentExp = experienceGoal;
				remainingExp = 0;

			end
		else
			currentExp = currentExp+addExp;
			remainingExp = 0;

		end
	end
	AddExp(exp);
	
	
	local owners = storageItem:GetValues("OwnersList") or {};
	local owner = storageItem:GetValues("Owner") or playerKey;
	
	if owner == player.Name then
		owner = playerKey;
	end
	
	if owners[player.Name] then
		owners[player.Name] = nil;
		owners[playerKey] = itemLevel;
	end
	
	if owners[owner] == nil then
		owners[owner] = itemLevel;
	elseif owner ~= playerKey and owners[playerKey] == nil then
		owners[playerKey] = 0;
	end;
	
	itemLevel = 0;
	for name, levels in pairs(owners) do
		itemLevel = itemLevel + levels;
	end
	
	local ownerLevel = owners and owners[playerKey];	
	if ownerLevel and ownerLevel > (gameSave:GetMasteries(itemId) or 0) then
		gameSave:SetMasteries(itemId, ownerLevel);
	end

	storageItem:SetValues("EG", experienceGoal);
	storageItem:SetValues("E", currentExp);
	storageItem:SetValues("L", itemLevel);
	storageItem:SetValues("Owner", owner);
	storageItem:SetValues("OwnersList", owners);

	storageItem:Sync({"E"; "EG"; "L"; "Owner"; "OwnersList"});
end

return Experience;