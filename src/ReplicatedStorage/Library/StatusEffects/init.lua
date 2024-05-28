local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local StatusEffects = {};

local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modEmotes = require(game.ReplicatedStorage.Library.EmotesLibrary);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modStorageItem = require(game.ReplicatedStorage.Library.StorageItem);

local remotePlayerStatusEffect = modRemotesManager:Get("PlayerStatusEffect");

if RunService:IsServer() then
	modSkillTree = require(game.ServerScriptService.ServerLibrary.SkillTree);
	modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
	remotePlayerStatusEffect.OnServerEvent:Connect(function(player, cmd)
		if cmd == "ready" then
			local classPlayer = modPlayers.GetByName(player.Name);
			classPlayer.StatusReady = true;
			remotePlayerStatusEffect:FireClient(player, "isready");
		end
	end)
end
--== Script;
local function replicateStatus(player, ...)
	local classPlayer = modPlayers.GetByName(player.Name);
	if classPlayer == nil or classPlayer.StatusReady == nil then
		Debugger:Warn("Player status not ready.", player);
	end
	while player:IsDescendantOf(game.Players) and classPlayer.StatusReady == nil do wait(0.5); end
	remotePlayerStatusEffect:FireClient(player, "do", ...);
end

function StatusEffects.FullHeal(player, rate)
	local classPlayer = modPlayers.GetByName(player.Name);
	if classPlayer and classPlayer.Humanoid then
		
		if classPlayer.Properties["MaxHeal"] == nil then
			local healthPool = classPlayer.Humanoid.MaxHealth;
			local armorPool = classPlayer.Properties.MaxArmor;
			
			classPlayer:SetProperties("MaxHeal", true);
			
			task.spawn(function()
				local prevHealth = math.ceil(classPlayer.Humanoid.Health);
				
				while classPlayer.Humanoid ~= nil and classPlayer.IsAlive and classPlayer.Properties["MaxHeal"] == true do
					local totalHeal = 0;
					
					if math.ceil(classPlayer.Humanoid.Health)+5 > prevHealth then
						local healAmount = (classPlayer.Humanoid.MaxHealth*(rate or 0.1));

						healAmount = math.clamp(healAmount, 0, classPlayer.Humanoid.MaxHealth-classPlayer.Humanoid.Health);

						if healAmount > 0 and healthPool > 0 then
							classPlayer:TakeDamagePackage(modDamagable.NewDamageSource{
								Damage=healAmount;
								TargetPart=classPlayer.RootPart;
								DamageType="Heal";
							})
							healthPool = healthPool - healAmount;
							
							totalHeal = totalHeal + healAmount;
						end;
						
					else
						-- took dmg
						break;
					end
					
					if classPlayer.Properties.Armor < classPlayer.Properties.MaxArmor then
						local regenAmount = (classPlayer.Properties.MaxArmor * (rate or 0.1));
						
						regenAmount = math.max(regenAmount, 1);
						regenAmount = math.clamp(regenAmount, 0, classPlayer.Properties.MaxArmor-classPlayer.Properties.Armor);
						
						if regenAmount > 0 and armorPool > 0 then
							classPlayer.Properties.Armor = classPlayer.Properties.Armor + regenAmount;
							
							armorPool = armorPool - regenAmount;
							totalHeal = totalHeal + regenAmount;
						end
					end
					
					if totalHeal <= 0 then
						break;
					end
					task.wait(1);
				end
				
				classPlayer:SetProperties("MaxHeal", nil);
			end)
			return true;
		else
			return false;
		end
	end
end

function StatusEffects.Slowness(player, amount, duration)
	amount = amount or 10;
	duration = duration or 1;
	
	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		local statusTable = {
			ExpiresOnDeath=true;
			Duration=duration;
			Amount=amount;
		};
		
		modOnGameEvents:Invoke("OnMovementImpairment", player, statusTable);
		modSkillTree:TriggerSkills(player, "OnMovementImpairment", statusTable.Duration, function(newDuration) statusTable.Duration = newDuration; end);
		
		statusTable.Expires=modSyncTime.GetTime() + statusTable.Duration;
		classPlayer:SetProperties("Slowness", statusTable);
		replicateStatus(player, "Slowness", amount, statusTable.Duration);
		
		modInfoBubbles.Create{
			Players={player};
			Position=(classPlayer.Head and classPlayer.Head.Position);
			Type="Status";
			ValueString="Slowed!";
		};
		
	else
		local modData = require(player:WaitForChild("DataModule"));
		local modCharacter = modData:GetModCharacter();
		local newWalkSpeed = modCharacter.CharacterProperties.DefaultWalkSpeed-amount;

		modCharacter.CharacterProperties.WalkSpeed:Set("slowness", newWalkSpeed, 5);
		spawn(function()
			if classPlayer.Properties["isSlowed"] then return end;
			classPlayer.Properties["isSlowed"] = true;
			modCharacter.CharacterProperties.CanSprint = false;
			repeat until modSyncTime.Clock.Value >= (classPlayer.Properties.Slowness and classPlayer.Properties.Slowness.Expires or modSyncTime.Clock.Value-1) or not RunService.Heartbeat:Wait();
			
			modCharacter.CharacterProperties.CanSprint = true;
			if modCharacter then
				modCharacter.CharacterProperties.WalkSpeed:Remove("slowness");
			end
			classPlayer.Properties["isSlowed"] = false;
		end)
	end
end

