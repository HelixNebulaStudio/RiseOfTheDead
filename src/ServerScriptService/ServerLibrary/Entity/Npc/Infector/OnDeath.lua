local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local CollectionService = game:GetService("CollectionService");

--== Modules
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);

local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modExperience = require(game.ServerScriptService.ServerLibrary.Experience);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);

local Zombie = {};

function Zombie.new(self)
	return function()
		local prefab = self.Prefab;

		self:KillNpc();
		CollectionService:RemoveTag(prefab, "TargetableEntities");
		prefab.Parent = workspace.Entities;
		delay(2, function() prefab:Destroy(); end)
		
		if self.Logic then self.Logic.Cancelled = true; end
		self.DeathPosition = self.RootPart.CFrame.p;
		self.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
		if self.StopAllAnimations then self.StopAllAnimations(); end;
		
		modAudio.Play("ZombieDeath4", self.RootPart).PlaybackSpeed = 1;
		

		modOnGameEvents:Fire("OnZombieDeath", self);

		local playerTags = modDamageTag:Get(self.Prefab, "Player");
		for a=1, #playerTags do
			local playerTag = playerTags[a];
			local player = playerTag.Player;
			local playerSave = modProfile:Get(player):GetActiveSave();

			if playerSave and playerSave.AddStat then
				playerSave:AddStat("Kills", 1);
			end
			
			local maxHealth = self.Humanoid.MaxHealth;
			if self.Weapons and self.Weapons[player.Name] then
				local weaponsPool = self.Weapons[player.Name];
				
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