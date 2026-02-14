local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);
local modSfxService = shared.require(game.ReplicatedStorage.Library.SfxService);

local NpcComponent = {};
NpcComponent.ClassName = "NpcComponent";
NpcComponent.__index = NpcComponent;
--==

function NpcComponent.new(npcClass: NpcClass)
    return function(targetPart)
		if npcClass.HealthComp.IsDead then return end;
        if npcClass:IsRagdolling() then return end;

		local disarmStatus = npcClass.StatusComp:GetOrDefault("Disarm");
		if disarmStatus then 
			npcClass.PlayAnimation("Disarm");
			return;
		end

		local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
		if enemyTargetData == nil then return end;

		local enemyHealthComp: HealthComp = enemyTargetData.HealthComp;
		if not enemyHealthComp:CanTakeDamageFrom(npcClass) then
			return;
		end

		local targetEntityClass: EntityClass = enemyHealthComp.CompOwner;
		targetPart = targetPart or targetEntityClass.RootPart;
		local targetPosition = targetPart.Position;
		
		if targetEntityClass.ClassName == "PlayerClass" or targetEntityClass.ClassName == "NpcClass" then
			local enemyClass: CharacterClass = targetEntityClass :: CharacterClass;
			
			npcClass.Move:HeadTrack(enemyClass.Head);
			npcClass.Move:Face(targetPosition, nil, 0.3);

		elseif targetEntityClass.ClassName == "Destructible" then
			local destructible: DestructibleInstance = targetEntityClass :: DestructibleInstance;

			npcClass.Move:HeadTrack(targetPart);
			npcClass.Move:Face(targetPart, nil, 0.3);

			local dir = (targetPosition - npcClass.Head.Position).Unit;

			local raycastParams = RaycastParams.new();
			raycastParams.FilterType = Enum.RaycastFilterType.Include;
			raycastParams.FilterDescendantsInstances = {targetPart};

			local raycastResult: RaycastResult = workspace:Raycast(npcClass.Head.Position, dir*16, raycastParams);
			if raycastResult then
				modSfxService.spawnImpactEffect{
					BasePart = targetPart;
					Point = raycastResult.Position;
					Normal = raycastResult.Normal;
					ImpactType = "Impact";
				};
			end
		end

		local npcAudio = npcClass.NpcPackage.Audio;
		if npcAudio and npcAudio.BasicMeleeAttack ~= false then
			modAudio.Play(npcAudio.BasicMeleeAttack, npcClass.RootPart).PlaybackSpeed = (math.random(100, 120)/100);
		elseif npcAudio and npcAudio.BasicMeleeAttack == false then
		else
			modAudio.Play("ZombieAttack"..math.random(1, 3), npcClass.RootPart).PlaybackSpeed = (math.random(100, 120)/100);
		end

		local configurations = npcClass.Configurations;

		npcClass.PlayAnimation("Attack", 0.05, nil, 2);

		local distance = enemyTargetData.Distance or 999;
		local dmgRange = math.pow((1-math.clamp(distance/configurations.AttackRange, 0, 1)), 1/2);
		
		local attackDamage = configurations.AttackDamage;

		if targetEntityClass.ClassName == "NpcClass" then
			attackDamage = attackDamage + (enemyHealthComp.MaxHealth * 0.1);
			
		elseif targetEntityClass.ClassName == "Destructible" then
			dmgRange = 1;
		
		end

		attackDamage = attackDamage * dmgRange;

		local dmgData: DamageData = DamageData.new{
			Damage = attackDamage;
			DamageBy = npcClass;
			DamageTo = targetEntityClass;
			DamageCate = DamageData.DamageCategory.Melee;
			TargetPart = targetPart;
		};
		enemyHealthComp:TakeDamage(dmgData);
		
    end
end

return NpcComponent;