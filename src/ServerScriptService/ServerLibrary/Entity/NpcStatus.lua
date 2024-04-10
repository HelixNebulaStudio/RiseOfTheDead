local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Server only
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modParticleSprinkler = require(game.ReplicatedStorage.Particles.ParticleSprinkler);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);


local MetaStatus = {};
local Status = setmetatable({}, MetaStatus);

function MetaStatus:__index(key)
	if key == "ClassName" then return "NpcStatus"; end
	if MetaStatus[key] then return MetaStatus[key] end;
	local r;
	local s, _e = pcall(function() r = Status.NpcModule.Humanoid[key]; end)
	return s and r or nil;
end

function Status.Initialize(npcModule)
	Status.NpcModule = npcModule;
	Status.OnTarget = npcModule.OnTarget;
	
	MetaStatus.__mode = "v";
end

function MetaStatus:GetModule()
	return self.NpcModule;
end

function MetaStatus:GetHumanoid()
	return self.NpcModule and self.NpcModule.Humanoid or nil;
end

function MetaStatus:CanTakeDamageFrom(player)
	if self == nil or self.NpcModule == nil or self.NpcModule.Humanoid == nil then return false; end;
	
	local dmgMulti = modConfigurations.TargetableEntities[self.NpcModule.Humanoid.Name];
	if dmgMulti == nil or dmgMulti <= 0 then return false; end
	
	if player == nil then return true end;
	if self.NpcModule.NetworkOwners == nil then return true end;
	
	for a=1, #self.NpcModule.NetworkOwners do
		if self.NpcModule.NetworkOwners[a] == player then
			return true;
		end
	end
	
	return false;
end

