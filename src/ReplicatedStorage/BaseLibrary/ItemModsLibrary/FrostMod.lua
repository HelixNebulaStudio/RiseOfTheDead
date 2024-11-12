local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClassItemMod = require(script.Parent:WaitForChild("ClassItemMod"));
local itemMod = modClassItemMod.new();

local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");
local TweenService = game:GetService("TweenService");

local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modMath = require(game.ReplicatedStorage.Library.Util.Math);
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modTDParticles = require(game.ReplicatedStorage.Particles.TDParticles);

local random = Random.new();
local frostParticle = game.ReplicatedStorage.Particles:WaitForChild("Frost");
local frostTexture = script:WaitForChild("FrostTexture");
local frostSpark = game.ReplicatedStorage.Particles:WaitForChild("FrostSpark");
local iceDecor = script:WaitForChild("IceDecor");

local faces = {Enum.NormalId.Back; Enum.NormalId.Bottom; Enum.NormalId.Front; Enum.NormalId.Left; Enum.NormalId.Right; Enum.NormalId.Top;};

function itemMod.Activate(packet)
	local info = itemMod.Library.Get(packet.ItemId);
	local module = packet.WeaponModule;
	local modStorageItem = packet.ModStorageItem;

	local sLayerInfo = itemMod.Library.GetLayer("S", packet);
	local sValue, sTweakVal = sLayerInfo.Value, sLayerInfo.TweakValue;
	
	if sTweakVal then
		sValue = sValue + sTweakVal;
	end

	local tLayerInfo = itemMod.Library.GetLayer("T", packet);
	local tValue, tTweakVal = tLayerInfo.Value, tLayerInfo.TweakValue;

	if tTweakVal then
		tValue = tValue + tTweakVal;
	end
	
	module.Configurations.Element = info.Element;
	module.Configurations.PropertiesOfMod = {
		Radius = sValue;
		Targets = tValue;
	}

	module:SetPrimaryModHook({
		StorageItemID=modStorageItem.ID; 
		Activate=itemMod.ActivateMod;
	}, info);
	
	--local modStorageItem, toolModule = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	
	--local radius = ModsLibrary.Linear(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["S"], info.Upgrades[1].MaxLevel);
	--local targets = ModsLibrary.Linear(info.Upgrades[2].BaseValue, info.Upgrades[2].MaxValue, values["T"], info.Upgrades[2].MaxLevel);

	--if paramPacket.TweakStat and info.Upgrades[2].TweakBonus then
	--	local bonusRadius = math.round(info.Upgrades[2].TweakBonus * math.abs(paramPacket.TweakStat/100));
	--	radius = radius + bonusRadius;
		
	--	local bonusTargets = math.round(info.Upgrades[2].TweakBonus * math.abs(paramPacket.TweakStat/100));
	--	targets = targets + bonusTargets;
	--end
	
	--toolModule.Configurations.Element = info.Element;
	--toolModule.Configurations.PropertiesOfMod = {
	--	Radius = radius;
	--	Targets = targets;
	--}

	--toolModule:SetPrimaryModHook({
	--	StorageItemID=modStorageItem.ID; 
	--	Activate=Mod.ActivateMod;
	--}, info);
end

