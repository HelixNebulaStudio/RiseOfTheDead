local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Experience = {};

local modWeaponsLibrary = require(game.ReplicatedStorage.Library.Weapons);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);

local remoteHudNotification = modRemotesManager:Get("HudNotification");

local baseExp = 100;
local goalExp = 4300; --5500

--[[
	Average zombie kill rate base weapon: 1.6s
	
	local baseExp = 100;
	local goalExp = 4300;
	
	local random = Random.new();
	local function CalculateExpGoal(itemLevel)
		local rate = math.clamp(itemLevel/20, 0, 1)^2;
		local goal = goalExp* rate^(1 + 0.05*(itemData and itemData.Tier or 1));
		local rngOffset = goal*0.5;
		print("Exp goal",goal,"rngOffset",rngOffset);
		return math.ceil(100 + goal + (math.fmod(itemLevel, 2) == 0 and rngOffset or -rngOffset));
	end
	
	local t = 0;
	for a=0, 20 do
		local goal = CalculateExpGoal(a);
		local kills = goal/20;
		t = t+(kills*1.6);
		print("Level",a," Goal:",goal," Kills:", kills," Time:",kills*1.6);
	end
	print("Time to max weapon:",t,"s or ",t/60,"mins");
--]]

local random = Random.new();
--== Script;
function Experience.CalculateExpGoal(itemLevel, weaponLib)
	if weaponLib == nil then return end;
	local rate = math.clamp(itemLevel/20, 0, 1)^2;
	local goal = goalExp* rate^(1 + (0.1*((weaponLib.Tier or 1)-1)));
	local rngOffset = goal*0.25;
	return math.ceil(baseExp + goal + (math.fmod(itemLevel, 2) == 0 and rngOffset or -rngOffset));
end

function Experience.Add(storageItem, exp, source)
	if modConfigurations.DisableExperienceGain then Debugger:Warn("Experience gain is disabled."); return end;
	local initialExp = exp;
	local itemId = storageItem.ItemId;
	local weaponLib = modWeaponsLibrary[itemId];
	local player = storageItem.Player;
	local classPlayer = modPlayers.GetByName(player.Name);
	local playerProfile = player and modProfile:Get(player);
	local playerSave = playerProfile and playerProfile:GetActiveSave() or nil;
	local playerKey = tostring(player.UserId);
	
	if classPlayer and classPlayer.Properties and classPlayer.Properties["XpBoost"] then
		exp = exp *2;
	end
	
	if weaponLib then
		if playerSave and playerSave.GetMasteries then
			local itemLevel = storageItem:GetValues("L") or 0;
			local experienceGoal = Experience.CalculateExpGoal(itemLevel, weaponLib);
			local currentExp = (storageItem:GetValues("E") or 0);
			local remaindingExp = math.clamp(math.ceil(currentExp+exp-experienceGoal), 0, math.huge);
			
			local function AddExp(addExp)
				addExp = math.floor(addExp);
				
				if script:GetAttribute("Debug") == true then
					Debugger:Log(storageItem.ID,"AddExp", addExp);
				end
				
				if currentExp+addExp >= experienceGoal then
					if itemLevel < 20 then
						itemLevel = math.clamp(itemLevel +1, 0, 20);
						
						local owners = storageItem:GetValues("OwnersList");
						if owners and owners[playerKey] then
							owners[playerKey] = owners[playerKey] +1;
						end
						
						remoteHudNotification:FireClient(player, "WeaponLevelup", {StorageItem=storageItem; Level=itemLevel;});
						
						experienceGoal = Experience.CalculateExpGoal(itemLevel, weaponLib);
						currentExp = 0;
						remaindingExp = math.clamp(math.ceil(currentExp+addExp-experienceGoal), 0, math.huge);
						if remaindingExp > 0 then
							AddExp(remaindingExp);
						end
					else
						currentExp = experienceGoal;
						remaindingExp = 0;
					end
				else
					currentExp = currentExp+addExp;
					remaindingExp = 0;
				end
			end
			AddExp(exp);
			
			if playerSave then
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
				if ownerLevel and ownerLevel > (playerSave:GetMasteries(itemId) or 0) then
					playerSave:SetMasteries(itemId, ownerLevel);
				end

				playerSave.Inventory:SetValues(storageItem.ID, {
					EG=experienceGoal;
					E=currentExp;
					L=itemLevel;
					Owner=owner;
					OwnersList=owners;
				});
			else
				storageItem:SetValues("EG", experienceGoal);
				storageItem:SetValues("E", currentExp);
				storageItem:SetValues("L", itemLevel);
			end
		else
			Debugger:Warn("Missing playerSave(",playerSave == nil,").");
		end
	end
end

return Experience;