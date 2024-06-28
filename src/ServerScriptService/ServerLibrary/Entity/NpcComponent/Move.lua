local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Script;

local TweenService = game:GetService("TweenService");
local CollectionService = game:GetService("CollectionService");

local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);

---
local Move = {};
Move.__index = Move;

function Move:Init()
	if self.Destroyed then return end;
	if self.Npc.RootPart == nil or self.Npc.IsDead then return end;

	local defaultWs = self.Npc.Humanoid.WalkSpeed;
	if self.SetDefaultWalkSpeed then
		defaultWs = self.SetDefaultWalkSpeed;
	end
	self:SetMoveSpeed("set", "default", defaultWs, 0);
end

function Move:HeadTrack(obj: BasePart, expireTime: number)
	local prefab = self.Npc.Prefab;
	local trackObjTag = prefab:FindFirstChild("HeadTrackObj");

	if obj then
		if self.Destroyed then return end;
		if self.Npc.IsDead then return end;
		if self.Npc.Humanoid.PlatformStand then return end;
		
		if trackObjTag == nil then
			trackObjTag = Instance.new("ObjectValue");
			trackObjTag.Name = "HeadTrackObj";
			trackObjTag.Parent = prefab;
			
			if expireTime then
				Debugger.Expire(trackObjTag, expireTime);
			end
			self.Npc.Garbage:Tag(trackObjTag);
		end
		trackObjTag.Value = obj;
		CollectionService:AddTag(self.Npc.Head, "LookingHead");
		
	elseif trackObjTag then
		trackObjTag:Destroy();
		
	end
end

function Move:Face(target, faceSpeed, duration)
	if self.Destroyed then return end;
	if self.Npc.RootPart == nil or self.Npc.IsDead then return end;
	if self.Npc.Humanoid.PlatformStand then return end;
	
	self.Npc:SetNetworkOwner();
	self.Npc:SendActorMessage("Face", {
		Initials=self.Initials;
		Target=target;
		FaceSpeed=faceSpeed;
		Duration=duration;
	});
end

-- !outline: Move:LookAt(point: Vector3 | BasePart)
function Move:LookAt(point: Vector3 | BasePart)
	if self.Destroyed then return end;
	if self.Npc.RootPart == nil or self.Npc.IsDead then return end;
	if self.Npc.Humanoid.PlatformStand then return end;
	
	if typeof(point) == "Instance" and point:IsA("BasePart") then
		point = point.Position;
	end
	assert(typeof(point) == "Vector3");
	
	local waistMotor = self.Npc.Prefab and self.Npc.Prefab:FindFirstChild("UpperTorso") and self.Npc.Prefab.UpperTorso:FindFirstChild("Waist");
	if self.WaistMotorC1 == nil then
		self.WaistMotorC1 = waistMotor.C1
	end
	if waistMotor then
		local waistX = math.atan2(self.Npc.RootPart.Position.Y - point.Y, 3.5);
		local waistY = self.Npc.JointRotations.WaistRot:Get();
		waistMotor.C1 = CFrame.new(self.WaistMotorC1.p) * CFrame.Angles(math.clamp(waistX, -0.7, 0.7), waistY, 0);
		
		if self.WaistTween then
			self.WaistTween:Cancel();
			self.WaistTween = nil;
		end
		
		self.WaistTween = TweenService:Create(waistMotor, TweenInfo.new(1), {
			C1 = CFrame.new(self.WaistMotorC1.p) * CFrame.Angles(0, waistY, 0);
		})
		self.WaistTween:Play();
	end
end

-- !outline: Move:MoveTo(target: Vector3 | BasePart)
function Move:MoveTo(target: Vector3 | BasePart)
	if self.Destroyed then return end;
	if self.Npc.RootPart == nil or self.Npc.IsDead then return end;
	if self.Npc.Humanoid.PlatformStand then return end;

	self.MoveId = self.MoveId + 1;
	local moveId = self.MoveId;
	self.IsMoving = true;
	self.Npc.Humanoid:SetAttribute("IsMoving", self.IsMoving);
	
	self.Npc:SetNetworkOwner();
	self.Npc:SendActorMessage("Move", {
		Initials=self.Initials;
		
		MoveId = self.MoveId;
		Target=target;
	});
	
	return moveId;
end

function Move:Follow(target: Vector3 | BasePart, maxFollowDist: number, minFollowDist: number)
	if self.Destroyed then return end;
	if self.Npc.RootPart == nil or self.Npc.IsDead then return end;
	if self.Npc.Humanoid.PlatformStand then return end;
	if target == nil then return end; -- Debugger:Warn("Move:Follow Target nil", self.Npc.Name);
	
	self.MoveId = self.MoveId + 1;
	self.IsMoving = true;
	self.Npc.Humanoid:SetAttribute("IsMoving", self.IsMoving);
	
	self.Npc:SetNetworkOwner();
	self.Npc:SendActorMessage("Move", {
		Initials=self.Initials;
		
		MoveId = self.MoveId;
		Follow=true;
		Target=target;
		MaxFollowDist=maxFollowDist;
		MinFollowDist=minFollowDist;
	});
	
	return self.MoveId;
