local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();



--== Script;
local Component = {};
Component.__index = Component;

function Component.new(Npc)
	local self = {};
	self.ScanActive = true;
	self.ViewDistance = 5;
	
	task.spawn(function()
		while not Npc.IsDead do
			if not self.ScanActive then task.wait(0.1); continue end;
			if Npc.IsDead then return end;
			
			if Npc.RootPart == nil then return end;
			
			local eyeRay = Ray.new(Npc.RootPart.Position+Vector3.new(0,2,0), Npc.RootPart.CFrame.LookVector*self.ViewDistance);
			local hitPart, eyePoint = workspace:FindPartOnRayWithWhitelist(eyeRay, {workspace.Environment; workspace.Terrain; workspace.Interactables}, true);
			
			if hitPart then
				
				local model = hitPart.Parent;
				while model:GetAttribute("DestructibleParent") do model = model.Parent; end
				while model:GetAttribute("InteractableParent") do model = model.Parent; end
				
				local destructibleModule = model:FindFirstChild("Destructible");
				local doorModule = model:FindFirstChild("Door");
				
				if doorModule and doorModule:IsA("ModuleScript") then
					local doorObject = require(doorModule);
					
					if doorObject.Public and not doorObject.Open then
						if Npc.PlayAnimation == nil then
							error("Npc "..Npc.Name.." missing PlayAnimation.");
						end
						Npc.PlayAnimation("OpenDoor");
						doorObject:Toggle(true, Npc.RootPart.CFrame);
						
						if Npc.Movement then
							Npc.Movement:Pause(0.5);
						end
						task.spawn(function()
							local dist;
							repeat 
								dist = (Npc.RootPart.Position-hitPart.Position).Magnitude;
								task.wait(1);
							until dist >= 6 or not doorObject.Open;
							if doorObject.Open then
								doorObject:Toggle(false);
							end
						end)
					end
				end
			end
			
			task.wait(0.5);
		end
	end)
	
	setmetatable(self, Component);
	return self;
end

return Component;