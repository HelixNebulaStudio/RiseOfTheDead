local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local PathfindingService = game:GetService("PathfindingService");
local TweenService = game:GetService("TweenService");
local random = Random.new();

local modLayeredVariable = require(game.ReplicatedStorage.Library.LayeredVariable);

local modMovementStatus = require(script:WaitForChild("MovementStatus"));

--== Script;
local Movement = {};
Movement.__index = Movement;

function Movement:Face(point)
	if self.Destroyed then return end;
	if self.Npc.RootPart == nil or self.Npc.IsDead then return end;
	if self.Npc.Humanoid.PlatformStand then return end;
	
	if self.Npc.Controller then
		self.Npc.Controller.FacingDirection = (point - self.Npc.RootPart.Position);
		
		return;
	end
	
	local bodyGyro = self.Npc.RootPart:FindFirstChildWhichIsA("BodyGyro");
	if bodyGyro == nil then bodyGyro = Instance.new("BodyGyro"); bodyGyro.Parent = self.Npc.RootPart; end;

	local humanoid = self.Npc.Humanoid;
	humanoid.AutoRotate = false;
	bodyGyro.MaxTorque = Vector3.new(0, math.huge, 0); bodyGyro.P = 15000;
	bodyGyro.CFrame = CFrame.lookAt(self.Npc.RootPart.CFrame.Position, point);
	
	task.delay(1, function() 
		bodyGyro.MaxTorque = Vector3.new(0, 0, 0); 
		humanoid.AutoRotate = true; 
	end);
end

function Movement:LookAt(point)
	if self.Destroyed then return end;
	if self.Npc.RootPart == nil or self.Npc.IsDead then return end;
	if self.Npc.Humanoid.PlatformStand then return end;
	local waistMotor = self.Npc.Prefab and self.Npc.Prefab:FindFirstChild("UpperTorso") and self.Npc.Prefab.UpperTorso:FindFirstChild("Waist");
	if self.WaistMotorC1 == nil then
		self.WaistMotorC1 = waistMotor.C1
	end
	if waistMotor then
		local waistX = math.atan2(self.Npc.RootPart.Position.Y - point.Y, 3.5);
		waistMotor.C1 = CFrame.new(self.WaistMotorC1.p) * CFrame.Angles(math.clamp(waistX, -0.7, 0.7), 0, 0);
	end
end

function Movement:EndMovement()
	if self.Destroyed then return end;
	if self.Npc == nil then return end;
	
	if self.MovementStatus then
		self.MovementStatus:Complete(false);
	end
	if self.Npc.Humanoid.PlatformStand then return end;
	self.Npc.Humanoid:MoveTo(self.Npc.RootPart.Position);
end;

function Movement:CanPath(destination)
	if self.Destroyed then return end;
	self.Npc.Path:ComputeAsync(self.Npc.RootPart.CFrame.p, destination);
	if self.Npc == nil then return false end;
	return self.Npc.Path.Status == Enum.PathStatus.Success;
end

function Movement:Follow(destination, gap)
	local movementStatus = self:Move(destination);
	movementStatus.Gap = gap or 26;
	
	return movementStatus;
end

function Movement:Move(destination, forceRegenPath)
	if self.Destroyed then return end;
	if self.Npc.IsDead then return end;
	
	if self.MovementStatus and self.MovementStatus.Destroyed ~= true then
		if forceRegenPath == true then
			self.MovementStatus.ForceRegen = true;
		end
		self.MovementStatus.Gap = nil;
		self.MovementStatus:UpdateDestination(destination);
		
	else
		self.MovementStatus = modMovementStatus.new(self, destination);
	end
	
	self.MovementStatus.CompleteFunc = nil;
	return self.MovementStatus;
end

