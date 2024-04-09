local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);

local TweenService = game:GetService("TweenService");
local CollectionService = game:GetService("CollectionService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRegion = require(game.ReplicatedStorage.Library.Region);

return function(self)
	local tree = modLogicTree.new{
		AggroSelect={"Or"; "AttackSequence"; "GrappleTarget"; "FaceTarget"};
		Root={"Or"; "StatusLogic"; "SetAggressSequence"; "AggroSequence"; "SetAggressLevel0"; "Idle";};
		AttackSequence={"And"; "CanAttackTarget"; "Attack";};
		SetAggressSequence={"And"; "SetAggress";};
		AggroSequence={"And"; "HasTarget"; "AggroSelect";};
	}
	
	local targetHumanoid, targetRootPart: BasePart;
	local cache = {};
	cache.AttackCooldown = tick();
	
	
	tree:Hook("StatusLogic", self.StatusLogic);
	
	tree:Hook("HasTarget", function() 
		targetHumanoid = self.Target and self.Target:FindFirstChildWhichIsA("Humanoid") or nil;
		targetRootPart = self.Target and self.Target.PrimaryPart;
		
		if self.Target ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
			return modLogicTree.Status.Success;
		end

		return modLogicTree.Status.Failure;
	end)
	
	tree:Hook("Idle", function()
		return modLogicTree.Status.Success;
	end)

	tree:Hook("CanAttackTarget", function()

		cache.TargetPosition = targetRootPart.CFrame.Position;

		if (self.GetTargetDistance() <= self.Properties.AttackRange) and (tick() > cache.AttackCooldown) then
			return modLogicTree.Status.Success;
		end

		return modLogicTree.Status.Failure;
	end)

	tree:Hook("Attack", function()
		local relativeCframe = self.RootPart.CFrame:ToObjectSpace(CFrame.new(cache.TargetPosition));

		local dirAngle = math.deg(math.atan2(relativeCframe.X, -relativeCframe.Z));
		if math.abs(dirAngle) > 60 then
			cache.AttackCooldown = tick() + math.random(10, 20)/100;
			return modLogicTree.Status.Success;
		end;

		cache.AttackCooldown = tick() + (self.Properties.AttackSpeed * math.random(90, 110)/100);

		if self.HeavyAttack1 and math.random(1, 3) == 1 then
			self.HeavyAttack1(targetHumanoid, 10, 2);
		else
			self.BasicAttack2(targetHumanoid);
		end
		
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

	local function grappleHookTarget(targetAtt: Attachment, isFake: boolean)
		if self.RootPart:FindFirstChild("GrapplerHook"..targetAtt.Name) then
			return;
		end

		local newRope = Instance.new("RopeConstraint");
		newRope.Name = "GrapplerHook".. targetAtt.Name;
		newRope.Parent = self.RootPart;

		newRope.Attachment0 = self.TendrilRoot;
		newRope.Attachment1 = targetAtt;

		newRope.Length = 16;

		if isFake == true then
			newRope.Restitution = 1;
			newRope.Visible = true;
			newRope.Thickness = 0.2;
			newRope.Color = BrickColor.new(Color3.fromRGB(86, 36, 36));
		end

		local pullTimer = 10;
		if self.Configuration.Level >= 10 then
			pullTimer = 8;

		elseif self.Configuration.Level >= 35 then
			pullTimer = 6;

		elseif self.Configuration.Level >= 50 then
			pullTimer = 4;

		end

		TweenService:Create(newRope, TweenInfo.new(pullTimer, Enum.EasingStyle.Linear), {
			Length = 4;
		}):Play();
	end
	
	tree:Hook("GrappleTarget", function()
		if self.LastGrappleTick and tick()-self.LastGrappleTick < 5 then return modLogicTree.Status.Failure; end;
		if self.HasHookedTarget then return modLogicTree.Status.Failure; end;
		if self.GetTargetDistance() > 16 then return modLogicTree.Status.Failure; end;
		
		local targetAtt = self.Enemy.RootPart:FindFirstChild("RootRigAttachment");
		local isTargetHooked = self.Enemy.Character:GetAttribute("GrapplerHooked");

		if isTargetHooked == nil and targetAtt and self.IsInVision(self.Enemy.RootPart, 220) then
			self.LastGrappleTick = tick();

			local targetCharacter = self.Enemy.Character;

			if self.TendrilRoot == nil then
				self.TendrilRoot = Instance.new("Attachment");

				local linkPart: BasePart = Debugger:CFrameLinkPart(self.UpperTorso);
				linkPart.Transparency = 1;
				linkPart.Parent = self.Prefab;

				linkPart.Destroying:Connect(function()
					if targetCharacter:GetAttribute("GrapplerHooked") == self.Id then
						targetCharacter:SetAttribute("GrapplerHooked", nil);
					end
					self.HasHookedTarget = false;
					self.TendrilRoot = nil;
					self.LastGrappleTick = tick();
				end)
				self.Garbage:Tag(self.Enemy.Character:GetAttributeChangedSignal("IsAlive"):Connect(function()
					if self.Enemy.Character:GetAttribute("IsAlive") == false then
						game.Debris:AddItem(linkPart, 0);
					end
				end))

				if self.Enemy.Player then
					linkPart:SetNetworkOwner(self.Enemy.Player);
				end

				self.TendrilRoot.Parent = linkPart;
				self.TendrilRoot.CFrame = CFrame.new(0, 0.282, 0);
			end

			self.HasHookedTarget = true;
			targetCharacter:SetAttribute("GrapplerHooked", self.Id);
			grappleHookTarget(targetAtt);

			task.delay(0.1, function()
				local tarCharDesc: {Instance} = self.Enemy.Character:GetDescendants();
				local tarAttsList: {Attachment} = {};

				for a=1, #tarCharDesc do
					if tarCharDesc[a]:IsA("Attachment") and tarCharDesc[a].Name ~= "UpperTorsoAttachment"
						and tarCharDesc[a].Name ~= "RootRigAttachment"
						and tarCharDesc[a].Name:find("Foot") == nil and tarCharDesc[a].Name:find("Ankle") == nil
						and tarCharDesc[a].Name:find("Leg") == nil
						and tarCharDesc[a].Parent.Name ~= "Head" then

						table.insert(tarAttsList, tarCharDesc[a]);
					end
				end

				if #tarAttsList > 0 then
					for a=1, math.random(4, 6) do
						local att = table.remove(tarAttsList, math.random(1, #tarAttsList));
						grappleHookTarget(att, true);
					end
				end
			end)

			modAudio.Play(math.random(1, 2) == 1 and "BulletBodyImpact" or "BulletBodyImpact2", self.Enemy.RootPart);
		end
	end)
	

	tree:Hook("FaceTarget", function()
		local relativeCframe = self.RootPart.CFrame:toObjectSpace(self.Enemy.RootPart.CFrame);
		local dirRad = math.atan2(relativeCframe.X, -relativeCframe.Z);

		TweenService:Create(self.LowerTorsoJoint, TweenInfo.new(0.13), {
			C1 = CFrame.Angles(0, dirRad, 0);
		}):Play();
		
		return modLogicTree.Status.Success;
	end)
	
	return tree;
end
