local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modScheduler = require(game.ReplicatedStorage.Library.Scheduler);
local globalScheduler = modScheduler:GetGlobal();

--== Script;
local MovementStatus = {};
MovementStatus.__index = MovementStatus;


function MovementStatus:UpdateDestination(newDestination)
	if self.Destroyed then return end;
	
	newDestination = newDestination or self.Destination;
	
	local timelapsed = tick()-self.LastComputeTick;
	local distanceSq;
	
	if self.ForceRegen == false then
		if timelapsed <= 0.25 then 
			return 
		else
			local diff = self.Npc.RootPart.CFrame.p - newDestination
			distanceSq = diff.X^2 + diff.Y^2 + diff.Z^2;
			
			if distanceSq <= 9 then
				return;
			elseif distanceSq <= 500 then
				if timelapsed <= 0.5 then
					return;
				end
			elseif distanceSq <= 2500 then
				if timelapsed <= 1 then
					return;
				end
			elseif distanceSq <= 5000 then
				if timelapsed <= 2 then
					return;
				end
			elseif distanceSq <= 10000 then
				if timelapsed <= 4 then
					return;
				end
			elseif timelapsed <= 5 then
				return;
			end
		end
		
		self.LastComputeTick = tick();
	end
	
	if self.ComputingPath then
		return;
	end
	
	if self.Npc.Prefab:GetAttribute("Debug") == true then
		Debugger:Log("UpdateDestination:A ", distanceSq);
	end
	self.Completed = false;
	
	self.LastDestination = self.Destination
	self.Destination = newDestination or self.Destination;
	
	if self.Npc.Humanoid.FloorMaterial ~= nil then
		task.spawn(function()
			if self.Completed then return end;
			self.ComputingPath = true;
			local rootPos = self.Npc.RootPart.Position;
			
			self.PathDistance = (rootPos-self.Destination).Magnitude;
			if self.Npc.Prefab:GetAttribute("Debug") == true then
				self.Npc.Prefab:SetAttribute("PathDistance", self.PathDistance);
			end
			
			
			if self.PathDistance <= 4 then
				self.ComputingPath = false;
				self:Complete(true);
				return;
				
			elseif self.PathDistance <= 1024 then
				local pathTime = tick();
				self.Npc.Path:ComputeAsync(rootPos, self.Destination);
				
				if self.Npc.Prefab == nil then return end;
				if self.Npc.Prefab:GetAttribute("Debug") == true then
					Debugger:Log("UpdateDestination:pathTime", math.ceil((tick()-pathTime)*100)/100);
				end
			end
			
			self.ComputingPath = false;
			
			if self.Completed then return end;
			
			if self.Npc.Path.Status.Value < 3 then -- Enum.PathStatus.Success
				self.Waypoints = self.Npc.Path:GetWaypoints();
				
				if self.Npc.Prefab:GetAttribute("Debug") == true then
					Debugger:Log("UpdateDestination:RegenPath");

					if self.DebugPointOrigin == nil then
						self.DebugPointOrigin = Debugger:PointPart(Vector3.zero);
						self.DebugPointOrigin.Size = Vector3.new(0.5, 0.5, 0.5);
						self.DebugPointOrigin.Color = Color3.fromRGB(0, 0, 0);
						self.DebugPointOrigin.Parent = workspace;
					end

					self.DebugPointOrigin.Position = rootPos;
					
					if self.DebugPointDest == nil then
						self.DebugPointDest = Debugger:PointPart(Vector3.zero);
						self.DebugPointDest.Size = Vector3.new(0.5, 0.5, 0.5);
						self.DebugPointDest.Color = Color3.fromRGB(255, 255, 255);
						self.DebugPointDest.Parent = workspace;
					end

					self.DebugPointDest.Position = self.Destination;

					for a=1, math.max(#self.Waypoints, #self.DebugPoints) do
						
						if self.DebugPoints[a] == nil then
							self.DebugPoints[a] = Debugger:PointPart(Vector3.zero);
							self.DebugPoints[a].Size = Vector3.new(0.25, 0.25, 0.25);
						end
						
						if self.Waypoints[a] then
							self.DebugPoints[a].Parent = workspace;
							
							self.DebugPoints[a].Position = self.Waypoints[a].Position;
							
							if self.Waypoints[a].Action == Enum.PathWaypointAction.Walk then
								self.DebugPoints[a].Color = Color3.fromRGB(0, 153, 255);
								
							elseif self.Waypoints[a].Action == Enum.PathWaypointAction.Jump then
								self.DebugPoints[a].Color = Color3.fromRGB(255, 244, 157);
							end
							
							if a == 1 then
								self.DebugPoints[a].Size = Vector3.new(0.5, 0.5, 0.5);
								self.DebugPoints[a].Color = Color3.fromRGB(143, 255, 147);
								
							elseif a == #self.Waypoints then
								self.DebugPoints[a].Size = Vector3.new(0.5, 0.5, 0.5);
								self.DebugPoints[a].Color = Color3.fromRGB(255, 151, 151);
								
							end
						else
							self.DebugPoints[a].Parent = nil;
						end
					end
				end
				
				local waypointOrign = self.Waypoints[1];
				local waypointDest = self.Waypoints[#self.Waypoints];
				
				if (waypointOrign and waypointDest) then
					if waypointOrign == waypointDest or (waypointOrign.Position - waypointDest.Position).Magnitude <= 4 then
						self.ComputingPath = false;
						self:Complete(true);
						return;
					end
				end
				
				--local closestPoint = nil;
				--local closestMag = math.huge;
				
				--for a=1, math.min(#self.Waypoints, 3) do
				--	local dist = (rootPos-self.Waypoints[a].Position).Magnitude;
				--	if dist <= closestMag then
				--		closestMag = dist;
				--		closestPoint = a;
				--	end
				--end
				
				--if closestPoint then
				--	for a=1, closestPoint do
				--		table.remove(self.Waypoints, 1);
				--	end
				--end
				
				self.ForceRegen = false;
			else
				
				if self.Npc.Prefab:GetAttribute("Debug") == true then
					Debugger:Log("UpdateDestination:RegenPath Failed. ", self.Npc.Path.Status);
				end
				
				self.Waypoints = {};
			end
			
			self.Completed = false;
			
			if self.IdleTask then
				globalScheduler:Resume(self.IdleTask, true);
				self.IdleTask = nil;
			end;
		end)
	else
		if self.Npc.Prefab:GetAttribute("Debug") == true then
			Debugger:Log("UpdateDestination:Not on Ground");
		end
	end
end

function MovementStatus:ClearYield()
	if self.Destroyed then return end;
	
	if self.ActiveTask == nil then return end;
	
	globalScheduler:Resume(self.ActiveTask, true);
	self.ActiveTask = nil;
end

function MovementStatus:Complete(arrived)
	if self.Npc.IsDead then return end;
	if self.Destroyed then return end;

	if not self.Npc.Humanoid.PlatformStand then
		self.Npc.Humanoid:MoveTo(self.Npc.RootPart.Position);
	end;
	
	self.Waypoints = {};
	self.Completed = true;
	
	self:ClearYield();
	if self.Movement then 
		self.Movement.IsMoving = false;
	end
	
	if self.CompleteFunc then
		task.spawn(function()
			self.CompleteFunc(arrived);
		end);
		self.CompleteFunc = nil;
	end
	
	self.ForceRegen = true;
end

function MovementStatus:OnComplete(f)
	self.CompleteFunc = f;
	return self;
end

function MovementStatus:Wait(timeout)
	if self.Destroyed then return end;
	
	if self.Completed then return end;
	
	self:ClearYield();
	self.ActiveTask = globalScheduler:Schedule(coroutine.running(), tick() + (timeout or 60));
	self.ActiveTask.StatKey = "msMovementStatusWait";
	
	coroutine.yield();
end

function MovementStatus:Jump()
	if self.Destroyed then return end;
	if self.IsClimbing ~= true and self.Npc.Humanoid.WalkSpeed > 0 then
		self.Npc.Humanoid.Jump = true;
	end
end

function MovementStatus:MoveToWaypoint()
	if self.Destroyed then return end;
	if self.Completed then return end;
	if self.Npc.Humanoid.PlatformStand then return end;
	
	local pathWaypoint = self.Waypoints[1];
	
	if self.Npc.Humanoid.Sit then self.Npc.Humanoid.Jump = true; end
	
	if pathWaypoint then
		if self.Npc.Disabled ~= true and self.Npc.RootPart:CanSetNetworkOwnership() then self.Npc.RootPart:SetNetworkOwner(nil); end
		
		self.MoveToFinished = false;
		
		if self.Npc.Sit then self.Npc.Sit = false; end
		self.Npc.Humanoid:MoveTo(pathWaypoint.Position);
		self.Movement.IsMoving = true;
		
		local lastPos = self.Npc.RootPart.Position;
		
		if pathWaypoint.Label == "DoorPortal" then
			Debugger:Warn("DoorPortal");
			
			
		elseif pathWaypoint.Action == Enum.PathWaypointAction.Jump and self.PreviousWaypoint then
			self.Npc.Humanoid.Jump = true;
			
			local jumpDistance = (self.PreviousWaypoint.Position-pathWaypoint.Position).Magnitude;
			
			self.Npc.RootPart.Velocity = self.Npc.RootPart.Velocity:Lerp(Vector3.new(0, self.Npc.RootPart.Velocity.Y, 0), 0.1);
			self.Movement:SetWalkSpeed("jump", jumpDistance+8, 99);
		end
		
	elseif self.ComputingPath then
		
	else
		if self.Npc.Prefab:GetAttribute("Debug") == true then
			Debugger:Log("No path.", #self.Waypoints);
		end

		self.Npc.Humanoid:MoveTo(self.Destination);
		
		if math.random(1, 60) == 1 then
			self:Jump();
		end
		
	end
end

function MovementStatus:Destroy()
	if self.Destroyed then return end;
	
	if self.PathBlockedConnection then
		self.PathBlockedConnection:Disconnect();
		self.PathBlockedConnection = nil;
	end
	
	if self.MoveToFinishedConnection then
		self.MoveToFinishedConnection:Disconnect();
		self.MoveToFinishedConnection = nil;
	end
	
	for a=1, #self.DebugPoints do
		self.DebugPoints[a]:Destroy();
		self.DebugPoints[a]=nil;
	end
	
	self:Complete(false);
	self.Destroyed = true;
end

function MovementStatus.new(movement, destination)
	local self = {
		Movement = movement;
		Npc = movement.Npc;
		
		Destination = destination;
		Completed = false;
		Waypoints = {};
		
		LastComputeTick = tick();
		MoveToFinished = false;
		MoveToReached = false;
		
		IdleTask = nil;
		ActiveTask = nil;
		
		PathDistance = 1024;
		ForceRegen = true;
		
		DebugPoints = {};
	};
	
	--movement.EndMovement = function()
	--	self:Complete(false);
	--end;
	
	self.PathBlockedConnection = self.Npc.Path.Blocked:Connect(function(blockedIndex)
		if self.Completed then return end;
		
		self:UpdateDestination();
	end);
	self.Npc.Garbage:Tag(self.PathBlockedConnection);
	
	-- Reworked MoveToFinish logic to prevent nonsense duplicated calls..
	self.MoveToFinishedConnection = self.Npc.Humanoid.MoveToFinished:Connect(function(reached)
		self.MoveToFinished = true;
		self.MoveToReached = reached;
	end);
	self.Npc.Garbage:Tag(self.MoveToFinishedConnection);
	
	setmetatable(self, MovementStatus);
	
	if self.Npc.RootPart.Anchored then self.Npc.RootPart.Anchored = false; end;
	self:UpdateDestination();
	
	task.spawn(function()
		while self.MoveToFinishedConnection and self.MoveToFinishedConnection.Connected == true do
			if self.Completed then
				self.IdleTask = globalScheduler:Schedule(coroutine.running(), tick() + 120);
				self.IdleTask.StatKey = "msMovementStatusIdle";
				
				coroutine.yield();
				if self.Completed then continue end;
			end
			
			local stuckJump = 0;
			while not self.MoveToFinished and not self.Completed do
				if self.MoveToFinishedConnection == nil then break; end;
				if self.Npc.IsDead then break; end;
				if self.Destroyed then return end;
				if self.Npc.Humanoid.PlatformStand then return end;
				
				if self.Movement.Paused then
					self.Npc.Humanoid:MoveTo(self.Npc.RootPart.Position);
					repeat
						task.wait(1);
					until self.Npc.IsDead or not self.Movement.Paused or self.Completed;
					self:UpdateDestination();
				end
				self:MoveToWaypoint();
				
				if math.random(1, 60) == 1 and Vector2.new(self.Npc.RootPart.Velocity.X, self.Npc.RootPart.Velocity.Z).Magnitude <= 2 then
					self:Jump();
					stuckJump = stuckJump +1;
					
				elseif stuckJump >= 2 then
					self:UpdateDestination();
					
					break;
				end
				
				task.wait();
			end
			
			if self.Destroyed then return end;
			
			if self.MoveToReached then
				self.PreviousWaypoint = self.Waypoints[1];
				table.remove(self.Waypoints, 1);
				self.Movement:SetWalkSpeed("jump", nil);

				if self.Npc.IsDead then return; end;
				local diff = self.Npc.RootPart.CFrame.p - self.Destination;
				local distanceSq = diff.X^2 + diff.Y^2 + diff.Z^2;
				if distanceSq <= (self.Gap and self.Gap^2 or 9) then
					self:Complete(true);
					
				elseif #self.Waypoints <= 0 then
					self.ForceRegen = true;
					self:UpdateDestination();
					
				end
			else
				self.ForceRegen = true;
				self:UpdateDestination();
			end
			
			self:MoveToWaypoint();
			task.wait();
		end
	end)
	
	return self;
end

return MovementStatus;
