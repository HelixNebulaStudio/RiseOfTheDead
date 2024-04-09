local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local CollectionService = game:GetService("CollectionService");
local templateTarget = script:WaitForChild("WeakpointTarget");

--== Script;
local Component = {};
Component.__index = Component;

function Component.new(Npc)
	local self = {};
	
	setmetatable(self, Component);
	return function(hitObject, targetHitFunc)
		if Npc.IsDead then return end;
		
		if self.TargetGui == nil and math.random(1, 3) == 1 then
			local prefabBodyParts = Npc.Prefab:GetChildren();
			local count = 0;
			
			local targetPart = nil;
			repeat
				count= count+1;
				targetPart = prefabBodyParts[math.random(1, #prefabBodyParts)];
				if count > #prefabBodyParts then
					targetPart = nil;
					break;
				end
			until targetPart:IsA("BasePart") and targetPart.AssemblyRootPart == Npc.RootPart
				and targetPart.Name ~= "HumanoidRootPart"
				and (targetPart.Size.X >= 0.5 and targetPart.Size.Y >= 0.5 and targetPart.Size.Z >= 0.5);
			
			if targetPart == nil then return end;
			
			local newTarget = templateTarget:Clone();
			self.TargetGui = newTarget;
			
			Npc.Garbage:Tag(newTarget);
			
			newTarget.Parent = targetPart;
			newTarget.Adornee = targetPart;
			CollectionService:AddTag(newTarget, "WeakPoints");
			newTarget.Destroying:Connect(function()
				self.TargetGui = nil;
			end)
			
		elseif self.TargetGui and self.TargetGui.Adornee == hitObject then
			self.TargetGui:Destroy();
			self.TargetGui = nil;
			
			targetHitFunc();
			
		end
	end
end

return Component;