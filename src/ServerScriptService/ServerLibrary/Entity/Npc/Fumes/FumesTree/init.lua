local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);
local modStatusEffects = Debugger:Require(game.ReplicatedStorage.Library.StatusEffects);

return function(self)
	local tree = modLogicTree.new{
        Root={"Or"; "StatusLogic"; "AggroSequence"; "Idle";};
        AttackSequence={"And"; "CanAttackTarget"; "Attack";};
        AggroSequence={"And"; "HasTarget"; "AggroSelect";};
        AggroSelect={"Or"; "FumesCloud"; "AttackSequence"; "FollowTarget";};
    }
	
	local targetHumanoid, targetRootPart: BasePart;
	local cache = {};
	cache.AttackCooldown = tick();
    cache.CloudState = 0;

	tree:Hook("StatusLogic", self.StatusLogic);

	tree:Hook("HasTarget", function() 
		targetHumanoid = self.Target and self.Target:FindFirstChildWhichIsA("Humanoid") or nil;
		targetRootPart = self.Target and self.Target.PrimaryPart;

		if self.Target ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
			return modLogicTree.Status.Success;
		end

        if cache.CloudState == 1 then
            tree:Call("FumesCloud");
        end

		return modLogicTree.Status.Failure;
	end)

	tree:Hook("FollowTarget", function()
		targetRootPart = self.Target and self.Target.PrimaryPart;

        if cache.CloudState == 1 then return tree.Failure; end;
		self.Move:Follow(targetRootPart);

		return modLogicTree.Status.Success;
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
		if math.abs(dirAngle) > 40 then
			cache.AttackCooldown = tick() + math.random(10, 20)/100;
			return modLogicTree.Status.Failure;
		end;
		
        if cache.CloudState == 1 then
            self.StopAnimation("ChannelFumes");
        end
		cache.AttackCooldown = tick() + (self.Properties.AttackSpeed * math.random(90, 110)/100);

		if self.Wield.Handler then
			self.Wield.PrimaryFireRequest();
		else
			self.BasicAttack2(targetHumanoid);
		end

		return modLogicTree.Status.Success;
	end)

    local fumesCloud = game.ServerStorage.PrefabStorage.Objects:WaitForChild("fumesCloud");
	tree:Hook("FumesCloud", function()
		if cache.CloudState == 0 then
            if self.GetTargetDistance() > 100 then
                return tree.Failure;
            end

            cache.CloudState = 1;

            self.Move:Stop();
            self.PlayAnimation("ChannelFumes");
            self.Move:Face(self.Target.PrimaryPart);

            local newFumeCloud: MeshPart = fumesCloud:Clone();
            newFumeCloud.CFrame = CFrame.new(self.RootPart.CFrame.Position) * CFrame.new(math.random(-16, 16), 0, math.random(-16, 16));

            if self.HardMode then
                newFumeCloud:SetAttribute("GasDamage", 30);
            else
                newFumeCloud:SetAttribute("GasDamage", 6);
            end

            newFumeCloud.Parent = workspace.Entities;
            self.Garbage:Tag(newFumeCloud);

        elseif cache.CloudState == 1 then
            self.PlayAnimation("ChannelFumes", 0.5);
            self.Move:Face(self.Target.PrimaryPart);
            
            local cancelChanneling = false;
            if self.GetTargetDistance() > 180 then
                cancelChanneling = true;
            end

            if cancelChanneling == true then
                cache.CloudState = 0;

                self.Garbage:Loop(function(a, trash)
                    if typeof(trash) == "Instance" and trash.Name == "fumesCloud" then
                        game.Debris:AddItem(trash, 0);
                    end
                end)

                self.StopAnimation("ChannelFumes");
            end

        end
		return modLogicTree.Status.Failure;
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

	return tree;
end
