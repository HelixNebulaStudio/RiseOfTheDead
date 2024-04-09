local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();
--==
local Handler = {};
Handler.__index = Handler;

local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modWeapons = require(game.ReplicatedStorage.Library.Weapons);
local modProjectile = require(game.ReplicatedStorage.Library.Projectile);
local modAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local modTagging = require(game.ServerScriptService.ServerLibrary.Tagging);
local modWeaponsMechanics = require(game.ReplicatedStorage.Library.WeaponsMechanics);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

local prefabsItems = game.ReplicatedStorage.Prefabs.Items;

local remotePrimaryFire = modRemotesManager:Get("PrimaryFire");
--== Script;

function Handler.new(npc, wield, toolItemId)
	local self = {
		Npc = npc;
		Wield = wield;
		ItemId = toolItemId;
		Binds = {};
	};
	
	setmetatable(self, Handler);
	return self;
end

function Handler:Equip()
	local weaponConfig = modWeapons[self.ItemId];
	
	local toolModule = self.Wield.ToolModule or weaponConfig.NewToolLib();
	self.Wield.ToolModule = toolModule;
	self.Wield.ToolModule.Library = weaponConfig;
	self.Wield.ToolModule.LoadedAnims = {};
	self.Wield.ToolModule.Configurations.InfiniteAmmo = 1;
	
	local animations = toolModule.Animations;
	
	self.AnimGroup = self.Npc.AnimationController:NewGroup(self.ItemId);
	
	if self.Wield.ToolModule.Configurations.BulletMode == modAttributes.BulletModes.Projectile then
		modProjectile.Load(self.Wield.ToolModule.Configurations.ProjectileId);
	end
	
	local destroyed = false;
	local function OnWeaponDestroyed()
		if destroyed then return end;
		destroyed = true;
	end
	
	local weldCount = 0;
	for weldName, prefabName in pairs(weaponConfig.Welds) do
		weldCount = weldCount +1;
	end
	
	local mainWeaponModel;
	
	for weldName, prefabName in pairs(weaponConfig.Welds) do
		if prefabName then
			local prefabTool = prefabsItems:FindFirstChild(prefabName);
			if prefabTool == nil then Debugger:Print(prefabName.." does not exist!"); return; end;

			local baseToolGrip;
			if prefabTool:FindFirstChild("WieldConfig") and prefabTool.WieldConfig:FindFirstChild(weldName) then
				baseToolGrip = prefabTool.WieldConfig[weldName]:Clone();

			elseif weaponConfig.Module:FindFirstChild(weldName) then
				baseToolGrip = weaponConfig.Module[weldName]:Clone();

			end
			
			local cloneTool = prefabTool:Clone();
			local handle = cloneTool:WaitForChild("Handle");
			cloneTool.Parent = self.Npc.Prefab;
			cloneTool:SetAttribute("InteractableParent", true);
			
			handle:SetNetworkOwner(nil);
			
			local parentChangeSignal;
			parentChangeSignal = cloneTool:GetPropertyChangedSignal("Parent"):Connect(function()
				if cloneTool.Parent == game.Debris then
					destroyed = true;
					
					self.AnimGroup:Destroy();
					
					task.wait();
					cloneTool:Destroy();
					if self.Wield.Instances ~= nil then
						for k, obj in pairs(self.Wield.Instances) do
							game.Debris:AddItem(obj, 0);
						end
					end

					self.Npc.JointRotations.WaistRot:Remove("tool");
					self.Npc.JointRotations.NeckRot:Remove("tool");
					
					self.Wield.Instances = {};
					self.Wield.ToolModule = nil;
					
				elseif cloneTool.Parent == nil or not cloneTool:IsDescendantOf(self.Npc.Prefab) then
					OnWeaponDestroyed();
					
				end
				if destroyed then
					parentChangeSignal:Disconnect();
				end
			end);
			
			local function createGrip(bodyPartName, cloneSyntax)
				local bodyPart = self.Npc.Prefab:FindFirstChild(bodyPartName);
				if weldCount > 1 then cloneTool.Name = cloneSyntax..prefabName; end;
				
				local toolGrip = baseToolGrip:Clone();
				toolGrip.Parent, toolGrip.Part1, toolGrip.Part0 = bodyPart, handle, bodyPart;
				
				return toolGrip;
			end
			
			if weldName == "ToolGrip" or weldName == "RightToolGrip" then
				self.Wield.Instances.RightModel = cloneTool;
				self.Wield.Instances.RightWeld = createGrip("RightHand", "Right");
				
				self.Binds.PrimaryFiringYield = Instance.new("BindableEvent");
				self.Binds.PrimaryFiringYield.Parent = cloneTool;
				self.Binds.ReloadYield = Instance.new("BindableEvent", cloneTool);
				self.Binds.ReloadYield.Parent = cloneTool;
				self.Binds.ReloadingYield = Instance.new("BindableEvent", cloneTool);
				self.Binds.ReloadingYield.Parent = cloneTool;
				
				if mainWeaponModel == nil then mainWeaponModel = cloneTool end;
				
			elseif weldName == "LeftToolGrip" then
				self.Wield.Instances.LeftModel = cloneTool;
				self.Wield.Instances.LeftWeld = createGrip("LeftHand", "Left");

				if mainWeaponModel == nil then mainWeaponModel = cloneTool end;
				
			end
		end
	end

	local wieldConfigModule = mainWeaponModel:FindFirstChild("WieldConfig");
	if wieldConfigModule then
		for k, v in pairs(require(wieldConfigModule)) do
			self.Wield.ToolModule.SetConfigurations(k, v);
		end
	end

	local toolWaistRotation = self.Wield.ToolModule.Configurations.WaistRotation or 0;
	
	self.Npc.JointRotations.WaistRot:Set("tool", toolWaistRotation, 1);
	self.Npc.JointRotations.NeckRot:Set("tool", toolWaistRotation, 1);
	
	for key, animLib in pairs(animations) do
		local animationFile = Instance.new("Animation");
		animationFile.Parent = self.Wield.Instances.RightModel;
		animationFile.AnimationId = "rbxassetid://"..(animLib.OverrideId or animLib.Id);
		
		if key == "Reload2" then
			key = "Reload";
			animationFile:SetAttribute("Chance", 0.3);
		end
		
		self.Wield.ToolModule.LoadedAnims[key] = self.AnimGroup:LoadAnimation(key, animationFile);
		local track = self.Wield.ToolModule.LoadedAnims[key].Track;
		
		if key == "Core" then
			track.Priority = Enum.AnimationPriority.Movement;
			
		elseif key == "Load" or key == "Idle" then
			track.Priority = Enum.AnimationPriority.Action3;
			
		else
			if key == "PrimaryFire" then
				track:AdjustWeight(2, 0.01);
			elseif key == "Reload" then
				track:AdjustWeight(2, 0.05);
			end
			track.Priority = Enum.AnimationPriority.Action2;
		end
		

		track:GetMarkerReachedSignal("PlaySound"):Connect(function(paramString)
			modAudio.Play(paramString, mainWeaponModel.PrimaryPart, false);
		end)
		
		track:GetMarkerReachedSignal("SetTransparency"):Connect(function(paramString)
			local args = string.split(tostring(paramString), ";");

			local toolModel = args[1] == "Left" and self.Wield.Instances.LeftModel or self.Wield.Instances.RightModel;
			local partObj = args[2] and toolModel and toolModel:FindFirstChild(args[2]);
			local transparencyValue = partObj and args[3];

			if transparencyValue then
				local function setTransparency(obj)
					if obj:IsA("BasePart") then
						obj.Transparency = obj:GetAttribute("CustomTransparency") or transparencyValue;
						for _, child in pairs(obj:GetChildren()) do
							if child:IsA("Decal") or child:IsA("Texture") then
								child.Transparency = transparencyValue;
							end
						end

					elseif obj:IsA("Model") then
						for _, child in pairs(obj:GetChildren()) do
							setTransparency(child);
						end
					end
				end

				setTransparency(partObj);
			end
		end)
	end

	self.AnimGroup:Play("Core");
	self:PlayLoad();

	local audio = self.Wield.ToolModule.Audio;
	if audio then
		modAudio.Play(audio.Load.Id, self.Npc.RootPart);
	end
	
	delay(self.Wield.ToolModule.Configurations.EquipLoadTime+0.5, function()
		self.Wield.AllowShooting = true;
		if self.Wield.ToolModule then self.Wield.ToolModule.Properties.CanPrimaryFire = true; end
	end);
