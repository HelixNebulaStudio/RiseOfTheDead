local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local modGlobalVars = require(game.ReplicatedStorage.GlobalVariables);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modPseudoRandom = require(game.ReplicatedStorage.Library.PseudoRandom);
local random = Random.new();

local Zombie = {};

function Zombie.new(self)
	local propScanActive = false;
	self.Garbage:Tag(self.Humanoid.Running:Connect(function(moveSpeed)
		propScanActive = moveSpeed <= 4;
	end))
	
	self.BreakDoorRandom = modPseudoRandom.new();
	spawn(function()
		while not self.IsDead do
			if propScanActive then
				
				local eyeRay = Ray.new(self.RootPart.Position+Vector3.new(0,2,0), self.RootPart.CFrame.LookVector*8);
				local hitPart, eyePoint = workspace:FindPartOnRayWithWhitelist(eyeRay, {workspace.Environment; workspace.Terrain; workspace.Interactables}, true);
				
				if hitPart then
					
					local model = hitPart.Parent;
					while model:GetAttribute("DestructibleParent") do model = model.Parent; end
					while model:GetAttribute("InteractableParent") do model = model.Parent; end
					
					local destructibleModule = model:FindFirstChild("Destructible");
					local doorModule = model:FindFirstChild("Door");
					
					if destructibleModule then
						self.BasicAttack2();
						self:DamageTarget(model, self.Properties.AttackDamage - (self.DamageReduction or 0));
						
					elseif doorModule and doorModule:IsA("ModuleScript") then
						self.BasicAttack2();
						local doorObject = require(doorModule);
						
						local breakDoorChance = 0.1;
						
						if self.Enemy and self.Enemy.Distance then
							if self.Enemy.Distance > 200 then
								breakDoorChance = 0.3;
							elseif self.Enemy.Distance > 400 then
								breakDoorChance = 0.6;
							end
						end
						
						if doorObject.Open ~= true and doorObject.CanBreakIn ~= false then
							if self.BreakDoorRandom:PrdRandom(nil, breakDoorChance) then
								if doorObject.Public then
									doorObject:Toggle(true, self.RootPart.CFrame);
								end
								doorObject:PlaySlam(1);
							else
								doorObject:PlaySlam(random:NextNumber(1.3, 1.6));
							end
						end
						
					end
				end
				
				task.wait(1);
			else
				task.wait(5);
			end
		end
	end)
	
	return function(targetHumanoid, paramPacket)
		paramPacket = paramPacket or {};
		if self.IsDead or self.Humanoid == nil or self.Humanoid.Health <= 0 or self.Humanoid.RootPart == nil then return end;
		if self.Humanoid.PlatformStand then return end;

		local disarmStatus = self.EntityStatus:GetOrDefault("Disarm");

		if disarmStatus and disarmStatus > tick() then 
			if self.PlayAnimation then self.PlayAnimation("Disarm"); end;
			return
		end
		
		if targetHumanoid and paramPacket.SkipMeleeDelay ~= true then
			local targetCharacter = targetHumanoid.Parent;
			if targetCharacter:FindFirstChild("MeleeEquipped") then
				task.wait(1);
			end
		end

		if self.Configuration.Audio and self.Configuration.Audio.Attack ~= false then
			modAudio.Play(self.Configuration.Audio.Attack, self.RootPart).PlaybackSpeed = random:NextNumber(1, 1.2);
		elseif self.Configuration.Audio and self.Configuration.Audio.Attack == false then
		else
			modAudio.Play("ZombieAttack"..random:NextInteger(1, 3), self.RootPart).PlaybackSpeed = random:NextNumber(1, 1.2);
		end

		if disarmStatus and disarmStatus > tick() then 
			if self.PlayAnimation then self.PlayAnimation("Disarm"); end;
			return
		end
		
		self.PlayAnimation("Attack", 0.05, nil, 2);
		
		if targetHumanoid then
			local distance = 0;
			if targetHumanoid.RootPart and self.Humanoid.RootPart then
				distance = (targetHumanoid.RootPart.Position - self.Humanoid.RootPart.Position).Magnitude;
			end
			
			if distance >= self.Properties.AttackRange then
				return;
			end
			
			local dmgRange = math.pow((1-math.clamp(distance/self.Properties.AttackRange, 0, 1)), 1/2);
			
			--local zLvl = self.Configuration.Level + math.floor(modGlobalVars.MaxLevels/100); -- math.clamp( zLvl/(modGlobalVars.MaxLevels/10), 0.1, 3);
			
			local attackDamage = self.Properties.AttackDamage;
			attackDamage = attackDamage * dmgRange - (self.DamageReduction or 0);
			
			self:DamageTarget(targetHumanoid.Parent, attackDamage, nil, nil, "Melee");
		end
	end
end

return Zombie;