if RunService:IsServer() then
	local statusKey = script.Name;

	local maxStacks = 10;
	local freezeDuration = 5;
	
	
	local activeStacks = {};
	local systemActive = false;
	
	local function addDecor(targetModel, frostStack)
		local bodyParts = targetModel:GetChildren();
		for a=1, #bodyParts do
			if bodyParts[a]:IsA("BasePart") and bodyParts[a].Name ~= "HumanoidRootPart" and bodyParts[a].Transparency ~= 1 then
				for b=1, #faces do
					local new = frostTexture:Clone();
					new.Face = faces[b];
					new.Parent = bodyParts[a];
					table.insert(frostStack.Cache, new);
				end
				if bodyParts[a].Name == "Head" then
					local newFrostParticle = frostParticle:Clone();
					newFrostParticle.Parent = bodyParts[a];
					table.insert(frostStack.Cache, newFrostParticle);
				end
				if bodyParts[a].Name:find("Foot") then
					local newIceRock = iceDecor:Clone();

					local newVal = Instance.new("ObjectValue");
					newVal.Name = "TargetFoot";
					newVal.Value = bodyParts[a];
					newVal.Parent = newIceRock;

					Debugger.Expire(newIceRock, 10);
					table.insert(frostStack.Cache, newIceRock);
				end
			end
		end
	end
	
	function itemMod.System()
		if systemActive then return end;
		systemActive = true;
		
		local s, e = pcall(function() 
			while systemActive do
				local currTick = tick();
				for a=#activeStacks, 1, -1 do
					local frostStack = activeStacks[a];
					local player = frostStack.Player;
					local npcModule = frostStack.NpcModule;
					local damageSource = frostStack.DamageSource;
					
					if frostStack.CompleteTick then
						if currTick > frostStack.CompleteTick then
							table.remove(activeStacks, a);
							frostStack.Destroy();
							continue;
							
						else
							local timeLeft = frostStack.CompleteTick - currTick;

							frostStack.Stacks = math.round((timeLeft/5)*maxStacks);
							
							if currTick-frostStack.LastStackTick >= 0.5 then
								frostStack.LastStackTick = tick();
								
								task.spawn(function()
									
									local damagable = modDamagable.NewDamagable(npcModule.Prefab);
									if damagable == nil or not damagable:CanDamage(player) then return end;
									if damagable.Object.ClassName ~= "NpcStatus" then return end;

									local targetPart = damageSource.TargetPart;

									local newParticle = frostSpark:Clone();
									newParticle.Parent = targetPart;
									newParticle:Emit(10);
									Debugger.Expire(newParticle, 2);
									modAudio.Play("IceCracks", targetPart).PlaybackSpeed = math.random(90,120)/100;

									damageSource.Damage = damageSource.ToolModule.Configurations.Damage;
									damageSource.DamageType = "FrostDamage";
									damagable:TakeDamagePackage(damageSource);
								end)
							end

						end
						
					elseif frostStack.Stacks <= 0 then
						table.remove(activeStacks, a);
						frostStack.Destroy();
						continue;

					elseif tick()-frostStack.LastStackTick >= 0.4 then
						frostStack.LastStackTick = tick();
						frostStack.DamagePool = 0;
						frostStack.Stacks = frostStack.Stacks -1;
						
					end
					
					task.spawn(frostStack.UpdateEffects);
				end
				task.wait(0.1);
				if #activeStacks <= 0 then
					systemActive = false;
				end
			end
		end)
		if not s then
			systemActive = false;
			error(e);
		end
	end
	
	function itemMod.IceBlast(frostStack, npcModule, params)
		local player = frostStack.Player;
		local maxTargets = params.Targets;
		local maxRadius = params.Radius;
		
		local targetModel = npcModule.Prefab;
		
		local overlapParams = OverlapParams.new();
		overlapParams.FilterType = Enum.RaycastFilterType.Include;
		overlapParams.MaxParts = maxTargets+2;

		local rootPos = targetModel:GetPivot().Position;

		task.spawn(function()
			local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Cubic);
			
			local shockWavePacket = {
				Type="Shockwave";
				
				TweenInfo = tweenInfo;
				Origin = CFrame.new(rootPos - Vector3.new(0, 1, 0));
				EndSize = Vector3.new(maxRadius*2, 0.2, maxRadius*2);
				
				WaveColor = Color3.fromRGB(175, 221, 255);
				WaveMaterial = Enum.Material.Ice;
				WaveTextureID = "rbxassetid://16279339455";
			};
			
			local newIceBall = Instance.new("Part");
			newIceBall.Anchored = true;
			newIceBall.Material = Enum.Material.Ice;
			newIceBall.Shape = Enum.PartType.Ball;
			newIceBall.CanCollide = false;
			newIceBall.CanQuery = false;
			newIceBall.Size = Vector3.new(2,2,2);
			newIceBall.CFrame = CFrame.new(rootPos);
			newIceBall.Color = Color3.fromRGB(175, 221, 255);
			newIceBall.Transparency = 0.3;
			newIceBall.Parent = workspace.Debris;

			modTDParticles:Emit(shockWavePacket);
			TweenService:Create(newIceBall, tweenInfo, {
				Size=Vector3.new(maxRadius*1.8, maxRadius*1.8, maxRadius*1.8);
				Transparency=1;
			}):Play();

		end)

		overlapParams.FilterDescendantsInstances = CollectionService:GetTagged("Enemies");

		local rootParts = workspace:GetPartBoundsInRadius(rootPos, maxRadius, overlapParams);
		local hitCount = 0;
		for a=1, #rootParts do
			local enemyRootPart = rootParts[a];
			local enemyPrefab = enemyRootPart.Parent;
			if enemyPrefab == targetModel then continue end;

			local enemyStatus = enemyPrefab:FindFirstChild("NpcStatus") and require(enemyPrefab.NpcStatus) or nil;
			if enemyStatus == nil then continue end;

			local enemyNpcModule = enemyStatus:GetModule();
			if enemyNpcModule == nil or enemyNpcModule.IsDead or enemyNpcModule.EntityStatus == nil then continue end;

			local enemyFrostStatus = enemyNpcModule.EntityStatus:GetOrDefault(statusKey);
			if enemyFrostStatus then continue end;

			local damagable = modDamagable.NewDamagable(enemyPrefab);
			if damagable == nil or not damagable:CanDamage(player) then continue end;
			if damagable.Object.ClassName ~= "NpcStatus" then continue end;
			
			local damageSource = frostStack.DamageSource:Clone();
			damageSource.TargetModel = enemyPrefab;
			damageSource.TargetPart = enemyPrefab.PrimaryPart;
			
			local newFrostStack = enemyNpcModule.EntityStatus:Apply(statusKey, {
				Stacks=10;
				Hijacked=true;

				InitialSpeed=enemyNpcModule.Humanoid.WalkSpeed;
				SlowValue=0;

				LastStackTick=tick()-0.1;
				DamagePool=0;
				
				CompleteTick=tick()+freezeDuration;
				UpdateEffects=(function() end);
			});
			
			itemMod.NewFrostStack(enemyNpcModule, newFrostStack, damageSource, player);
			
			enemyNpcModule.StatusLogic();
			newFrostStack.UpdateEffects();
			
			hitCount = hitCount +1;
			if hitCount > maxTargets then break; end;
		end
	end
	
	
	function itemMod.NewFrostStack(npcModule, frostStack, damageSource, player)
		if frostStack == nil then return end;

		local frostMeta = {};
		frostMeta.__index = frostMeta;
		frostMeta.Player = player;
		frostMeta.NpcModule = npcModule;
		frostMeta.DamageSource = damageSource;
		frostMeta.Cache = {};
		setmetatable(frostStack, frostMeta);
		
		addDecor(npcModule.Prefab, frostStack);
		
		local cache = frostStack.Cache;
		frostMeta.UpdateEffects = function()
			if npcModule == nil or npcModule.IsDead then return end;
			
			local stackRatio = 1-math.clamp(frostStack.Stacks/maxStacks, 0, 0.9);
			local t = modMath.MapNum(stackRatio, 1, 0, 1, 0.3);

			if frostStack.CompleteTick then
				npcModule.SetTimescale(0);
			else
				npcModule.SetTimescale(stackRatio);
			end

			for a=1, #cache do
				local obj = cache[a];

				if obj.Name == "FrostTexture" then

					if frostStack.CompleteTick then
						obj.Transparency = t;
						obj.Color3 = Color3.fromRGB(255, 255, 255);

					else
						obj.Transparency = t;
						obj.Color3 = Color3.fromRGB(181, 235, 255);

					end


				elseif obj.Name == "IceDecor" then
					local targetFootVal = obj:FindFirstChild("TargetFoot") and obj.TargetFoot;
					if targetFootVal and targetFootVal.Value then
						local footPart = targetFootVal.Value;

						if frostStack.CompleteTick then
							obj.Size = footPart.Size*2;
						else
							obj.Size = footPart.Size*0;
						end

						obj.CFrame = CFrame.new(footPart.CFrame.Position + Vector3.new(0, -0.5, 0));
						obj.Parent = workspace.Debris;
					end

				end

			end
		end
		
		frostMeta.Destroy = function()
			if npcModule == nil or npcModule.IsDead then return end;
			
			for a=1, #cache do
				cache[a]:Destroy();
			end
			
			if npcModule.SetTimescale then
				npcModule.SetTimescale(1);
			end
			if npcModule.EntityStatus then
				npcModule.EntityStatus:Apply(statusKey, nil);
			end
		end;
		
		if table.find(activeStacks, frostStack) == nil then
			table.insert(activeStacks, frostStack);
		end
		
		task.spawn(itemMod.System);
	end
	
	function itemMod.ActivateMod(damageSource)
		local player = damageSource.Dealer;
		local weaponItem, weaponModel, toolModule = damageSource.ToolStorageItem, damageSource.ToolModel, damageSource.ToolModule;
		local targetModel, targetPart = damageSource.TargetModel, damageSource.TargetPart;
		local damage = damageSource.Damage;
		
		local propertiesOfMod = toolModule.Configurations.PropertiesOfMod;
		
		local maxTargets = propertiesOfMod.Targets;
		local maxRadius = propertiesOfMod.Radius;

		
		local damagable = modDamagable.NewDamagable(targetModel);
		if damagable == nil or not damagable:CanDamage(player) then return end;
		if damagable.Object.ClassName ~= "NpcStatus" then return end;

		local npcStatus = damagable.Object;
		local npcModule = npcStatus:GetModule();
		if npcModule == nil then return end;
		
		local targetImmunity = npcStatus:GetImmunity();
		if targetImmunity >= 1 then return end;
		
		local entityStatus = npcModule.EntityStatus;
		local isBasicEnemy = npcModule and npcModule.Properties and npcModule.Properties.BasicEnemy == true;

		local maxHealth = npcModule:GetHealth("MaxHealth", targetPart);
		local initSpeed = npcModule.Humanoid.WalkSpeed;
		
		local frostStack = entityStatus:GetOrDefault(statusKey);
		
		if frostStack == nil then
			frostStack = entityStatus:Apply(statusKey, {
				Stacks=1;

				InitialSpeed=initSpeed;
				SlowValue=initSpeed;

				LastStackTick=tick()-0.1;
				DamagePool=0;
			});
			
			itemMod.NewFrostStack(npcModule, frostStack, damageSource, player);
		end
		
		
		if frostStack == nil then return end;
		
		
		local percentPerStage = 0.01;
		local healthPerStage = maxHealth * percentPerStage;
		frostStack.DamagePool = frostStack.DamagePool + damage;
		
		if frostStack.DamagePool >= healthPerStage and tick() - frostStack.LastStackTick >= 0.1 and frostStack.CompleteTick == nil then
			frostStack.LastStackTick = tick();
			frostStack.DamagePool = 0;
			
			local addStack = math.clamp(math.floor(frostStack.DamagePool/healthPerStage), 1, 3);
			frostStack.Stacks = frostStack.Stacks +addStack;
			
			local stackRatio = 1-math.clamp(frostStack.Stacks/maxStacks, 0, 1); -- 1 to 0
			local slowedWalkSpeed = frostStack.InitialSpeed * stackRatio;

			frostStack.SlowValue = slowedWalkSpeed;

			if frostStack.Stacks >= maxStacks then
				frostStack.Hijacked = true;
				frostStack.CompleteTick = tick() + freezeDuration;
				
				task.delay(0.1, function()
					itemMod.IceBlast(frostStack, npcModule, {Targets=maxTargets; Radius=maxRadius;});
				end)
			end
			
			npcModule.StatusLogic();
			frostStack.UpdateEffects();
		end
	end
	
else
	
	
end

return itemMod;