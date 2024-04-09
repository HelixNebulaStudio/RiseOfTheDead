local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Vars;
local RunService = game:GetService("RunService");
local character = script.Parent;

local GearAttachments = {
	Attached={};
};
--== Script;

function GearAttachments:RefreshAttachments(prefab)
	if self.Attached[prefab] == nil then Debugger:Warn("Missing prefab (",prefab,") attachment data"); return end
	table.sort(self.Attached[prefab], function(A, B) return A.Priority > B.Priority; end)
	
	local canQuery = true;
	for a=1, #self.Attached[prefab] do
		local attachmentData = self.Attached[prefab][a];
		if attachmentData.Motor then
			if a == 1 then
				attachmentData.Motor.Part1 = prefab.PrimaryPart;
				canQuery = attachmentData.Motor:GetAttribute("CanQuery") ~= false;
				
			else
				attachmentData.Motor.Part1 = nil;
				
			end
		end
	end
	
	for _, obj in pairs(prefab:GetDescendants()) do
		if not obj:IsA("BasePart") then continue end;
		obj.CanQuery = canQuery;
	end
end

function GearAttachments:AttachMotor(prefab, motor, bodyPart, priority)
	if bodyPart == nil then Debugger:Warn("Missing bodypart (",prefab,")"); return end
	if prefab.PrimaryPart == nil then Debugger:Warn("Prefab missing primary part (",prefab,")"); return end;
	if self.Attached[prefab] == nil then self.Attached[prefab] = {} end;
	
	motor.Parent, motor.Part1, motor.Part0 = bodyPart, prefab.PrimaryPart, bodyPart;
	
	table.insert(self.Attached[prefab], {Motor=motor; Priority=priority;});
	self:RefreshAttachments(prefab);
end

function GearAttachments:CreateAttachmentMotor(attachment)
	if attachment == nil then return end;
	local bodyPart = attachment.Parent;
	local motor = Instance.new("Motor6D");
	motor.C1 = attachment.CFrame:Inverse();
	--if RunService:IsStudio() then
	--	attachment:GetPropertyChangedSignal("CFrame"):Connect(function()
	--		motor.C1 = attachment.CFrame:Inverse();
	--	end)
	--end
	
	return motor;	
end

function GearAttachments:Detach(prefab, motorName)
	if self.Attached[prefab] == nil then Debugger:Warn("Missing prefab (",prefab,") attachment data"); return end
	
	for k, attachmentData in pairs(self.Attached[prefab]) do
		if attachmentData.Motor.Name == motorName then
			table.remove(self.Attached[prefab], k);
		end
	end 
	self:RefreshAttachments(prefab);
end

function GearAttachments:DestroyAttachments(prefab)
	self.Attached[prefab] = nil;
end

function GearAttachments:GetAttachedPrefab(name)
	for prefab, attachmentData in pairs(self.Attached) do
		if prefab.Name ~= name then continue end;
		if not workspace:IsAncestorOf(prefab) then 
			self:DestroyAttachments(prefab);
			continue 
		end;
		
		return prefab;
	end
end

return GearAttachments;