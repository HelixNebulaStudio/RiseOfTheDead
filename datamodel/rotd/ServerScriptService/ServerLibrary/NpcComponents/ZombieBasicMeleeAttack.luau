local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local NpcComponent = {};
--==

function NpcComponent.new(npcClass: NpcClass)
    return function()
		if npcClass.HealthComp.IsDead then return end;
        if npcClass:IsRagdolling() then return end;

		local disarmStatus = npcClass.StatusComp:GetOrDefault("Disarm");
		if disarmStatus then 
			npcClass.PlayAnimation("Disarm");
			return;
		end

		local enemyTargetData = npcClass.Properties.EnemyTargetData;
		if enemyTargetData == nil then return end;

		local npcAudio = npcClass.NpcPackage.Audio;

		local enemyHealthComp: HealthComp = enemyTargetData.HealthComp;
		local enemyClass: CharacterClass = enemyHealthComp.CompOwner;
		if not enemyHealthComp:CanTakeDamageFrom(npcClass) then
			return;
		end

		if npcAudio.BasicMeleeAttack ~= false then
			modAudio.Play(npcAudio.BasicMeleeAttack, enemyClass.RootPart).PlaybackSpeed = (math.random(100, 120)/100);
		elseif npcAudio.BasicMeleeAttack == false then
		else
			modAudio.Play("ZombieAttack"..math.random(1, 3), enemyClass.RootPart).PlaybackSpeed = (math.random(100, 120)/100);
		end

		npcClass.Move:HeadTrack(enemyClass.Head);
		npcClass.Move:Face(enemyClass.RootPart.Position, nil, 0.3);
		npcClass.PlayAnimation("Attack", 0.05, nil, 2);

		local distance = enemyTargetData.Distance or 999;
		local dmgRange = math.pow((1-math.clamp(distance/npcClass.Properties.AttackRange, 0, 1)), 1/2);
		
		local attackDamage = npcClass.Configurations.AttackDamage;
		attackDamage = attackDamage * dmgRange;

		local dmgData: DamageData = DamageData.new{
			Damage = attackDamage;
			DamageBy = npcClass;
			DamageTo = enemyClass;
			DamageCate = DamageData.DamageCategory.Melee;
		};
		enemyHealthComp:TakeDamage(dmgData);
		
    end
end

return NpcComponent;