end

function Handler:PlayLoad()
	if self.AnimGroup:HasAnim("Load") then
		self.AnimGroup:Play("Load");
		
		local audio = self.Wield.ToolModule.Audio;
		modAudio.Play(audio.Load.Id, self.Npc.RootPart);
	end
end

function Handler:ToggleIdle(v)
	if self.AnimGroup:HasAnim("Idle") then
		
		if v ~= false then
			self.AnimGroup:Play("Idle");
			
			self.Npc.JointRotations.WaistRot:Set("toolIdle", 0, 2);
			self.Npc.JointRotations.NeckRot:Set("toolIdle", 0, 2);

		else
			self.AnimGroup:Stop("Idle");
			
			self.Npc.JointRotations.WaistRot:Remove("toolIdle");
			self.Npc.JointRotations.NeckRot:Remove("toolIdle");
			
		end
	end
	
end

function Handler:Unequip()
	self.Wield.AllowShooting = false;
	self.Wield.Controls.Mouse1Down = false; 
	if next(self.Wield.Instances) ~= nil then
		for key, obj in next, self.Wield.Instances do
			if obj.Parent ~= nil then obj.Parent = game.Debris; end
		end
	end
	
	self.AnimGroup:Destroy();
	
	self.Wield.ToolModule = nil;
	self.Wield.AllowShooting = true;
