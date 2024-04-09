local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);

local CollectionService = game:GetService("CollectionService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);

local remotes = game.ReplicatedStorage.Remotes;
local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;

return function(self)
	local tree = modLogicTree.new{
		Root={"Or"; "AggroLogic"};
		
		AggroLogic={"And"; "CanMoveTest"; "CanMove";};
		CanMove={"IfElse"; "CanAttackTest"; "CanAttack"; "InDanger";};
		InDanger={"And"; "InDangerTest"; "runToSafety";};
		CanAttack={"And"; "CanDashTest"; "CanDash";};
		CanDash={"And"; "dashToTarget"; "TargetDistTest"; "throwAttack"};
		
	};
	
	local cache = {};
	cache.AttackCooldown = 6--0.2;
	cache.AttackTick = tick();
	cache.DashCooldown = 3;
	cache.DashTick = tick();
	cache.DangerTick = tick();
	cache.DangerStartTick = tick();
	
	tree:Hook("CanMoveTest", function()
		return modLogicTree.Status.Success;
	end)
	tree:Hook("CanAttackTest", function() 
		return tick()-cache.AttackTick <= cache.AttackCooldown and modLogicTree.Status.Failure or modLogicTree.Status.Success;
	end)
	tree:Hook("CanDashTest", function()
		return modLogicTree.Status.Success;
	end)
	
	local projsOverlapParams = OverlapParams.new();
	projsOverlapParams.FilterType = Enum.RaycastFilterType.Include;
	projsOverlapParams.MaxParts = 1;
	
	tree:Hook("InDangerTest", function()
		if tick() - cache.DangerTick < 10 then return modLogicTree.Status.Failure end;
		
		local danger = nil
		for a=1, #self.Enemies do
			local rootPart = self.Enemies[a] and self.Enemies[a].Humanoid and self.Enemies[a].Humanoid.Health > 0 and self.Enemies[a].Humanoid.RootPart;
			if rootPart and (self.RootPart.Position-rootPart.Position).Magnitude <= 16 then
				danger = rootPart;
				break;
			end
		end
		
		local projectileList = CollectionService:GetTagged("Projectile");
		projsOverlapParams.FilterDescendantsInstances = projectileList;
		local hitList = workspace:GetPartBoundsInRadius(self.RootPart.Position, 64, projsOverlapParams);
		
		if #hitList >= 1 then
			danger = hitList[1];
		end
		
		if danger and danger ~= cache.DangerPart then
			cache.DangerStartTick = tick();
			cache.DangerPart = danger
			
			return modLogicTree.Status.Success;
		end
		
		
		return modLogicTree.Status.Failure;
	end)
	
	tree:Hook("runToSafety", function()
		local displace = (self.RootPart.Position - cache.DangerPart.Position)
		local runDir = displace.Unit;
		
		self.Movement.DefaultWalkSpeed = 100;
		self.Movement:Move(self.RootPart.Position + runDir * 8);
		
		if displace.Magnitude > 17 or tick()-cache.DangerStartTick > 4 then
			cache.DangerTick = tick();
			cache.DangerPart = nil;
			
		end
		
		print("runToSafety")
		
		return modLogicTree.Status.Success;
	end)
	
	tree:Hook("dashToTarget", function()
		local targetRootPart = self.Target.PrimaryPart;
		
		local tarPos = targetRootPart.Position;
		
		self.Movement.DefaultWalkSpeed = 100;
		self.Movement:Move(tarPos);
		
		--print("dashToTarget")
		
		return modLogicTree.Status.Success;
	end)

	tree:Hook("TargetDistTest", function()
		local targetRootPart = self.Target.PrimaryPart;
		local dist = targetRootPart and (self.RootPart.Position-targetRootPart.Position).Magnitude or math.huge;
		
		if dist <= 3 then
			cache.DashTick = tick() + math.random(-10, 10)/10;
			
			return modLogicTree.Status.Success;
		end
		return modLogicTree.Status.Failure;
	end)
	
	tree:Hook("throwAttack", function()
		--cache.AttackTick = tick();
		
		--local targetHumanoid = self.Target:FindFirstChildWhichIsA("Humanoid") or nil;
		
		--self.PlayAnimation("Attack",0.05, nil, 2);
		
		--local enemyName = self.Target.Name;
		--local enemyPlayer = game.Players:FindFirstChild(enemyName);
		--if enemyPlayer then
		--	remoteCameraShakeAndZoom:FireClient(enemyPlayer, 10, 5, 4, 0.01, true);
			
		--	local dir = self.RootPart.CFrame.LookVector;
		--	modAudio.Play("Punch", self.RootPart);
		--	modStatusEffects.Launch(enemyPlayer, (dir+Vector3.new(0, 1, 0))*100);
		--end
		
		--self:DamageTarget(targetHumanoid.Parent, 5);
		
		--print("throwAttack")
		
		--return modLogicTree.Status.Success;
	end)
	
	return tree;
end


--[[
	--AggroLogic={"Selector"; "CanMoveCheck";};
	--CanMoveCheck={"Sequence"; "CanMove"; "DashSequence"; "CanAttackCheck"};
	--DashSequence={"Sequence"; "IsDashing"; "DashToTarget"};
	--CanAttackCheck={"Sequence"; "CanAttack"; "CanDashCheck"};
	--CanDashCheck={"Sequence"; "CanDash"; "DashToTarget"; "CheckTargetDist"};
	--CheckTargetDist={"Sequence"; "checkTargetDist"; "throwAttack"};
]]