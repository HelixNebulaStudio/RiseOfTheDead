local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local characterTag = script:WaitForChild("Character");
repeat task.wait(0.1) until characterTag.Value ~= nil;

local character = characterTag.Value;
if not workspace:IsAncestorOf(character) then return end;

local localplayer = game.Players.LocalPlayer;
local modData = shared.require(localplayer:WaitForChild("DataModule") :: ModuleScript);
local modCharacter = modData:GetModCharacter();
local playerClass: PlayerClass = shared.modPlayers.get(localplayer);
--==

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local humanoid = character:WaitForChild("Zombie");
local rootPart = character:WaitForChild("HumanoidRootPart");
local zpiderLimbs = character:WaitForChild("ZpiderLimbs");

local ikCycleIndex = 1;
local ikControlData = {};

local poleTargetPoint = Vector3.new(0, 10, 2);
local poleAtt = Instance.new("Attachment");
poleAtt.Name = `Pole`
poleAtt.Parent = rootPart;
poleAtt.Position = poleTargetPoint;

local function bindLimbSolver(sidePrefix, limbType, index)
	local upperLimb = zpiderLimbs:WaitForChild(`{sidePrefix}Upper{limbType}{index}`);
	local lowerLimb = zpiderLimbs:WaitForChild(`{sidePrefix}Lower{limbType}{index}`);
	local footLimb = zpiderLimbs:WaitForChild(`{sidePrefix}{limbType == "Arm" and "Hand" or "Foot"}{index}`);
	
	local name = `{sidePrefix}{limbType}{index}`
	
	local ikControl = Instance.new("IKControl");
	ikControl.Name = name;
	ikControl.Weight = 1;
	ikControl.Priority = 0;
	ikControl.SmoothTime = 0.05;
	ikControl.Enabled = false;
	ikControl.Parent = humanoid;
	
	ikControl.ChainRoot = upperLimb:WaitForChild(upperLimb.Name);
	ikControl.EndEffector = footLimb:WaitForChild(footLimb.Name);
	
	local targetAtt: Attachment = Instance.new("Attachment");
	targetAtt.Name = name;
	targetAtt.Parent = workspace.Terrain;

	local footCf = footLimb.CFrame;
	targetAtt.WorldCFrame = footCf;
	
	ikControl.Target = targetAtt;
	ikControl.Pole = poleAtt;
	
	ikControl.Destroying:Connect(function()
		targetAtt:Destroy();
	end)
	
	local footAtt = Instance.new("Attachment");
	footAtt.Name = `FootAtt`
	footAtt.Parent = rootPart;

	local dir = (footCf.Position-poleAtt.WorldPosition).Unit;
	footAtt.WorldCFrame = CFrame.lookAlong(footCf.Position, dir);
	
	local legIndex = limbType == "Arm" and index or index+2;
	table.insert(ikControlData, {
		SidePrefix = sidePrefix;
		LegIndex = legIndex;
		
		IKControl = ikControl;
		FootAtt = footAtt;
		LastCFrame = footCf;
	});
end

bindLimbSolver("Left", "Arm", 1);
bindLimbSolver("Right", "Arm", 1);
bindLimbSolver("Left", "Arm", 2);
bindLimbSolver("Right", "Arm", 2);
bindLimbSolver("Left", "Leg", 1);
bindLimbSolver("Right", "Leg", 1);
bindLimbSolver("Left", "Leg", 2);
bindLimbSolver("Right", "Leg", 2);

local raycastParams: RaycastParams = RaycastParams.new();
raycastParams.FilterType = Enum.RaycastFilterType.Include;
raycastParams.RespectCanCollide = true;
raycastParams.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain};

local STEP_DIST = 4;
local function onHeartbeat(index)
	if playerClass:DistanceFromCharacter(rootPart.Position) > 128 then return end;

	local ikData = ikControlData[index or ikCycleIndex];
	if ikData == nil then
		ikData = ikControlData[1];
		ikCycleIndex = 1;
	end
	ikCycleIndex = ikCycleIndex +1;

	--
	local ikControl: IKControl = ikData.IKControl;
	
	ikControl.Enabled = true;
	local targetAtt: Attachment = ikControl.Target :: Attachment;

	local footAtt = ikData.FootAtt;
	local footDir = footAtt.WorldCFrame.LookVector;
	local sidePrefix = ikData.SidePrefix == "Left" and 1 or -1;
	local legIndex = ikData.LegIndex;
	local rpLookVector = rootPart.CFrame.LookVector;
	
	
	local footDist = 4;
	local legOrigin = footAtt.WorldPosition - footDir*footDist;
	
	if sidePrefix == 1 and legIndex%2 == 0 then
		legOrigin = legOrigin + rpLookVector;
	elseif sidePrefix == -1 and legIndex%2 == 1 then
		legOrigin = legOrigin + rpLookVector;
	end
	local rayResult = workspace:Raycast(legOrigin, footDir*(footDist+2), raycastParams);
	
	
	local newPosition;
	if rayResult then
		newPosition = rayResult.Position;
	else
		newPosition = footAtt.WorldPosition;
	end
	local oldPosition = ikData.LastCFrame.Position;
	
	
	local curStepDist = (newPosition-oldPosition).Magnitude;
	if curStepDist > STEP_DIST then
		ikData.LastCFrame = CFrame.new(newPosition);
		targetAtt.WorldCFrame = ikData.LastCFrame;
	end
end

RunService.Heartbeat:Connect(function()
	onHeartbeat();
end)