end

function Handler:PrimaryFire(direction)
	self.Wield.Controls.Mouse1Down = true;
	local configurations, properties, audio = self.Wield.ToolModule.Configurations, self.Wield.ToolModule.Properties, self.Wield.ToolModule.Audio;
	if properties.Reloading then self.Binds.ReloadingYield.Event:Wait(); end;
	
	local function UpdateDirection()
		if self.Wield.EnemyHumanoid and self.Wield.EnemyHumanoid:IsDescendantOf(workspace) and self.Npc.Head then
			local pick = random:NextInteger(1,100)
			local basePart = pick <= 10 and self.Wield.EnemyHumanoid.RootPart
							or pick <= 85 and self.Wield.EnemyHumanoid.Parent:FindFirstChild("UpperTorso")
							or self.Wield.EnemyHumanoid.Parent:FindFirstChild("Head")
							or self.Wield.EnemyHumanoid.Parent:FindFirstChildWhichIsA("BasePart");
			if basePart then
				direction = (basePart.Position-self.Npc.Head.Position).Unit;
			end
		end
	end
	UpdateDirection();
	if direction == nil or (self.Wield.EnemyHumanoid and self.Wield.EnemyHumanoid.Health <= 0) then return end;
	
	if self.Npc.Humanoid.Health > 0 and properties.CanPrimaryFire then
		properties.CanPrimaryFire = false;
		self.AnimGroup:Stop("Inspect");
		
		if properties.Ammo > 0 then
			self.AnimGroup:Stop("Empty");
			if configurations.TriggerMode == modAttributes.TriggerModes.Semi then
				UpdateDirection();
				self:FireWeapon(direction);
				
			elseif configurations.TriggerMode == modAttributes.TriggerModes.Automatic or configurations.TriggerMode == modAttributes.TriggerModes.SpinUp then

				if configurations.TriggerMode == modAttributes.TriggerModes.SpinUp then
					if self.Wield.SpinFloat == nil then
						self.Wield.SpinFloat = 0;
						self.Wield.SpinStartTick = tick();
					end;
					self.Wield.IsSpinning = true;

					local function revFunc()
						while (self.Wield.SpinFloat or 0) < 1 and self.Wield.Controls.Mouse1Down do
							local tickLapsed = tick()-self.Wield.SpinStartTick;
							self.Wield.SpinFloat = math.clamp(tickLapsed/configurations.SpinUpTime, 0, 1);
							task.wait();
						end
					end

					if audio.SpinUp then modAudio.Play(audio.SpinUp.Id, self.Npc.RootPart).Volume = 2; end;
					if self.AnimGroup:HasAnim("SpinUp") then 
						self.AnimGroup:Play("SpinUp", {FadeTime=configurations.SpinUpTime;});
						self:ToggleIdle(false);
					end;

					if configurations.SpinAndFire then
						task.spawn(revFunc);
					else
						revFunc();
					end
					if self.Npc.Movement then
						self.Npc.Movement:SetWalkSpeed("hmg", 6, 5);
					end
				end
				
				if configurations.TriggerMode == modAttributes.TriggerModes.Automatic or self.Wield.SpinFloat >= 1 or configurations.SpinAndFire then
					if configurations.RapidFire then
						self.Wield.RapidFireStart = tick();
					end

					repeat
						UpdateDirection();
						self:FireWeapon(direction);
						task.wait();
					until self.Wield.EnemyHumanoid.Health <= 0 or not self.Wield.Controls.Mouse1Down;
					
					if self.Wield.Audio.PrimaryFire then
						game.Debris:AddItem(self.Wield.Audio.PrimaryFire, 0); 
						self.Wield.Audio.PrimaryFire = nil;
					end
				end

				self.Wield.SpinFloat = nil;
				if self.Npc.Movement then
					self.Npc.Movement:SetWalkSpeed("hmg", nil);
				end

				if configurations.TriggerMode == modAttributes.TriggerModes.SpinUp then
					self.AnimGroup:Stop("SpinUp", {FadeTime=configurations.SpinDownTime;});
					if audio.SpinDown then modAudio.Play(audio.SpinDown.Id, self.Npc.RootPart).Volume = 2; end;
					self.Wield.IsSpinning = nil;

				end

				if self.Wield.loopedPrimaryFire ~= nil then
					local prevPrimaryFire = self.Wield.loopedPrimaryFire;
					self.Wield.loopedPrimaryFire = nil;
					
					if configurations.PrimaryFireAudio ~= nil then
						configurations.PrimaryFireAudio(prevPrimaryFire, 2);
					else
						prevPrimaryFire:Destroy();
					end
				end
				
			end
			if properties.Ammo <= 0 and properties.MaxAmmo > 0 and not properties.Reloading then self:Reload(); end;
			
		else
			self.AnimGroup:Play("Empty");
			self:ToggleIdle(false);
			
			modAudio.Play(audio.Empty.Id, self.Npc.RootPart);
			if properties.MaxAmmo > 0 and not properties.Reloading then self:Reload(); end;
		end
		properties.CanPrimaryFire = true;
	end
