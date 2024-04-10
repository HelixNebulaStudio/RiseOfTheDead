local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
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

local Zombie = {};

function Zombie.new(self)
	return function(players)
		local prefab = self.Prefab;
		local config = self.Configuration;

		self:KillNpc();
		CollectionService:RemoveTag(prefab, "TargetableEntities");
		--prefab.Parent = workspace.Entities;

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

		if config.Audio and config.Audio.Death and config.Audio.Death ~= false then
			modAudio.Play(config.Audio.Death, self.RootPart).PlaybackSpeed = math.random(100, 120)/100;
		elseif config.Audio and config.Audio.Death == false then
		else
			modAudio.Play("ZombieDeath"..math.random(1, 4), self.RootPart).PlaybackSpeed = math.random(50, 150)/100;
		end

		if self.DropReward and #players > 0 then
			self:DropReward(CFrame.new(self.DeathPosition) * CFrame.Angles(math.rad(math.random(0, 360)), math.rad(math.random(0, 360)), math.rad(math.random(0, 360))));
		end

		if #players > 0 then
			modOnGameEvents:Fire("OnZombieDeath", players, self);
			modOnGameEvents:Fire("OnNpcDeath", players, self);
		end

		for a=1, #players do
			local player = players[a];
			local profile = modProfile:Get(player);
			local playerSave = profile:GetActiveSave();

			if playerSave and playerSave.AddStat then
				playerSave:AddStat("Kills", 1);
				playerSave:AddStat("ZombieKills", 1);
				profile:AddPlayPoints(3);

				local moneyReward = math.random(config.MoneyReward.Min, config.MoneyReward.Max) + (config.Level-1);
				playerSave:AddStat("Money", moneyReward);

				if playerSave.Statistics then
					local killKey = "L"..config.Level.."-"..self.Name.."Kills";
					playerSave.Statistics:AddStat("KillTracker", killKey, 1);
				end

				local levelKey = "LevelKills-"..config.Level;
				playerSave:AddStat(levelKey, 1);

				local levelKills = playerSave:GetStat(levelKey) or 0;
				local playerLevel = playerSave:GetStat("Level") or 0;
				if levelKills > 0 and math.fmod(levelKills, modGlobalVars.GetFocusLevel(playerLevel, config.Level)) == 0 then
					playerSave:AddStat("Perks", 1);

					if not modMission:IsComplete(player, 27) then
						modMission:Progress(player, 27, function(mission)
							if mission.ProgressionPoint == 2 then
								modMission:CompleteMission(player, 27);
							end;
						end)
					end

					shared.Notify(player, (("Killed $enemyName [$level] +$$moneyReward, +1 Perk"):gsub("$level", config.Level)
						:gsub("$enemyName", self.Name):gsub("$moneyReward", moneyReward)), "Reward");

					modAnalytics.RecordResource(player.UserId, 1, "Source", "Perks", "Gameplay", "FocusKills");
				else
					shared.Notify(player, (("Killed $enemyName [$level] +$$moneyReward"):gsub("$level", config.Level)
						:gsub("$enemyName", self.Name):gsub("$moneyReward", moneyReward)), "Reward");
				end
			end

			local totalDamage = 0;
			if self.Weapons and self.Weapons[player.Name] then
				local weaponsPool = self.Weapons[player.Name];
				local playerSave = modProfile:Get(player):GetActiveSave();

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