function MetaStatus:TakeDamagePackage(damageSource)
	if self.NpcModule.IsDead then return end;
	
	local amount = damageSource.Damage;
	local dealer = damageSource.Dealer;
	local storageItem = damageSource.ToolStorageItem;
	local hitPart = damageSource.TargetPart;
	local damageType = damageSource.DamageType;
	
	local dmgForce = damageSource.DamageForce or Vector3.zero;
	local dmgPosition = damageSource.DamagePosition or (hitPart and hitPart.Position);

	local npcModule = self.NpcModule;
	local immortality = npcModule.Immortal;
	local humanoid = npcModule.Humanoid;
	local rootPart: BasePart = npcModule.RootPart;
	local immunity = npcModule.Immunity or 0;
	
	if damageType == "Heal" then
		amount = -amount;

	else
		if immortality and immortality > 0 then
			amount = amount * math.clamp(1-immortality, 0, 1);
		end
		
	end

	local initAmount = amount;
	local player = dealer or (storageItem and storageItem.Player);
	
	if damageType == "ExplosiveModel" then
		damageType = nil;
		immunity = 0;
	end

	if damageType == "FrostDamage" then immunity = 0 end;
	
	if npcModule.MeleeImmunity and npcModule.MeleeImmunity > 0 and damageSource.IsMeleeDamage then
		immunity = npcModule.MeleeImmunity;
	end
	
	local toxicDmgTaken = false;
	if immunity > 0 and damageType ~= "ToxicDamage" then
		local initDmg = amount;

		amount = amount * math.clamp(1-immunity, 0, 999);
		
		local toxicModValue = npcModule.EntityStatus:GetOrDefault("ToxicMod");
		if toxicModValue then
			local newImmunity = math.max(immunity - toxicModValue, 0) ; --math.clamp(immunity*toxicModValue, 0, 1);
			local toxicDamage = initDmg * (1-newImmunity) - amount;
			
			local newDmgSrc = modDamagable.NewDamageSource{
				Damage=toxicDamage;
				Dealer=dealer;
				ToolStorageItem=storageItem;
				TargetPart=hitPart;
				DamageType="ToxicDamage";
			}
			self:TakeDamagePackage(newDmgSrc);
			toxicDmgTaken = true;
		end
	end

	if initAmount > 0 and npcModule.CustomHealthbar and npcModule.CustomHealthbar.OnDamaged then
		local returnPacket = npcModule.CustomHealthbar:OnDamaged(initAmount, dealer, storageItem, hitPart);
		
		if typeof(returnPacket) == "table" then
			amount = returnPacket.Amount or amount;
			immunity = returnPacket.Immunity or immunity;

		elseif returnPacket == true then -- stop damage processing here
			local healthInfo = npcModule.CustomHealthbar.Healths[hitPart.Name];
			local damage = initAmount;
			if healthInfo and healthInfo.Health <= 0 then
				damage = 0;
			end
			
			modInfoBubbles.Create{
				Players=self:GetAttackers();
				Position=hitPart.Position;
				Value=damage;
			};
			return;
			
		elseif returnPacket == false then -- cancel damage;
			
			return;
		end
	end

	if npcModule.OnDamaged then
		if amount > 0 then
			local frostModValue = npcModule.EntityStatus:GetOrDefault("FrostMod");
			if frostModValue and damageType ~= "FrostDamage" then
				if humanoid.Health <= humanoid.MaxHealth*0.1 then
					
					local newDmgSrc = modDamagable.NewDamageSource{
						Damage=math.ceil(humanoid.MaxHealth*0.11);
						Dealer=dealer;
						ToolStorageItem=storageItem;
						TargetPart=hitPart;
						DamageType="FrostDamage";
					}
					self:TakeDamagePackage(newDmgSrc);

					modAudio.Play("IceShatter", humanoid.RootPart.Position);

					local rootPartSize = rootPart.Size.Magnitude*0.1;
					local particlePacket = {
						Type=1;
						Origin=CFrame.new(npcModule.RootPart.Position);
						Velocity=Vector3.new(0, 1, 0);
						SizeRange={Min=rootPartSize; Max=rootPartSize};
						Color=Color3.fromRGB(255,255,255);
						Material=Enum.Material.Ice;
						DespawnTime=3;
						Speed=30;
						MinSpawnCount=4;
						MaxSpawnCount=6;
					};
					modParticleSprinkler:Emit(particlePacket);
					
					Debugger:Warn("Shatter", npcModule.KilledMark, npcModule.KillerPlayer);
				end
			end
		end

		npcModule.OnDamaged(amount, dealer, storageItem, hitPart, damageType);
		
	end

	if amount < 0 and npcModule.OnHealed then 
		npcModule.OnHealed(amount, dealer, storageItem, hitPart);
	end
	
	local armorDmg, breakArmor = nil, false;
	if humanoid == nil then return end;
	if tonumber(immortality) ~= nil then
		if humanoid.Health-amount > 10 then
			humanoid:TakeDamage(amount);
		end

	elseif amount > 0 then -- On Damaged;
		if npcModule.FirstDamageTaken == nil then
			npcModule.FirstDamageTaken = tick();
		end

		npcModule.LastDamageTaken = tick();
		
		local armorSystem = npcModule.ArmorSystem;
		if armorSystem and armorSystem.Armor > 0 then
			if armorSystem.Armor - amount <= 0 then
				breakArmor = true;
			end
			armorSystem:AddArmor(-amount);
			armorDmg = amount;
			
		else
			humanoid:TakeDamage(amount);
		end

	elseif amount < 0 then -- On Heal;
		if humanoid.Health + math.abs(amount) > humanoid.MaxHealth then
			humanoid.Health = humanoid.MaxHealth;
		else
			humanoid:TakeDamage(amount);
		end
	end

	hitPart = hitPart or self.RootPart;
	if amount >= 1 then
		local dmgType = armorDmg and "Armor" or "Damage";
		if npcModule.Immunity then
			dmgType = (immunity > 0 and "Shield") or (immunity < 0 and "AntiShield");
		end
		dmgType = damageType or dmgType;
		
		local isLethal = humanoid.Health <= 0;
		
		local killMarkerSnd;
		if isLethal and npcModule.KilledMark == nil then
			npcModule.KilledMark = true;
			killMarkerSnd = (hitPart.Name == "Head" or hitPart:GetAttribute("IsHead") == true) and "KillHead" or "KillFlesh";
			
			if dmgPosition then
				rootPart:ApplyImpulseAtPosition(dmgForce * rootPart.AssemblyMass, dmgPosition);
			end
			
			local netown = dealer;
			if npcModule.Owner and not dealer:IsA("Player") then
				netown = npcModule.Owner;
			end
			
			if typeof(netown) == "Instance" and netown:IsA("Player") then
				npcModule.KillerPlayer = netown;
				npcModule:SetNetworkOwner(netown, true);
				npcModule.Remote:FireClient(netown, "ApplyImpulseAtPosition", rootPart, dmgForce * rootPart.AssemblyMass, dmgPosition);
				
			else
				npcModule:SetNetworkOwner("auto", true);
			end
		end
		
		task.spawn(function()
			if damageSource.BreakJoint ~= true then return end
			if amount <= humanoid.MaxHealth*0.05 then return end; --math.random(10, 20)/100

			local dealerRootPart: BasePart = dealer;
			if dealer:IsA("Player") then
				local classPlayer = shared.modPlayers.Get(dealer);
				dealerRootPart  = classPlayer and classPlayer.RootPart;
				
			elseif dealer:IsA("Model") then
				dealerRootPart = dealer.PrimaryPart;
				
			end
			if dealerRootPart == nil then return end;
			
			
			local motor: Motor6D = hitPart and hitPart:FindFirstChildWhichIsA("Motor6D") or nil;

			local exludeList = {
				Root=true;
				Waist=(not isLethal);
				Neck=(not isLethal);
				LeftHip=(not isLethal);
				RightHip=(not isLethal);
				ToolGrip=(not isLethal);
			};

			local leftWieldJoints = {
				LeftShoulder=true;
				LeftElbow=true;
				LeftWrist=true;
			};
			local rightWieldJoints = {
				RightShoulder=true;
				RightElbow=true;
				RightWrist=true;
			};

			if npcModule.Wield then
				if npcModule.Wield.Instances.LeftWeld then
					exludeList.LeftShoulder = math.random(1, 16) ~= 1;
					exludeList.LeftElbow = math.random(1, 16) ~= 1;
					exludeList.LeftWrist = math.random(1, 16) ~= 1;
				end
				if npcModule.Wield.Instances.RightWeld then
					exludeList.RightShoulder = math.random(1, 16) ~= 1;
					exludeList.RightElbow = math.random(1, 16) ~= 1;
					exludeList.RightWrist = math.random(1, 16) ~= 1;
				end
			end

			if npcModule.JointsStrength then
				for key, value in pairs(npcModule.JointsStrength) do
					exludeList[key] = math.random(1, math.max(value, 2)) ~= 1;
				end
			end
			
			if npcModule.Properties == nil or npcModule.Properties.BasicEnemy ~= true then return end;
			if motor == nil or exludeList[motor.Name] == true then return end;
			
			if npcModule.Wield then
				if (leftWieldJoints[motor.Name] and npcModule.Wield.Instances.LeftWeld)
					or (rightWieldJoints[motor.Name] and npcModule.Wield.Instances.RightWeld) then

					npcModule.Wield.Unequip();
				end
			end
			local activeDmg = (npcModule.Properties.AttackDamage or 0) - (npcModule.DamageReduction or 0);
			npcModule.DamageReduction = (npcModule.DamageReduction or 0) + activeDmg*0.05;


			local part1: BasePart = motor.Part1 :: BasePart;
			
			npcModule:BreakJoint(motor);
			
			local dir = (part1.Position-dealerRootPart.Position).Unit;
			part1:ApplyImpulse(dir * part1.AssemblyMass * math.random(80, 140));
		end)
		
		task.delay(0.1, function()
			if isLethal and npcModule.IsDead ~= true and npcModule.OnDeath then
				npcModule.OnDeath();
			end
		end)
		
		modInfoBubbles.Create{
			Players=self:GetAttackers();
			Position=hitPart.Position;
			Value=amount;
			Type=dmgType;

			KillSnd=killMarkerSnd;
			BreakSnd=breakArmor;
		};

	elseif amount <= -1 then
		modInfoBubbles.Create{
			Players=self:GetAttackers();
			Position=hitPart.Position;
			Value=math.abs(amount);
			Type="Heal";
		};

	else
		if toxicDmgTaken ~= true then
			local attackers = self:GetAttackers();
			
			if typeof(dealer) == "Instance" then
				if dealer:IsA("Player") and table.find(attackers, dealer) == nil then
					table.insert(attackers, dealer);

				else
					local attackerPlayer = game.Players:GetPlayerFromCharacter(dealer);
					if attackerPlayer and table.find(attackers, attackerPlayer) == nil then
						table.insert(attackers, attackerPlayer);
					end

				end
			end

			modInfoBubbles.Create{
				Players=attackers;
				Position=hitPart.Position;
				Type="Immune";
			};
		end
	end
	
	local cloneDmgSrc;
	if damageSource.Clone then
		cloneDmgSrc = damageSource:Clone();
		cloneDmgSrc.NpcModule = npcModule;
		cloneDmgSrc.Killed = npcModule.KilledMark==true;
		
	else
		cloneDmgSrc = table.clone(damageSource);
		cloneDmgSrc.NpcModule = npcModule;
		cloneDmgSrc.Killed = npcModule.KilledMark==true;
		
		Debugger:Warn(npcModule.Name,"deprecate TakeDamage used: ", debug.traceback());
	end
	
	cloneDmgSrc.Immunity = immunity;
	modOnGameEvents:Fire("OnNpcDamaged", player, cloneDmgSrc);
	
	return true;
end

function MetaStatus:TakeDamage(amount, character, storageItem, bodyPart, damageType)
	return self:TakeDamagePackage{
		Damage=amount;
		Attacker=character;
		StorageItem=storageItem;
		HitPart=bodyPart;
		DamageType=damageType;
	};
end


function MetaStatus:GetAttackers()
	local players = {};
	if self.NpcModule.Weapons then
		for name, _ in pairs(self.NpcModule.Weapons) do table.insert(players, game.Players:FindFirstChild(name)) end;
	end
	
	if self.NpcModule.NetworkOwners then
		for a=1, #self.NpcModule.NetworkOwners do
			local found = table.find(players, self.NpcModule.NetworkOwners[a]);
			if found == nil then
				table.insert(players, self.NpcModule.NetworkOwners[a]);
			end
		end
	end
	
	return players;
end

return Status;
