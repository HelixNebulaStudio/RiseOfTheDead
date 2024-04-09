local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local PathfindingService = game:GetService("PathfindingService");

local modScheduler = require(game.ReplicatedStorage.Library.Scheduler);
local globalScheduler = modScheduler:GetGlobal();
local random = Random.new();

--== Script;
local Follow = {};
Follow.__index = Follow;

--local debugWaypoints = {};
--local debug_waypoint = Instance.new("Part"); debug_waypoint.Name = "DebugWaypoints"; debug_waypoint.Anchored = true; debug_waypoint.Size = Vector3.new(1, 1, 1); debug_waypoint.CanCollide = false;
--local function ClearDebugWaypoints() for a=#debugWaypoints, 1, -1 do if debugWaypoints[a] ~= nil then debugWaypoints[a].BrickColor = BrickColor.Gray(); debugWaypoints[a].Size = Vector3.new(0.5, 0.5, 0.5); debugWaypoints[a].Transparency = 0.9; else table.remove(debugWaypoints, a) end; end; end;
--local function DebugWaypoints(action, position) local n = debug_waypoint:Clone(); n.Parent = workspace.Debris; n.CFrame = CFrame.new(position); n.BrickColor = action == Enum.PathWaypointAction.Jump and BrickColor.Blue() or BrickColor.Green(); table.insert(debugWaypoints, n); game.Debris:AddItem(n, 10) return n; end

local raycastParams = RaycastParams.new();
raycastParams.RespectCanCollide = true;

function Follow:GetDestination()
	if self.FollowPart == nil then return end;
	if self.FollowGap == nil then return self.FollowPart.Position; end
	
	local dir = -(self.FollowGap*(self.FollowPart.Position - self.Npc.RootPart.Position).Unit);
	local fp = CFrame.new(self.FollowPart.Position) * CFrame.Angles(0, self.OffPointRad, 0) * CFrame.new(dir);
	
	if self.Npc and self.Npc.Smart then
		local ray = Ray.new(fp.p, Vector3.new(0, -32, 0));
		--local rayHit, rayPoint = workspace:FindPartOnRayWithWhitelist(ray, {workspace.Environment; workspace.Terrain}, true);
		local raycastResult = workspace:Raycast(fp.p, Vector3.new(0, -32, 0), raycastParams);
		
		if raycastResult and raycastResult.Instance then
			return raycastResult.Position;
		end
	end
	
	return fp.p;
end

function Follow:MakePath()
	if self.Npc.IsDead or self.Npc.RootPart == nil then return end;
	if not self.Npc.IsFollowing then return end;
	local destination = self:GetDestination();
	if destination == nil then return end;
	
	local distance = (self.Npc.RootPart.CFrame.p-destination).Magnitude;
	if distance < 256 then
		for a=1, 3 do
			if destination == nil then return end;
			
			local rootPos = self.Npc.RootPart.CFrame.p;
			if a > 1 or math.random(1, 5) == 1 then
				rootPos = rootPos + Vector3.new(math.random(-4, 4), 0, math.random(-4, 4));
			end
			pcall(function()
				self.Npc.Path:ComputeAsync(rootPos, destination);
			end)
			if self.Npc == nil or self.Npc.IsDead or self.Npc.RootPart == nil then return end;
			if self.Npc.Path.Status ~= Enum.PathStatus.Success then
				self.OffPointRad = random:NextNumber(-math.pi, math.pi);
				destination = self:GetDestination();
			else
				break;
			end;
		end
		
		if self.Npc.Path.Status == Enum.PathStatus.Success then
			self.Waypoints = self.Npc.Path:GetWaypoints();

			self.WaypointIndex = 2;
			if self.Npc.Sit then
				self.Npc.Sit = false;
			end
			
			for a=self.WaypointIndex, 0, -1 do
				if self.Waypoints[a] then
					self.Npc.Humanoid:MoveTo(self.Waypoints[a].Position);
					
					break;
				end
			end
			return;
			
		else
			self.Npc.Humanoid:MoveTo(destination or self.Npc.RootPart.Position);
			
			if math.random(1, 10) == 1 then
				self.Npc.Humanoid.Jump = true;
			end
		end
	else
		self.Npc.Humanoid:MoveTo(destination);
	end
	
	if self.Npc.CantFollow then
		self.Npc.CantFollow(destination);
	end
end

function Follow:MoveToFinished(reached)
	if not self.Npc.IsFollowing then return end;
	if self.Npc.IsDead then return end;
	if not self.Npc.RootPart.Anchored and self.WaypointIndex < #self.Waypoints then
		self.WaypointIndex = self.WaypointIndex +1;
		self:MoveToWaypoint(self.WaypointIndex);
		if self.WaypointIndex+2 > #self.Waypoints then self:MakePath(); end
	end
