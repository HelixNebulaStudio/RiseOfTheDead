local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--=
local random = Random.new();

--== Modules
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);

local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modExperience = require(game.ServerScriptService.ServerLibrary.Experience);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modGlobalVars = require(game.ReplicatedStorage.GlobalVariables);

local Enemy = {};

function Enemy.new(self)
	return function()
		self:KillNpc();

		if self.Logic then self.Logic.Cancelled = true; end
		self.DeathPosition = self.RootPart.CFrame.p;
		self.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
		if self.StopAllAnimations then self.StopAllAnimations(); end;
		
		if self.Configuration.Audio and self.Configuration.Audio.Death and self.Configuration.Audio.Death ~= false then
			modAudio.Play(self.Configuration.Audio.Death, self.RootPart).PlaybackSpeed = random:NextNumber(1, 1.2);
		elseif self.Configuration.Audio and self.Configuration.Audio.Death == false then
		else
			modAudio.Play("HumanDeath", self.RootPart);
		end
		
		local playerTags = modDamageTag:Get(self.Prefab, "Player");

		if self.DropReward and #playerTags > 0 then
			self:DropReward(CFrame.new(self.DeathPosition) * CFrame.Angles(math.rad(random:NextNumber(0, 360)), math.rad(random:NextNumber(0, 360)), math.rad(random:NextNumber(0, 360))));
		end
		
		modOnGameEvents:Fire("OnNpcDeath", self);
		
		for a=1, #playerTags do
			local playerTag = playerTags[a];
			local player = playerTag.Player;
			local profile = modProfile:Get(player);

			local playerSave = modProfile:Get(player):GetActiveSave();
			if playerSave and playerSave.AddStat then
				playerSave:AddStat("Kills", 1);
				playerSave:AddStat("HumanKills", 1);
				profile:AddPlayPoints(3, "Gameplay:Kill");
				
				local moneyReward = random:NextInteger(self.Configuration.MoneyReward.Min, self.Configuration.MoneyReward.Max) + 2*(self.Configuration.Level-1);
				playerSave:AddStat("Money", moneyReward);
				
				if playerSave.Statistics then
					local killKey = "L"..self.Configuration.Level.."-"..self.Name.."Kills";
					playerSave.Statistics:AddStat("KillTracker", killKey, 1);
				end
				
				local levelKey = "LevelKills-"..self.Configuration.Level;
				playerSave:AddStat(levelKey, 1);
				
				local levelKills = playerSave:GetStat(levelKey) or 0;
				local playerLevel = playerSave:GetStat("Level") or 0;
				if levelKills > 0 and math.fmod(levelKills, modGlobalVars.GetFocusLevel(playerLevel, self.Configuration.Level)) == 0 then
					playerSave:AddStat("Perks", 1);
					
					shared.Notify(player, (("Killed $enemyName [$level] +$$moneyReward, +1 Perk"):gsub("$level", self.Configuration.Level)
						:gsub("$enemyName", self.Name):gsub("$moneyReward", moneyReward)), "Reward");
				else
					shared.Notify(player, (("Killed $enemyName [$level] +$$moneyReward"):gsub("$level", self.Configuration.Level)
						:gsub("$enemyName", self.Name):gsub("$moneyReward", moneyReward)), "Reward");
				end
			end
			
			local maxHealth = self.Humanoid.MaxHealth;
			if self.Weapons and self.Weapons[player.Name] then
				local weaponsPool = self.Weapons[player.Name];
				
				for id, weaponData in pairs(weaponsPool) do
					local damageRatio = math.clamp(weaponData.Damaged/maxHealth, 0, 1);
					local experienceGain = math.floor(damageRatio*self.Configuration.ExperiencePool);
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

return Enemy;