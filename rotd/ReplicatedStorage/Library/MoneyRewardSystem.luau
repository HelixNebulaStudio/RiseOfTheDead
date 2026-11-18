local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Script;
local MoneyRewardSystem = {};

MoneyRewardSystem.Config = {
	LevelGapPenalty = 0.10;
	MinLevelGapMultiplier = 0.10;
	MaxLevelGapMultiplier = 1.00;

	MinShare = 0.00;

	MaxSkillBonus = 0.50;
	FastKillWindow = 1.0;
	LongRangeDistance = 200;
	PointBlankDistance = 8;
	OverkillMultiplier = 1.5;
};

MoneyRewardSystem.Bonuses = {
	{
		Tag = "Headshot";
		Text = "Headshot";
		Bonus = 0.15;
		Check = function(self, params)
			return params.IsKiller and params.IsHeadshot;
		end;
	};
	{
		Tag = "WeakPoint";
		Text = "Weak Point";
		Bonus = 0.30;
		Check = function(self, params)
			return params.IsKiller and params.IsWeakPoint == true;
		end;
	};
	{
		Tag = "OneShot";
		Text = "One Shot";
		Bonus = 0.25;
		Suppresses = {"FastKill"};
		Check = function(self, params)
			return params.IsKiller
				and params.KillingBlowDamage >= (params.NpcMaxHealth + params.NpcMaxArmor);
		end;
	};
	{
		Tag = "FastKill";
		Text = "Quick Kill";
		Bonus = 0.20;
		Check = function(self, params)
			return params.FirstDamageTaken ~= nil
				and params.DeathTime ~= nil
				and (params.DeathTime - params.FirstDamageTaken) <= self.Config.FastKillWindow;
		end;
	};
	{
		Tag = "MultiKill";
		Text = "Chain Kill";
		Bonus = 0.25;
		Check = function(self, params)
			return params.IsKiller
				and params.TimeSinceLastKill ~= nil
				and params.TimeSinceLastKill <= 0.3;
		end;
	};
	{
		Tag = "NoDamage";
		Text = "Untouched";
		Bonus = 0.15;
		Check = function(self, params)
			return params.FirstDamageTaken ~= nil
				and params.PlayerLastDamageTaken ~= nil
				and params.PlayerLastDamageTaken < params.FirstDamageTaken;
		end;
	};
	{
		Tag = "LongRange";
		Text = "Long Range";
		Bonus = 0.15;
		Check = function(self, params)
			return params.IsKiller
				and params.KillDistance ~= nil
				and params.KillDistance >= self.Config.LongRangeDistance;
		end;
	};
	{
		Tag = "PointBlank";
		Text = "Point Blank";
		Bonus = 0.15;
		Check = function(self, params)
			return params.IsKiller
				and params.KillDistance ~= nil
				and params.KillDistance <= self.Config.PointBlankDistance;
		end;
	};
	{
		Tag = "Overkill";
		Text = "Overkill";
		Bonus = 0.10;
		Check = function(self, params)
			return params.IsKiller
				and params.KillingBlowDamage >= (params.NpcMaxHealth + params.NpcMaxArmor) * self.Config.OverkillMultiplier;
		end;
	};
	{
		Tag = "Aerial";
		Text = "Aerial Kill";
		Bonus = 0.15;
		Check = function(self, params)
			return params.IsKiller and params.IsPlayerAirborne == true;
		end;
	};
	{
		Tag = "Melee";
		Text = "Melee Kill";
		Bonus = 0.20;
		Check = function(self, params)
			return params.IsKiller and params.DamageCate == "Melee";
		end;
	};
	{
		Tag = "Explosive";
		Text = "Explosive Kill";
		Bonus = 0.15;
		Check = function(self, params)
			return params.IsKiller
				and (params.DamageCate == "Area Of Effect"
					or params.DamageType == "Explosive");
		end;
	};
	{
		Tag = "Fire";
		Text = "Burned";
		Bonus = 0.15;
		Check = function(self, params)
			return params.IsKiller and params.DamageType == "Fire";
		end;
	};
	{
		Tag = "Electric";
		Text = "Electrocuted";
		Bonus = 0.15;
		Check = function(self, params)
			return params.IsKiller and params.DamageType == "Electric";
		end;
	};
	{
		Tag = "Frost";
		Text = "Frozen";
		Bonus = 0.15;
		Check = function(self, params)
			return params.IsKiller and params.DamageType == "Frost";
		end;
	};
	{
		Tag = "Toxic";
		Text = "Toxicity";
		Bonus = 0.15;
		Check = function(self, params)
			return params.IsKiller and params.DamageType == "Toxic";
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

	for _, bonus in ipairs(self.Bonuses) do
		if bonus.Check(self, params) then
			totalBonus += bonus.Bonus;
			table.insert(awarded, {
				Tag = bonus.Tag;
				Text = bonus.Text;
				Bonus = bonus.Bonus;
				Suppresses = bonus.Suppresses;
			});
		end
	end

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
			table.remove(awarded, i);
		end
	end

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
