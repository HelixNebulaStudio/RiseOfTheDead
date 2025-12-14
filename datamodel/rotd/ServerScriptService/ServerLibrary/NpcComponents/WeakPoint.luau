local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Component = {};
Component.ClassName = "NpcComponent";
Component.__index = Component;

function Component.onRequire()
	templateTarget = game.ServerStorage.Prefabs:WaitForChild("WeakpointTarget");
end

function Component.new(npcClass: NpcClass)
	local self = {
		NpcClass = npcClass
	};
	
	setmetatable(self, Component);
	return self;
end

function Component:__call(hitObject, targetHitFunc)
	local npcClass = self.NpcClass;

	local healthComp: HealthComp = npcClass.HealthComp;
	if healthComp.IsDead then return end;
	
	if npcClass.WeakPointHidden then return end;

	if self.WeakPointTarget == nil and math.random(1, 3) == 1 then
		npcClass.Garbage:Loop(function(index, trash)
			if typeof(trash) == "Instance" and trash.Name == "WeakpointTarget" then
				game.Debris:addItem(trash, 0);
			end
		end)
		self.WeakPointTarget = nil;
		
		local prefabBodyParts = npcClass.Prefab:GetChildren();
		local count = 0;
		
		local targetPart = nil;
		repeat
			count= count+1;
			targetPart = prefabBodyParts[math.random(1, #prefabBodyParts)];
			if count > #prefabBodyParts then
				targetPart = nil;
				break;
			end
		until targetPart:IsA("BasePart") and targetPart.AssemblyRootPart == npcClass.RootPart
			and targetPart.Name ~= "HumanoidRootPart"
			and (targetPart.Size.X >= 0.5 and targetPart.Size.Y >= 0.5 and targetPart.Size.Z >= 0.5);
		
		if targetPart == nil then return end;
		
		local newTarget = templateTarget:Clone();
		self.WeakPointTarget = newTarget;
		
		newTarget.Adornee = targetPart;
		newTarget.Parent = targetPart;

		npcClass.Garbage:Tag(newTarget);

		newTarget:AddTag("WeakPoints");

		newTarget.Destroying:Connect(function()
			self.WeakPointTarget = nil;
		end)
		
	elseif self.WeakPointTarget and self.WeakPointTarget.Adornee == hitObject then
		self.WeakPointTarget:Destroy();
		self.WeakPointTarget = nil;
		
		targetHitFunc();
	end
end

return Component;