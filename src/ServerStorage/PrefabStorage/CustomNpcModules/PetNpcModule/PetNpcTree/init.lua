local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);
local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

return function(self)
	local tree = modLogicTree.new{
		NotHasTarget={"Not"; "HasTarget";};
		AttackSelect={"Or"; "MeleeSequence"; "RangedSequence"; "FireAttackSelect";};
		Root={"Or"; "FollowOwner"; "HealSequence"; "AggroSequence"; "ReloadSequence";};
		RangedSequence={"And"; "SwitchWeaponRanged";};
		HealSequence={"And"; "ShouldHeal"; "NotHasTarget"; "SwitchToolHeal"; "UseHeals";};
		FireAttackSelect={"Or"; "MeleeAttack"; "RangedAttack";};
		NotIsMeleeRange={"Not"; "IsMeleeRange";};
		ReloadSequence={"And"; "AttemptReload";};
		MeleeSequence={"And"; "IsMeleeRange"; "SwitchWeaponMelee";};
		AggroSequence={"And"; "HasTarget"; "AttackSelect";};
	}
	
	self.FollowOwner = true;
	self.FollowGap = 16;
	
	self.TargetNpcModule = nil;
	
	self.MeleeTarget = nil;
	self.LastSwitchWeapon = tick()-10;
	
	local targetableEntities = modConfigurations.TargetableEntities;
	
	tree:Hook("FollowOwner", function()
		if self.MeleeTarget and tick()-self.MeleeTarget <= 2 then
			self.Move:SetMoveSpeed("set", "sprint", 25, 2, 2);
			return modLogicTree.Status.Failure;
		end
		local ownerRootPart: BasePart = self.Actions:GetOwnerRoot();
		
		if self.FollowOwner then
			local ownerDist = self.Owner:DistanceFromCharacter(self.RootPart.Position);
			
			if ownerDist >= 64 then
				self.Actions:Teleport();
				
			elseif ownerDist >= 16 then
				self.Move:SetMoveSpeed("set", "sprint", 25, 2, 1);
				
			else
				self.Move:SetMoveSpeed("set", "walk", 10, 2, 1);
			end
			
			if ownerRootPart then
				self.Move:Follow(ownerRootPart, self.FollowGap);
			end
		end
		
		return modLogicTree.Status.Failure;
	end)

	tree:Hook("HasTarget", function()
		local ownerCharacter = self.Owner and self.Owner.Character;
		
		self.Wield.Targetable = targetableEntities;
		
		local targetNpcModule;
		
		for a=1, #modNpc.NpcModules do
			local npcModule = modNpc.NpcModules[a] and modNpc.NpcModules[a].Module;
			if npcModule 
				and npcModule.Humanoid 
				and targetableEntities[npcModule.Humanoid.Name]
				and npcModule.IsDead ~= true
				and (npcModule.Target == ownerCharacter or npcModule.Target == self.Prefab)
				and self.IsInVision(npcModule.RootPart) then
				
				targetNpcModule = npcModule;
				
				break;
			end
		end
		
		self.TargetNpcModule = targetNpcModule;
		
		if targetNpcModule == nil then
			return modLogicTree.Status.Failure;
		end
		return modLogicTree.Status.Success;
	end)

	tree:Hook("ShouldHeal", function()
		if self.Humanoid.Health > self.Humanoid.MaxHealth * 0.5 then
			return modLogicTree.Status.Failure;
		end
		return modLogicTree.Status.Success;
	end)
	
	
	tree:Hook("SwitchToolHeal", function()
		self.Wield.Equip(self.ActiveHealTool);
		self.LastSwitchWeapon = tick()-10;
		
		return modLogicTree.Status.Success;
	end)

	tree:Hook("UseHeals", function()
		self.Wield.PlayAnim("Use");
		task.wait(self.Wield.ToolModule.Configurations.UseDuration);
		
		if self.IsDead then
			return modLogicTree.Status.Failure;
		end

		local toolHandler = self.Wield.ToolHandler;
		toolHandler.ToolConfig.Configurations.HealAmount = self.Humanoid.MaxHealth * 0.5;
	
		self.Wield.ActionRequest("heal");
		self.Wield.StopAnim("Use");
		
		return modLogicTree.Status.Success;
	end)
	
	
	tree:Hook("IsMeleeRange", function()
		if self.TargetNpcModule == nil then return modLogicTree.Status.Failure; end;
		
		local distFromTarget = (self.RootPart.Position - self.TargetNpcModule.RootPart.Position).Magnitude;
		if distFromTarget <= 14 then
			return modLogicTree.Status.Success;
		end
		return modLogicTree.Status.Failure;
	end)

	tree:Hook("SwitchWeaponMelee", function()
		if tick()-self.LastSwitchWeapon < 10 then
			return modLogicTree.Status.Failure;
		end
		self.LastSwitchWeapon = tick();
		
		self.Wield.Equip(self.ActiveMeleeWeapon);
		return modLogicTree.Status.Success;
	end)

	tree:Hook("MeleeAttack", function()
		if self.Wield.ItemId ~= self.ActiveMeleeWeapon then
			return modLogicTree.Status.Failure;
		end
		
		local targetHumanoid = self.TargetNpcModule.Humanoid;
		local targetRootPart = self.TargetNpcModule.RootPart;
		
		pcall(function()
			self.Wield.ToolModule.Configurations.Damage = math.max(targetHumanoid.MaxHealth * 0.45, 120);
		end);
		
		self.MeleeTarget = tick();
		self.Move:Follow(targetRootPart, 1);
		self.Move:LookAt(targetRootPart);
		self.Move:Face(targetRootPart);
		
		self.Wield.SetEnemyHumanoid(targetHumanoid);
		self.Wield.PrimaryFireRequest();
		
		return modLogicTree.Status.Success;
	end)
	
	
	tree:Hook("SwitchWeaponRanged", function()
		if tick()-self.LastSwitchWeapon < 10 then
			return modLogicTree.Status.Failure;
		end
		self.LastSwitchWeapon = tick();
		
		self.Wield.Equip(self.ActiveRangedWeapon);
		return modLogicTree.Status.Success;
	end)

	tree:Hook("RangedAttack", function()
		if self.Wield.ItemId ~= self.ActiveRangedWeapon then
			return modLogicTree.Status.Failure;
		end
		
		if self.Wield.ToolModule.Properties.Ammo <= 0 then
			return modLogicTree.Status.Failure;
		end
		
		local targetHumanoid = self.TargetNpcModule.Humanoid;
		local targetRootPart = self.TargetNpcModule.RootPart;
		
		pcall(function()
			local dmgRatio = 1/self.Wield.ToolModule.Configurations.AmmoLimit;
			self.Wield.ToolModule.Configurations.MinBaseDamage = math.clamp(targetHumanoid.MaxHealth * math.max(dmgRatio, 0.1), 35, 32100);
		end);

		table.clear(self.Wield.Targetable);
		self.Wield.Targetable[targetHumanoid.Name] = 1;

		self.Move:Follow(targetRootPart, 4);
		self.Move:LookAt(targetRootPart);
		self.Move:Face(targetRootPart);

		self.Wield.SetEnemyHumanoid(targetHumanoid);
		self.Wield.PrimaryFireRequest();

		return modLogicTree.Status.Success;
	end)
	

	tree:Hook("AttemptReload", function()
		local properties = self.Wield.ToolModule and self.Wield.ToolModule.Properties;
		if self.TargetNpcModule then
			self.LastSwitchWeapon = tick()-10;
		end

		local isMeleeRange = tree:Call("IsMeleeRange") == modLogicTree.Status.Success;
		if isMeleeRange then
			return modLogicTree.Status.Failure;
		end
		
		if self.TargetNpcModule == nil or properties.Ammo <= 0 then
			self.Wield.ReloadRequest();
		end

		return tree.Failure;
	end)
	
	return tree;
end