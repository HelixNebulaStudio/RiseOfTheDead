local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local RunService = game:GetService("RunService");

local modParallelData = require(game.ReplicatedStorage.ParallelLibrary:WaitForChild("DataModule"));

--
local Ragdoll = {}
Ragdoll.__index = Ragdoll;

function Ragdoll.new(parallelNpc)
	local meta = {};
	meta.__index = meta;
	meta.ParallelNpc = parallelNpc;

	local self = {};

	setmetatable(meta, Ragdoll);
	setmetatable(self, meta);

	local prefab: Actor = self.ParallelNpc.Prefab;
	local humanoid: Humanoid = self.ParallelNpc.Humanoid;
	local rootPart: BasePart = self.ParallelNpc.RootPart;
	
	local canRagdoll = prefab:GetAttribute("HasRagdoll") == true;
	if canRagdoll then
		local ragJoints = {};
		local bodyParts = {};
		
		local ragEnabled = false;
		for _, obj in pairs(prefab:GetDescendants()) do
			if obj:IsA("Motor6D") and obj:GetAttribute("RagdollJoint") == true then
				table.insert(ragJoints, obj);

			elseif obj:IsA("BasePart") then
				if obj.Name == "CollisionRootPart" then continue end;
				table.insert(bodyParts, obj);
			end
		end

		local ragdollEnabled = false;
		
		local function updateBodyParts()
			for a=1, #bodyParts do
				local obj = bodyParts[a];
				if obj == nil or not prefab:IsAncestorOf(obj) then continue end;

				if obj.Name == "Head" or obj.Name == "UpperTorso" or obj.Name == "LowerTorso"
					or obj.Name == "LeftHand" or obj.Name == "RightHand" 
					or obj.Name == "LeftFoot" or obj.Name == "RightFoot"then

					obj.CanCollide = ragdollEnabled;

				else
					obj.CanCollide = false;

				end
			end
		end

		local function toggleRagdoll()
			for a=1, #ragJoints do
				if ragJoints[a] == nil or not prefab:IsAncestorOf(ragJoints[a]) then continue end;
				if ragJoints[a].Parent == nil then continue end;

				ragJoints[a].Parent.BallSocketConstraint.Enabled = ragdollEnabled;
				ragJoints[a].Enabled = not ragdollEnabled;
			end

			updateBodyParts();
		end
		
		local function onIsDead()
			if humanoid:GetAttribute("IsDead") ~= true then return end;
			if humanoid:GetAttribute("DisableRagdoll") == true then return end
			if modParallelData:GetSetting("DisableDeathRagdoll") == 1 then return end;
			
			ragdollEnabled = true;

			toggleRagdoll();
		end
		humanoid:GetAttributeChangedSignal("IsDead"):Connect(onIsDead)
		onIsDead();
		
		humanoid:GetAttributeChangedSignal("Ragdoll"):Connect(function()
			if humanoid:GetAttribute("DisableRagdoll") == true then return end
			if modParallelData:GetSetting("DisableDeathRagdoll") == 1 then return end;
			
			local ragdollActive = humanoid:GetAttribute("Ragdoll") == true;
			ragdollEnabled = ragdollActive;
			toggleRagdoll();
		end)
		humanoid.StateChanged:Connect(function()
			if humanoid:GetAttribute("IsDead") ~= true then return end;
			if modParallelData:GetSetting("DisableDeathRagdoll") == 1 then return end;
			
			updateBodyParts();
		end)

	end

	return self;
end

return Ragdoll;