local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

local Zombie = {};

function Zombie.new(self)
	self.Enemies = {};
	self.SearchingForTarget = false;
	self.AutoSearch = false;

	function self.GetTargetDistance()
		if self.Target == nil then return nil; end;

		local distance = (self.RootPart.Position - self.Target:GetPivot().Position).Magnitude;
		return distance;
	end
	
	if self.InfTargeting == true or modConfigurations.InfTargeting then

		self.NextTarget = function()
			for a=#self.Enemies, 1, -1  do
				local enemy = self.Enemies[a]
				if enemy.Character and workspace:IsAncestorOf(enemy.Character) then
					continue;
				end
				if enemy.Humanoid and enemy.Humanoid.Health > 0 then
					continue;
				end
				if enemy.Character and enemy.Character:FindFirstChild("NpcStatus") then
					local npcModule = require(enemy.Character.NpcStatus):GetModule();
					if npcModule.IsDead ~= true then
						continue;
					end
				end
				
				table.remove(self.Enemies, a);
			end
			
			if #self.Enemies <= 0 then self.Target = nil; return end;
			table.sort(self.Enemies, function(a,b) return (a and a.Distance or 0) < (b and b.Distance or 0); end);
			
			self.Target = self.Enemies[1].Character;
			self.Enemy = self.Enemies[1];
			
			self.ThreatSense();

			if self.Logic then self.Logic:SetState("Aggro"); end;
		end
		
		task.spawn(function()
			while not self.IsDead do
				local players = game.Players:GetPlayers();
				for _, player in pairs(players) do
					
					local character = player.Character;
					local humanoid = character and character:FindFirstChild("Humanoid");
					local rootPart = character and character:FindFirstChild("HumanoidRootPart");
					
					if character and humanoid and rootPart and humanoid.Health > 0 then
						local dist = (self.RootPart.Position - rootPart.Position).Magnitude;
						
						local exist = false;
						for a=1, #self.Enemies do
							if self.Enemies[a].Character == character then
								self.Enemies[a].Distance = dist;
								exist = true;
								break;
							end
						end

						if not exist then
							table.insert(self.Enemies, {
								Player=game.Players:GetPlayerFromCharacter(character);
								Character=character;
								RootPart=rootPart;
								Humanoid=humanoid;
								Distance=dist;
								DamageDealt=0;
							});
						end
					end
				end
				
				self.NextTarget();
				task.wait(1);
				if self.IsDead then return end;
				
				if math.random(1, 3) == 1 then
					self.Think:Fire();
				end
			end
		end)
		
		return function(prefabs, distances)
			if self.IsDead then return end;
			if prefabs == nil then return end;

			if type(prefabs) ~= "table" then prefabs = {prefabs}; end
			if type(distances) ~= "table" then distances = {distances}; end
			
			for a=1, #prefabs do
				if self.RootPart == nil then return end;

				local prefab = prefabs[a];
				if prefab then
					local humanoid = prefab:FindFirstChildWhichIsA("Humanoid");
					local rootPart = prefab:FindFirstChild("HumanoidRootPart");

					if rootPart == nil then continue end;

					if humanoid and humanoid:IsDescendantOf(workspace) and humanoid.Health > 0 then
						if humanoid.Name == "Structure" then
							local distance = distances[a] or (self.RootPart.CFrame.p - rootPart.CFrame.p).Magnitude;
							
							local exist = false;
							for b=1, #self.Enemies do
								if self.Enemies[b] and self.Enemies[b].Character == prefab then
									exist = true;
									self.Enemies[b].Distance = distance;
									break;
								end
							end
							
							if not exist then
								local dmgDealt = 0;
								if humanoid.Name == "Structure" then dmgDealt = math.huge; end;
								table.insert(self.Enemies, {Character=prefab; RootPart=rootPart; Humanoid=humanoid; Distance=distance; DamageDealt=dmgDealt});
							end
						end
					end
				end
			end

			self.Think:Fire();
		end
		
	else
		self.NextTarget = function()
			if #self.Enemies <= 0 then self.Target = nil; return end;
			table.sort(self.Enemies, function(a,b) return (a and a.DamageDealt or 0) < (b and b.DamageDealt or 0); end);
			local targetFound = false;

			local function remove(index)
				if self.ForgetEnemies ~= false and self.Enemies then
					table.remove(self.Enemies, index);
				end
			end

			for a=#self.Enemies, 1, -1 do
				if self.Enemies[a] and self.Enemies[a].Ignore ~= true then
					if self.Enemies[a].Character and self.Enemies[a].Character:IsDescendantOf(workspace)
						and self.Enemies[a].Humanoid and self.Enemies[a].Humanoid.Health > 0
						and self.Enemies[a].Humanoid.RootPart ~= nil and self.RootPart.Parent ~= nil then

						self.Enemies[a].Distance = (self.Enemies[a].Humanoid.RootPart.CFrame.p-self.RootPart.CFrame.p).Magnitude
						if self.Enemies[a].Distance <= (self.Properties.TargetableDistance or 50) then
							
							if self.Enemies and self.Enemies[a] then
								self.Target = self.Enemies[a].Character;
								self.Enemy = self.Enemies[a];

								self.ThreatSense();
								targetFound = true;
								break;
							end
						else
							remove(a);
						end
					else
						remove(a);
					end
				end
			end
			if not targetFound then self.Target = nil; end;
			if self.Logic then
				self.Logic:SetState("Aggro");
			end;
		end

		local function shuffleArray(array)
			if array == nil then return end;
			local n=#array
			for i=1,n-1 do
				local l= math.random(i,n);
				array[i],array[l]=array[l],array[i]
			end
		end

		return function(characters, distances)
			if self.IsDead then return end;
			
			if characters then 
				if type(characters) ~= "table" then characters = {characters}; end
				if type(distances) ~= "table" then distances = {distances}; end
				
				for a=1, #characters do
					if self.RootPart == nil then return end;
					local character = characters[a];
					local distance = distances[a];
					local player;
					if character and character:IsA("Player") then player = character; character = character.Character; end;
					if character then
						
						local humanoid = character:FindFirstChildWhichIsA("Humanoid");
						local rootPart = character:FindFirstChild("HumanoidRootPart");
						
						if rootPart == nil then continue end;
						
						if humanoid and humanoid:IsDescendantOf(workspace) and humanoid.Health > 0 then
							if distance == nil then
								if player then
									distance = player:DistanceFromCharacter(self.RootPart.CFrame.p);
								else
									distance = (self.RootPart.CFrame.p - rootPart.CFrame.p).Magnitude
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
								local dmgDealt = 0;
								if humanoid.Name == "Structure" then dmgDealt = math.huge; end;
								table.insert(self.Enemies, {Character=character; RootPart=rootPart; Humanoid=humanoid; Distance=distance; DamageDealt=dmgDealt});
							end
							
							self.NextTarget();
						end
					end
				end
			end;
			
			self.Think:Fire();
			
			shuffleArray(self.Enemies);
			if self.AutoSearch then
				spawn(function()
					if self.SearchingForTarget then return end;
					self.SearchingForTarget = true;
					
					while self.NextTarget == nil and not self.IsDead do
						if #self.Enemies > 0 then self.NextTarget() end;
						wait(1);
						if self.IsDead then break; end;
					end
					
					self.SearchingForTarget = false;
				end)
			end
		end
		
	end
end

return Zombie;