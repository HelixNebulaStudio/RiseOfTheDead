local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local HumanModule = game.ServerScriptService.ServerLibrary.Entity.Npc.Human;
--== Modules
local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

local remotes = game.ReplicatedStorage.Remotes;
local remoteOnDoorEnter = remotes.Interactable.OnDoorEnter;

return function(npc, spawnPoint)
	local self = modNpcComponent{
		Name = npc.Name;
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Humanoid = npc:FindFirstChildWhichIsA("Humanoid");
		RootPart = npc.PrimaryPart;
		
		Properties = {
			WalkSpeed = {Min=5; Max=5};
		};
	};
	
	--== Components;
	self:AddComponent("Follow");
	self:AddComponent("Movement");
	self:AddComponent("Wield");
	self:AddComponent("IsInVision");
	self:AddComponent(HumanModule.OnHealthChanged);
	self:AddComponent(HumanModule.Chat);
	
	--== Initialize;
	function self.Initialize()
		if self.Prefab:FindFirstChild("Interactable") then
			self.Prefab.Interactable.Parent = script;
		end
		self.Humanoid.WalkSpeed = 25;
		self.Humanoid.JumpPower = 60;
		self.Humanoid.MaxHealth = 500;
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		
		self.Chat(self.Owner, "I am at your service!");
		
		local weapons = {"mp7"; "m4a4"; "xm1014"; "ak47";}
		self.Wield.Equip(weapons[math.random(1, #weapons)]);
		
		repeat until not self.Update();
	end
	
	--== NPC Logic;
	function self.SwitchWeapon(name)
		self.Wield.Unequip();
		if name ~= "None" then
			wait(1);
			self.Wield.Equip(name or "p250");
			self.Wield.SetSkin({
				Textures={
					["Handle"]=10;
				};
			});
		end
	end
	
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
		if self.Owner ~= nil then
			local character = self.Owner.Character;
			local rootPart = character and character:FindFirstChild("HumanoidRootPart") or nil;
			if rootPart then
				local distance = self.Owner:DistanceFromCharacter(self.RootPart.Position);
				if distance >= 64 then
					self.RootPart.CFrame = rootPart.CFrame;
				elseif distance >= 16 then
					self.Humanoid.WalkSpeed = 25;
				else
					self.Humanoid.WalkSpeed = 10;
				end
				self.Follow(rootPart, 10);
			end
			
			local enemyFound = false;
			for a=1, #modNpc.NpcModules do
				if modNpc.NpcModules[a] and modNpc.NpcModules[a].Module.Humanoid and modNpc.NpcModules[a].Module.Humanoid.Health > 0 and modNpc.NpcModules[a].Module.Target == character then
					local EnemyModule = modNpc.NpcModules[a].Module;
					if EnemyModule.RootPart and self.IsInVision(EnemyModule.RootPart) then
						self.Wield.SetEnemyHumanoid(EnemyModule.Humanoid);

						pcall(function()
							self.Wield.ToolModule.Configurations.MinBaseDamage = EnemyModule.Humanoid.MaxHealth * math.max(1/self.Wield.ToolModule.Configurations.AmmoLimit, 0.1);
						end);
						
						self.Movement:Face(EnemyModule.RootPart.Position);
						self.Wield.PrimaryFireRequest();
						enemyFound = true;
					end
					break;
				end
			end
			if not enemyFound then self.Wield.ReloadRequest() end;
		end
		wait(1);
		return true;
	end
	
	--== Connections;
	remoteOnDoorEnter.Event:Connect(function(player, interactData)
		if self.Owner == player and interactData.Object then
			if interactData.Object then
				self.Follow();
				self.RootPart.CFrame = CFrame.new(interactData.Object.Destination.WorldPosition + Vector3.new(0, 2.35, 0))
									 * CFrame.Angles(0, math.rad(interactData.Object.Destination.WorldOrientation.Y-90), 0);
			end
		end
	end)
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	
return self end