function StatusEffects.Stun(player, duration)
	duration = duration or 1;
	
	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		local statusTable = {
			ExpiresOnDeath=true;
			Expires=modSyncTime.GetTime()+duration;
			Duration=duration;
		};
		
		modOnGameEvents:Invoke("OnMovementImpairment", player, statusTable);
		modSkillTree:TriggerSkills(player, "OnMovementImpairment", statusTable.Duration, function(newDuration) statusTable.Duration = newDuration; end);
		
		statusTable.Expires=modSyncTime.GetTime() + statusTable.Duration;
		classPlayer:SetProperties("Stun", statusTable);
		replicateStatus(player, "Stun", statusTable.Duration);
		
	else
		local modData = require(player:WaitForChild("DataModule"));
		local modCharacter = modData:GetModCharacter();

		local animator = classPlayer.Humanoid:WaitForChild("Animator");
		local track = animator:LoadAnimation(script.Stun);
		track:Play(0.25);
		modCharacter.CharacterProperties.CanMove = false;
		modCharacter.CharacterProperties.CanAction = false;
		modCharacter.MouseProperties.Mouse1Down = false;
		modCharacter.MouseProperties.Mouse2Down = false;
		modCharacter.UpdateWalkSpeed();
		spawn(function()
			if classPlayer.Properties["isStunned"] then return end;
			classPlayer.Properties["isStunned"] = true;
			repeat until modSyncTime.Clock.Value >= (classPlayer.Properties.Stun and classPlayer.Properties.Stun.Expires or modSyncTime.Clock.Value-1) or not RunService.Heartbeat:Wait();
			if modCharacter then
				track:Stop(0.25);
				modCharacter.CharacterProperties.CanMove = true;
				modCharacter.CharacterProperties.CanAction = true;
				modCharacter.UpdateWalkSpeed();
			end
			classPlayer.Properties["isStunned"] = false;
		end)
	end
end

function StatusEffects.Dizzy(player, duration, dizzyType)
	duration = duration or 1;
	
	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		classPlayer:SetProperties("Dizzy", {
			ExpiresOnDeath=true;
			Expires=modSyncTime.GetTime()+duration;
			Duration=duration; Amount=duration;
		});
		replicateStatus(player, "Dizzy", duration, dizzyType);
		
	else
		local modData = require(player:WaitForChild("DataModule"));
		local modCharacter = modData:GetModCharacter();
		local classPlayer = modPlayers.Get(game.Players.LocalPlayer);

		local cameraEffects = modData.CameraClass;
		
		local gasProtection = false;
		if classPlayer then
			gasProtection = classPlayer:GetBodyEquipment("GasProtection") ~= nil;
		end
		
		if modCharacter.StatusBlur == nil then
			modCharacter.StatusBlur = Instance.new("BlurEffect");
			modCharacter.StatusBlur.Name = "StatusBlur";
			modCharacter.StatusBlur.Parent = workspace.CurrentCamera;
		end
		
		modCharacter.StatusBlur.Size = 30;
		if not gasProtection then
			modCharacter.MouseProperties.MovementNoise = true;
		end
		modCharacter.DizzyZAim = true;
		
		if dizzyType == "bloater" then
			cameraEffects.TintColor:Set("bloater", Color3.fromRGB(221, 178, 117), 1);
		end
		
		if modCharacter.CameraShakeAndZoom then
			modCharacter.CameraShakeAndZoom(5, 0, duration*2, 0, true);
		end
		
		TweenService:Create(modCharacter.StatusBlur, 
			TweenInfo.new(tonumber(duration+0.5), Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = 0;}
		):Play();
		
		spawn(function()
			if classPlayer.Properties["isDizzy"] then return end;
			classPlayer.Properties["isDizzy"] = true;
			
			repeat until modSyncTime.Clock.Value >= (classPlayer.Properties.Dizzy and classPlayer.Properties.Dizzy.Expires or modSyncTime.Clock.Value-1) or not RunService.Heartbeat:Wait();
			
			if dizzyType == "bloater" then
				cameraEffects.TintColor:Remove("bloater");
			end
			
			if modCharacter then
				if modCharacter.StatusBlur then
					modCharacter.StatusBlur.Size = 0;
				end
				modCharacter.MouseProperties.MovementNoise = false;
				modCharacter.DizzyZAim = false;
			end
			classPlayer.Properties["isDizzy"] = false;
		end)
	end
end

function StatusEffects.ForceField(player, duration)
	duration = duration or 60;

	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		local statusTable = {
			ExpiresOnDeath=true;
			Expires=modSyncTime.GetTime()+duration; 
			Duration=duration;
		};

		statusTable.Expires=modSyncTime.GetTime() + statusTable.Duration;
		classPlayer:SetProperties("Forcefield", statusTable);

		local rootPart = classPlayer.RootPart;
		if rootPart then
			if classPlayer.Character:FindFirstChild("ForcefieldStatus") then
				game.Debris:AddItem(classPlayer.Character.ForcefieldStatus, 0);
			end
			local new = Instance.new("ForceField");
			new.Name = "ForcefieldStatus";
			new.Parent = classPlayer.Character;
			Debugger.Expire(new, statusTable.Duration);
		end
	end
end

