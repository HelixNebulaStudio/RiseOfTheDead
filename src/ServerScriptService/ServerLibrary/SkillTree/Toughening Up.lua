local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== 
local Skill = {Library=nil;};
Skill.__index = Skill;
--==
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

--== Script;

function Skill:Trigger(profile, triggerType, points, ...)
	local classPlayer = modPlayers.GetByName(profile.Player.Name);
	if triggerType == "OnNpcDamaged" then
		local level, stats = Skill:CalStats(Skill.Library, points);
		
		local eventPacket = ...;
		local npcModule = eventPacket.NpcModule;
		local damage = eventPacket.Damage;
		
		if npcModule and damage and classPlayer.Properties.Armor > 0 then
			local maxHealth = npcModule.Humanoid and npcModule.Humanoid.MaxHealth;
			local percentageDamage = maxHealth and damage/maxHealth or 0;
			
			local armorGain = percentageDamage*100 * stats.Amount.Value;
			
			classPlayer.Properties.Armor = math.clamp(classPlayer.Properties.Armor + armorGain, 0, classPlayer.Properties.MaxArmor);
		end
		
	end
end

function Skill.init(skillTree, lib)
	Skill.Library = lib;
	setmetatable(Skill, skillTree);
	return Skill;
end

return Skill;