end

function Move:Stop()
	if self.Destroyed then return end;
	if self.Npc.RootPart == nil or self.Npc.IsDead then return end;
	if self.Npc.Humanoid.PlatformStand then return end;
	
	self.Npc:SendActorMessage("Stop");
end

function Move:Pause(pauseTime)
	if self.Destroyed then return end;
	if self.Npc.RootPart == nil or self.Npc.IsDead then return end;
	if self.Npc.Humanoid.PlatformStand then return end;

	self.Npc:SendActorMessage("Pause", {PauseTime=pauseTime});
end

function Move:Resume()
	if self.Destroyed then return end;
	if self.Npc.RootPart == nil or self.Npc.IsDead then return end;
	if self.Npc.Humanoid.PlatformStand then return end;

	self.Npc:SendActorMessage("Resume");
end

function Move:Recompute()
	if self.Destroyed then return end;
	if self.Npc.RootPart == nil or self.Npc.IsDead then return end;

	self.Npc:SendActorMessage("Recompute");
end

function Move:SetMoveSpeed(action, id, value, priority, expire)
	if self.Destroyed then return end;
	if self.Npc.RootPart == nil or self.Npc.IsDead then return end;

	self.Npc:SendActorMessage("SetMoveSpeed", {
		Initials=self.Initials;
		
		Action=action;
		Id=id;
		Value=value;
		Priority=priority;
		Expire=expire;
	});
end

type TrajectoryPoints = {
	[number] : {
		Velocity : Vector3;
		Direction : Vector3;
	}
}
function Move:Fly(trajPoints: TrajectoryPoints, delta: number, onStepFunc)
	if #trajPoints <= 0 then return end;
	if self.Npc.IsDead then return; end;
	
	local linVel: LinearVelocity = self.LinearVelocity;
	local alignOri: AlignOrientation = self.AlignOrientation;
	
	linVel.Enabled = true;
	alignOri.Enabled = true;
	self:SetMoveSpeed("set", "fly", 0, 9);
	
	local lastPointInd = #trajPoints;
	for a=1, lastPointInd do
		local trajPoint = trajPoints[a];
		trajPoint.AlignCFrame = CFrame.lookAt(Vector3.zero, trajPoint.Direction);
		
		local breakRequest = false;
		if onStepFunc then
			breakRequest = onStepFunc(a, trajPoint);
		end
		
		linVel.VectorVelocity = trajPoint.Velocity;
		alignOri.CFrame = trajPoint.AlignCFrame;

		task.wait(delta or 1/15);
		if breakRequest then break; end;
		if self.Npc.IsDead then break; end;
	end
	
	linVel.Enabled = false;
	alignOri.Enabled = false;
	self:SetMoveSpeed("remove", "fly");
	
	if self.Npc.RootPart then
		self.Npc.RootPart.AssemblyLinearVelocity = Vector3.new();
	end
end

function Move.new(self)
	local moveObject = {};
	moveObject.Npc = self;
	moveObject.Initials = {
		PathAgent=self.PathAgent;
		SmartNpc=(self.Humanoid.Name == "Human");
	}
	
	moveObject.IsMoving = false;
	self.Npc.Humanoid:SetAttribute("IsMoving", self.IsMoving);
	moveObject.Status = "idle";

	moveObject.MoveId = 0;
	moveObject.MoveToEnded = modEventSignal.new("MoveToEnded");
	
	if self.IsDead then
		Debugger:Warn("Dead", self.Name);
		return;
	end
	local rootRigAttachment = self.RootPart:WaitForChild("RootRigAttachment");

	local linVel: LinearVelocity = Instance.new("LinearVelocity");
	linVel.Name = "FlyLinearVelocity";
	linVel.Enabled = false;
	linVel.ForceLimitsEnabled = false;
	linVel.Attachment0 = rootRigAttachment;
	linVel.Parent = self.RootPart;

	local alignOri: AlignOrientation = Instance.new("AlignOrientation");
	alignOri.Name = "FlyAlignOrientation";
	alignOri.Enabled = false;
	alignOri.Responsiveness = 100;
	alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment;
	alignOri.Attachment0 = rootRigAttachment;
	alignOri.Parent = self.RootPart;
	
	moveObject.LinearVelocity = linVel;
	moveObject.AlignOrientation = alignOri;
	
	self.ActorEvent.Event:Connect(function(action, ...)
		if self == nil or self.IsDead then return end;

		if action == "moveToEnded" then
			moveObject.IsMoving = false;
			moveObject.MoveToEnded:Fire(...);
			self.Npc.Humanoid:SetAttribute("IsMoving", self.IsMoving);

		elseif action == "updateStatus" then
			moveObject.Status = ...;

			if self.Prefab:GetAttribute("DebugMoveStatus") then
				Debugger:Display({
					MoveStatus=tostring(moveObject.Status);
				});
			end
		end
	end)
	
	self.Garbage:Tag(linVel);
	self.Garbage:Tag(alignOri);
	
	setmetatable(moveObject, Move);
	return moveObject;
end

return Move;