function StatusEffects.TiedUp(player, duration)
	duration = duration or 2.5;
	
	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		local statusTable = {
			ExpiresOnDeath=true;
			Expires=modSyncTime.GetTime()+duration; 
			Duration=duration;
		};
		
		modOnGameEvents:Invoke("OnMovementImpairment", player, statusTable);
		modSkillTree:TriggerSkills(player, "OnMovementImpairment", statusTable.Duration, function(newDuration) statusTable.Duration = newDuration; end);

		statusTable.Expires=modSyncTime.GetTime() + statusTable.Duration;
		classPlayer:SetProperties("TiedUp", statusTable);
		replicateStatus(player, "TiedUp", statusTable.Duration);
		
		local rootPart = classPlayer.RootPart;
		if rootPart then
			if classPlayer.Character:FindFirstChild("rope") then
				game.Debris:AddItem(classPlayer.Character.rope, 0);
			end
			local newRope = script:WaitForChild("rope"):Clone();
			local joint = newRope:WaitForChild("Weld");
			newRope.Parent = classPlayer.Character;
			joint.Part0 = newRope;
			joint.Part1 = rootPart;
			Debugger.Expire(newRope, statusTable.Duration);
		end
		
	else
		local modData = require(player:WaitForChild("DataModule"));
		local modCharacter = modData:GetModCharacter();
		local classPlayer = modPlayers.Get(game.Players.LocalPlayer);
		
		local animator = classPlayer.Humanoid:WaitForChild("Animator");
		local track = animator:LoadAnimation(script.TiedUp);
		track:Play(0.25);
		modCharacter.CharacterProperties.CanMove = false;
		modCharacter.CharacterProperties.CanAction = false;
		modCharacter.MouseProperties.Mouse1Down = false;
		modCharacter.MouseProperties.Mouse2Down = false;
		modCharacter.UpdateWalkSpeed();
		spawn(function()
			if classPlayer.Properties["isTiedUp"] then return end;
			classPlayer.Properties["isTiedUp"] = true;
			repeat until modSyncTime.Clock.Value >= (classPlayer.Properties.TiedUp and classPlayer.Properties.TiedUp.Expires or modSyncTime.Clock.Value-1) or not RunService.Heartbeat:Wait();
			if modCharacter then
				track:Stop(0.25);
				modCharacter.CharacterProperties.CanMove = true;
				modCharacter.CharacterProperties.CanAction = true;
				modCharacter.UpdateWalkSpeed();
			end
			classPlayer.Properties["isTiedUp"] = false;
		end)
	end
end

function StatusEffects.BloxyRush(player, duration)
	duration = duration or 2.5;
	
	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		classPlayer:SetProperties("BloxyRush", {
			ExpiresOnDeath=true;
			Expires=modSyncTime.GetTime()+duration;
			Duration=duration;
		});
		replicateStatus(player, "BloxyRush", duration);
		
	else
		local modData = require(player:WaitForChild("DataModule"));
		local modCharacter = modData:GetModCharacter();
		local classPlayer = modPlayers.Get(game.Players.LocalPlayer);
		
		modCharacter.CharacterProperties.SprintSpeed = 26.4;
		spawn(function()
			if classPlayer.Properties["isBloxyRush"] then return end;
			classPlayer.Properties["isBloxyRush"] = true;
			
			repeat until modSyncTime.Clock.Value >= (classPlayer.Properties.BloxyRush and classPlayer.Properties.BloxyRush.Expires or modSyncTime.Clock.Value-1) or not RunService.Heartbeat:Wait();
			if modCharacter then
				modCharacter.CharacterProperties.SprintSpeed = 22;
				modCharacter.UpdateWalkSpeed();
			end
			
			classPlayer.Properties["isBloxyRush"] = false;
		end)
	end
end

function StatusEffects.Burn(player, damage, duration)
	
	damage = damage or 10;
	duration = duration or 2.5;
	
	local dmgPS = math.ceil(damage/duration);
	
	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		classPlayer:SetProperties("Burn", {
			ExpiresOnDeath=true;
			Expires=modSyncTime.GetTime()+duration; 
			Duration=duration;
			Amount=dmgPS;
		});
		
		local setFireOnParts = {};
		for _, obj in pairs(classPlayer.Character:GetChildren() or {}) do
			if obj:IsA("BasePart") then
				local fire = obj:FindFirstChild("burnFire");
				if fire then
					fire:Destroy();
				end
				if #setFireOnParts == 0 or math.random(1, 4) == 1 then
					table.insert(setFireOnParts, obj);
				end
			end
		end
		for a=1, #setFireOnParts do
			local fire = Instance.new("Fire");
			fire.Name = "burnFire";
			fire.Heat = 3;
			fire.Size = 2;
			fire.Parent = setFireOnParts[a];
		end
		task.spawn(function()
			if classPlayer.Properties["isBurning"] then return end;
			classPlayer.Properties["isBurning"] = true;
			repeat
				if classPlayer then
					classPlayer:TakeDamagePackage(modDamagable.NewDamageSource{
						Damage=dmgPS;
						TargetPart=classPlayer.RootPart;
						DamageType="FireDamage";
					})
				end
				task.wait(1);
			until (classPlayer.Humanoid and classPlayer.Humanoid:GetState() == Enum.HumanoidStateType.Swimming)
			or modSyncTime.Clock.Value >= (classPlayer.Properties.Burn and classPlayer.Properties.Burn.Expires or modSyncTime.Clock.Value-1);
			classPlayer:SetProperties("Burn", nil);
			
			for _, obj in pairs(classPlayer.Character:GetChildren() or {}) do
				if obj:IsA("BasePart") then
					local fire = obj:FindFirstChild("burnFire");
					if fire then
						fire:Destroy();
					end
				end
			end
			classPlayer.Properties["isBurning"] = false;
		end)
	end
end

