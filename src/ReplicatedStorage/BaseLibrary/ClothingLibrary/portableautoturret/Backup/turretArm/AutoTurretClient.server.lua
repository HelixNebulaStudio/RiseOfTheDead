if not workspace:IsAncestorOf(script) then return end;

local RunService = game:GetService("RunService");

local targetValue = script:WaitForChild("Target");
local hydraulicRoot = script.Parent:WaitForChild("Hydraulics");
local hydraulicRod = script.Parent:WaitForChild("HydraulicRod");
local arm1 = script.Parent:WaitForChild("Arm1");
local arm2 = script.Parent:WaitForChild("Arm2");

local jointHarCf = CFrame.new(hydraulicRod:WaitForChild("JointHRA").CFrame.Position);
local jointAa2Cf = CFrame.new(arm1:WaitForChild("JointAA2").CFrame.Position);

local rad120 = math.rad(120);
local rad90 = math.rad(90);
local rad80 = math.rad(80);
local rad30 = math.rad(30);
local rad1 = math.rad(1);

RunService.Heartbeat:Connect(function(delta: number)
	local mode = script:GetAttribute("Mode") or 1;
	
	local targetPart = targetValue.Value;
	
	if mode == 1 then
		if targetPart == nil or not workspace:IsAncestorOf(targetPart) then
			mode = 2;
		end
	end
	
	if mode == 1 then -- Online
		local targetCf = CFrame.new(targetPart.Position);
		local relativeYawCframe = hydraulicRoot.CFrame:ToObjectSpace(targetCf);
		local angleYaw = math.atan2(relativeYawCframe.X, -relativeYawCframe.Z);
		local relativePitchCframe = hydraulicRod.CFrame:ToObjectSpace(targetCf);
		local anglePitch = math.atan2(relativePitchCframe.Y, -relativePitchCframe.Z);
		
		hydraulicRod.HydraulicRod.CFrame = CFrame.Angles(0, angleYaw, 0);
		hydraulicRod.JointHRA.CFrame  = jointHarCf * CFrame.Angles(math.clamp(anglePitch+rad30, 0, rad80), 0, 0)
		arm1.JointAA2.CFrame = jointAa2Cf * CFrame.Angles(0, 0, 0);
		
	elseif mode == 2 then -- Idle;
		local y = (math.sin(tick()) - 1)/3; 
		hydraulicRod.HydraulicRod.CFrame = CFrame.Angles(0, y, 0);
		hydraulicRod.JointHRA.CFrame  = jointHarCf * CFrame.Angles(rad30, 0, 0);
		arm1.JointAA2.CFrame = jointAa2Cf * CFrame.Angles(0, 0, 0);
		
	elseif mode == 3 then -- offline;
		hydraulicRod.HydraulicRod.CFrame = CFrame.Angles(0, rad120, 0);
		hydraulicRod.JointHRA.CFrame  = jointHarCf * CFrame.Angles(-rad90, 0, 0);
		arm1.JointAA2.CFrame = jointAa2Cf * CFrame.Angles((rad30-rad1), 0, 0);
		
	end
end)