end

function Follow:MoveToWaypoint(index)
	local pathWaypoint = self.Waypoints[index];
	if self.Npc.Humanoid.Sit then self.Npc.Humanoid.Jump = true; end
	if pathWaypoint then
		
		self.Npc.Humanoid:MoveTo(pathWaypoint.Position);
		
		task.delay(1, function()
			if self.Npc == nil then return end;
			if self.WaypointIndex ~= index then return end;
			self:MakePath();
		end);
		if self.Npc == nil then return end;
		

		if pathWaypoint.Label == "DoorPortal" then
			Debugger:Warn("DoorPortal");
			
		elseif pathWaypoint.Action == Enum.PathWaypointAction.Jump then
			self.Npc.Humanoid.Jump = true;
		end
	end
end

function Follow.new(Npc)
	if Npc.Path == nil then Npc.Path = PathfindingService:CreatePath(Npc.PathAgent); end
	
	local self = {
		Npc = Npc;
		FollowPart = nil;
		FollowGap = nil;
		KeepDistance = nil;
		Distance = nil;
		Waypoints = {};
		WaypointIndex = 2;
		OffPointRad = math.rad(random:NextNumber(0, 359));
		RadResetTick = tick();
	};
	
	setmetatable(self, Follow);

	self.Npc.Garbage:Tag(Npc.Path.Blocked:Connect(function(blockedIndex)
		if blockedIndex and blockedIndex > self.WaypointIndex then
			self:MakePath();
		end
	end));
	
	self.Npc.Garbage:Tag(Npc.Humanoid.MoveToFinished:Connect(function(reached) self:MoveToFinished(reached) end));
	
	return function(followPart, followGap, keepDist)
		self.FollowPart = followPart;
		self.FollowGap = followGap;
		self.KeepDistance = keepDist;
		self.Distance = 0;

		if self.FollowPart == nil then
			self.Npc.Humanoid:MoveTo(self.Npc.RootPart.Position);
			
			self:MoveToFinished();
			return; 
		end;
		
		if Npc.RootPart and self.Npc.Disabled ~= true and Npc.RootPart:CanSetNetworkOwnership() then Npc.RootPart:SetNetworkOwner(nil); end
		
		if Npc.IsFollowing then return; end;
		Npc.IsFollowing = true;
		
		local untagFunc;
		task.spawn(function()
			local moveThreshold = 2;
			local lastCFrame = CFrame.new();
			local lastPathUpdate = tick();
			
			self:MakePath();
			while Npc.IsFollowing and not Npc.IsDead and Npc.RootPart.Parent ~= nil do
				if (tick()-self.RadResetTick) > 10 then self.RadResetTick = tick(); self.OffPointRad = math.rad(random:NextNumber(-45, 45)); end;
				if self.FollowPart == nil or not self.FollowPart:IsA("BasePart") or not self.FollowPart:IsDescendantOf(workspace) then
					Npc.IsFollowing = false;
					break;
				else
					local delta = (self.FollowPart.CFrame.p-lastCFrame.p);
					if (tick()-lastPathUpdate >= 5) or delta.X > moveThreshold or delta.X < -moveThreshold or delta.Y > moveThreshold*2 or delta.Y < -moveThreshold*2 or delta.Z > moveThreshold or delta.Z < -moveThreshold then
						if self.FollowPart then
							lastCFrame = self.FollowPart and self.FollowPart.CFrame or lastCFrame;
							self.Distance = (Npc.RootPart.Position - self.FollowPart.CFrame.p).Magnitude;
							if (self.KeepDistance and self.Distance < self.KeepDistance) or self.Distance-5 > self.FollowGap or (self.FollowPart.CFrame.p.Y-Npc.RootPart.Position.Y) >= 6 then
								lastPathUpdate = tick();
								self:MakePath();
							end
						end
					end;
				end;

				local timer = self.Distance > 256 and 5 or self.Distance > 128 and 2 or self.Distance > 64 and 1 or 0.25;
				self.ActiveFollowTask = globalScheduler:Schedule(coroutine.running(), tick() + timer);
				
				if untagFunc == nil then
					untagFunc = function()
						globalScheduler:Resume(self.ActiveFollowTask, true);
					end
				end
				
				if self.Npc.Garbage == nil then return end;
				self.Npc.Garbage:Tag(untagFunc);
				coroutine.yield();
				self.Npc.Think:Fire();
				if self.Npc and self.Npc.Garbage then
					self.Npc.Garbage:Untag(untagFunc);
				end
			end
		end);
	end;
end

return Follow;