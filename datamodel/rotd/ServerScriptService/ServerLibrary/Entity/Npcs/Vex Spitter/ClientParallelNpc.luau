
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modParallelData = shared.require(game.ReplicatedStorage.ParallelLibrary:WaitForChild("DataModule"));

local clientNpc = {};

function clientNpc.init(localNpc)
    local character: Actor = localNpc.Character;
	local humanoid: Humanoid = localNpc.Humanoid;
	local rootPart = localNpc.RootPart;

	local head: BasePart = character:WaitForChild("Head") :: BasePart;
	local headMotor: Motor6D = rootPart:WaitForChild("Head");
	local targetPartObj: ObjectValue = character:WaitForChild("TargetPart") :: ObjectValue;

	local defaultC0 = headMotor:GetAttribute("DefaultC0") or headMotor.C0;
	
	local lagTick = tick();
	RunService.Heartbeat:ConnectParallel(function()
		local targetPart = targetPartObj.Value;
		if targetPart == nil then
			return;
		end

		local curTick = tick();
		if curTick < lagTick then
			return;
		end
		lagTick = curTick + 0.1;

		local rpCf = rootPart.CFrame;
		local dir = (targetPart.Position - rpCf.Position).Unit;

		local wCfRot = CFrame.lookAlong(rpCf.Position, dir) * CFrame.Angles(math.rad(-90), 0, 0);
		local lCf = CFrame.new(defaultC0.Position) * rpCf:ToObjectSpace(wCfRot).Rotation;

		task.synchronize();
		TweenService:Create(headMotor, TweenInfo.new(0.11, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
			C0 = lCf;
		}):Play();
	end)

end

return clientNpc;