function StatusEffects.FrostivusSpirit(player, duration, startAmount)
	duration = duration or 120;

	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		local timer = tick();
		classPlayer:SetProperties("FrostivusSpirit", {
			PresistUntilExpire={"Duration"; "Amount"};
			Expires=modSyncTime.GetTime()+duration;
			Duration=duration;
			Amount=(startAmount or 0);
			OnTick=(function(classPlayer, status)
				if (tick()-timer >= 3) then
					timer = tick();
					if status.Amount > 0 then
						status.Amount = status.Amount-20;
						return true;
					end
				end
			end);
		});
		
	end
end

function StatusEffects.Reinforcement(player, duration)
	duration = duration or 60;

	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		local statusTable = {
			ExpiresOnDeath=true;
			Expires=modSyncTime.GetTime()+duration; 
			Duration=duration;
			OnExpire=function()
				if classPlayer.Properties.ReinforcementBuff ~= nil then
					classPlayer.Properties.ReinforcementBuff:Destroy();
				end
			end
		};

		statusTable.Expires=modSyncTime.GetTime() + statusTable.Duration;
		classPlayer:SetProperties("Reinforcement", statusTable);

		local namesList = {"Jesse"; "Diana"; "Frank"; "Maverick"; "Larry"};
		
		if classPlayer.Properties.ReinforcementBuff ~= nil then
			classPlayer.Properties.ReinforcementBuff:Destroy();
		end
		local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
		classPlayer.Properties.ReinforcementBuff = modNpc.Spawn(namesList[math.random(1, #namesList)], classPlayer.RootPart.CFrame, function(npc, npcModule)
			npcModule.Humanoid.Name = "Pet";
			npcModule.Owner = player;
		end, require(game.ServerStorage.PrefabStorage.CustomNpcModules.PetNpcModule));
	end
end

function StatusEffects.XpEnergyDrink(player, duration)
	duration = duration or 10;
	
	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		classPlayer:SetProperties("XpBoost", {
			PresistUntilExpire={"Duration";};
			Expires=modSyncTime.GetTime()+duration;
			Duration=duration;
		});
	end
end

function StatusEffects.Superspeed(player, duration)
	duration = duration or 60;

	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		local debris = {};
		local statusTable = {
			ExpiresOnDeath=true;
			Expires=modSyncTime.GetTime()+duration; 
			Duration=duration;
			OnExpire=function()
				StatusEffects.SetWalkspeed(player);
				for a=1, #debris do
					game.Debris:AddItem(debris[a], 0);
				end
			end
		};

		statusTable.Expires=modSyncTime.GetTime() + statusTable.Duration;
		classPlayer:SetProperties("Superspeed", statusTable);
		
		local character = classPlayer.Character;
		if character then
			local function addTrail(part)
				local attA = part:FindFirstChild("SpeedTrailAtt01") or Instance.new("Attachment");
				attA.Name = "SpeedTrailAtt01";
				attA.Position = Vector3.new(0, -0.2, 0);
				attA.Parent = part;
				table.insert(debris, attA);

				local attB = part:FindFirstChild("SpeedTrailAtt02") or Instance.new("Attachment");
				attB.Name = "SpeedTrailAtt02";
				attB.Position = Vector3.new(0, 0.2, 0);
				attB.Parent = part;
				table.insert(debris, attB);

				local newTrail = part:FindFirstChild("SpeedTrail") or script.SpeedTrail:Clone();
				newTrail.Attachment0 = attA;
				newTrail.Attachment1 = attB;
				newTrail.Parent = part;
				table.insert(debris, newTrail);
			end
			if character:FindFirstChild("LowerTorso") then
				addTrail(character.LowerTorso);
			end
			if character:FindFirstChild("LeftHand") then
				addTrail(character.LeftHand);
			end
			if character:FindFirstChild("RightHand") then
				addTrail(character.RightHand);
			end
			if character:FindFirstChild("LeftFoot") then
				addTrail(character.LeftFoot);
			end
			if character:FindFirstChild("RightFoot") then
				addTrail(character.RightFoot);
			end
		end
		
		StatusEffects.SetWalkspeed(player, 40);
	end
end

function StatusEffects.Lifesteal(player, duration, amount)
	duration = duration or 120;
	amount = amount or 5;

	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		local timer = tick();
		classPlayer:SetProperties("Lifesteal", {
			PresistUntilExpire={"Duration"; "Amount"};
			Expires=modSyncTime.GetTime()+duration;
			Duration=duration;
			Amount=amount;
		});

	end
end

function StatusEffects.Poison(player, duration)
	duration = duration or 1;

	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		local timer = tick();
		classPlayer:SetProperties("Poisoned", {
			ExpiresOnDeath=true;
			Expires=modSyncTime.GetTime()+duration;
			Duration=duration;
			Amount=duration;
			OnTick=(function(classPlayer, status)
				if (tick()-timer >= 0.5) then
					timer = tick();

					local damagable = modDamagable.NewDamagable(classPlayer.Character);
					if damagable then
						damagable:TakeDamagePackage(modDamagable.NewDamageSource{
							Damage=2;
						});
					end
				end
			end);
		});
		replicateStatus(player, "Poison", duration);

	else
		local modData = require(player:WaitForChild("DataModule"));
		local modCharacter = modData:GetModCharacter();

		modCharacter.MouseProperties.MovementNoise = true;

		modCharacter.CameraShakeAndZoom(5, 0, 0.5, 0, true);

		spawn(function()
			if classPlayer.Properties["isPoisoned"] then return end;
			classPlayer.Properties["isPoisoned"] = true;
			repeat until modSyncTime.Clock.Value >= (classPlayer.Properties.Poisoned and classPlayer.Properties.Poisoned.Expires or modSyncTime.Clock.Value-1) or not RunService.Heartbeat:Wait();
			if modCharacter then
				modCharacter.MouseProperties.MovementNoise = false;
			end
			classPlayer.Properties["isPoisoned"] = false;
		end)
	end
end

function StatusEffects.NightVision(player)
	
	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		classPlayer:SetProperties("NightVision", {});
		replicateStatus(player, "NightVision");

	else
		-- client
		local modData = require(player:WaitForChild("DataModule"));
		local modCharacter = modData:GetModCharacter();
		
		spawn(function()
			local t=tick();
			while classPlayer == nil do
				classPlayer = modPlayers.GetByName(player.Name);
				task.wait();
				if tick()-t >= 60 then return end;
			end
			
			if classPlayer.Properties["nightVisionActive"] then return end;
			classPlayer.Properties["nightVisionActive"] = true;
			
			local function setNV()
				local h, s, v = game.Lighting.OutdoorAmbient:ToHSV();

				game.Lighting.Ambient = Color3.fromRGB(0, math.max(128, v*255), 0);
			end
			
			local conn;
			conn = game.Lighting:GetPropertyChangedSignal("Ambient"):Connect(setNV)
			local conn2;
			conn2 = game.Lighting:GetPropertyChangedSignal("OutdoorAmbient"):Connect(setNV);
			
			setNV();
			
			repeat
				RunService.Heartbeat:Wait(); 
			until classPlayer.Properties.NightVision == nil;
			
			conn:Disconnect();
			conn = nil;
			conn2:Disconnect();
			conn2 = nil;
			
			game.Lighting.Ambient = Color3.fromRGB(10, 10, 10);
			
			classPlayer.Properties["nightVisionActive"] = false;
		end)
	end
end


function StatusEffects.StatusResistance(player, duration, percent)
	duration = duration or 1;
	percent = percent or 30;

	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		local timer = tick();
		classPlayer:SetProperties("StatusResistance", {
			ExpiresOnDeath=true;
			Expires=modSyncTime.GetTime()+duration;
			Duration=duration;
			Percent=percent;
		});
	end
end

function StatusEffects.SetWalkspeed(player, amount)
	amount = tonumber(amount);
	
	local classPlayer = modPlayers.GetByName(player.Name);
	if classPlayer == nil then return end;
	
	if RunService:IsServer() then
		if amount == nil then
			classPlayer:SetProperties("ForceWalkspeed", nil);
			classPlayer.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true);
			
			replicateStatus(player, "SetWalkspeed");
			
		else
			classPlayer:SetProperties("ForceWalkspeed", {Amount=amount;});
			classPlayer.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, amount > 0);
			
			replicateStatus(player, "SetWalkspeed", amount);
			
		end

	else
		local modData = require(player:WaitForChild("DataModule"));
		local modCharacter = modData:GetModCharacter();
		
		if amount == nil then
			classPlayer.Properties["forcedWalkspeed"] = nil;
			
		else
			for a=1, 3 do if modCharacter.CharacterProperties.WalkSpeed then break; else task.wait(0.5) end end;
				
			modCharacter.CharacterProperties.WalkSpeed:Set("forceWalkspeed", amount, 10);
			modCharacter.UpdateWalkSpeed();
			spawn(function()
				if classPlayer.Properties["forcedWalkspeed"] then return end;
				classPlayer.Properties["forcedWalkspeed"] = true;
				modCharacter.CharacterProperties.CanSprint = false;

				repeat RunService.Heartbeat:Wait() until classPlayer.Properties.forcedWalkspeed == nil;
				modCharacter.CharacterProperties.CanSprint = true;
				if modCharacter then
					modCharacter.CharacterProperties.WalkSpeed:Remove("forceWalkspeed");
				end
				classPlayer.Properties["forcedWalkspeed"] = nil;
			end)
			
		end
	end
