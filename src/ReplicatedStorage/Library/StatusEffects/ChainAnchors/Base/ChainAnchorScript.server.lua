
local primaryPart: BasePart = script.Parent;
local tarRpObj: ObjectValue = script.Parent:WaitForChild("TargetRootPart");
local linVel: LinearVelocity = script.Parent:WaitForChild("LinearVelocity");

local gap = 1;

while true do
	task.wait(0.5);
	if tarRpObj.Value == nil then continue end;
	local rootPart = tarRpObj.Value;
	local rootPos = rootPart.Position;
	
	local dist = math.abs(primaryPart.Position.Y - (rootPos.Y+(gap/2)));
	if dist < gap then 
		linVel.VectorVelocity = Vector3.zero;
		continue 
	end;
	
	if primaryPart.Position.Y > rootPos.Y then
		linVel.VectorVelocity = Vector3.yAxis * -dist * 0.3;
		
	elseif primaryPart.Position.Y < rootPos.Y then
		linVel.VectorVelocity = Vector3.yAxis * dist * 0.3;
		
	end
end