end

function Handler:FireWeapon(direction)
	local configurations, properties, audio = self.Wield.ToolModule.Configurations, self.Wield.ToolModule.Properties, self.Wield.ToolModule.Audio;
	if properties.IsPrimaryFiring then return end
	properties.IsPrimaryFiring = true;
	local onShotTick = tick();
	
	if self.Wield.EnemyHumanoid and self.Wield.EnemyHumanoid.Health <= 0 then
		self.Wield.EnemyHumanoid = nil;
	end
	
	task.spawn(function()
		for k, model in pairs(self.Wield.Instances) do
			if model:IsA("Model") and model:FindFirstChild("Handle") then
				if properties.Ammo <= 0 then 
					modAudio.Play(audio.Empty.Id, model.Handle); 
					self.Wield.Controls.Mouse1Down = false; 
					return 
				end;
				if properties.Reloading then return end;
				local shotTick = tick();
				local shotData = {};
				
				properties.Ammo = properties.Ammo + (configurations.InfiniteAmmo == 2 and 0 or -1);
				if audio.PrimaryFire.Looped then
					if self.Wield.Audio.PrimaryFire == nil then
						self.Wield.Audio.PrimaryFire = modAudio.Play(audio.PrimaryFire.Id, model.Handle);
						self.Wield.Audio.PrimaryFire.Looped = true;
						self.Wield.Audio.PrimaryFire.Volume = 2;
					end
					
				else
					local primaryFireSound = modAudio.Play(audio.PrimaryFire.Id, model.Handle, false);
					if configurations.PrimaryFireAudio ~= nil then configurations.PrimaryFireAudio(primaryFireSound, 1); end
				end
				
				local multishot = type(properties.Multishot) == "table" and random:NextInteger(properties.Multishot.Min, properties.Multishot.Max) or properties.Multishot;
				
				local function spread(direction, maxSpreadAngle)
					local deflection = random:NextNumber()^2 * math.rad(maxSpreadAngle);
					local cf = CFrame.new(Vector3.new(), direction);
					cf = cf*CFrame.Angles(0, 0, random:NextNumber()*2*math.pi);
					cf = cf*CFrame.Angles(deflection, 0, 0);
					return cf.lookVector;
				end
				
				shotData.ShotOrigin = model.Handle.BulletOrigin;
				if configurations.BulletMode == modAttributes.BulletModes.Hitscan then
					shotData.TargetPoints = {};
					shotData.Victims = {};
				elseif configurations.BulletMode == modAttributes.BulletModes.Projectile then
					shotData.Projectiles = {};
				end
				
				shotData.Direction = direction;
				
				if self.Npc == nil or self.Npc.IsDead then
					self.Wield.Controls.Mouse1Down = false; 
					return;
				end
				local movingInaccuracyRatio = self.Npc.Humanoid.WalkSpeed > 0 and ((self.Npc.RootPart.Velocity.Magnitude)/self.Npc.Humanoid.WalkSpeed) or 0;
				self.Wield.ToolModule.Inaccuracy = configurations.BaseInaccuracy + movingInaccuracyRatio*configurations.MovingInaccuracyScale;
				
				for _=1, multishot do
					if self.Wield.ToolModule == nil then continue end;
					local newInaccuracy = self.Wield.ToolModule.Inaccuracy;
					if newInaccuracy == nil then return end;
					local spreadedDirection = spread(shotData.Direction, math.max(newInaccuracy, 0));
					
					if configurations.BulletMode == modAttributes.BulletModes.Hitscan then
						local function onCast(basePart, position, normal, material, index, distance)
							if basePart == nil then return end;
						
							local humanoid = basePart.Parent:FindFirstChildWhichIsA("Humanoid");
							local targetRootPart = basePart.Parent:FindFirstChild("HumanoidRootPart");
							
							if humanoid then
								if humanoid.Health > 0 then
									if targetRootPart then
										if (basePart.Name == "Head" or basePart:GetAttribute("IsHead") == true) then
											local hitSoundRoll = random:NextNumber(0,1) == 1 and "BulletHeadImpact" or "BulletHeadImpact2";
											modAudio.Play(hitSoundRoll, basePart);
										else
											local hitSoundRoll = random:NextNumber(0,1) == 1 and "BulletBodyImpact" or "BulletBodyImpact2";
											modAudio.Play(hitSoundRoll, basePart);
										end
										table.insert(shotData.Victims, {Object=((basePart.Name == "Head" or basePart:GetAttribute("IsHead") == true) and basePart or targetRootPart); Index=index;});
									end
									return basePart.Parent;
								end
							else
								if basePart.Parent:FindFirstChild("Destructible") and basePart.Parent.Destructible.ClassName == "ModuleScript" then
									table.insert(shotData.Victims, {Object=basePart; Index=index;});
								end
							end
						end
						
						local whitelist = {workspace.Environment; workspace.Terrain};
						if self.Wield.Targetable then
							if self.Wield.Targetable.Zombie then
								whitelist = CollectionService:GetTagged("Zombies");
								table.insert(whitelist, workspace.Environment);
							end
							if self.Wield.Targetable.Human then
								local humanoidList = CollectionService:GetTagged("Humans");
								for a=1, #humanoidList do
									table.insert(whitelist, humanoidList[a]);
								end
								table.insert(whitelist, workspace.Environment);
							end
								
							if self.Wield.Targetable.Bandit then
								local humanoidList = CollectionService:GetTagged("Bandits");
								for a=1, #humanoidList do
									table.insert(whitelist, humanoidList[a]);
								end
								table.insert(whitelist, workspace.Environment);
							end
								
							if self.Wield.Targetable.Cultist then
								local humanoidList = CollectionService:GetTagged("Cultists");
								for a=1, #humanoidList do
									table.insert(whitelist, humanoidList[a]);
								end
								table.insert(whitelist, workspace.Environment);
							end
							
							if self.Wield.Targetable.Rat then
								local humanoidList = CollectionService:GetTagged("Rats");
								for a=1, #humanoidList do
									table.insert(whitelist, humanoidList[a]);
								end
								table.insert(whitelist, workspace.Environment);
							end
								
							if self.Wield.Targetable.Humanoid then
								local humanoidList = CollectionService:GetTagged("PlayerCharacters");
								for a=1, #humanoidList do
									table.insert(whitelist, humanoidList[a]);
								end
								table.insert(whitelist, workspace.Environment);
							end
						end

						local bulletEnd = modWeaponsMechanics.CastHitscanRay{
							Origin = self.Npc.Head.Position;
							Direction = spreadedDirection;
							IncludeList = whitelist;
							Range = 256;
							OnCastFunc = onCast;
						};
						
						table.insert(shotData.TargetPoints, bulletEnd);
					elseif configurations.BulletMode == modAttributes.BulletModes.Projectile then

					end
				end
				if self.Wield.ToolModule then
					self.AnimGroup:Play("PrimaryFire", {FadeTime=0;});
					self:ToggleIdle(false);
				end
				
				self:ReplicateFire(shotData);
			end
		end
	end)
	
	if properties.FireRate-(tick()-onShotTick) > 0 then
		repeat
			RunService.Heartbeat:Wait();
		until (tick()-onShotTick) >= properties.FireRate;
	else
		RunService.Heartbeat:Wait();
	end
	properties.IsPrimaryFiring = false;
	self.Binds.PrimaryFiringYield:Fire();
