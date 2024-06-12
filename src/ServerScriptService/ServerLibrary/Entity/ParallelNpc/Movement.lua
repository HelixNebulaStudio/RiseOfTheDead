local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local RunService = game:GetService("RunService");
local PathfindingService = game:GetService("PathfindingService");

local modRegion = require(game.ReplicatedStorage.Library.Region);
local modMath = require(game.ReplicatedStorage.Library.Util.Math);
local modRaycastUtil = require(game.ReplicatedStorage.Library.Util.RaycastUtil);
local modVector = require(game.ReplicatedStorage.Library.Util.Vector);

--
local Movement = {}
Movement.__index = Movement;

function Movement.new(parallelNpc)
	local meta = {};
	meta.__index = meta;
	meta.ParallelNpc = parallelNpc;
	meta.DebugMove = false;
	
	local self = {};
	
	self.PersistFollowTarget = false;
	
	self.Path = nil;
	
	self.Status = "idle";
	self.MoveId = nil;
	
	self.TargetPosition = nil;
	self.TargetPart = nil;
	self.LastSuccessfulTargetPosition = nil;
	
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
	local prefabHeight = prefab:GetExtentsSize().Y;

	local stuckTick = tick();
	local lastStuckTick = nil;
	local forceRecomputeTick = tick();
	local dumbFollow = nil;
	local deltaPosChange, deltaRootPos = 0, nil;
	
	local bodyGyro = Instance.new("BodyGyro");
	bodyGyro.MaxTorque = Vector3.new(0, 0, 0);
	bodyGyro.Parent = rootPart;
	
	local groundRayParams = RaycastParams.new();
	groundRayParams.FilterType = Enum.RaycastFilterType.Include;
	groundRayParams.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain;};


	local walkSpeed = 0;
	local humanoidAutoRotate = true;
	local bodyGyroD = 500;
	local moveToPoint = nil;
	local jumpRequest = 0;
	local jumpRequestDebounce = tick();

	--
	local function SetStatus(status)
		if status ~= self.Status then
			self.ParallelNpc.Event:Fire("updateStatus", status);
		end
		self.Status = status;
	end

	local function IsInRange(posA, posB, range, pDist)
		--local dist = (posA-posB).Magnitude;
		--if pDist == true then Debugger:Warn("dist", dist) end;
		--return dist <= range;
		if math.abs(posA.Y-posB.Y) > (prefabHeight/2) then return false end;

		posA = Vector3.new(posA.X, 0, posA.Z);
		posB = Vector3.new(posB.X, 0, posB.Z);
		return modRegion:InRegion(posA, posB, range);
	end
	
	local function getRootPos()
		return rootPart.Position + Vector3.new(0, -1, 0);
	end

	local function doDumbFollow(add)
		if self.SmartNpc then return end;

		local rootPartPos = getRootPos();
		if self.TargetPosition and rootPartPos.Y < (self.TargetPosition.Y-3) then return end;

		dumbFollow = tick() + (add or 0);
	end
	
	local computeDebounce = tick();
	function self:ComputePathAsync()
		local cTick = tick();
		if computeDebounce and tick() <= computeDebounce then
			if self.DebugMove == true then if not Debugger:Debounce("cpadebounce", 1) then Debugger:Warn("cpa debounce") end end;
			return 
		end;
		computeDebounce = cTick +1;
		
		task.spawn(function()
			task.synchronize();
			local path: Path = self.Path;
			
			local rootPartPos = getRootPos();
			local targetPos = self.TargetPosition;
			
			if IsInRange(rootPartPos, targetPos, 2) and rootPartPos.Y > targetPos.Y then 
				if self.DebugMove == true then Debugger:Warn("rpp == tp") end;
				
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
			if self.DebugMove == true then Debugger:Warn("genpath") end;

			if path.Status == Enum.PathStatus.NoPath and self.LastSuccessfulTargetPosition then
				-- MARK: path failed logic;
				pcall(function()
					path:ComputeAsync(rootPartPos, self.LastSuccessfulTargetPosition);
				end)
				
				if path.Status == Enum.PathStatus.NoPath then
					if self.DebugMove == true then Debugger:Warn("path failed", path.Status.Value) end;
					self.NextWaypoint = nil;
					table.clear(self.Waypoints);
					computeDebounce = cTick +5;
					SetStatus("moveToDirection");
	
					doDumbFollow();
					return;
				else
					SetStatus("moveToLastPosition");

				end
			else
				self.LastSuccessfulTargetPosition = self.TargetPosition;
				SetStatus("moveToPosition");

			end

			task.synchronize();
			self.Waypoints = path:GetWaypoints();
			
			self.NextWaypointIndex = math.min(#self.Waypoints, 2);
			self.NextWaypoint = nil;
			task.desynchronize();
			
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
					if self.DebugMove == true then Debugger:Warn("dumbmove") end;
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
		if self.DebugMove == true then Debugger:Warn("Move ended", self.MoveId, "reason:",reason) end;
		if self.MoveId then
			local moveId = self.MoveId;
			self.MoveId = nil;

			self.ParallelNpc.Event:Fire("moveToEnded", moveId, reason);
			if self.DebugMove == true then Debugger:Warn("moveToEnded Fire", self.MoveId) end;
		end
	end
	
	humanoid.MoveToFinished:Connect(function(reached)
		if parallelNpc.IsDead then return end;

		if self.PauseTick and tick() <= self.PauseTick then
			return;
		end
		
		if self.TargetPosition == nil then return end;
		if not reached then
			if self.DebugMove == true then Debugger:Warn("mtf != reach") end;
			self.Recompute = true;
			return;
		end

		if #self.Waypoints <= 0 then
			if self.DebugMove == true then Debugger:Warn("mtf #wp = 0") end;
			self.Recompute = true;
			return;
		end

		if self.NextWaypointIndex <= #self.Waypoints then
			if self.DebugMove == true then Debugger:Warn("mtf unw",self.NextWaypointIndex, #self.Waypoints) end;
			self:UpdateNextWaypoint();
			lastStuckTick = nil;
			
		else
			if self.DebugMove == true then Debugger:Warn("mtf nomorepath",self.NextWaypointIndex,#self.Waypoints) end;
			
			moveSpeed:Remove("Pathfinding");
			if self.PersistFollowTarget == false then

				local isNextToTarget = IsInRange(getRootPos(), self.TargetPosition, 1);
				if self.DebugMove == true then Debugger:Warn("nextToTarget", isNextToTarget) end;
				
				if isNextToTarget then
					self.TargetPart = nil;
					self.TargetPosition = nil;
					self.NextWaypoint = nil;
					SetStatus("arrived");
					self:MoveEnded("nomorepath");
					
				else
					self.Recompute = true;
					lastStuckTick = nil;
					
				end
				
			else
				if (dumbFollow == nil or tick()-dumbFollow > 2.1) and self.SmartNpc ~= true then
					doDumbFollow();
					if self.DebugMove == true then Debugger:Warn("df") end;
				end
				
			end
			
		end
		
	end)
	
	rootPart:GetPropertyChangedSignal("CFrame"):ConnectParallel(function()
		if self.DebugMove == true then Debugger:Warn("npc tp recompute") end;
		self.Recompute = true;
	end)

	RunService.Stepped:Connect(function()
		if parallelNpc.IsDead then
			if bodyGyro then
				game.Debris:AddItem(bodyGyro, 0);
				bodyGyro = nil;
			end

			return 
		end;

		humanoid.WalkSpeed = walkSpeed;
		humanoid.AutoRotate = humanoidAutoRotate;

		if moveToPoint and humanoid.WalkToPoint ~= moveToPoint then
			humanoid:MoveTo(moveToPoint);
		end

		if jumpRequest > 0 and walkSpeed > 0 and tick()>jumpRequestDebounce then
			jumpRequestDebounce = tick()+0.1;
			humanoid.Jump = true;
			if self.DebugMove then Debugger:Warn("jmp") end;
			jumpRequest = math.clamp(jumpRequest - 1, 0, 3);
		end

		if humanoidAutoRotate then
			bodyGyro.MaxTorque = Vector3.new(0, 0, 0);

		elseif self.FacePosition then
			bodyGyro.MaxTorque = Vector3.new(0, math.huge, 0);
			bodyGyro.D = bodyGyroD;
			bodyGyro.P = 15000;
			bodyGyro.CFrame = CFrame.lookAt(rootPart.Position, self.FacePosition);

		else
			bodyGyro.MaxTorque = Vector3.new(0, 0, 0);
			
		end
	end)

	RunService.Stepped:ConnectParallel(function(t, delta)
		if parallelNpc.IsDead then
			return 
		end;
		
		self.DebugMove = prefab:GetAttribute("DebugMove");

		local rootPosition = getRootPos();
		if deltaRootPos then
			deltaPosChange = (math.abs(deltaRootPos.X-rootPosition.X) + math.abs(deltaRootPos.Y-rootPosition.Y) + math.abs(deltaRootPos.Z-rootPosition.Z));
		end
		deltaRootPos = rootPosition;

		walkSpeed = math.clamp(moveSpeed:Get(), 0, 64);

		if self.FacePart then
			self.FacePosition = self.FacePart.Position;
		end

		if self.LastFaceSetTick 
			and tick()-self.LastFaceSetTick <= 0
			and self.FacePosition 
			and self.FacePosition ~= rootPart.Position
			and humanoid.PlatformStand ~= true then
			
			bodyGyroD = math.clamp(modMath.MapNum(self.FaceSpeed or walkSpeed, 10, 64, 500, 2000), 500, 2000);
			if self.FaceSpeed then self.FaceSpeed = nil; end
			
			humanoidAutoRotate = false;
			
		else
			self.FacePart = nil;
			self.FacePosition = nil;

			humanoidAutoRotate = true;
			
		end

		if self.PauseTick and tick() <= self.PauseTick then
			if not IsInRange(humanoid.WalkToPoint, getRootPos(), 1) then
				moveToPoint = getRootPos();
				SetStatus("moveToPause");
			end
			return;
		end

		if self.TargetPart then
			self.TargetPosition = self.TargetPart.Position;
		end
		
		if self.TargetPosition == nil then
			SetStatus("idle");
			return 
		end;	
		
		
		if #self.Waypoints <= 0 then
			self.Recompute = true;
			if self.DebugMove == true then
				if not Debugger:Debounce("wp<=0", 0.1) then
					Debugger:Warn("#wp <= 0");
				end
			end;
			
		else
			local tarDistChange = self.LastTargetPosition and modVector.DistanceSqrd(self.TargetPosition, self.LastTargetPosition) or 0;
			local distSqr = modVector.DistanceSqrd(self.TargetPosition, getRootPos())*(workspace:GetAttribute("RecomputePathThreshold") or 0.1);
			
			if self.LastTargetPosition == nil or (tarDistChange > distSqr) then -- Target position moved;
				local ltpIsNil = self.LastTargetPosition == nil;

				self.LastTargetPosition = self.TargetPosition;
				self.Recompute = true;
				
				if self.DebugMove == true then Debugger:Warn("tp ~= ltp, ltpIsNil", ltpIsNil, "recompute") end;
			end
			
		end
		
		local minFDist = (self.MinFollowDist or 0)
		local maxFDist = math.max(minFDist, self.MaxFollowDist or 0)+4;
		
		local isInMaxFollowDist = IsInRange(rootPosition, self.TargetPosition, maxFDist) and math.abs(rootPosition.Y-self.TargetPosition.Y) < 8;
		local isNextToTarget = IsInRange(rootPosition, self.TargetPosition, minFDist);
		
		if isInMaxFollowDist and self.MaxFollowDist then
			if dumbFollow and tick() <= dumbFollow then
				moveToPoint = self.TargetPosition;
				return;
			end
			
			if isNextToTarget then
				local awayDir = (rootPosition-self.TargetPosition).Unit;
				local displaceScaler = ( minFDist+ (maxFDist-minFDist)/2);
				local newPos = self.TargetPosition + awayDir*displaceScaler;
				
				moveToPoint = newPos;
				dumbFollow = tick() + math.random(5,15)/10;
				
			else
				dumbFollow = nil;
				moveToPoint = rootPosition;
				
			end
			return;
		end
		
		
		if dumbFollow and tick()-dumbFollow <= 2 then
			moveToPoint = self.TargetPosition;

			if math.random(1, deltaPosChange <= 0.01 and 32 or 64) == 1 then
				local heightDif = self.TargetPosition.Y-rootPosition.Y;
				if heightDif > 8 or deltaPosChange <= 0.001 then
					if jumpRequest <= 0 then
						if self.DebugMove == true then Debugger:Warn("df jmp+", heightDif) end;
						jumpRequest = jumpRequest +1;
					end
				end
			end
			return;
			
		elseif self.Recompute or tick()-forceRecomputeTick >= 10 then
			forceRecomputeTick = tick();
			
			self.Recompute = false;

			moveToPoint = self.TargetPosition
			
			self:ComputePathAsync();
			return;
		end
		
		if self.NextWaypoint and not isNextToTarget then
			local walkToPoint = self.NextWaypoint.Position;
			
			moveToPoint = walkToPoint;
			
			if self.NextWaypoint.Action == Enum.PathWaypointAction.Jump then
				local jumpingDist = (math.max(humanoid.WalkSpeed/2, 4)^2)-5;
				local wtpDist = modVector.DistanceSqrd(rootPosition+Vector3.new(0, 1, 0), walkToPoint);
				
				if self.DebugMove == true then Debugger:Warn("wp jmp+ rq", jumpingDist, wtpDist) end;
				if wtpDist <= jumpingDist then
					jumpRequest = jumpRequest +1;
				end
			end

			if tick()-stuckTick < 3 then return end;
			stuckTick = tick();
			
			if lastStuckTick and tick()-lastStuckTick <= 6.1 then
				if walkSpeed > 0 then
					if jumpRequest <= 0 then
						jumpRequest = jumpRequest +1;
					end
					if self.DebugMove == true then Debugger:Warn("ls jump") end;
				end
				if self.DebugMove == true then Debugger:Warn("long stuck") end;
			else
				lastStuckTick = nil;
			end

			if deltaPosChange <= 0.01 then -- if IsInRange(self.LastRootPosition, rootPosition, 1) then
				self.Recompute = true;
				if self.DebugMove == true then Debugger:Warn("detected stuck", deltaPosChange) end;
				lastStuckTick = tick();
			end

			self.LastRootPosition = rootPosition;
			
		elseif isNextToTarget then
			SetStatus("arrived");
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
		end)

		path.Unblocked:Connect(function(wpIndex)
			if parallelNpc.IsDead then return end;
			
			if self.TargetPosition == nil then return end;
			if wpIndex <= self.NextWaypointIndex then return end;

			self:ComputePathAsync();
		end)

		self.Path = path;
		self.SmartNpc = packet.SmartNpc;
	end
	
	parallelNpc.Actor:BindToMessage("Move", function(packet)
		if packet.Initials then self:Init(packet.Initials); end
		
		self.PersistFollowTarget = packet.Follow == true;
		self.MaxFollowDist = packet.MaxFollowDist;
		self.MinFollowDist = packet.MinFollowDist;
		self.LastRootPosition = getRootPos();

		-- if self.DebugMove == true then
		-- 	Debugger:Warn("Move Target", packet.Target, typeof(packet.Target)) 
		-- end;
		
		if typeof(packet.Target) == "Vector3" then
			self.TargetPart = nil;
			self.TargetPosition = packet.Target;
			
		elseif typeof(packet.Target) == "Instance" then
			if self.TargetPart ~= packet.Target then
				self.Recompute = true;
				self.LastSuccessfulTargetPosition = nil;
			end
			
			self.TargetPart = packet.Target;
			if self.TargetPosition == nil then
				self.TargetPosition = self.TargetPart.Position;
			end
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
		self.LastSuccessfulTargetPosition = nil;
		self.MaxFollowDist = nil;
		self.MinFollowDist = nil;
		self.PauseTick = nil;
		
		humanoid:MoveTo(getRootPos());
		
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