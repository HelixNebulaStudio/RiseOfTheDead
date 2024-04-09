local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local Rope = {};
Rope.__index = Rope;

Rope.Ropes = {};

local CollectionService = game:GetService("CollectionService");
local RunService = game:GetService("RunService");

local rayParam = RaycastParams.new();
rayParam.FilterType = Enum.RaycastFilterType.Include;
rayParam.IgnoreWater = true;
rayParam.CollisionGroup = "Raycast";
rayParam.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain};

local delta = 1/30;
--== Script;

task.spawn(function()
	while true do
		local waited = false;
		for a=#Rope.Ropes, 1, -1 do
			local rope = Rope.Ropes[a];
			if rope then
				if rope.Destroyed == true then
					table.remove(Rope.Ropes, a);
					
				else
					if rope.Locked == false then 
						rope:Process(delta);
						task.wait()
						waited = true;
					end;
				end
			end
		end
		if not waited then
			task.wait(1/15);
		end
	end
end)

function Rope.new()
	local self = {
		Cycles = 5;
		
		Points = {};
		Sticks = {};
		
		GravitationalForce = Vector3.new(0, -workspace.Gravity, 0) * delta * delta;
		Damping = 1.1;
		
		Locked = false;
	};
	
	setmetatable(self, Rope);
	return self;
end

function Rope:Run()
	table.insert(self.Ropes, self);
end

function Rope:Stop()
	for a=#self.Ropes, 1, -1 do
		if self.Ropes[a] == self then
			table.remove(self.Ropes, a);
			break;
		end
	end
end

function Rope:Destroy()
	if self.Destroyed then return end;
	self.Locked = true;
	self.Destroyed = true;
	
	for a=1, #self.Points do
		self.Points[a].Locked = true;
		self.Points[a].Object = nil;
	end
	
	for a=1, #self.Sticks do
		self.Sticks[a].Update = nil;
	end
	
	self.Points = nil;
	self.Sticks = nil;
end

function Rope:NewPoint(position, locked)
	if self.Destroyed == true then return end;
	
	local new = {};
	
	new.Position = position;
	new.Locked = locked == true;
	
	new.PrevPosition = position;
	
	table.insert(self.Points, new);
	return new;
end

function Rope:DestroyPoint(a)
	local point = table.remove(self.Points, a);
	if point == nil then return end;
	
	for a=#self.Sticks, 1, -1 do
		local stick = self.Sticks[a];
		
		if stick.PointA == point then
			table.remove(self.Sticks, a);
		end
		if stick.PointB == point then
			table.remove(self.Sticks, a);
		end
	end
end

function Rope:NewStick(pointA, pointB, length)
	if self.Destroyed == true then return end;
	local new = {};
	
	new.PointA = pointA;
	new.PointB = pointB;
	
	new.Length = length or (pointA.Position-pointB.Position).Magnitude;
	
	table.insert(self.Sticks, new);
	return new;
end

local function shuffleArray(array)
	if array == nil then return end;
	local n=#array
	for i=1,n-1 do
		local l= math.random(i, n);
		array[i],array[l]=array[l],array[i]
	end
end

function Rope:Process(delta)
	if self.Destroyed == true then return end;
	if #self.Points > 32 or #self.Sticks > 16 then
		self:Destroy();
		return;
	end
	
	for a=1, #self.Points do
		local pt = self.Points[a];
		
		if not pt.Locked then
			local prevPos = pt.Position;
			
			local raycastResult = workspace:Raycast(pt.Position, Vector3.new(0, -2, 0), rayParam);
			
			pt.Position = pt.Position + (pt.Position - pt.PrevPosition) / self.Damping;
			pt.Position = pt.Position + (self.GravitationalForce);
			
			if raycastResult then
				pt.YLock = raycastResult.Position.Y;
				
				pt.Position = Vector3.new(
					pt.Position.X, 
					math.max(pt.Position.Y, pt.YLock), 
					pt.Position.Z
				);
			end
			
			pt.PrevPosition = prevPos;
		end
		if self.Destroyed == true then return end;
	end
	
	if self.Destroyed == true then return end;
	
	shuffleArray(self.Sticks);
	for i=1, self.Cycles do
		if self.Destroyed == true then return end;
		for a=1, #self.Sticks do
			if self.Destroyed == true then return end;
			
			local st = self.Sticks[a];
			
			if st.Destroyed then continue end;
			
			local dir = (st.PointA.Position - st.PointB.Position).Unit;
			if shared.IsNan(dir) then continue end;
			
			local center = (st.PointA.Position + st.PointB.Position)/2;
			local len = (st.PointA.Position - st.PointB.Position).Magnitude;
			
			if not st.PointA.Locked then
				st.PointA.Position = center + dir * math.min(len, st.Length)/2;
				
				if st.PointA.YLock and len <= st.Length*2 then
					st.PointA.Position = Vector3.new(
						st.PointA.Position.X, 
						math.max(st.PointA.Position.Y, st.PointA.YLock), 
						st.PointA.Position.Z
					);
				else
					st.PointA.YLock = nil;
				end
			end
			
			if not st.PointB.Locked then
				st.PointB.Position = center - dir * math.min(len, st.Length)/2;
				
				if st.PointB.YLock and len <= st.Length*2 then
					st.PointB.Position = Vector3.new(
						st.PointB.Position.X, 
						math.max(st.PointB.Position.Y, st.PointB.YLock), 
						st.PointB.Position.Z
					);
				else
					st.PointB.YLock = nil;
				end
			end
		end
	end
	
	if self.Destroyed == true then return end;
	
	for a=1, #self.Points do
		if self.Destroyed == true then return end;
		
		local pt = self.Points[a];
		
		if pt.Locked then
			if pt.Object then
				pt.Position = pt.Object.Position;
			end
			
		else
			if pt.Object then
				pt.Object.Position = pt.Position;
			end
			
			if self.Debug then
				if pt.DebugPart == nil then
					pt.DebugPart = Debugger:PointPart(pt.Position);
					pt.DebugPart.Shape = Enum.PartType.Ball;
					pt.DebugPart.Size = Vector3.new(1, 1, 1);
				else
					pt.DebugPart.Position = pt.Position;
				end
			end
			
		end
	end
	
	if self.Destroyed == true then return end;
	
	for a=1, #self.Sticks do
		local stick = self.Sticks[a];
		
		if stick.Update then
			stick:Update();
		end
		
		if self.Debug then
			local center = (stick.PointA.Position+stick.PointB.Position)/2;
			
			if stick.DebugPart == nil then
				stick.DebugPart = Debugger:PointPart(center);
				stick.DebugPart.Name = tostring(stick);
				stick.DebugPart.Shape = Enum.PartType.Block;
			end
			
			stick.DebugPart.Size = Vector3.new(0.5, math.min(stick.Length, (stick.PointA.Position-stick.PointB.Position).Magnitude), 0.5);
			stick.DebugPart.CFrame = CFrame.lookAt(center, stick.PointB.Position) * CFrame.Angles(math.rad(90), 0, 0);
			
		end
		
	end
end

return Rope;