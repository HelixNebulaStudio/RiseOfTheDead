local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);

local TweenService = game:GetService("TweenService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRegion = require(game.ReplicatedStorage.Library.Region);

local explosionEffectPrefab = script:WaitForChild("ExplosionEffect");
return function(self)
	local tree = modLogicTree.new{
		IgniteSequence={"And"; "Ignite"; "Detonate";};
		Root={"Or"; "StatusLogic"; "SetAggressSequence"; "AggroSequence"; "SetAggressLevel0"; "Idle";};
		AggroSelect={"Or"; "SetAggressLevel1"; "IgniteSequence"; "FollowTarget"; };
		SetAggressSequence={"And"; "SetAggress";};
		AggroSequence={"And"; "HasTarget"; "AggroSelect";};
	}
	
	local targetHumanoid, targetRootPart;
	local cache = {};

	tree:Hook("StatusLogic", self.StatusLogic);
	
	tree:Hook("HasTarget", function() 
		targetHumanoid = self.Target and self.Target:FindFirstChildWhichIsA("Humanoid") or nil;
		targetRootPart = self.Target and self.Target.PrimaryPart;
		
		if self.Target ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
			return modLogicTree.Status.Success;
		end

		self.Prefab:SetAttribute("DetonationTime", nil);
		
		return modLogicTree.Status.Failure;
	end)
	
	tree:Hook("FollowTarget", function()
		targetRootPart = self.Target and self.Target.PrimaryPart;
		
		self.Move:Follow(targetRootPart);
		
		return modLogicTree.Status.Success;
	end)

	tree:Hook("Idle", function()
		return modLogicTree.Status.Success;
	end)
		
	tree:Hook("SetAggressLevel0", function()
		if self.AggressLevel ~= 0 then
			self.AggressLevel = 0;
		end

		return modLogicTree.Status.Failure;
	end)
	
	tree:Hook("SetAggressLevel1", function()
		if self.AggressLevel < 1 then
			self.AggressLevel = 1;
		end

		return modLogicTree.Status.Failure;
	end)
	
	tree:Hook("SetAggress", function()
		if self.SetAggression then
			tree:Call("SetAggressLevel"..self.SetAggression);
			self.SetAggression = nil;
		end
		
		return modLogicTree.Status.Failure;
	end)

	tree:Hook("Ignite", function()
		if self.Detonated then
			return modLogicTree.Status.Failure;
		end
		
		local detonTime = self.Prefab:GetAttribute("DetonationTime");
		if detonTime == nil then
			--local dist = self.GetTargetDistance();
			--if dist <= 100 then
			if modRegion:InRegion(self.RootPart.Position, self.Target:GetPivot().Position, 30) then
				local duration = 4;
				self.Prefab:SetAttribute("DetonationTime", workspace:GetServerTimeNow()+duration);
				
				local tickingSound = modAudio.Play("ZombieAttack3", self.RootPart);
				tickingSound.Looped = true;
				tickingSound.Volume = 0;
				self.Garbage:Tag(tickingSound);
				
				task.spawn(function()
					detonTime = self.Prefab:GetAttribute("DetonationTime");
					while workspace:GetServerTimeNow() <= detonTime do
						local timeLeft = self.Prefab:GetAttribute("DetonationTime")-workspace:GetServerTimeNow();
						
						timeLeft = duration-math.clamp(timeLeft, 0, duration);
						
						tickingSound.PlaybackSpeed = 1+ (timeLeft/duration * 8);
						tickingSound.Volume = math.clamp(timeLeft/duration, 0.5, 1);
						task.wait(0.2);
						if self.IsDead then break end;
					end

					game.Debris:AddItem(tickingSound, 0);
					if self.IsDead then return end;
					modAudio.Play("TicksZombieExplode", self.RootPart.Position).PlaybackSpeed = math.random(100,120)/100;
					tree:Call("Detonate");
				end)
			end
			
		end
		
		return modLogicTree.Status.Failure;
	end)

	tree:Hook("Detonate", function()
		if self.Detonated then
			return modLogicTree.Status.Failure;
		end
		self.Detonated = true;
		
		if self.IsDead then return end;
		self.Humanoid:SetAttribute("DisableRagdoll", true);
		
		local newEffect = explosionEffectPrefab:Clone();
		newEffect.CFrame = self.Head.CFrame;
		local effectMesh = newEffect:WaitForChild("Mesh");
		newEffect.Parent = workspace.Debris;
		local speed = 0.5;
		local range = 60;
		TweenService:Create(effectMesh, TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = Vector3.new(range,range,range)}):Play();
		TweenService:Create(newEffect, TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.8}):Play();
		Debugger.Expire(newEffect, speed+0.1);
		
		local damage = self.Properties.AttackDamage * (1-math.clamp(self.GetTargetDistance(), 0, 30)/30);
		if damage >= 1  then
			task.spawn(function()
				if game.Players:FindFirstChild(targetHumanoid.Parent.Name) then
					local classPlayer = shared.modPlayers.Get(game.Players[targetHumanoid.Parent.Name]);

					if classPlayer then
						local gasProtection = classPlayer:GetBodyEquipment("GasProtection");
						if gasProtection then
							damage = damage * (1-gasProtection);
						end

						if classPlayer.Properties.tickre then
							return;
						end

						local tickRepellent = classPlayer:GetBodyEquipment("TickRepellent");
						if tickRepellent then
							classPlayer:SetProperties("tickre", {Expires=workspace:GetServerTimeNow()+tickRepellent; Duration=tickRepellent; Amount=tickRepellent;});
						end
					end
				end

				self:DamageTarget(targetHumanoid.Parent, damage);
			end)
		end

		task.spawn(function()
			game.Debris:AddItem(self.Prefab:FindFirstChild("ExplosiveTickBlobs"), 0);
			
			local explosionPoint = self.RootPart.Position + Vector3.new(math.random(-20,20)/100, -0.5, math.random(-20,20)/100);
			for _, obj: BasePart in pairs(self.Prefab:GetChildren()) do
				if not obj:IsA("BasePart") then continue end;
				
				local motor = obj:FindFirstChildWhichIsA("Motor6D")
				if motor and motor:GetAttribute("RagdollJoint") and obj.Name ~= "LowerTorso" then
					self:BreakJoint(motor);
					
					local force = math.random(80, 140);
					local dir = (obj.Position-explosionPoint).Unit;
					local vel = dir * obj.AssemblyMass * force;
					obj:ApplyImpulse(vel);
				end
				
			end
		end)
		self.Humanoid.Health = 0;
		

		local remotes = game.ReplicatedStorage.Remotes;
		local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;
		local player = game.Players:GetPlayerFromCharacter(self.Target);
		local dist = player and player:DistanceFromCharacter(self.RootPart.Position);
		if dist and dist < 32 then
			remoteCameraShakeAndZoom:FireClient(player, 10 * math.clamp(dist/32, 0, 1), 0, 0.5, 0.01, false);
		end
		
		return modLogicTree.Status.Success;
	end)
	
	return tree;
end
