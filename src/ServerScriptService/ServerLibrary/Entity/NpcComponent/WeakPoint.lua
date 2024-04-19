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
		if Npc.WeakPointHidden then return end;

		if self.WeakPointTarget == nil and math.random(1, 3) == 1 then
			Npc.Garbage:Loop(function(index, trash)
				if typeof(trash) == "Instance" and trash.Name == "WeakpointTarget" then
					game.Debris:addItem(trash, 0);
				end
			end)
			self.WeakPointTarget = nil;
			
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
			self.WeakPointTarget = newTarget;
			
			newTarget.Adornee = targetPart;
			newTarget.Parent = targetPart;

			Npc.Garbage:Tag(newTarget);
			CollectionService:AddTag(newTarget, "WeakPoints");
			newTarget.Destroying:Connect(function()
				self.WeakPointTarget = nil;
			end)
			
		elseif self.WeakPointTarget and self.WeakPointTarget.Adornee == hitObject then
			self.WeakPointTarget:Destroy();
			self.WeakPointTarget = nil;
			
			targetHitFunc();
			
		end
	end
end

return Component;