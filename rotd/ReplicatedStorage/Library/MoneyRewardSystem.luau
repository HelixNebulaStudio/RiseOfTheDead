local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Script;
local MoneyRewardSystem = {};

MoneyRewardSystem.Config = {
	LevelGapPenalty = 0.10;
	MinLevelGapMultiplier = 0.10;
	MaxLevelGapMultiplier = 1.00;

	MinShare = 0.00;

	MaxSkillBonus = 10;
	FastKillWindow = 1.0;
	LongRangeDistance = 200;
	PointBlankDistance = 8;
	OverkillMultiplier = 2;
	MixedDamagesMinSources = 2;

	UnderdogLevelGap = 10;
	StreakWindow = 5;
	RampageStreak = 5;
};

MoneyRewardSystem.Bonuses = {
	{
		Tag = "Headshot";
		Text = "Headshot";
		Bonus = 1;
		Check = function(self, params)
			return params.IsKiller and params.IsHeadshot;
		end;
	};
	{
		Tag = "WeakPoint";
		Text = "Weak Point";
		Bonus = 2;
		Check = function(self, params)
			return params.IsKiller and params.IsWeakPoint == true;
		end;
	};
	{
		Tag = "OneShot";
		Text = "One Shot";
		Bonus = 1;
		Suppresses = {"FastKill"};
		Check = function(self, params)
			return params.IsKiller
				and params.DamageSources ~= nil
				and #params.DamageSources == 1
				and params.NpcMaxArmor <= 0
				and params.KillingBlowDamage >= params.NpcMaxHealth;
		end;
	};
	{
		Tag = "FastKill";
		Text = "Quick Kill";
		Bonus = 0.5;
		Check = function(self, params)
			return params.FirstDamageTaken ~= nil
				and params.DeathTime ~= nil
				and (params.DeathTime - params.FirstDamageTaken) <= self.Config.FastKillWindow;
		end;
	};
	{
		Tag = "MultiKill";
		Text = "Chain Kill";
		Bonus = 0.2;
		Check = function(self, params)
			return params.IsKiller
				and params.TimeSinceLastKill ~= nil
				and params.TimeSinceLastKill <= 0.3;
		end;
	};
	{
		Tag = "LongRange";
		Text = "Long Range";
		Bonus = 1;
		Check = function(self, params)
			return params.IsKiller
				and params.KillDistance ~= nil
				and params.KillDistance >= self.Config.LongRangeDistance;
		end;
	};
	{
		Tag = "PointBlank";
		Text = "Point Blank";
		Bonus = 1;
		Check = function(self, params)
			return params.IsKiller
				and params.KillDistance ~= nil
				and params.KillDistance <= self.Config.PointBlankDistance;
		end;
	};
	{
		Tag = "Overkill";
		Text = "Overkill";
		Bonus = 1.5;
		Suppresses = {"OneShot"};
		Check = function(self, params)
			return params.IsKiller
				and params.DamageSources ~= nil
				and #params.DamageSources == 1
				and params.KillingBlowDamage >= (params.NpcMaxHealth + params.NpcMaxArmor) * self.Config.OverkillMultiplier;
		end;
	};
	{
		Tag = "MixedDamages";
		Text = "Mixed Damages";
		Bonus = 0.5;
		Check = function(self, params)
			return params.IsKiller
				and params.DamageSources ~= nil
				and #params.DamageSources >= self.Config.MixedDamagesMinSources;
		end;
	};
	{
		Tag = "Aerial";
		Text = "Aerial Kill";
		Bonus = 2;
		Check = function(self, params)
			return params.IsKiller and params.IsPlayerAirborne == true;
		end;
	};
	{
		Tag = "Sliding";
		Text = "Sliding Kill";
		Bonus = 2;
		Check = function(self, params)
			return params.IsKiller and params.PlayerProperties.IsSliding == true;
		end;
	};
	{
		Tag = "Sleding";
		Text = "Sleding Kill";
		Bonus = 1.5;
		Check = function(self, params)
			return params.IsKiller and params.PlayerProperties.IsSleding == true;
		end;
	};
	{
		Tag = "Melee";
		Text = "Melee Kill";
		Bonus = 1;
		Suppresses = {"PointBlank"};
		Check = function(self, params)
			return params.IsKiller and params.DamageCate == "Melee";
		end;
	};
	{
		Tag = "Explosive";
		Text = "Explosive Kill";
		Bonus = 0.3;
		Check = function(self, params)
			return params.IsKiller
				and (params.DamageCate == "Area Of Effect"
					or params.DamageType == "Explosive");
		end;
	};
	{
		Tag = "Fire";
		Text = "Burned";
		Bonus = 1;
		Check = function(self, params)
			return params.IsKiller and params.DamageType == "Fire";
		end;
	};
	{
		Tag = "Electric";
		Text = "Electrocuted";
		Bonus = 0.3;
		Check = function(self, params)
			return params.IsKiller and params.DamageType == "Electric";
		end;
	};
	{
		Tag = "Frost";
		Text = "Frozen";
		Bonus = 1;
		Check = function(self, params)
			return params.IsKiller and params.DamageType == "Frost";
		end;
	};
	{
		Tag = "Toxic";
		Text = "Toxicity";
		Bonus = 1;
		Check = function(self, params)
			return params.IsKiller and params.DamageType == "Toxic";
		end;
	};
	{
		Tag = "Underdog";
		Text = "Underdog";
		Bonus = 1.5;
		Check = function(self, params)
			return params.IsKiller
				and (params.NpcLevel or 0) - (params.PlayerLevel or 0) >= self.Config.UnderdogLevelGap;
		end;
	};
	{
		Tag = "CritKill";
		Text = "Critical Kill";
		Bonus = 0.5;
		Suppresses = {"Headshot"};
		Check = function(self, params)
			return params.IsKiller and params.DamageType == "Crit";
		end;
	};
	{
		Tag = "BledOut";
		Text = "Bled Out";
		Bonus = 1.5;
		Check = function(self, params)
			return params.IsKiller and params.DamageType == "Bleed";
		end;
	};
	{
		Tag = "Submerged";
		Text = "Submerged";
		Bonus = 1;
		Check = function(self, params)
			return params.IsKiller
				and params.PlayerProperties ~= nil
				and params.PlayerProperties.IsUnderWater == true;
		end;
	};
	{
		Tag = "Rampage";
		Text = "Rampage";
		Bonus = 1.5;
		Check = function(self, params)
			return params.IsKiller
				and (params.KillStreak or 0) >= self.Config.RampageStreak;
		end;
	};
	--MARK: Combos
	{
		Tag = "Marksman";
		Text = "Marksman";
		Bonus = 1;
		Requires = {"LongRange", "WeakPoint"};
		Check = function(self, params)
			return params.IsKiller;
		end;
	};
	{
		Tag = "SharpShooter";
		Text = "Sharp Shooter";
		Bonus = 1;
		Requires = {"LongRange", "Headshot"};
		Check = function(self, params)
			return params.IsKiller;
		end;
	};
	{
		Tag = "AerialSlasher";
		Text = "Aerial Melee";
		Bonus = 2;
		Requires = {"Aerial", "Melee"};
		Check = function(self, params)
			return params.IsKiller;
		end;
	};
	{
		Tag = "ChainExecution";
		Text = "Chain Execution";
		Bonus = 1;
		Requires = {"MultiKill", "Headshot"};
		Check = function(self, params)
			return params.IsKiller;
		end;
	};
};

