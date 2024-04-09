local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local CollectionService = game:GetService("CollectionService");

--== Modules
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modExperience = require(game.ServerScriptService.ServerLibrary.Experience);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modTagging = require(game.ServerScriptService.ServerLibrary.Tagging);
local modGlobalVars = require(game.ReplicatedStorage.GlobalVariables);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local random = Random.new();

local Zombie = {};

function Zombie.new(self)
	return function(players)
		local prefab = self.Prefab;

		self:KillNpc();
		CollectionService:RemoveTag(prefab, "TargetableEntities");
		prefab.Parent = workspace.Entities;
		delay(2, function() prefab:Destroy(); end)
		
		if players == nil then
			local tagsList = modTagging.Tagged[prefab];
			if tagsList then
				for a=#tagsList, 1, -1 do
					local tagData = tagsList[a];
					if tagData ~= nil and tagData.Tagger and tagData.Tagger.Parent ~= nil then
						players = game.Players:GetPlayerFromCharacter(tagData.Tagger);
						if players then break; end
					end
				end
			end
		end
		
		if self.Logic then self.Logic.Cancelled = true; end
		self.DeathPosition = self.RootPart.CFrame.p;
		self.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
		if self.StopAllAnimations then self.StopAllAnimations(); end;
		
		players = type(players) == "table" and players or {players};
	
		modAudio.Play("ZombieDeath4", self.RootPart).PlaybackSpeed = 1;
		
		if #players > 0 then
			modOnGameEvents:Fire("OnZombieDeath", players, self);
		end
		for a=1, #players do
			local player = players[a];
			local playerSave = modProfile:Get(player):GetActiveSave();
			if playerSave and playerSave.AddStat then
				playerSave:AddStat("Kills", 1);
			end
			
			local maxHealth = self.Humanoid.MaxHealth;
			if self.Weapons and self.Weapons[player.Name] then
				local weaponsPool = self.Weapons[player.Name];
				local playerSave = modProfile:Get(player):GetActiveSave();
				for id, weaponData in pairs(weaponsPool) do
					local damageRatio = math.clamp(weaponData.Damaged/maxHealth, 0, 1);
					local expPool = 100;
					
					local experienceGain = math.floor(damageRatio * expPool);
					modExperience.Add(weaponData.Weapon, experienceGain, self.Name);

					local storageItem = playerSave and playerSave.Inventory:Find(id) or nil;
					if storageItem then
						storageItem:Sync({"L"; "E"; "EG"});
					end
					
				end
			end
		end
	end
end

return Zombie;