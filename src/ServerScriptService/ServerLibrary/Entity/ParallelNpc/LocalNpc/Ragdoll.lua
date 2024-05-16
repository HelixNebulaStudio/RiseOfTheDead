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

	local canRagdoll = prefab:GetAttribute("HasRagdoll") == true;
	if canRagdoll then
		for _, obj in pairs(prefab:GetDescendants()) do
			if obj:IsA("Motor6D") and obj:GetAttribute("RagdollJoint") == true then
				if obj == nil or not prefab:IsAncestorOf(obj) then continue end;
				if obj.Parent == nil then continue end;

				obj:GetPropertyChangedSignal("Enabled"):Connect(function()
					if modParallelData:GetSetting("DisableDeathRagdoll") ~= 1 then return end;

					obj.Enabled = true;
				end)

			elseif obj:IsA("BasePart") and obj.Parent == prefab then
				if obj.Name == "CollisionRootPart" then continue end;
				
			end
		end
	end

	return self;
end

return Ragdoll;