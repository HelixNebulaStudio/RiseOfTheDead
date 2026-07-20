local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);
local modSfxService = shared.require(game.ReplicatedStorage.Library.SfxService);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modMath = shared.require(game.ReplicatedStorage.Library.Util.Math);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

local NpcComponent = {};
NpcComponent.ClassName = "NpcComponent";
NpcComponent.__index = NpcComponent;
NpcComponent.HitIndex = 0;
NpcComponent.HitCache = {};
--==

function NpcComponent.onRequire()
	remoteNpcComponent = modRemotesManager:Get("NpcComponent");

	remoteNpcComponent.OnServerEvent:Connect(function(player, compName, hitIndex, isHit)
		if compName ~= script.Name then return end;

		for a=#NpcComponent.HitCache, 1, -1 do
			local hitCache = NpcComponent.HitCache[a];

			if hitCache.HitIndex ~= hitIndex then continue end;
			if hitCache.Player ~= player then continue end;

			hitCache.IsHit = isHit;
		end
	end)
end

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
			
			npcClass.Move:HeadTrack(enemyClass.Head, 4);
			npcClass.Move:Face(targetPosition, nil, 0.3);

		elseif targetEntityClass.ClassName == "Destructible" then
			local destructible: DestructibleInstance = targetEntityClass :: DestructibleInstance;

			npcClass.Move:HeadTrack(targetPart, 4);
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
		if npcAudio and typeof(npcAudio.BasicMeleeAttack) == "string" then
			modAudio.Play(npcAudio.BasicMeleeAttack, npcClass.RootPart).PlaybackSpeed = (math.random(100, 120)/100);
		elseif npcAudio and npcAudio.BasicMeleeAttack == false then
		else
			modAudio.Play("ZombieAttack"..math.random(1, 3), npcClass.RootPart).PlaybackSpeed = (math.random(100, 120)/100);
		end

		local configurations: ConfigVariable = npcClass.Configurations;

		npcClass.PlayAnimation("Attack", 0.05, nil, 1);

		if targetEntityClass.ClassName == "PlayerClass" or targetEntityClass.ClassName == "NpcClass" then
			local isZombieMeleeDebounced = targetEntityClass.Properties 
				and targetEntityClass.Properties.ZombieMeleeDebounce
				and tick() < targetEntityClass.Properties.ZombieMeleeDebounce;
				
			if isZombieMeleeDebounced then return end; -- Hit Cooldown

			if targetEntityClass.Properties then
				targetEntityClass.Properties.ZombieMeleeDebounce = tick()+0.1;
			end
		end

		npcClass.Move:SetMoveSpeed("set", "attack", 0, npcClass.Move.MoveSpeedPriority.Action, 0.5);
		
		local character = npcClass.Character;
		local rootPart = npcClass.RootPart;
		local humanoid = npcClass.Humanoid;

		local charCf = character:GetPivot();
		local extentsSize = npcClass.DefaultExtentsSize;

		local meleeBoxSize = Vector3.new(extentsSize.X, extentsSize.Y, configurations.AttackRange + extentsSize.Z);
		local meleeBoxCf = charCf * CFrame.new(0, -humanoid.HipHeight-rootPart.Size.Y/2 + (extentsSize.Y/2), -(meleeBoxSize.Z/2));

		local curTick = tick();
		local hitCache;
		if targetEntityClass.ClassName == "PlayerClass" then
			local player = (targetEntityClass :: PlayerClass):GetInstance();

			NpcComponent.HitIndex += 1;
			hitCache = {
				Player = player; 
				HitIndex = NpcComponent.HitIndex;
				Tick = tick()+1;
			};

			table.insert(NpcComponent.HitCache, hitCache);
			remoteNpcComponent:FireClient(
				player,
				"ZombieBasicMeleeAttack", 
				"attack", 
				hitCache.HitIndex,
				meleeBoxCf,
				meleeBoxSize,
				targetPart
			);

			for a=#NpcComponent.HitCache, 1, -1 do
				if curTick < NpcComponent.HitCache[a].Tick then continue end;
				table.remove(NpcComponent.HitCache, a);
			end
		end

		local targetVel = targetPart.AssemblyLinearVelocity;

		task.wait(0.5);
		if npcClass.HealthComp.IsDead then return end;

		local isInMeleeHitboxServer = modVector.IsInBoundingBox(meleeBoxCf, meleeBoxSize, targetPosition);
		local isInMeleeHitboxClient = hitCache and hitCache.IsHit == true;

		targetPosition += targetVel;

		if RunService:IsStudio() then
			local box = Instance.new("Part");
			box.Anchored = true;
			box.CanCollide = false;
			box.CanQuery = false;
			box.CanTouch = false;
			box.Color = Color3.fromRGB(255, 0, 0);
			box.Material = Enum.Material.ForceField;
			box.Size = meleeBoxSize;
			box.CFrame = meleeBoxCf;
			box.Parent = workspace.Debris;

			Debugger.Expire(box, 0.1);
		end
		if not isInMeleeHitboxClient or not isInMeleeHitboxServer then return end;

		local distance = enemyTargetData.Distance or 999;
		local dmgMulti = 1;
		
		local attackDamage = configurations.AttackDamage;

		if targetEntityClass.ClassName == "NpcClass" then
			attackDamage = math.min(attackDamage + (enemyHealthComp.MaxHealth * 0.1), npcClass.HealthComp.MaxHealth);
			
		elseif targetEntityClass.ClassName == "Destructible" then
			dmgMulti = 1+math.abs(modMath.GaussianRandom());
		
		end

		attackDamage = attackDamage * dmgMulti;

		local dmgData: DamageData = DamageData.new{
			Damage = attackDamage;
			DamageBy = npcClass;
			DamageTo = targetEntityClass;
			DamageCate = DamageData.DamageCategory.Melee;
			TargetPart = targetPart;
		};
		enemyHealthComp:TakeDamage(dmgData);

		if targetEntityClass.ClassName == "Destructible" then return end;

		modSfxService.spawnImpactEffect{
			BasePart = targetPart;
			Point = targetPosition;
			Normal = -npcClass:GetCFrame().LookVector;
			ImpactType = "Impact";
		};
		
		if configurations.CripplingHit and configurations.CripplingHit >= math.random(0, 100)/100 then
			local targetCharacterClass: CharacterClass = targetEntityClass :: CharacterClass;

			targetCharacterClass.StatusComp:Apply("Slowness", {
				Expires = workspace:GetServerTimeNow() + 5;
				Duration = 5;
				Values = {
					Amount = 10;
				};
			});
		end

    end
end

return NpcComponent;