function Movement:BlindMove(destination)
	if self.Destroyed then return end;
	if self.Npc.RootPart == nil or self.Npc.IsDead then return end;
	if self.Npc.Disabled ~= true and self.Npc.RootPart:CanSetNetworkOwnership() then self.Npc.RootPart:SetNetworkOwner(nil); end
	self.Npc.Humanoid:MoveTo(destination);
end

function Movement:IdleMove(radius, check)
	if self.Destroyed then return end;
	if self.Npc.RootPart == nil then return end;

	local randomPoint = self.Npc.RootPart.CFrame.p + Vector3.new(random:NextNumber(-radius, radius), 0, random:NextNumber(-radius, radius));
	
	if check then
		self.Npc.Path:ComputeAsync(self.Npc.RootPart.CFrame.p, randomPoint);
		if self.Npc.Path.Status ~= Enum.PathStatus.Success then
			local dir = (self.Npc.RootPart.CFrame.p - randomPoint).Unit;
			local ray = Ray.new(self.Npc.RootPart.CFrame.p, dir*32);
			local rayHit, rayPoint = workspace:FindPartOnRayWithWhitelist(ray, {workspace.Environment}, true);
			randomPoint = rayPoint;
		end
	end
	
	self:BlindMove(randomPoint);
end
	
function Movement:Pause(timeout)
	if self.Destroyed then return end;
	self.PauseEndsTick = (self.PauseEndsTick or tick()) + timeout;
	self.Paused = true;
	self.Npc.Humanoid:MoveTo(self.Npc.Humanoid.RootPart.Position);
	repeat until self.PauseEndsTick == nil or self.Npc.IsDead or (tick()-self.PauseEndsTick) > 0 or not task.wait(0.5);
	self.Paused = false;
	self.PauseEndsTick = nil;
end
	
function Movement:Resume()
	self.PauseEndsTick = nil;
end

function Movement:Destroy()
	if self.Destroyed then return end;
	
	if self.MovementStatus then
		self.MovementStatus:Destroy();
	end
	self.MovementStatus = nil;
	for k, _ in pairs(self) do
		self[k] = nil;
	end
	self.Destroyed = true;
end

function Movement:SetWalkSpeed(id, speed, order, expire) -- higher order first -- set to nil to remove
	if self.Destroyed then return end;
	
	if speed == nil then
		self.LayeredWalkSpeed:Remove(id);
		
	else
		self.LayeredWalkSpeed:Set(id, speed, order, expire);
		
	end
	
	self:UpdateWalkSpeed();
end

function Movement:UpdateWalkSpeed()
	if self.Destroyed then return end;
	local speed = self.DefaultWalkSpeed or 0;

	speed = self.LayeredWalkSpeed:Get();
	
	self.Npc.Humanoid.WalkSpeed = math.clamp(speed, 0, 300);
	self.Npc.Humanoid.JumpPower = math.clamp(self.DefaultJumpPower, 0, 200);
end

function Movement.new(Npc)
	local self = {
		Npc = Npc;
		Paused = false;
		IsFollowing = false;
		IsMoving = false;
		MovementStatus = nil;
		
		DefaultWalkSpeed = 12;
		DefaultJumpPower = 50;
		
		WalkSpeedTable = {};
		LayeredWalkSpeed = modLayeredVariable.new(12);
	};
	
	if Npc.Path == nil then
		Npc.Path = PathfindingService:CreatePath(Npc.PathAgent);
	end;
	
	setmetatable(self, Movement);
	return self;
end

--local debugWaypoints = {};
--local debug_waypoint = Instance.new("Part");
--debug_waypoint.Name = "DebugWaypoints";
--debug_waypoint.Anchored = true;
--debug_waypoint.Size = Vector3.new(0.5, 0.5, 0.5);
--debug_waypoint.CanCollide = false;
--local function DebugWaypoints()
--	local n = debug_waypoint:Clone();
--	n.Parent = workspace.Debris;
--	table.insert(debugWaypoints, n);
--	return n;
--end

return Movement;