end

function StatusEffects.Ragdoll(player, value, canAction)
	local classPlayer = modPlayers.GetByName(player.Name);
	if classPlayer == nil then return end;
	
	if RunService:IsServer() then
		if value == true then
			classPlayer.Humanoid.PlatformStand = true;
			
			classPlayer:SetProperties("Ragdoll", 1);
			replicateStatus(player, "Ragdoll", 1, canAction);
		else
			classPlayer.Humanoid.PlatformStand = false;
			
			classPlayer:SetProperties("Ragdoll", 0);
		end

	else
		local modData = require(player:WaitForChild("DataModule"));
		local modCharacter = modData:GetModCharacter();
		
		classPlayer.Humanoid.PlatformStand = true;
		modCharacter.CharacterProperties.Ragdoll = true;
		if canAction ~= true then
			modCharacter.CharacterProperties.CanAction = false;
		end

		task.spawn(function()
			repeat RunService.Heartbeat:Wait(); until classPlayer.Properties.Ragdoll == 0;
			if modCharacter then
				classPlayer.Humanoid.PlatformStand = false;
				modCharacter.CharacterProperties.Ragdoll = false;
				modCharacter.CharacterProperties.CanAction = true;
			end
		end)
	end
end


function StatusEffects.AntiGravity(player, value)
	local classPlayer = modPlayers.GetByName(player.Name);
	if classPlayer == nil then return end;
	
	if RunService:IsServer() then
		local antiGravityForce = classPlayer.RootPart:FindFirstChild("AntiGravity");
		
		if value ~= nil then
			if antiGravityForce == nil then
				antiGravityForce = Instance.new("BodyForce");
				antiGravityForce.Name = "AntiGravity";
			end
			
			classPlayer.Humanoid.PlatformStand = true;
			
			antiGravityForce:SetAttribute("Gravity", value);
			antiGravityForce.Parent = classPlayer.RootPart;
			
		else
			classPlayer.Humanoid.PlatformStand = false;
			if antiGravityForce then
				antiGravityForce:Destroy();
			end
			
		end
		
	end
