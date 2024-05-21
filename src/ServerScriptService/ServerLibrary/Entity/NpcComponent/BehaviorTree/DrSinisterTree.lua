local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local PathfindingService = game:GetService("PathfindingService");
local TweenService = game:GetService("TweenService");


local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);

local templateImmuneBeam = script:WaitForChild("ImmuneBeam");
local templateLinks = script:WaitForChild("linksPrefab");

return function(self)
	local tree = modLogicTree.new{
		Root={"Or"; "StatusLogic"; "ProtectSequence"; "ZombieTree";};
		ProtectSequence={"And"; "GetZombies"; "ChannelImmunity";};
	}
	
	local cache = {};
	cache.LastFailScan = tick()-60;
	cache.LastGetZombies = tick()-5;
	cache.LinkedUnits = {};
	
	local veinOptions = templateLinks:GetChildren();

	tree:Hook("StatusLogic", self.StatusLogic);

	tree:Hook("GetZombies", function()
		if tick()-cache.LastFailScan <= 5 then
			return modLogicTree.Status.Failure;
		end
		if tick() < cache.LastGetZombies then
			return modLogicTree.Status.Success;
		end
		
		local maxRange = 64;
		local selfRootPosition = self.RootPart.Position;
		local npcModules = self.NpcService.EntityScan(selfRootPosition, maxRange, 16);
		--Debugger:Warn("Sinister Scan");
		
		local sortedNpcModules = {};
		for a=1, #npcModules do
			local npcModule = npcModules[a];

			local validNpcModule = (npcModule ~= nil
				and npcModule ~= self
				and npcModule.SinisterImmunity ~= true
				and npcModule.Humanoid ~= nil
				and npcModule.Humanoid.Name == "Zombie" 
				and npcModule.Humanoid.Health > 0
				and npcModule.Properties ~= nil
				and npcModule.Properties.BasicEnemy == true);
			
			if npcModule.Name == "Ticks Zombie" then
				validNpcModule = false;
			end
			
			if validNpcModule then
				local prefab = npcModule.Prefab;
				local prefabPosition = prefab:GetPivot().Position;
				
				if table.find(cache.LinkedUnits, prefab) == nil then
					table.insert(sortedNpcModules, {
						NpcModule=npcModule;
						Distance=(prefabPosition-selfRootPosition).Magnitude;
					});
					
				end
			end
		end
		
		table.sort(sortedNpcModules, function(a, b) return a.Distance < b.Distance; end);
		for a=1, #sortedNpcModules do
			local npcModule = sortedNpcModules[a].NpcModule;
			local prefab = npcModule.Prefab;
			
			if table.find(cache.LinkedUnits, prefab) then
				continue;
			end
			
			table.insert(cache.LinkedUnits, prefab);
			
			local waypointSpacing = 8;
			local linkingPath = PathfindingService:CreatePath({
				WaypointSpacing=waypointSpacing;
			});
			
			local linkActive = true;
			local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut);
			
			task.spawn(function()
				
				while linkActive do
					if self.IsDead then return; end;
					
					local prefabPosition = prefab:GetPivot().Position;
					local distance = (self.RootPart.Position - prefabPosition).Magnitude;
					
					if distance <= maxRange then
						linkingPath:ComputeAsync(self.RootPart.Position, prefabPosition);
					end
					
					if distance <= maxRange and linkingPath.Status == Enum.PathStatus.Success then
						local waypoints = linkingPath:GetWaypoints();
						
						-- link effect;
						for a, waypoint in pairs(waypoints) do
							if a == 1 then continue end;
							
							local part = veinOptions[math.random(1, #veinOptions)]:Clone();
							Debugger.Expire(part, 1.05);
							
							local prevPos = waypoints[a-1].Position;
							local pos = waypoint.Position;
							
							local center = (prevPos+pos)/2;
							
							part.CFrame = CFrame.new(center) * CFrame.lookAt(pos, prevPos).Rotation * CFrame.new(0, -0.8, 0);
							part.Size = Vector3.new(0.6, 0.2, (prevPos-pos).Magnitude);
							part.Parent = self.Prefab;
							
						end
						--
						
						for _, obj in pairs(prefab:GetChildren()) do
							if obj:IsA("BasePart") then
								if obj:GetAttribute("DefaultColor") == nil then
									obj:SetAttribute("DefaultColor", obj.Color);
								end
								obj.Color = Color3.fromRGB(135, 67, 67);
							end
						end
						
						npcModule.SinisterImmunity = tick();
						npcModule.Immunity = npcModule.Name ~= "Dr. Sinister" and 1 or 0.5;
						task.delay(2, function()
							if npcModule.SinisterImmunity == nil then return end;
							if tick()-npcModule.SinisterImmunity >= 1.5 then
								for _, obj in pairs(prefab:GetChildren()) do
									if obj:IsA("BasePart") then
										obj.Color = obj:GetAttribute("DefaultColor") or Color3.fromRGB(211, 190, 150);
									end
								end

								npcModule.SinisterImmunity = nil;
								npcModule.Immunity = nil;
								
							end
						end)
						
					end
					
					task.wait(1);
				end
			end)

			self.Garbage:Tag(prefab.Destroying:Connect(function()
				linkActive = false;
				
				if cache.LinkedUnits == nil then return end;
				for a=#cache.LinkedUnits, 1, -1 do
					if cache.LinkedUnits[a] == prefab then
						table.remove(cache.LinkedUnits, a);
						break;
					end
				end
			end));
		end
		
		local delayTime = 1;
		cache.LastGetZombies = tick() + delayTime

		task.delay(delayTime+0.1, function()
			self.Think:Fire();
		end)
		
		if #cache.LinkedUnits <= 0 then
			cache.LastFailScan = tick();
			return modLogicTree.Status.Failure;
		end
		
		if self.FollowLinkedUnits ~= false then
			self.Move:SetMoveSpeed("set", "walk", 10, 1);
			self.Move:Follow(cache.LinkedUnits[math.random(1, #cache.LinkedUnits)].PrimaryPart);
		end
		
		return modLogicTree.Status.Success;
	end)
	
	tree:Hook("ChannelImmunity", function()
		return modLogicTree.Status.Success;
	end)
	
	tree:Hook("ZombieTree", function()
		local dist = self.GetTargetDistance();
		if dist >= 100 then
			self.Move:SetMoveSpeed("set", "sprint", 25, 2);
		else
			self.Move:SetMoveSpeed("remove", "sprint");
		end
		return self.BehaviorTree:RunTree("ZombieTree");
	end)
	
	self.Garbage:Tag(function()

		for a=#cache.LinkedUnits, 1, -1 do
			local prefab = cache.LinkedUnits[a];
			local npcModule = self.NpcService.GetNpcModule(prefab);
			
			if npcModule then
				npcModule.SinisterImmunity = nil;
				npcModule.Immunity = nil;
				
				for _, obj in pairs(prefab:GetChildren()) do
					if obj:IsA("BasePart") then
						obj.Color = obj:GetAttribute("DefaultColor") or Color3.fromRGB(211, 190, 150);
					end
				end
			end
		end
		
		for _, obj in pairs(self.Prefab:GetChildren()) do
			if obj.Name == "VeinLink" then
				obj:Destroy();
			end
		end
		
		table.clear(cache);
		
		self.RootPart:ClearAllChildren();
		Debugger:Warn("Clear behavior cache");
	end)
	
	return tree;
end
