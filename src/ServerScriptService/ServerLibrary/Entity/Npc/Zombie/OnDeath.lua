local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

--== Modules
local modGlobalVars = require(game.ReplicatedStorage.GlobalVariables);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);

local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modExperience = require(game.ServerScriptService.ServerLibrary.Experience);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modAnalyticsService = require(game.ServerScriptService.ServerLibrary.AnalyticsService);

local Zombie = {};

function Zombie.new(self)
	return function()
		local prefab = self.Prefab;
		local config = self.Configuration;
		
		self:KillNpc();
		CollectionService:RemoveTag(prefab, "TargetableEntities");

		if self.Logic then self.Logic.Cancelled = true; end
		self.DeathPosition = self.RootPart.CFrame.p;
		self.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
		if self.StopAllAnimations then self.StopAllAnimations(); end;

		if config.Audio and config.Audio.Death and config.Audio.Death ~= false then
			modAudio.Play(config.Audio.Death, self.RootPart).PlaybackSpeed = math.random(100, 120)/100;
		elseif config.Audio and config.Audio.Death == false then
		else
			modAudio.Play("ZombieDeath"..math.random(1, 4), self.RootPart).PlaybackSpeed = math.random(50, 150)/100;
		end

		local playerTags = modDamageTag:Get(prefab, "Player");
		if self.DropReward and #playerTags > 0 then
			self:DropReward(CFrame.new(self.DeathPosition) * CFrame.Angles(math.rad(math.random(0, 360)), math.rad(math.random(0, 360)), math.rad(math.random(0, 360))));
		end

		modOnGameEvents:Fire("OnZombieDeath", self);
		modOnGameEvents:Fire("OnNpcDeath", self);

		for a=1, #playerTags do
			local playerTag = playerTags[a];
			local player = playerTag.Player;
			local profile = modProfile:Get(player);
			local playerSave = profile:GetActiveSave();

			if playerSave and playerSave.AddStat then
				playerSave:AddStat("Kills", 1);
				playerSave:AddStat("ZombieKills", 1);

				local killNotice = {`Killed {self.Name} [{config.Level}]`};
				if config.MoneyReward then
					local moneyReward = math.random(config.MoneyReward.Min, config.MoneyReward.Max) + (config.Level-1);

					if playerSave:AddStat("Money", moneyReward) > 0 then
						modAnalyticsService:Source{
							Player=player;
							Currency=modAnalyticsService.Currency.Money;
							Amount=moneyReward;
							EndBalance=playerSave:GetStat("Money");
							ItemSKU=`Kill:{self.Name}`;
						};
					end

					table.insert(killNotice, `+${moneyReward}`);
				end

				local levelKey = "LevelKills-"..config.Level;
				playerSave:AddStat(levelKey, 1);
				local levelKills = playerSave:GetStat(levelKey) or 0;
				local playerLevel = playerSave:GetStat("Level") or 0;
				if levelKills > 0 and math.fmod(levelKills, modGlobalVars.GetFocusLevel(playerLevel, config.Level)) == 0 then

					if playerSave:AddStat("Perks", 1) > 0 then
						modAnalytics.RecordResource(player.UserId, 1, "Source", "Perks", "Gameplay", "FocusKills");
						modAnalyticsService:Source{
							Player=player;
							Currency=modAnalyticsService.Currency.Perks;
							Amount=1;
							EndBalance=playerSave:GetStat("Perks");
							ItemSKU=`FocusKills`;
						};
					end

					modOnGameEvents:Fire("OnFocusKill", self, player);
					table.insert(killNotice, `+1 Perk`);
				end
				
				shared.Notify(player, table.concat(killNotice, " "), "Reward");
				
				
				-- statistics;
				profile:AddPlayPoints(3, "Gameplay:Kill:Zombie");
				if playerSave.Statistics then
					local killKey = "L"..config.Level.."-"..self.Name.."Kills";
					playerSave.Statistics:AddStat("KillTracker", killKey, 1);
				end
			end

			local totalDamage = 0;
			if self.Weapons and self.Weapons[player.Name] then
				local weaponsPool = self.Weapons[player.Name];
				
				for id, weaponData in pairs(weaponsPool) do
					totalDamage = totalDamage + weaponData.Damaged;
				end

				for id, weaponData in pairs(weaponsPool) do
					local damageRatio = math.clamp(weaponData.Damaged/totalDamage, 0, 1);

					local ttk = math.max(tick() - (self.FirstDamageTaken or tick()), 0);

					if self.DebugTTK then
						local ttkStr = self.Name.." Time-To-Kill: "..math.round(ttk*1000)/1000 .."s"

						if game:GetService("RunService"):IsStudio() then
							Debugger:Warn(ttkStr);
						else
							shared.Notify(player, ttkStr, "Inform");
						end
					end

					local expTtRatio = math.clamp(ttk/60, 0, 1);
					local expPool = config.ExperiencePool or 20;

					expPool = math.clamp(expPool * expTtRatio, 20, math.max(config.ExperiencePool, 20));

					local experienceGain = math.floor(damageRatio * expPool);
					modExperience.Add(weaponData.Weapon, experienceGain, self.Name);

					local storageItem = playerSave and playerSave.Inventory:Find(id) or nil;
					if storageItem then
						storageItem:Sync({"L"; "E"; "EG"});
					end

				end
			end
		end

		local faceDecal = prefab:FindFirstChild("face", true);
		if faceDecal then
			faceDecal.Texture = "rbxassetid://4644356184";
		end
	end;
end

return Zombie;