--==
function MoneyRewardSystem:GetLevelGapMultiplier(playerLevel: number?, npcLevel: number?): number
	local config = self.Config;

	local gap = (playerLevel or 0) - (npcLevel or 0);
	if gap <= 0 then
		return config.MaxLevelGapMultiplier;
	end

	local multiplier = 1 - gap * config.LevelGapPenalty;
	return math.clamp(multiplier, config.MinLevelGapMultiplier, config.MaxLevelGapMultiplier);
end

function MoneyRewardSystem:GetDamageShare(playerDamage: number?, totalDamage: number?, participantCount: number?): number
	local config = self.Config;

	if totalDamage and totalDamage > 0 then
		return math.clamp((playerDamage or 0) / totalDamage, config.MinShare, 1);
	end

	if participantCount and participantCount > 0 then
		return 1 / participantCount;
	end

	return 1;
end

function MoneyRewardSystem:GetFeed(): {anydict}
	local feed = {};
	for _, bonus in ipairs(self.Bonuses) do
		table.insert(feed, {
			Tag = bonus.Tag;
			Text = bonus.Text;
		});
	end
	return feed;
end

function MoneyRewardSystem:GetSkillBonus(params: anydict): (number, {anydict})
	local config = self.Config;

	local totalBonus = 0;
	local awarded = {};
	local awardedTags = {};

	local function awardBonus(bonus)
		totalBonus += bonus.Bonus;
		awardedTags[bonus.Tag] = true;
		table.insert(awarded, {
			Tag = bonus.Tag;
			Text = bonus.Text;
			Bonus = bonus.Bonus;
			Suppresses = bonus.Suppresses;
		});
	end

	local function applySuppressions()
		local suppressed = {};
		for _, bonus in ipairs(awarded) do
			if bonus.Suppresses then
				for _, tag in ipairs(bonus.Suppresses) do
					suppressed[tag] = true;
				end
			end
		end
		for i = #awarded, 1, -1 do
			if suppressed[awarded[i].Tag] then
				totalBonus -= awarded[i].Bonus;
				awardedTags[awarded[i].Tag] = nil;
				table.remove(awarded, i);
			end
		end
	end

	for _, bonus in ipairs(self.Bonuses) do
		if bonus.Requires == nil and bonus.Check(self, params) then
			awardBonus(bonus);
		end
	end
	applySuppressions();

	for _, bonus in ipairs(self.Bonuses) do
		if bonus.Requires ~= nil then
			local allPresent = true;
			for _, tag in ipairs(bonus.Requires) do
				if not awardedTags[tag] then
					allPresent = false;
					break;
				end
			end
			if allPresent and bonus.Check(self, params) then
				awardBonus(bonus);
			end
		end
	end
	applySuppressions();

	totalBonus = math.min(totalBonus, config.MaxSkillBonus);
	return totalBonus, awarded;
end

function MoneyRewardSystem:Compute(params: anydict): anydict?
	local baseReward = params.BaseReward or 0;
	if baseReward <= 0 then
		return nil;
	end

	local levelMultiplier = self:GetLevelGapMultiplier(params.PlayerLevel, params.NpcLevel);
	local share = self:GetDamageShare(params.PlayerDamage, params.TotalDamage, params.ParticipantCount);
	local skillBonus, awardedBonuses = self:GetSkillBonus(params);

	local totalReward = baseReward * levelMultiplier;
	local shareReward = totalReward * share;
	local finalReward = math.floor(shareReward * (1 + skillBonus) + 0.5);

	return {
		Base = baseReward;
		LevelMultiplier = levelMultiplier;
		Share = share;
		SkillBonus = skillBonus;
		Bonuses = awardedBonuses;
		Total = finalReward;
	};
end

return MoneyRewardSystem;