end

function Handler:Reload()
	if self.Wield.ToolModule == nil then return end;
	
	local configurations, properties, audio = self.Wield.ToolModule.Configurations, self.Wield.ToolModule.Properties, self.Wield.ToolModule.Audio;
	if self.Wield.Instances.RightModel:FindFirstChild("Handle") == nil then return end;
	if properties.Reloading then return end;
	if configurations.InfiniteAmmo == nil and properties.MaxAmmo <= 0 then modAudio.Play(audio.Empty.Id, self.Npc.RootPart); return end;
	if properties.IsPrimaryFiring then spawn(function() self.Wield.Controls.Mouse1Down = true; end) self.Binds.PrimaryFiringYield.Event:Wait(); end;
	if properties.Ammo == configurations.AmmoLimit then return end;
	properties.Reloading = true;
	
	self.AnimGroup:Stop("Inspect");
	self.AnimGroup:Stop("Empty");
	
	if configurations.ReloadMode == modAttributes.ReloadModes.Full then
		self.AnimGroup:Play("Reload", {Length=properties.ReloadSpeed;});
		
		local reloadSound;
		if audio.Reload then
			reloadSound = modAudio.Play(audio.Reload.Id, self.Wield.Instances.RightModel.Handle);
			reloadSound.PlaybackSpeed = reloadSound.TimeLength/properties.ReloadSpeed;
		end
		
		local reloadYielded = false;
		delay(math.clamp(properties.ReloadSpeed-0.2, 0.05, 20), function() if not reloadYielded then self.Binds.ReloadYield:Fire(true); end end);
		local reloadComplete = self.Binds.ReloadYield.Event:Wait(); reloadYielded = true;
		
		self.AnimGroup:Stop("Reload");
		
		if reloadComplete and self.Wield.Instances.RightModel:IsDescendantOf(self.Npc.Prefab) then
			wait(0.2);
			local ammoNeeded = configurations.AmmoLimit - properties.Ammo;
			local newMaxAmmo = properties.MaxAmmo - ammoNeeded;
			local newAmmo = configurations.AmmoLimit;
			if newMaxAmmo < 0 then newAmmo = properties.MaxAmmo+properties.Ammo; newMaxAmmo = 0 end;
			properties.Ammo = newAmmo;
			properties.MaxAmmo = configurations.InfiniteAmmo == nil and newMaxAmmo or configurations.MaxAmmoLimit;
		end
		
	elseif configurations.ReloadMode == modAttributes.ReloadModes.Single and properties.Ammo < configurations.AmmoLimit then
		repeat
			self.AnimGroup:Play("Reload", {Length=properties.ReloadSpeed;});
			
			modAudio.Play(audio.Reload.Id, self.Wield.Instances.RightModel.Handle);
			local reloadYielded = false;
			delay(math.clamp(properties.ReloadSpeed-0.2, 0.05, 20), function() if not reloadYielded then self.Binds.ReloadYield:Fire(true); end end);
			local reloadComplete = self.Binds.ReloadYield.Event:Wait(); reloadYielded = true;
			if reloadComplete and self.Wield.Instances.RightModel and self.Wield.Instances.RightModel:IsDescendantOf(self.Npc.Prefab) and properties.MaxAmmo > 0 then
				properties.Ammo = properties.Ammo +1;
				properties.MaxAmmo = configurations.InfiniteAmmo == nil and (properties.MaxAmmo - 1) or configurations.MaxAmmoLimit;
				wait(0.2);
			end
			
			if self.Npc.IsDead then
				break;
			end
		until properties.Ammo >= configurations.AmmoLimit or properties.MaxAmmo <=0 or properties.CancelReload or self.Wield.Instances == nil or self.Wield.Instances.RightModel == nil or self.Wield.Instances.RightModel.Parent == nil;
	end
	properties.CancelReload = false;
	properties.Reloading = false;
	self.Binds.ReloadingYield:Fire();