end

function StatusEffects.ApplyImpulse(player, force)
	if typeof(force) == "string" then return; end
	force = Vector3.new(0, 80, 0);

	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		local humanoid = classPlayer.Humanoid;
		local rootPart = classPlayer.RootPart;

		replicateStatus(player, "ApplyImpulse", force);
	else
		local rootPart = classPlayer.RootPart;
		local mass = classPlayer:GetMass(); 
		
		local velocity = rootPart.AssemblyLinearVelocity;
		rootPart:ApplyImpulse((force + Vector3.new(0, math.max(0, -velocity.Y), 0)) * mass);

	end
end

function StatusEffects.Launch(player, force)
	if typeof(force) == "string" then return; end
	force = Vector3.new(0, 80, 0);
	
	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		local humanoid = classPlayer.Humanoid;
		local rootPart = classPlayer.RootPart;
		
		StatusEffects.Ragdoll(player, true);
		
		replicateStatus(player, "Launch", force);
		
		task.delay(2, function()
			StatusEffects.Ragdoll(player, false);
		end)
		
	else
		local rootPart = classPlayer.RootPart;
		local mass = classPlayer:GetMass();
		rootPart:ApplyImpulse(force * mass);
		
	end
end

function StatusEffects.Throw(player, force)
	if typeof(force) == "string" then return; end
	force = force or Vector3.zero;
	force = Vector3.new(force.Unit.X, 1, force.Unit.Z)*100;
	
	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		local humanoid = classPlayer.Humanoid;
		local rootPart = classPlayer.RootPart;

		StatusEffects.Ragdoll(player, true);

		replicateStatus(player, "Throw", force);

		task.delay(2, function()
			StatusEffects.Ragdoll(player, false);
		end)

	else
		local rootPart = classPlayer.RootPart;
		local mass = classPlayer:GetMass();
		
		rootPart:ApplyImpulse(force * mass);

	end
end

function StatusEffects.Knockback(player, basePart, force, stunDuration)
	stunDuration = stunDuration or 2;
	if typeof(basePart) == "string" or typeof(force) == "string" then return; end
	force = math.clamp(force, 0, 500);
	
	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		local humanoid = classPlayer.Humanoid;
		local rootPart = classPlayer.RootPart;
		
		StatusEffects.Ragdoll(player, true);

		replicateStatus(player, "Knockback", basePart, force);

		task.delay(stunDuration, function()
			StatusEffects.Ragdoll(player, false);
		end)

	else
		local rootPart = classPlayer.RootPart;
		local mass = classPlayer:GetMass();
		
		local knockbackDir = (rootPart.Position-basePart.Position).Unit;
		
		if rawequal(knockbackDir, knockbackDir) == false then return end;
		
		rootPart:ApplyImpulse(knockbackDir * force * mass);
	end
end

function StatusEffects.CritBoost(player, duration, amount)
	duration = duration or 60;
	amount = amount or 10;

	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		local timer = tick();
		classPlayer:SetProperties("CritBoost", {
			PresistUntilExpire={"Duration";};
			Amount=amount;
			Expires=modSyncTime.GetTime()+duration;
			Duration=duration;
		});

	end
end

function StatusEffects.Ziphoning(player, duration)
	duration = duration or 60;

	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		local timer = tick();
		classPlayer:SetProperties("Ziphoning", {
			PresistUntilExpire={"Duration";};
			Expires=modSyncTime.GetTime()+duration;
			Duration=duration;
			Pool = 0;
			Amount = 0;
		});

	end
end

function StatusEffects.Freezing(player, duration)
	duration = duration or 2.5;

	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		classPlayer:SetProperties("Freezing", {
			ExpiresOnDeath=true;
			Expires=modSyncTime.GetTime()+duration; 
			Duration=duration;
		});
		replicateStatus(player, "Freezing", duration);
		
	else

		local modData = require(player:WaitForChild("DataModule"));
		local modCharacter = modData:GetModCharacter();

		modCharacter.CharacterProperties.WalkSpeed:Set("freezing", 10, 4);
		modCharacter.UpdateWalkSpeed();
		task.spawn(function()
			if classPlayer.Properties["FreezingWs"] then return end;
			classPlayer.Properties["FreezingWs"] = true;
			modCharacter.CharacterProperties.CanSprint = false;
			modCharacter.CharacterProperties.CanAction = false;

			local animLib = modEmotes:Find("feelingcold");
			if animLib then
				local animator = classPlayer.Humanoid:WaitForChild("Animator");
				local track = animator:LoadAnimation(animLib.Animation);
				track:Play();
			end;
			
			local disarmTick = tick();
			repeat
				task.wait();
				
				if tick()-disarmTick >= 1.3 then
					modCharacter.CharacterProperties.CanAction = true;
				end
			until classPlayer.Properties.Freezing == nil;
			
			modCharacter.CharacterProperties.CanSprint = true;
			modCharacter.CharacterProperties.CanAction = true;
			if modCharacter then
				modCharacter.CharacterProperties.WalkSpeed:Remove("freezing");
			end
			classPlayer.Properties["FreezingWs"] = nil;
		end)
		
	end
