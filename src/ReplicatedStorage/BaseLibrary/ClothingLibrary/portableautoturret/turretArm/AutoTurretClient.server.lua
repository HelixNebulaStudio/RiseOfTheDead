if not workspace:IsAncestorOf(script) then return end;

local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");

local localPlayer = game.Players.LocalPlayer;
local character = localPlayer.Character;

while character == nil do
	task.wait(0.5);
	character = localPlayer.Character;
end

local isOwner = character:IsAncestorOf(script);

local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

local modVector = require(game.ReplicatedStorage.Library.Util.Vector);

local remoteAutoTurret = modRemotesManager:Get("AutoTurret");


local targetValue = script:WaitForChild("Target");
local turretArm = script.Parent;
local hydraulicRoot = script.Parent:WaitForChild("Hydraulics");
local hydraulicRod = script.Parent:WaitForChild("HydraulicRod");
local arm1 = script.Parent:WaitForChild("Arm1");
local _arm2 = script.Parent:WaitForChild("Arm2");

local jointHarCf = CFrame.new(hydraulicRod:WaitForChild("JointHRA").CFrame.Position);
local jointAa2Cf = CFrame.new(arm1:WaitForChild("JointAA2").CFrame.Position);

local halfPi = math.pi/2;
local rad180 = math.rad(180);
local rad120 = math.rad(120);
local rad90 = math.rad(90);
local rad80 = math.rad(80);
local rad30 = math.rad(30);
local _rad1 = math.rad(1);

local syncTick = tick();
RunService.Heartbeat:Connect(function(delta: number)

	if not isOwner then
		local dist = modVector.DistanceSqrd(character:GetPivot().Position, turretArm:GetPivot().Position);
		if dist > 1024 then
			if tick()-syncTick<=0.2 then
				return;
			end
			syncTick = tick();
		end
		if dist > 4096 then
			return;
		end
	end
	
	local mode = script:GetAttribute("Mode") or 1;

	local targetPart = targetValue.Value;

	if mode == 1 then
		if targetPart == nil or not workspace:IsAncestorOf(targetPart) then
			mode = 2;
		end
	end

	if mode == 1 then -- Online
		local angleYaw, anglePitch = 0, 0;
		if isOwner then
			local targetCf = CFrame.new(targetPart.Position);
			local relativeYawCframe = hydraulicRoot.CFrame:ToObjectSpace(targetCf);
			angleYaw = math.atan2(relativeYawCframe.X, -relativeYawCframe.Z);
			local relativePitchCframe = hydraulicRod.CFrame:ToObjectSpace(targetCf);
			anglePitch = math.atan2(relativePitchCframe.Y, -relativePitchCframe.Z);

			if tick()-syncTick >= 0.5 then
				syncTick = tick();
				task.spawn(function()
					remoteAutoTurret:InvokeServer("syncjoints", {
						angleYaw;
						anglePitch;
					});
				end)
			end
			
		else
			angleYaw = turretArm:GetAttribute("AngleYaw") or 0;
			anglePitch = turretArm:GetAttribute("AnglePitch") or 0;
			
		end
		
		hydraulicRod.HydraulicRod.CFrame = CFrame.Angles(0, halfPi + angleYaw, 0);
		hydraulicRod.JointHRA.CFrame  = jointHarCf * CFrame.Angles(math.clamp(anglePitch+rad30, 0, rad80), 0, 0)
		arm1.JointAA2.CFrame = jointAa2Cf * CFrame.Angles(-rad120, 0, 0);

	elseif mode == 2 then -- Idle;
		local y = (halfPi*3 + math.sin(tick()))/3; 
		hydraulicRod.HydraulicRod.CFrame = CFrame.Angles(0, y, 0);
		hydraulicRod.JointHRA.CFrame  = jointHarCf * CFrame.Angles(rad30, 0, 0);
		arm1.JointAA2.CFrame = jointAa2Cf * CFrame.Angles(-rad120, 0, 0);

	elseif mode == 3 then -- offline;
		hydraulicRod.HydraulicRod.CFrame = CFrame.Angles(0, rad180, 0);
		hydraulicRod.JointHRA.CFrame  = jointHarCf * CFrame.Angles(-rad90, 0, 0);
		arm1.JointAA2.CFrame = jointAa2Cf * CFrame.Angles(-rad90, 0, 0);

	elseif mode == 4 then -- reload;
		hydraulicRod.HydraulicRod.CFrame = CFrame.Angles(0, rad90, 0);
		hydraulicRod.JointHRA.CFrame  = jointHarCf * CFrame.Angles(-rad90, 0, 0);
		arm1.JointAA2.CFrame = jointAa2Cf * CFrame.Angles(-rad90, 0, 0);

	end
	
end)

if isOwner then
	local debounce = tick()-1;

	local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
	local storageItem;
	UserInputService.InputBegan:connect(function(inputObject, inputEvent)
		if UserInputService:GetFocusedTextBox() ~= nil then return end;
		if modKeyBindsHandler:Match(inputObject, "KeyTogglePat") then
			if turretArm.Parent == nil or turretArm.Parent.Parent ~= character then return end;

			if tick()-debounce <= 1 then return end;
			debounce = tick();
			local returnPacket = remoteAutoTurret:InvokeServer("toggleonline");

			if returnPacket and returnPacket.Success then
				storageItem = modData.GetItemById(returnPacket.ID);
				storageItem.Values.Online = returnPacket.Values.Online;
				storageItem.Values.Config = returnPacket.Values.Config;
			end

			debounce = tick()-0.5;
		end
	end)

end