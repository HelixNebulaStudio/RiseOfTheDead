local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local RunService = game:GetService("RunService");
local PathfindingService = game:GetService("PathfindingService");

local modRegion = require(game.ReplicatedStorage.Library.Region);
local modMath = require(game.ReplicatedStorage.Library.Util.Math);

--
local Movement = {}
Movement.__index = Movement;

function Movement.new(parallelNpc)
	local meta = {};
	meta.__index = meta;
	meta.ParallelNpc = parallelNpc;
	
	local self = {};
	
	self.PersistFollowTarget = false;
	
	self.Path = nil;
	
	self.MoveId = nil;
	
	self.TargetPosition = nil;
	self.TargetPart = nil;
	
	self.MaxFollowDist = nil;
	self.MinFollowDist = nil;

	self.FacePart = nil;
	self.FacePosition = nil;
	self.LastFaceSetTick = nil;
	
	self.PauseTick = nil;
	
	self.Waypoints = {};
	self.NextWaypointIndex = 1;
	self.NextWaypoint = nil;
	
	setmetatable(self, meta);
	setmetatable(meta, Movement);
	---
	
	local prefab: Actor = self.ParallelNpc.Prefab;
	local humanoid: Humanoid = self.ParallelNpc.Humanoid;
	local rootPart: BasePart = self.ParallelNpc.RootPart;
	local moveSpeed = self.ParallelNpc.MoveSpeed;

	local stuckTick = tick();
	local lastStuckTick = nil;
	local forceRecomputeTick = tick();
	local dumbFollow = nil;
	
	local bodyGyro = Instance.new("BodyGyro");
	bodyGyro.MaxTorque = Vector3.new(0, 0, 0);
	bodyGyro.Parent = rootPart;
	
	
	--
	local function IsInRange(posA, posB, range, pDist)
		--local dist = (posA-posB).Magnitude;
		--if pDist == true then Debugger:Warn("dist", dist) end;
		--return dist <= range;
		return modRegion:InRegion(posA, posB, range);
	end
	
	local function doDumbFollow(add)
		if self.SmartNpc then return end;
		dumbFollow = tick() + (add or 0);
	end
	
	local computeDebounce = tick();
	function self:ComputePathAsync()
		local cTick = tick();
		if computeDebounce and tick() <= computeDebounce then
			if prefab:GetAttribute("DebugMove") == true then Debugger:Warn("cpa debounce") end;
			return 
		end;
		computeDebounce = cTick +1;
		
		task.spawn(function()
			local path: Path = self.Path;
			
			local rootPartPos = rootPart.Position;
			local targetPos = self.TargetPosition;
			
			if IsInRange(rootPartPos, targetPos, 4) and rootPartPos.Y > targetPos.Y then 
				if prefab:GetAttribute("DebugMove") == true then Debugger:Warn("rpp == tp") end;
				
				dumbFollow = tick();
				return;
			end;
			
			local s, e = pcall(function()
				path:ComputeAsync(rootPartPos, targetPos);
			end)
			if not s then
				Debugger:Warn("Handled Exception:", prefab, e);
			end

			if parallelNpc.IsDead then return end;
			if prefab:GetAttribute("DebugMove") == true then Debugger:Warn("genpath") end;

			if path.Status.Value >= 3 then
				if prefab:GetAttribute("DebugMove") == true then Debugger:Warn("path failed", path.Status.Value) end;
				self.NextWaypoint = nil;
				table.clear(self.Waypoints);

				doDumbFollow();
				return;
			end

			self.Waypoints = path:GetWaypoints();
			
			self.NextWaypointIndex = math.min(#self.Waypoints, 2);
			self.NextWaypoint = nil;
			
			if #self.Waypoints <= 2 then
				local hasJump = false;
				for _, wp in pairs(self.Waypoints) do
					if wp.Action == Enum.PathWaypointAction.Jump then
						hasJump = true;
						break;
					end
				end
				if not hasJump then
					doDumbFollow();
					if prefab:GetAttribute("DebugMove") == true then Debugger:Warn("dumbmove") end;
					return;
				end
			end
			
			self:UpdateNextWaypoint();
			
			local computeCd = (#self.Waypoints * 0.1);
			computeDebounce = cTick + computeCd;
		end)
	end
	
	function self:UpdateNextWaypoint()
		if #self.Waypoints <= 0 then return end;
		
		local waypoint: PathWaypoint = self.Waypoints[self.NextWaypointIndex];
		if waypoint == nil then return end;

		self.NextWaypointIndex = self.NextWaypointIndex+1;
		self.NextWaypoint = waypoint;
		
		if self.NextWaypoint.Action == Enum.PathWaypointAction.Jump then
			moveSpeed:Set("Pathfinding", 16, 99);
			
		else
			moveSpeed:Remove("Pathfinding");
			
		end
	end
	
	function self:MoveEnded(reason: string)
		if prefab:GetAttribute("DebugMove") == true then Debugger:Warn("Move ended", self.MoveId, "reason:",reason) end;
		if self.MoveId then
			local moveId = self.MoveId;
			self.MoveId = nil;

			self.ParallelNpc.Event:Fire("moveToEnded", moveId, reason);
			if prefab:GetAttribute("DebugMove") == true then Debugger:Warn("moveToEnded Fire", self.MoveId) end;
		end
	end
	
	humanoid.MoveToFinished:Connect(function(reached)
		if parallelNpc.IsDead then return end;

		if self.PauseTick and tick() <= self.PauseTick then
			return;
		end
		
		if self.TargetPosition == nil then return end;
		if not reached then
			self.Recompute = true;
			return;
		end

		if #self.Waypoints <= 0 then
			if prefab:GetAttribute("DebugMove") == true then Debugger:Warn("mtf #wp = 0") end;
			self.Recompute = true;
			return;
		end

		if self.NextWaypointIndex <= #self.Waypoints then
			if prefab:GetAttribute("DebugMove") == true then Debugger:Warn("mtf unw",self.NextWaypointIndex,#self.Waypoints) end;
			self:UpdateNextWaypoint();
			lastStuckTick = nil;
			
		else
			if prefab:GetAttribute("DebugMove") == true then Debugger:Warn("mtf nomorepath",self.NextWaypointIndex,#self.Waypoints) end;
			
			moveSpeed:Remove("Pathfinding");
			if self.PersistFollowTarget == false then

				local isNextToTarget = IsInRange(rootPart.Position, self.TargetPosition, 1);
				if prefab:GetAttribute("DebugMove") == true then Debugger:Warn("nextToTarget", isNextToTarget) end;
				
				if isNextToTarget then
					self.TargetPart = nil;
					self.TargetPosition = nil;
					self.NextWaypoint = nil;
					self:MoveEnded("nomorepath");
					
				else
					self.Recompute = true;
					lastStuckTick = nil;
					
				end
				
			else
				if (dumbFollow == nil or tick()-dumbFollow > 2.1) and self.SmartNpc ~= true then
					doDumbFollow();
					if prefab:GetAttribute("DebugMove") == true then Debugger:Warn("df") end;
				end
				
			end
			
		end
		
	end)
	
	
	RunService.Stepped:Connect(function(t, delta)
		if parallelNpc.IsDead then 
			game.Debris:AddItem(bodyGyro, 0);
			return 
		end;
		
		local walkSpeed = math.clamp(moveSpeed:Get(), 0, 64);
		humanoid.WalkSpeed = walkSpeed;

		if self.FacePart then
			self.FacePosition = self.FacePart.Position;
			--if prefab:GetAttribute("DebugMoveFace") == true then Debugger:Warn("set fp", self.FacePosition) end;
		end

		if self.LastFaceSetTick 
			and tick()-self.LastFaceSetTick <= 0
			and self.FacePosition 
			and self.FacePosition ~= rootPart.Position
			and humanoid.PlatformStand ~= true then
			
			local bodyGyroD = math.clamp(modMath.MapNum(self.FaceSpeed or walkSpeed, 10, 64, 500, 2000), 500, 2000);
			if self.FaceSpeed then self.FaceSpeed = nil; end
			
			humanoid.AutoRotate = false;
			bodyGyro.MaxTorque = Vector3.new(0, math.huge, 0);
			bodyGyro.D = bodyGyroD;
			bodyGyro.P = 15000;
			bodyGyro.CFrame = CFrame.lookAt(rootPart.Position, self.FacePosition);
			
		else
			self.FacePart = nil;
			self.FacePosition = nil;

			bodyGyro.MaxTorque = Vector3.new(0, 0, 0);
			humanoid.AutoRotate = true;
			
		end

		if self.PauseTick and tick() <= self.PauseTick then
			if not IsInRange(humanoid.WalkToPoint, rootPart.Position, 1) then
				humanoid:MoveTo(rootPart.Position);
			end
			return;
		end

		if self.TargetPart then
			self.TargetPosition = self.TargetPart.Position;
		end
		
		if self.TargetPosition == nil then 
			--if prefab:GetAttribute("DebugMove") == true then Debugger:Warn("tp == nil") end; 
			return 
		end;	
		
		
		if #self.Waypoints <= 0 then
			self.Recompute = true;
			if prefab:GetAttribute("DebugMove") == true then Debugger:Warn("#wp <= 0") end;
			
		else
			if self.LastTargetPosition == nil or not IsInRange(self.TargetPosition, self.LastTargetPosition, 2) then -- Target position moved;
				local ltpIsNil = self.LastTargetPosition == nil;
				self.LastTargetPosition = self.TargetPosition;
				self.Recompute = true;
				
				if prefab:GetAttribute("DebugMove") == true then Debugger:Warn("tp ~= ltp, ltpIsNil", ltpIsNil) end;
			end
			
		end
		
		local minFDist = (self.MinFollowDist or 0)
		local maxFDist = math.max(minFDist, self.MaxFollowDist or 0)+4;
		
		local isInMaxFollowDist = IsInRange(rootPart.Position, self.TargetPosition, maxFDist) and math.abs(rootPart.Position.Y-self.TargetPosition.Y) < 8;
		local isNextToTarget = IsInRange(rootPart.Position, self.TargetPosition, minFDist);
		
		if isInMaxFollowDist and self.MaxFollowDist then
			if dumbFollow and tick() <= dumbFollow then
				return;
			end
			
			if isNextToTarget then
				local awayDir = (rootPart.Position-self.TargetPosition).Unit;
				local displaceScaler = ( minFDist+ (maxFDist-minFDist)/2);
				local newPos = self.TargetPosition + awayDir*displaceScaler;
				
				humanoid:MoveTo(newPos);
				dumbFollow = tick() + math.random(5,15)/10;
				
			else
				dumbFollow = nil;
				humanoid:MoveTo(rootPart.Position);
				
			end
			return;
		end
		
		
		if dumbFollow and tick()-dumbFollow <= 2 then
			humanoid:MoveTo(self.TargetPosition);
			if math.random(1, 64) == 1 then
				local heightDif = self.TargetPosition.Y-rootPart.Position.Y;
				if prefab:GetAttribute("DebugMove") == true then Debugger:Warn("Try jump", heightDif) end;
				if heightDif > 8 then
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping);
				end
			end
			return;
			
		elseif self.Recompute or tick()-forceRecomputeTick >= 10 then
			forceRecomputeTick = tick();
			
			self.Recompute = false;

			humanoid:MoveTo(self.TargetPosition);
			
			self:ComputePathAsync();
		end
		
		if self.NextWaypoint and not isNextToTarget then
			local walkToPoint = self.NextWaypoint.Position;
			humanoid:MoveTo(walkToPoint);
			
			if self.NextWaypoint.Action == Enum.PathWaypointAction.Jump and IsInRange(rootPart.Position, walkToPoint, math.max(humanoid.WalkSpeed/2, 4)) then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping);
			end

			if tick()-stuckTick < 3 then return end;
			stuckTick = tick();
			
			if lastStuckTick and tick()-lastStuckTick <= 6.1 then
				if moveSpeed:Get() > 0 then
					humanoid.Jump = true;
					if prefab:GetAttribute("DebugMove") == true then Debugger:Warn("ls jump") end;
				end
				if prefab:GetAttribute("DebugMove") == true then Debugger:Warn("long stuck") end;
			else
				lastStuckTick = nil;
			end

			if IsInRange(self.LastRootPosition, rootPart.Position, 1) then
				self.Recompute = true;
				if prefab:GetAttribute("DebugMove") == true then Debugger:Warn("detected stuck") end;
				lastStuckTick = tick();
			end

			self.LastRootPosition = rootPart.Position;
			
		elseif isNextToTarget then
			self:MoveEnded("arrived")
			
		end
		
	end)
	
	function self:Init(packet)
		if self.Path then return end;
		
		local path: Path = PathfindingService:CreatePath(packet.PathAgent);

		path.Blocked:Connect(function(wpIndex)
			if parallelNpc.IsDead then return end;
			
			if self.TargetPosition == nil then return end;
			if wpIndex <= self.NextWaypointIndex then return end;

			self:ComputePathAsync();
			Debugger:Warn("path blocked");
		end)

		path.Unblocked:Connect(function(wpIndex)
			if parallelNpc.IsDead then return end;
			
			if self.TargetPosition == nil then return end;
			if wpIndex <= self.NextWaypointIndex then return end;

			self:ComputePathAsync();
			Debugger:Warn("path unblocked");
		end)

		self.Path = path;
		self.SmartNpc = packet.SmartNpc;
	end
	
	parallelNpc.Actor:BindToMessage("Move", function(packet)
		if packet.Initials then self:Init(packet.Initials); end
		
		self.PersistFollowTarget = packet.Follow == true;
		self.MaxFollowDist = packet.MaxFollowDist;
		self.MinFollowDist = packet.MinFollowDist;
		self.LastRootPosition = rootPart.Position;

		if prefab:GetAttribute("DebugMove") == true then
			Debugger:Warn("Move Target", packet.Target, typeof(packet.Target)) 
		end;
		
		if typeof(packet.Target) == "Vector3" then
			self.TargetPart = nil;
			self.TargetPosition = packet.Target;
			
		elseif typeof(packet.Target) == "Instance" then
			if self.TargetPart ~= packet.Target then
				self.Recompute = true;
			end
			
			self.TargetPart = packet.Target;
			self.TargetPosition = self.TargetPart.Position;
		end
		
		self.MoveId = packet.MoveId;
	end)
	
	parallelNpc.Actor:BindToMessage("Face", function(packet)
		if packet.Initials then self:Init(packet.Initials); end

		if typeof(packet.Target) == "Vector3" then
			self.FacePart = nil;
			self.FacePosition = packet.Target;

		elseif typeof(packet.Target) == "Instance" then
			self.FacePart = packet.Target;
			self.FacePosition = self.FacePart.Position;
			
		else
			self.FacePart = nil;
			self.FacePosition = nil;
			
		end

		self.FaceSpeed = packet.FaceSpeed;
		
		self.LastFaceSetTick = tick()+(packet.Duration or 1);
	end)
	

	parallelNpc.Actor:BindToMessage("Stop", function(packet)
		self.TargetPart = nil;
		self.TargetPosition = nil;
		self.MaxFollowDist = nil;
		self.MinFollowDist = nil;
		self.PauseTick = nil;
		
		humanoid:MoveTo(rootPart.Position);
		
		self:MoveEnded("stop");
	end)
	
	parallelNpc.Actor:BindToMessage("Recompute", function()
		self.Recompute = true;
	end)
	
	parallelNpc.Actor:BindToMessage("SetMoveSpeed", function(packet)
		if packet.Initials then self:Init(packet.Initials); end
		
		local action, id, value, priority, expire = 
			packet.Action, packet.Id, packet.Value, packet.Priority, packet.Expire;
		
		if action == "set" then
			moveSpeed:Set(id, value, priority, expire);

		elseif action == "remove" then
			moveSpeed:Remove(id);
			
		else
			Debugger:Warn("Unknown SetMoveSpeed action", action);
			
		end
		
	end)

	parallelNpc.Actor:BindToMessage("Pause", function(packet)
		self.PauseTick = tick()+packet.PauseTime;
	end)

	parallelNpc.Actor:BindToMessage("Resume", function(packet)
		self.PauseTick = nil;
	end)
	
	return self;
end


return Movement;