end

function Handler:ReplicateFire(shotData)
	if self.Npc.Prefab == nil then Debugger:Warn("Character missing.") return end;
	local humanoid = self.Npc.Prefab:FindFirstChildWhichIsA("Humanoid") or nil;
	if humanoid == nil or humanoid.Health <= 0 then return end;
	local rootPart = humanoid.RootPart;
	if rootPart == nil then Debugger:Warn("Character missing RootPart.") return end;
	
	if self.Wield.ToolModule then
		local audio = self.Wield.ToolModule.Audio;
		local configurations = self.Wield.ToolModule and self.Wield.ToolModule.Configurations;
		
		local ammo = configurations.Ammo or configurations.AmmoLimit;
		if ammo > 0 then
			if configurations.BulletMode == modAttributes.BulletModes.Hitscan then

				local newDamageSource = modDamagable.NewDamageSource{
					Dealer = self.Npc.Prefab;
				};
				
				local victims, targetPoints = (shotData.Victims or {}), (shotData.TargetPoints or {});
				for a=1, #victims do
					local targetObject = victims[a].Object;
					local targetModel = targetObject and targetObject.Parent;
					if targetModel then
						local humanoid = targetModel:FindFirstChildWhichIsA("Humanoid");
						local dmgMulti = humanoid and self.Wield.Targetable[humanoid.Name];
						local damage = self.Wield.ToolModule and configurations.MinBaseDamage or configurations.BaseDamage or 20;
						local distance = nil;
						
						if configurations.DamageDropoff then
							distance = (rootPart.Position-targetObject.Position).Magnitude;
							damage = modWeaponsMechanics.DamageDropoff(self.Wield.ToolModule, damage, distance);
						end
						
						if humanoid and dmgMulti then
							modTagging.Tag(targetModel, self.Npc.Prefab, targetObject.Name == "Head" and true or nil);
							damage = damage*dmgMulti;
							
							if self.Wield.OnWieldHit then
								self.Wield.OnWieldHit(targetModel);
							end
							
							newDamageSource.Damage = damage;
							newDamageSource.DamageType = newDamageSource.DamageType;

							local dir = (targetObject.Position-rootPart.Position).Unit;
							local targetRootPart: BasePart = humanoid.RootPart;

							local killImpulseForce = configurations.KillImpulseForce or 5;
							newDamageSource.DamageForce = dir*killImpulseForce;
							newDamageSource.DamagePosition = targetObject.Position;
						
						elseif targetModel:FindFirstChild("Destructible") then
							local destructibleObject = require(targetModel.Destructible);
							local dmgMulti = self.Wield.Targetable.Destructible or 1;
							
							destructibleObject:TakeDamagePackage(modDamagable.NewDamageSource{
								Damage = (damage * dmgMulti);
								Dealer = self.Npc.Prefab;
								--ToolStorageItem = self.StorageItem;
								TargetModel = targetModel;
								TargetPart = targetObject;
							});
							
						end
						
						local player = game.Players:GetPlayerFromCharacter(targetModel);
						if player then
							local classPlayer = shared.modPlayers.Get(player);

							local bulletProtection = classPlayer.Properties.BodyEquipments and classPlayer.Properties.BodyEquipments.BulletProtection;
							if bulletProtection then
								damage = damage * math.clamp(1-bulletProtection, 0, 1);
							end
						end

						self.Npc:DamageTarget(targetModel, damage, self.Npc.Prefab, newDamageSource);
						
					end
				end
				
				if audio.PrimaryFire.Looped ~= true then
					modAudio.Play(audio.PrimaryFire.Id, rootPart);
				end
				remotePrimaryFire:FireAllClients(self.Wield.ToolModule.Library.Name, self.Wield.Instances.RightModel, targetPoints, true);
				
				
			elseif self.Wield.ToolModule.Configurations.BulletMode == modAttributes.BulletModes.Projectile then
				
				-- Npc Projectile WeaponHandler not implemented
				
			end
		else
			Debugger:Warn("Character ("..self.Npc.Prefab.Name..") Attempted to fire without ammo.");
		end
	end
end


function Handler:PrimaryFireRequest(direction)
	if self.Wield.ToolModule == nil then return end;
	if not self.Wield.AllowShooting then return end;
	task.spawn(function()
		local properties = self.Wield.ToolModule.Properties;
		local configurations = self.Wield.ToolModule.Configurations;
		
		if properties.Ammo <= 0 then
			self:ReloadRequest();
		end
		
		if self.Wield.ToolModule.Properties.CanPrimaryFire then self:PrimaryFire(direction); end;
	end);
end

function Handler:ReloadRequest()
	if self.Wield.ToolModule == nil then return end;
	local properties = self.Wield.ToolModule.Properties;
	local configurations = self.Wield.ToolModule.Configurations;
	
	if not properties.Reloading and properties.Ammo ~= configurations.AmmoLimit then
		if properties.MaxAmmo > 0 or configurations.InfiniteAmmo then
			if properties.Ammo == 0 or (tick()-self.Wield.ReloadCoolDown) > 12 then
				self:Reload();
				self.Wield.ReloadCoolDown = tick();
			end
		end
	end
end

function Handler:Destroy()
	self:Unequip();
end

return Handler;
