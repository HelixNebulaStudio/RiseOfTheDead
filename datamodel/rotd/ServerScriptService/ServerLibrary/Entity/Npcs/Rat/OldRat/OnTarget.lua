local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modPlayers = shared.require(game.ReplicatedStorage.Library.Players);
local random = Random.new();

local Enemy = {};

function Enemy.new(self)
	self.Enemies = {};
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
		
	return function(characters, distances)
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
						local npcInstance = humanoid.Parent:FindFirstChild("NpcClassInstance") and shared.require(humanoid.Parent.NpcClassInstance) or nil;
						local npcClass = npcInstance and npcInstance.NpcClass or nil;
						table.insert(self.Enemies, {
							Character=character; 
							Humanoid=humanoid; 
							Distance=distance; 
							DamageDealt=0; 
							NpcModule=npcClass;
						});
					end
					
					if self.Enemy == nil then self.NextTarget(); end
				end
			end
		end
		
		shuffleArray(self.Enemies);
	end
end

return Enemy;