end


function StatusEffects.KnockedOut(player, knockoutTime)
	knockoutTime = knockoutTime or 60;
	local classPlayer = modPlayers.GetByName(player.Name);
	
	if RunService:IsServer() then
		local statusTable = {
			ExpiresOnDeath=true;
			Duration=knockoutTime;
		};
		statusTable.Expires=modSyncTime.GetTime() + knockoutTime;
		
		classPlayer.Humanoid.Health = 0;
		
		classPlayer:SetProperties("KnockedOut", statusTable);
	end
end


function StatusEffects.CoveredVision(player, value)
	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		if value == true then
			classPlayer:SetProperties("CoveredVision", {});
			replicateStatus(player, "CoveredVision");
			
		else
			classPlayer:SetProperties("CoveredVision", nil);
			
		end

	else
		local modData = require(player:WaitForChild("DataModule"));
		local modCharacter = modData:GetModCharacter();
		local cameraInterface = modData:GetInterfaceModule().CameraInterface;
		
		local clothBagFrame = script:WaitForChild("ClothbagFrame");
		
		spawn(function()
			if classPlayer.Properties["coveredVisionActive"] then return end;
			classPlayer.Properties["coveredVisionActive"] = true;
			
			if cameraInterface:FindFirstChild("ClothbagFrame") == nil then
				local new = clothBagFrame:Clone();
				new.Parent = cameraInterface;
			end
			
			if modCharacter.StatusBlur == nil then
				modCharacter.StatusBlur = Instance.new("BlurEffect");
				modCharacter.StatusBlur.Name = "StatusBlur";
				modCharacter.StatusBlur.Parent = workspace.CurrentCamera;
			end

			modCharacter.StatusBlur.Size = 5;
			
			repeat
				RunService.Heartbeat:Wait(); 
			until classPlayer.Properties.CoveredVision == nil;
			
			for _, obj in pairs(cameraInterface:GetChildren()) do
				if obj.Name == "ClothbagFrame" then
					game.Debris:AddItem(obj, 0);
				end
			end

			if modCharacter and modCharacter.StatusBlur then
				modCharacter.StatusBlur.Size = 0;
			end
			
			classPlayer.Properties["coveredVisionActive"] = false;
		end)
	end
end

function StatusEffects.Withering(player, duration)
	if RunService:IsClient() then return end
	duration = duration or 30;
	
	local classPlayer = modPlayers.GetByName(player.Name);
	classPlayer:SetProperties("Withering", {
		ExpiresOnDeath=true;
		Expires=modSyncTime.GetTime()+duration;
		Duration=duration;
	});
end

function StatusEffects.VexBile(player, duration)
	duration = duration or 1;

	local classPlayer = modPlayers.GetByName(player.Name);
	if RunService:IsServer() then
		classPlayer:SetProperties("VexBile", {
			ExpiresOnDeath=true;
			Expires=modSyncTime.GetTime()+duration;
			Duration=duration;
		});
		replicateStatus(player, "VexBile", duration);

	else
		local modData = require(player:WaitForChild("DataModule"));
		local modCharacter = modData:GetModCharacter();
		local classPlayer = modPlayers.Get(game.Players.LocalPlayer);

		local cameraClass = modData.CameraClass;

		local gasProtection = false;
		if classPlayer then
			gasProtection = classPlayer:GetBodyEquipment("GasProtection") ~= nil;
		end

		if modCharacter.StatusBlur == nil then
			modCharacter.StatusBlur = Instance.new("BlurEffect");
			modCharacter.StatusBlur.Name = "StatusBlur";
			modCharacter.StatusBlur.Parent = workspace.CurrentCamera;
		end

		modCharacter.StatusBlur.Size = 10;
		cameraClass.TintColor:Set("vexbile", Color3.fromRGB(255, 136, 96), 1);
		cameraClass:SetAtmosphere(script.VexBileAtmosphere, "vexbile", cameraClass.EffectsPriority.Environment, duration+0.5);

		spawn(function()
			if classPlayer.Properties["isVexBile"] then return end;
			classPlayer.Properties["isVexBile"] = true;

			repeat until modSyncTime.Clock.Value >= (classPlayer.Properties.VexBile and classPlayer.Properties.VexBile.Expires or modSyncTime.Clock.Value-1) 
				or not RunService.Heartbeat:Wait();

				cameraClass.TintColor:Remove("vexbile");

			if modCharacter then
				if modCharacter.StatusBlur then
					modCharacter.StatusBlur.Size = 0;
				end
				modCharacter.MouseProperties.MovementNoise = false;
				modCharacter.DizzyZAim = false;
			end
			classPlayer.Properties["isVexBile"] = false;
		end)
	end
end

