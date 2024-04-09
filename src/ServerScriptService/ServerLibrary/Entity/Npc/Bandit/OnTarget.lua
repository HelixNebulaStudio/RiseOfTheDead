local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local random = Random.new();

local targetMarkerTemplate = script:WaitForChild("TargetCheck");

local Enemy = {};

function Enemy.new(self)
	self.Enemies = {};
	
	self.OnTargetPickRandom = function()
		if #self.Enemies <= 0 then return nil end;
		
		local pick;
		
		for a=1, 5 do
			pick = self.Enemies[math.random(1, #self.Enemies)];
			if pick.Ignore ~= true and pick.Humanoid and pick.Humanoid:IsDescendantOf(workspace) and pick.Humanoid.Health > 0 then
				return pick;
			end
		end
		
		return nil;
	end
	
	self.NextTarget = function()
		if #self.Enemies <= 0 then self.Enemy = nil; return end;
		local enemyFound = false;
		
		local function remove(index)
			if self.ForgetEnemies ~= false then
				table.remove(self.Enemies, index);
			end
		end
		
		for a=#self.Enemies, 1, -1 do
			if self.Enemies[a].Ignore ~= true then
				if self.Enemies[a].Humanoid and self.Enemies[a].Humanoid:IsDescendantOf(workspace) and self.Enemies[a].Humanoid.Health > 0 then
					if self.Enemies[a].Distance > (self.Properties.TargetableDistance or 50) then
						remove(a);
					end
				else
					remove(a);
				end
			end
		end
		
		table.sort(self.Enemies, function(a,b) return (a and a.Distance or 999) > (b and b.Distance or 999); end);
		
		for a=#self.Enemies, 1, -1 do
			if self.Enemies[a] then
				self.Enemy = self.Enemies[a];
				self.ThreatSense();
				enemyFound = true;
				break;
			end
		end
		
		if not enemyFound then self.Enemy = nil; end;
		if self.Logic then
			self.Logic:SetState("Aggro");
		end;
	end
	
	local function shuffleArray(array)
		local n=#array
		for i=1,n-1 do
			local l= random:NextInteger(i,n)
			array[i],array[l]=array[l],array[i]
		end
	end
		
	return function(characters, distances, recursive)
		if self.IsDead then return end;
		if characters == nil then return end;
		
		if type(characters) ~= "table" then characters = {characters}; end
		if type(distances) ~= "table" then distances = {distances}; end
		
		for a=1, #characters do
			if self.Humanoid.RootPart == nil then return end;
			local character = characters[a];
			local distance = distances[a];
			local player;
			
			if character.ClassName == "NpcModule" then character = character.Prefab; end;
			if character:IsA("Player") then player = character; character = character.Character; end;
			if character then
				local humanoid = character:FindFirstChildWhichIsA("Humanoid");
				
				if humanoid and humanoid:IsDescendantOf(workspace) and humanoid.Health > 0 then
					if distance == nil then
						if player then
							distance = player:DistanceFromCharacter(self.Humanoid.RootPart.CFrame.p);
						else
							distance = (self.Humanoid.RootPart.CFrame.p - humanoid.RootPart.CFrame.p).Magnitude
						end
					end
					
					local exist = false;
					for b=1, #self.Enemies do
						if self.Enemies[b] and self.Enemies[b].Character == character then
							exist = true;
							self.Enemies[b].Distance = distance;
							break;
						end
					end
					
					if not exist then
						local npcStatus = humanoid.Parent:FindFirstChild("NpcStatus") and require(humanoid.Parent.NpcStatus) or nil;
						local npcModule = npcStatus and npcStatus:GetModule() or nil;
						table.insert(self.Enemies, {Character=character; Humanoid=humanoid; Distance=distance; DamageDealt=0; NpcModule=npcModule;});
					end
					
					if self.Enemy == nil then self.NextTarget(); end
				end
			end
		end
		
		shuffleArray(self.Enemies);
		
		--==
		if recursive == true then return end;
		
		if self.FriendEntityIds then
			for a=1, #self.FriendEntityIds do
				local entityId = self.FriendEntityIds[a];
				if self.Id == entityId then continue end;
				
				local npcModule = self.NpcService.Get(entityId);
				if npcModule and npcModule.OnTarget then
					task.delay(0.5, function()
						npcModule.OnTarget(characters, distances, true);
					end)
				end
			end
		end
	end
end

return Enemy;