local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

--==
local TouchHandler = {};
TouchHandler.ScanTypes = {
	Box=1;
	Sphere=2;
	Part=3;
}

TouchHandler.__index = TouchHandler;
TouchHandler.ScanType = 1;
TouchHandler.List = {};
TouchHandler.TargetableEntities = modConfigurations.TargetableEntities;

function TouchHandler.new(id, rate, loopRate)
	id = "TouchHandler_"..id;
	if TouchHandler.List[id] then return TouchHandler.List[id]; end;
	
	local self = {
		Id = id;
		Loop = false;
		Victims = {};
		Rate = rate or 1;
	};
	
	local overlapParam = OverlapParams.new();
	overlapParam.MaxParts = 16;
	overlapParam.FilterType = Enum.RaycastFilterType.Include;
	self.OverlapParams = overlapParam;
	
	TouchHandler.List[id] = self;
	setmetatable(self, TouchHandler);
	
	CollectionService:GetInstanceAddedSignal(id):Connect(function()
		if self.Loop then return end;
		self.Loop = true;
		
		while self.Loop do
			overlapParam.MaxParts = self.MaxParts or 16;
			if self.WhitelistFunc then
				overlapParam.FilterDescendantsInstances = self:WhitelistFunc();
				
			else
				local whitelist = {workspace.Entity; workspace.Interactables}; --workspace.Environment; 
				for _, player in pairs(game.Players:GetPlayers()) do
					if player and player.Character then
						table.insert(whitelist, player.Character);
					end
				end
				
				overlapParam.FilterDescendantsInstances = whitelist;
			end
			
			
			local baseParts = CollectionService:GetTagged(self.Id);
			
			if self.Debug then
				Debugger:Log("Debugging TouchHandler(",self.Id,") parts#", #baseParts);
			end
			
			for a=#baseParts, 1, -1 do
				local colliderPart = baseParts[a];
				if colliderPart == nil then continue end;
				
				local parts = {};
				
				if self.ScanType == TouchHandler.ScanTypes.Box then
					parts = workspace:GetPartBoundsInBox(colliderPart.CFrame, colliderPart.Size, overlapParam);
				elseif self.ScanType == TouchHandler.ScanTypes.Sphere then
					local radius = (colliderPart.Size.X/2)*0.9;
					parts = workspace:GetPartBoundsInRadius(colliderPart.Position, radius, overlapParam);
				elseif self.ScanType == TouchHandler.ScanTypes.Part then
					parts = workspace:GetPartsInPart(colliderPart, overlapParam);
				end
				
				
				if self.Debug then
					Debugger:Log(colliderPart, "Touching parts", parts);
				end
				
				for b=1, #parts do
					self:HandleTouch(colliderPart, parts[b]);
				end
				if #parts > 0 then
					task.wait();
				end
				
				if colliderPart:GetAttribute("Debug") == true then
					Debugger:Warn("Debug touch", #parts);
				end
			end
			task.wait(loopRate or self.Rate);
			
			for k, v in pairs(self.Victims) do
				if k and (workspace:IsAncestorOf(k) or game.Players:IsAncestorOf(k)) then
				else
					self.Victims[k] = nil;
				end
			end
		end
	end)
	 
	CollectionService:GetInstanceRemovedSignal(id):Connect(function()
		local objs = CollectionService:GetTagged(self.Id);
		if #objs  <= 0 then
			self.Loop = false;
		end
	end)
	
	return self;
end

function TouchHandler.get(id)
	id = "TouchHandler_"..id;
	return TouchHandler.List[id];
end

function TouchHandler:Destroy()
	if TouchHandler.List[self.Id] then
		TouchHandler.List[self.Id] = nil;
	end
end

function TouchHandler:HandleTouch(basePart, touchPart)
	local humanoid = touchPart.Parent and touchPart.Parent:FindFirstChildOfClass("Humanoid");
	local player = humanoid and game.Players:GetPlayerFromCharacter(humanoid.Parent);
	
	if player and self.OnPlayerTouch then
		if self.Victims[player] == nil or tick()-self.Victims[player] >= self.Rate then
			self.Victims[player] = tick();
			self:OnPlayerTouch(player, basePart, touchPart);
		end
		
	elseif humanoid and self.OnHumanoidTouch then
		if self.Victims[humanoid] == nil or tick()-self.Victims[humanoid] >= self.Rate then
			self.Victims[humanoid] = tick();
			self:OnHumanoidTouch(humanoid, basePart, touchPart);
		end
		
	elseif self.OnPartTouch then
		if self.Victims[touchPart] == nil or tick()-self.Victims[touchPart] >= self.Rate then
			self.Victims[touchPart] = tick();
			self:OnPartTouch(basePart, touchPart);
		end
		
	end
end

function TouchHandler:AddObject(obj)
	if obj and not obj:IsA("BasePart") then return end;
	if CollectionService:HasTag(obj, self.Id) then return end;
	CollectionService:AddTag(obj, self.Id);

	obj.Touched:Connect(function(part)
		if self.IgnoreTouch == true then return end;
		self:HandleTouch(obj, part);
	end)
	
	obj.CollisionGroup = "Entities";
	
	for k, t in pairs(self.Victims) do
		if tick()-t >= self.Rate then
			self.Victims[k] = nil;
		end
	end
end

function TouchHandler:RemoveObject(obj)
	if obj and not obj:IsA("BasePart") then return end;
	CollectionService:RemoveTag(obj, self.Id);
end

return TouchHandler;