function StatusEffects.Chained(player, duration, position, anchorHealth, isHardMode)
	if RunService:IsClient() then return end
	duration = duration or 10;
	anchorHealth = anchorHealth or 100;

	local classPlayer = modPlayers.GetByName(player.Name);
	local rootPart = classPlayer.RootPart;
	local rootAtt = rootPart.RootRigAttachment;
	
	position = position or rootPart.Position;
	
	local newAnchor = script.ChainAnchors:Clone();
	local anchorAtt = newAnchor:WaitForChild("Base"):WaitForChild("AnchorAtt");
	local tarRpValue: ObjectValue = newAnchor:WaitForChild("Base"):WaitForChild("TargetRootPart");
	
	local newRope = Instance.new("RopeConstraint");
	newRope.Attachment0 = anchorAtt;
	newRope.Attachment1 = rootAtt;
	newRope.Length = isHardMode and 20 or 32;
	newRope.Visible = false;
	newRope:SetAttribute("FPIgnore", true);
	newRope.Parent = rootPart;
	Debugger.Expire(newRope, duration);

	local newChains = script.Chains:Clone();
	newChains.Attachment0 = anchorAtt;
	newChains.Attachment1 = rootAtt;
	if isHardMode then
		newChains.Color = ColorSequence.new(Color3.new(0.243137, 0.196078, 0.196078), Color3.new(0.243137, 0.168627, 0.168627));
	end
	newChains.Parent = rootPart;
	Debugger.Expire(newChains, duration);
	
	local statusTable = classPlayer.Properties.Chained or {};
	
	local garbageList = statusTable.Garbage or {};
	statusTable.Garbage = garbageList;
	
	statusTable.ExpiresOnDeath=true;
	statusTable.Expires=modSyncTime.GetTime()+duration;
	statusTable.Duration=duration;
	
	classPlayer:SetProperties("Chained", statusTable);
	
	Debugger.Expire(newAnchor, duration);
	newAnchor:PivotTo(CFrame.new(position));
	
	tarRpValue.Value = rootPart;
	
	local destructibleObj = require(newAnchor:WaitForChild("Destructible"));
	
	destructibleObj:SetHealth(anchorHealth, anchorHealth);
	function destructibleObj:OnDestroy()
		game.Debris:AddItem(newAnchor, 0);
		game.Debris:AddItem(anchorAtt, 0);
		game.Debris:AddItem(newRope, 0);
		game.Debris:AddItem(newChains, 0);
	end
	destructibleObj.Enabled = true;
	
	newAnchor.Parent = workspace.Environment;
	
	pcall(function()
		newAnchor.Base:SetNetworkOwner(player);
	end)
	
	table.insert(garbageList, newAnchor);
	
	newAnchor.Destroying:Connect(function()
		destructibleObj:OnDestroy();
		
		local index = table.find(garbageList, newAnchor);
		if index then
			table.remove(garbageList, index);
		end
	end)
	
	statusTable.OnTick=(function(classPlayer, status, tickPack)
		if tickPack.ms100 ~= true then return end;

		if #status.Garbage <= 0 then
			status.Expires=modSyncTime.GetTime();
			classPlayer:SyncProperty("Chained");
		end
	end);
	
	statusTable.OnTeleport=function(classPlayer, status, destinationCframe)
		for _, obj in pairs(status.Garbage) do
			obj:Destroy();
		end
	end
	
	return newAnchor;
end

function StatusEffects.FumesGas(player, damage)
	if RunService:IsClient() then return end
	damage = damage or 6;
	local classPlayer = modPlayers.GetByName(player.Name);

	local statusTable = classPlayer.Properties.FumesGas;
	if statusTable then
		statusTable.LastRefresh = tick();
		return;
	end

	statusTable = {
		ExpiresOnDeath=true;
		LastRefresh = tick();
	}
	
	statusTable.OnTick=(function(classPlayer, status, tickPack)
		if tickPack.ms100 ~= true then return end;

		local lapse = tick()-status.LastRefresh;
		
		if lapse > 0.65 then
			status.Expires=modSyncTime.GetTime();
			classPlayer:SyncProperty("FumesGas");
			return;
		elseif lapse > 0.5 then
			return;
		end

		if tickPack.ms500 ~= true then return end;

		classPlayer:TakeDamagePackage(modDamagable.NewDamageSource{
			Damage=damage;
			DamageType="IgnoreArmor";
			DamageCate=modDamagable.DamageCategory.FumesGas;
		});
		
		local player = classPlayer:GetInstance();
		if player == nil then return end;

		local profile = shared.modProfile:Get(player);
		local saveData = profile:GetActiveSave();
		if saveData.Clothing then
			local clothingList = saveData.Clothing:ListByIndexOrder();

			local dmgTaken = false;
			for a=1, #clothingList do
				local storageItem = clothingList[a];
				local siid = storageItem.ID;

				local itemClass = profile:GetItemClass(siid);
				if itemClass == nil or itemClass.GasProtection == nil then continue end;

				local itemLib = modItemsLibrary:Find(storageItem.ItemId);
				if itemLib == nil then continue end;

				local prevHealth = storageItem:GetValues("Health") or 100;
				if prevHealth <= 0 then
					modStorageItem.PopupItemStatus("ItemHealth", storageItem);
					continue;
				end;
				
				if dmgTaken then continue end;
				dmgTaken = true;

				storageItem:TakeDamage(damage/2);

				local newHealth = storageItem:GetValues("Health");
				if prevHealth ~= newHealth then
					if newHealth == 0 then
						modAudio.Play("GasMaskBroken", classPlayer.Head);
						saveData.AppearanceData:Update(saveData.Clothing);

					elseif math.fmod(newHealth, 20) == 0 then
						modAudio.Play("GasMaskBreaking"..math.random(1,3), classPlayer.Head).PlaybackSpeed = math.random(90,110)/100;
						
					end
				end
				
				modStorageItem.PopupItemStatus("ItemHealth", storageItem);
			end
		end
	end);

	classPlayer:SetProperties("FumesGas", statusTable);
end


if RunService:IsServer() then
	modPlayers.OnPlayerDied:Connect(function(classPlayer)
		classPlayer:SetProperties("NekroVeinDeath", nil);
	end)
end

return StatusEffects;