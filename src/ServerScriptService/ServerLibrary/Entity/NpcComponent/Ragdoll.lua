local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Script;
local Component = {};
Component.__index = Component;

function Component.new(Npc)
	return function()
		local prefab = Npc.Prefab;
		
		-- Neck ragdoll joint
		pcall(function()
			local ragUpperTorso = Instance.new("Attachment");
			ragUpperTorso.Name = "RagUpperTorso";
			ragUpperTorso.Parent = prefab:WaitForChild("Head");
			ragUpperTorso.CFrame = CFrame.new(0, -0.396, -0.061) * CFrame.Angles(0, 0, 90);

			local ragHead = Instance.new("Attachment");
			ragHead.Name = "RagHead";
			ragHead.Parent = prefab.UpperTorso;
			ragHead.CFrame = CFrame.new(0, 1.105, 0) * CFrame.Angles(0, 0, 90);

			local neckBallSocket = Instance.new("BallSocketConstraint");
			neckBallSocket.LimitsEnabled = true;
			neckBallSocket.MaxFrictionTorque = 100;
			neckBallSocket.TwistLimitsEnabled = true;
			neckBallSocket.UpperAngle = 45;
			neckBallSocket.TwistLowerAngle = -30;
			neckBallSocket.TwistUpperAngle = 30;
			neckBallSocket.Parent = prefab.Head;
			neckBallSocket.Attachment0 = ragUpperTorso;
			neckBallSocket.Attachment1 = ragHead;

			local neckMotor: Motor6D = prefab.Head.Neck;
			neckMotor.Destroying:Connect(function()
				neckBallSocket:Destroy();
			end)
		end)

		-- Waist ragdoll joint
		pcall(function()
			local ragUpperTorso = Instance.new("Attachment");
			ragUpperTorso.Name = "RagUpperTorso";
			ragUpperTorso.Parent = prefab.LowerTorso;
			ragUpperTorso.CFrame = CFrame.new(0, 0.148, -0.012) * CFrame.Angles(0, 180, -90);

			local ragLowerTorso = Instance.new("Attachment");
			ragLowerTorso.Name = "RagLowerTorso";
			ragLowerTorso.Parent = prefab.UpperTorso;
			ragLowerTorso.CFrame = CFrame.new(0, -0.869, 0) * CFrame.Angles(0, 180, -90);

			local waistBallSocket = Instance.new("BallSocketConstraint");
			waistBallSocket.LimitsEnabled = true;
			waistBallSocket.MaxFrictionTorque = 100;
			waistBallSocket.TwistLimitsEnabled = true;
			waistBallSocket.UpperAngle = 35;
			waistBallSocket.TwistLowerAngle = -20;
			waistBallSocket.TwistUpperAngle = 20;
			waistBallSocket.Parent = prefab.UpperTorso;
			waistBallSocket.Attachment0 = ragLowerTorso;
			waistBallSocket.Attachment1 = ragUpperTorso;

			local waistMotor: Motor6D = prefab.UpperTorso.Waist;
			waistMotor.Destroying:Connect(function()
				waistBallSocket:Destroy();
			end)
		end)

		-- RightShoulder ragdoll joint
		pcall(function()
			local ragUpperTorso = Instance.new("Attachment");
			ragUpperTorso.Name = "RagUpperTorso";
			ragUpperTorso.Parent = prefab.RightUpperArm;
			ragUpperTorso.CFrame = CFrame.new(-0.275, 0.286, -0.061) * CFrame.Angles(0, 0, 0);

			local ragRightUpperArm = Instance.new("Attachment");
			ragRightUpperArm.Name = "RagRightUpperArm";
			ragRightUpperArm.Parent = prefab.UpperTorso;
			ragRightUpperArm.CFrame = CFrame.new(1.037, 0.64, 0.025) * CFrame.Angles(0, 0, 0);

			local ballSocket = Instance.new("BallSocketConstraint");
			ballSocket.LimitsEnabled = true;
			ballSocket.MaxFrictionTorque = 50;
			ballSocket.TwistLimitsEnabled = true;
			ballSocket.UpperAngle = 60;
			ballSocket.TwistLowerAngle = -180;
			ballSocket.TwistUpperAngle = 180;
			ballSocket.Parent = prefab.RightUpperArm;
			ballSocket.Attachment0 = ragRightUpperArm;
			ballSocket.Attachment1 = ragUpperTorso;
			
			local shoulderMotor: Motor6D = prefab.RightUpperArm.RightShoulder;
			shoulderMotor.Destroying:Connect(function()
				ballSocket:Destroy();
			end)
		end)

		-- LeftShoulder ragdoll joint
		pcall(function()
			local ragUpperTorso = Instance.new("Attachment");
			ragUpperTorso.Name = "RagUpperTorso";
			ragUpperTorso.Parent = prefab.LeftUpperArm;
			ragUpperTorso.CFrame = CFrame.new(0.296, 0.286, -0.06) * CFrame.Angles(0, 0, 180);

			local ragLeftUpperArm = Instance.new("Attachment");
			ragLeftUpperArm.Name = "RagLeftUpperArm";
			ragLeftUpperArm.Parent = prefab.UpperTorso;
			ragLeftUpperArm.CFrame = CFrame.new(-1.016, 0.64, 0.025) * CFrame.Angles(0, 0, 0);

			local ballSocket = Instance.new("BallSocketConstraint");
			ballSocket.LimitsEnabled = true;
			ballSocket.MaxFrictionTorque = 50;
			ballSocket.TwistLimitsEnabled = true;
			ballSocket.UpperAngle = 60;
			ballSocket.TwistLowerAngle = -180;
			ballSocket.TwistUpperAngle = 180;
			ballSocket.Parent = prefab.LeftUpperArm;
			ballSocket.Attachment0 = ragLeftUpperArm;
			ballSocket.Attachment1 = ragUpperTorso;

			local shoulderMotor: Motor6D = prefab.LeftUpperArm.LeftShoulder;
			shoulderMotor.Destroying:Connect(function()
				ballSocket:Destroy();
			end)
		end)

		-- LeftHip ragdoll joint
		pcall(function()
			local ragLowerTorso = Instance.new("Attachment");
			ragLowerTorso.Name = "RagLowerTorso";
			ragLowerTorso.Parent = prefab.LeftUpperLeg;
			ragLowerTorso.CFrame = CFrame.new(-0, 0.576, -0.019) * CFrame.Angles(0, 180, -90);

			local ragLeftUpperLeg = Instance.new("Attachment");
			ragLeftUpperLeg.Name = "RagLeftUpperLeg";
			ragLeftUpperLeg.Parent = prefab.LowerTorso;
			ragLeftUpperLeg.CFrame = CFrame.new(-0.443, -0.293, 0) * CFrame.Angles(0, 180, -90);

			local ballSocket = Instance.new("BallSocketConstraint");
			ballSocket.LimitsEnabled = true;
			ballSocket.MaxFrictionTorque = 50;
			ballSocket.TwistLimitsEnabled = true;
			ballSocket.UpperAngle = 45;
			ballSocket.TwistLowerAngle = -30;
			ballSocket.TwistUpperAngle = 30;
			ballSocket.Parent = prefab.LeftUpperLeg;
			ballSocket.Attachment0 = ragLowerTorso;
			ballSocket.Attachment1 = ragLeftUpperLeg;

			local hipMotor: Motor6D = prefab.LeftUpperLeg.LeftHip;
			hipMotor.Destroying:Connect(function()
				ballSocket:Destroy();
			end)
		end)

		-- RightHip ragdoll joint
		pcall(function()
			local ragLowerTorso = Instance.new("Attachment");
			ragLowerTorso.Name = "RagLowerTorso";
			ragLowerTorso.Parent = prefab.RightUpperLeg;
			ragLowerTorso.CFrame = CFrame.new(0.009, 0.576, -0.019) * CFrame.Angles(0, 180, -90);

			local ragRightUpperLeg = Instance.new("Attachment");
			ragRightUpperLeg.Name = "RagRightUpperLeg";
			ragRightUpperLeg.Parent = prefab.LowerTorso;
			ragRightUpperLeg.CFrame = CFrame.new(0.452, -0.293, 0) * CFrame.Angles(0, 180, -90);

			local ballSocket = Instance.new("BallSocketConstraint");
			ballSocket.LimitsEnabled = true;
			ballSocket.MaxFrictionTorque = 50;
			ballSocket.TwistLimitsEnabled = true;
			ballSocket.UpperAngle = 45;
			ballSocket.TwistLowerAngle = -30;
			ballSocket.TwistUpperAngle = 30;
			ballSocket.Parent = prefab.RightUpperLeg;
			ballSocket.Attachment0 = ragLowerTorso;
			ballSocket.Attachment1 = ragRightUpperLeg;

			local hipMotor: Motor6D = prefab.RightUpperLeg.RightHip;
			hipMotor.Destroying:Connect(function()
				ballSocket:Destroy();
			end)
		end)
	end
end

return Component;