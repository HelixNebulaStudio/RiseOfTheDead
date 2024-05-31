local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Npc = {};

--== Script;
local CollectionService = game:GetService("CollectionService");
local RunService = game:GetService("RunService");

local modGlobalVars = require(game.ReplicatedStorage.GlobalVariables);
local modNpcAnimator = require(game.ServerScriptService.ServerLibrary.Entity.NpcAnimator);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

local modNpcModules = {};
for _, npcMod in pairs(game.ServerScriptService.ServerLibrary.Entity.Npc:GetChildren()) do
	if npcMod:IsA("ModuleScript") then
		modNpcModules[npcMod.Name] = Debugger:Require(npcMod);
	end;
end;

local function searchCustom(t, k)
	local npcMod = game.ServerStorage.PrefabStorage.CustomNpcModules:FindFirstChild(k); 
	if npcMod then
		modNpcModules[npcMod.Name] = Debugger:Require(npcMod);
		return modNpcModules[npcMod.Name];
	end
	return;
end
setmetatable(modNpcModules, {__index=searchCustom});

local npcStatusModulePrefab = game.ServerScriptService.ServerLibrary.Entity.NpcStatus;

local parallelNpcTemplate = script.Parent:WaitForChild("ParallelNpc");
local npcPrefabs = game.ServerStorage.PrefabStorage.Npc;

local idCounter = 1;

local bindSpawn = Instance.new("BindableFunction");
bindSpawn.Name = "SpawnNpc";
bindSpawn.Parent = script;

Npc.NpcBaseModules = modNpcModules;
Npc.NpcModules = {} :: {{Module:modNpcComponent.NpcModule; Prefab:Actor|Model}};
Npc.PlayerNpcs = {};

Npc.OnNpcSpawn = modEventSignal.new("OnNpcSpawn");
Npc.GarbageModules = {};

local npcPrefabsList = npcPrefabs:GetChildren();
for a=1, #npcPrefabsList do
	
	local function updatePrefab(prefab)
		local humanoidInstance = prefab:FindFirstChildWhichIsA("Humanoid");

		if modBranchConfigs.IsWorld("TheInvestigation") then
			if prefab.Name == "Robert" then
				humanoidInstance.Name = "Zombie";
			end
		end

		if humanoidInstance.Name == "Human" then
			for _, obj in next, prefab:GetDescendants() do

				if obj:IsA("BasePart") then
					obj.CollisionGroup = "Characters";

				end
			end

		elseif humanoidInstance.Name == "Zombie" or humanoidInstance.Name == "Bandit" or humanoidInstance.Name == "Cultist" then
			for _, obj in next, prefab:GetDescendants() do
				if obj:IsA("BasePart") then
					obj.CollisionGroup = "EnemiesSpawn";
				end
			end

		end
	end
	
	if npcPrefabsList[a]:IsA("Folder") then 
		local variants = npcPrefabsList[a]:GetChildren();
		
		for _, prefab in pairs(variants) do
			updatePrefab(prefab);
			prefab:SetAttribute("Variant",prefab.Name);
			prefab.Name = npcPrefabsList[a].Name;
		end
		
		continue;
	end;
	
	updatePrefab(npcPrefabsList[a]);
end
npcPrefabsList = nil;



local prefabCache = {};
function Npc.GetNpcPrefab(name)
	if prefabCache[name] then return prefabCache[name] end;
	if npcPrefabs:FindFirstChild(name) == nil then Debugger:Warn("Npc prefab: "..name.." does not exist."); end;

	local prefab = npcPrefabs[name];
	if prefab:IsA("Folder") then
		local refPrefabName = prefab:GetAttribute("Prefab");
		if refPrefabName == nil then
			local prefabsList = prefab:GetChildren();
			return prefabsList[math.random(1, #prefabsList)];
			
		elseif npcPrefabs:FindFirstChild(refPrefabName) == nil then
			Debugger:Warn("Npc prefab: "..refPrefabName.." does not exist."); 
			
		else
			prefab = npcPrefabs[refPrefabName];
			
		end;
	end
	
	prefabCache[name] = prefab;
	
	return prefabCache[name];
end

Npc.GetPlayerNpc = function(player, name, condition)
	for a=#Npc.PlayerNpcs, 1, -1 do
		local npcModule = Npc.PlayerNpcs[a] and Npc.PlayerNpcs[a].Module;
		if npcModule and npcModule.Name == name and npcModule.Owner == player then
			
			if condition == nil or condition(npcModule) == true then
				return npcModule;
			end
		end
	end
	return;
end

Npc.GetPlayerNpcList = function(player) : {modNpcComponent.NpcModule}
	local list: {modNpcComponent.NpcModule} = {};
	for a=#Npc.PlayerNpcs, 1, -1 do
		local npcModule = Npc.PlayerNpcs[a] and Npc.PlayerNpcs[a].Module;
		if npcModule and npcModule.Owner == player then
			table.insert(list, npcModule);
		end
	end

	return list;
end

Npc.GetNpcModule = function(prefab) : modNpcComponent.NpcModule?
	local npcStatus = prefab:FindFirstChild("NpcStatus") and require(prefab.NpcStatus);
	if npcStatus then
		return npcStatus:GetModule();
	end
	
	for a=#Npc.NpcModules, 1, -1  do
		local npcModule = Npc.NpcModules[a] and Npc.NpcModules[a].Module;
		if npcModule and Npc.NpcModules[a].Prefab == prefab then
			return npcModule;
		end;
	end
	return;
end

Npc.Get = function(id) : modNpcComponent.NpcModule?
	for a=#Npc.NpcModules, 1, -1  do
		local npcModule = Npc.NpcModules[a] and Npc.NpcModules[a].Module;
		if npcModule and npcModule.Id == id then
			return npcModule;
		end;
	end
	return;
end

--[[
	Npc.ListEntities()
	
	@param name string  Prefab of npc.
	@param func? (npcModule)-> boolean Match function, return true to match. `nil` defaults as if func returns true.

	@returns {modNpcComponent.NpcModule} List of npcModules.
]]
function Npc.ListEntities(name: string, func: ((modNpcComponent.NpcModule)->boolean)?) : {modNpcComponent.NpcModule}
	local list = {};

	for a=1, #Npc.NpcModules do
		local aNpcModule = Npc.NpcModules[a] and Npc.NpcModules[a].Module;
		if aNpcModule.Name == name then
			table.insert(list, aNpcModule);

		elseif func ~= nil and func(aNpcModule) == true then
			table.insert(list, aNpcModule);
		end
	end

	return list;
end

local npcScanOverlapParam = OverlapParams.new();
npcScanOverlapParam.FilterType = Enum.RaycastFilterType.Include;

local function onEntityRootPartChanged()
	npcScanOverlapParam.FilterDescendantsInstances = CollectionService:GetTagged("EntityRootPart");
end
CollectionService:GetInstanceAddedSignal("EntityRootPart"):Connect(onEntityRootPartChanged);

function Npc.EntityScan(origin, radius, maxRootpart) : {[number]: modNpcComponent.NpcModule}
	local scannedTargets = {};
	if radius <= 0 then return scannedTargets; end;
	
	npcScanOverlapParam.MaxParts = maxRootpart or 32;
	
	local targets = workspace:GetPartBoundsInRadius(origin, radius, npcScanOverlapParam);
	
	for a=1, #targets do
		local targetEntity = targets[a].Parent;
		if targetEntity then
			local npcModule = Npc.GetNpcModule(targetEntity);
			if npcModule and npcModule.IgnoreScan ~= true then
				table.insert(scannedTargets, npcModule);
			end
		end
	end
	
	return scannedTargets;
end

--[[
	Npc.AttractEnemies()
	
	@param character <Model> Prefab of npc.
	@param range Range of detection.
	@param func `(npcModule)->boolean?` Match function, return true to attract. Defaultly returns true.

	@return List of npc prefab models.
]]
Npc.AttractEnemies = function(character: Model, range: number, func: ((npcModule: modNpcComponent.NpcModule)-> boolean)? ): {[number]: Model | Actor}
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid") or nil;
	local primaryPart = character and character.PrimaryPart or nil;
	local forcefield = character and character:FindFirstChildWhichIsA("ForceField") or nil;
	
	local enemies = {};
	if primaryPart and humanoid.Health > 0 then
		local scanEntities = Npc.EntityScan(primaryPart.CFrame.Position, range);
		
		for a=1, #scanEntities do
			local npcModule = scanEntities[a];
			if npcModule and not npcModule.IsDead then
				
				if func == nil or func(npcModule) == true then
					
					local player = game.Players:GetPlayerFromCharacter(character);
					if player then
						if npcModule.NetworkOwners then
							if table.find(npcModule.NetworkOwners, player) == nil then
								continue;
							end
						end
						
						npcModule:LoadClientScript(player);
						
					end
					
					if forcefield == nil or forcefield.Name == "ForcefieldStatus" or npcModule.Target == character then -- ForcefieldStatus is power up;
						if npcModule.OnTarget then
							npcModule.OnTarget(character);
						end
					end

					npcModule.Think:Fire();

					table.insert(enemies, npcModule.Prefab);
				end
			end;
		end
	end
	
	return enemies;
end

--[[**
	Spawns a NPC of name.
	@param name <String> Name of the NPC.
	@param cframe <CFrame> Spawn location of NPC.
	@param preloadCallback <Function> Function(Model npc, NpcModule npcModule) called after NPC Module has been loaded.
	@param customNpcModule <NpcModule:Object> Load in a custom NPC Module for the NPC.
	@return Model npc Returns NPC's character model.
**--]]
Npc.DoSpawn = function (name, cframe, preloadCallback, customNpcModule)
	if name == "Ticks Zombie" then
		name = "Ticks";
	end
	if name == "Leaper Zombie" then
		name = "Leaper";
	end
	if name == "Heavy Zombie" then
		name = "Heavy";
	end
	
	local basePrefab = Npc.GetNpcPrefab(name);
	if basePrefab == nil then return end;
	
	local npcPrefab: Actor = basePrefab:Clone();
	npcPrefab.ModelStreamingMode = Enum.ModelStreamingMode.PersistentPerPlayer;
	npcPrefab.Name = name;
	
	local rootPart = npcPrefab:WaitForChild("HumanoidRootPart");
	rootPart:SetAttribute("IgnoreWeaponRay", true);
	
	cframe = cframe or rootPart.CFrame;
	npcPrefab:PivotTo(cframe);
	
	
	local npcModule;
	if customNpcModule then
		npcModule = customNpcModule(npcPrefab, cframe);
	elseif modNpcModules[name] then
		npcModule = modNpcModules[name](npcPrefab, cframe);
	else
		npcModule = Npc.NpcBaseModules.BasicNpcModule(npcPrefab, cframe);
	end

	local npcModuleMeta = getmetatable(npcModule);
	npcModuleMeta.NpcService = Npc;
	
	
	local strongRef = {Prefab=npcPrefab; Module=npcModule;};
	table.insert(Npc.NpcModules, strongRef);
	script:SetAttribute("ActiveNpcs", #Npc.NpcModules);
	
	npcModule.Id = idCounter;
	npcPrefab:SetAttribute("EntityId", npcModule.Id);
	idCounter = idCounter +1;
	
	npcModule.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false);
	npcModule.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false);
	npcModule.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false);
	npcModule.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false);
	
	npcModule.SpawnTime = tick();
	npcModule.SpawnPoint = cframe;
	
	
	local npcStatusModule = npcStatusModulePrefab:Clone();
	npcStatusModule.Parent = npcPrefab;
	
	if basePrefab:FindFirstChild("Interactable") then
		npcModule.Interactable = npcPrefab:WaitForChild("Interactable");
		
	end

	if npcPrefab:IsA("Actor") then
		local newParallelHandler = parallelNpcTemplate:Clone();
		newParallelHandler.Parent = npcPrefab;
		
		npcModule.Remote = newParallelHandler:WaitForChild("NpcRemote");
		
		npcModule.ActorEvent.Event:Connect(function(action, ...)
			if action == "init" then 
				local pNpc = ...;
				npcModule.ParallelNpc = pNpc;
				return;
			end;

			if npcModule == nil or npcModule.IsDead then return end;

			--if action == "moveToEnded" then
			--	npcModule.Move.IsMoving = false;
			--	npcModule.Move.MoveToEnded:Fire(...);
				
			--end
		end)
		
		local bindActor: BindableFunction = Instance.new("BindableFunction");
		bindActor.Name = "ActorBind";
		bindActor.Parent = npcPrefab;
		npcModule.Bind = bindActor;

		newParallelHandler.Enabled = true;
		
	else
		npcModule.Remote = script.Parent:WaitForChild("OldNpcRemote");
		
	end
	
	task.spawn(function()
		task.wait(0.1);
		
		local rightArm: BasePart = npcPrefab:FindFirstChild("RightUpperArm") :: BasePart;
		local rightHand: BasePart = npcPrefab:FindFirstChild("RightHand") :: BasePart;
		local rightPoint: BasePart = npcPrefab:FindFirstChild("RightPoint") :: BasePart;
		if rightArm and rightHand and rightPoint then
			local middle: BasePart = npcPrefab:FindFirstChild("RightMiddle") :: BasePart;
			local pinky: BasePart = npcPrefab:FindFirstChild("RightPinky") :: BasePart;

			local function updateHand()
				rightPoint.Color = rightArm.Color;
				middle.Color = rightArm.Color;
				pinky.Color = rightArm.Color;

				rightPoint.Transparency = rightHand.Transparency;
				middle.Transparency = rightHand.Transparency;
				pinky.Transparency = rightHand.Transparency;
			end
			rightArm:GetPropertyChangedSignal("Color"):Connect(updateHand);
			rightHand:GetPropertyChangedSignal("Transparency"):Connect(updateHand);
			updateHand()
		end

		local leftArm: BasePart = npcPrefab:FindFirstChild("LeftUpperArm") :: BasePart;
		local leftHand: BasePart = npcPrefab:FindFirstChild("LeftHand") :: BasePart;
		local leftPoint: BasePart = npcPrefab:FindFirstChild("LeftPoint") :: BasePart;
		if leftArm and leftHand and leftPoint then
			local middle: BasePart = npcPrefab:FindFirstChild("LeftMiddle") :: BasePart;
			local pinky: BasePart = npcPrefab:FindFirstChild("LeftPinky") :: BasePart;

			local function updateHand()
				leftPoint.Color = leftArm.Color;
				middle.Color = leftArm.Color;
				pinky.Color = leftArm.Color;

				leftPoint.Transparency = leftHand.Transparency;
				middle.Transparency = leftHand.Transparency;
				pinky.Transparency = leftHand.Transparency;
			end
			leftArm:GetPropertyChangedSignal("Color"):Connect(updateHand);
			leftHand:GetPropertyChangedSignal("Transparency"):Connect(updateHand);
			updateHand()
		end
	end)
	
	task.spawn(function()
		local modNpcStatus = require(npcStatusModule);
		modNpcStatus:Initialize(npcModule);
		
		npcModule.Status = modNpcStatus;
	end)
	
	if preloadCallback then 
		preloadCallback(npcPrefab, npcModule :: modNpcComponent.NpcModule);
		task.spawn(function()
			Npc.OnNpcSpawn:Fire(npcModule);

			if npcModule.SetShirt then
				local shirt = npcPrefab:FindFirstChildWhichIsA("Shirt");
				if shirt then
					shirt.ShirtTemplate = npcModule.SetShirt;
				end
			end
			if npcModule.SetPants then
				local pants = npcPrefab:FindFirstChildWhichIsA("Pants");
				if pants then
					pants.PantsTemplate = npcModule.SetPants;
				end
			end
		end)
	end;
	
	if npcModule.Interactable == nil then
		if basePrefab:FindFirstChild("Interactable") then
			npcModule.Interactable = npcPrefab:WaitForChild("Interactable");
		end
	end
	
	if npcModule.Owner then
		table.insert(Npc.PlayerNpcs, strongRef);
		npcPrefab:AddPersistentPlayer(npcModule.Owner);
	end
	npcPrefab.Parent = workspace.Entity;
	
	npcModule:SetNetworkOwner(nil);
	
	npcModule.Garbage:Tag(npcModule.Humanoid.Died:Connect(function()
		if npcModule == nil then return end;
		npcModule.IsDead = true;
	end));
	npcModule.Garbage:Tag(npcPrefab.ChildRemoved:Connect(function(child)
		if child.Name ~= "HumanoidRootPart" then return end;
		if npcModule == nil then return end;
		npcModule:KillNpc();
	end))
	npcModule.Garbage:Tag(npcPrefab.Destroying:Connect(function()
		if npcModule == nil then return end;
		npcModule:KillNpc();
	end));
	if RunService:IsStudio() then
		npcModule.Garbage:Tag(npcPrefab.AncestryChanged:Connect(function()
			if npcPrefab.Parent ~= nil then return end;
			if npcModule == nil then return end;
			
			npcModule:KillNpc();
		end));
	end
	
	if modConfigurations.TargetableEntities[npcModule.Humanoid.Name] then
		CollectionService:AddTag(npcPrefab, "TargetableEntities");
		CollectionService:AddTag(npcPrefab:WaitForChild("HumanoidRootPart"), "Enemies");
	end
	if npcModule.Humanoid.Name == "Zombie" then
		CollectionService:AddTag(npcPrefab, "Zombies");
		
	elseif npcModule.Humanoid.Name == "Human" then
		CollectionService:AddTag(npcPrefab, "Humans");
		
	elseif npcModule.Humanoid.Name == "Bandit" then
		CollectionService:AddTag(npcPrefab, "Bandits");
		
	elseif npcModule.Humanoid.Name == "Cultist" then
		CollectionService:AddTag(npcPrefab, "Cultists");

	elseif npcModule.Humanoid.Name == "Rat" then
		CollectionService:AddTag(npcPrefab, "Rats");
		
	end
	
	if npcModule.Humanoid.Name == "Zombie" or npcModule.Humanoid.Name == "Bandit" or npcModule.Humanoid.Name == "Cultist" or npcModule.Humanoid.Name == "Rats" then
		task.delay(2, function()
			for _, obj in pairs(npcPrefab:GetDescendants()) do
				if obj:IsA("BasePart") and obj:IsDescendantOf(workspace) and obj.CollisionGroup == "EnemiesSpawn" then
					obj.CollisionGroup = "Enemies";
				end
			end
		end)
	end
	
	CollectionService:AddTag(rootPart, "EntityRootPart");

	modNpcAnimator(npcModule);
	if npcModule.BaseArmor then
		npcModule:AddComponent("ArmorSystem");
	end
	
	if npcModule.Initialize then
		task.defer(function()
			local key = string.gsub(name, " ", "");
			key = string.gsub(key, "%.", "");

			Npc.GarbageModules[name] = (Npc.GarbageModules[name] or 0) +1;
			script:SetAttribute(key, Npc.GarbageModules[name]);
			
			npcModule.InitializeThread = coroutine.running();
			
			npcModule:LoadClientScript(game.Players:GetPlayers());
			npcModule.Initialize();
			
			local despawnPrefab = npcModule.DespawnPrefab;
			if despawnPrefab then
				game.Debris:AddItem(npcPrefab, despawnPrefab);
			end
			
			local autoRespawn = npcModule.AutoRespawn;
			
			task.spawn(function()
				local t=setmetatable({npcModule},{__mode='v'});
				local garbageTick = tick();
				
				repeat
					task.wait(10) 
					if tick()-garbageTick >= 300 then
						break;
					end
				until t[1] == nil;
				
				if t[1] == nil then
					Npc.GarbageModules[name] = (Npc.GarbageModules[name] or 0) -1;
					script:SetAttribute(key, Npc.GarbageModules[name]);
					
				else
					local memSize = #game:GetService("HttpService"):JSONEncode(t[1]);
					if memSize >= 1024 then
						modAnalytics:ReportError("Npc Memory Leak", name, "warning");

						task.spawn(function()
							modGlobalVars.DeepClearTable(t[1]);
						end)
					end
				end
				
				--for k,v in pairs(game.ServerScriptService.ServerLibrary.Entity.Npc:GetAttributes()) do
				--	print(k,v);
				--end
			end)
			
			CollectionService:RemoveTag(rootPart, "EntityRootPart");
			npcModule:Destroy();
			script:SetAttribute("ActiveNpcs", #Npc.NpcModules);
			
			for a=#Npc.NpcModules, 1, -1 do
				if Npc.NpcModules[a] == strongRef then
					table.remove(Npc.NpcModules, a);
				end
			end
			
			for a=#Npc.PlayerNpcs, 1, -1 do
				if Npc.PlayerNpcs[a] == strongRef then
					table.remove(Npc.PlayerNpcs, a);
				end
			end
			
			npcModule = nil; -- IMPORTANT Need to clear strong ref;
			table.clear(strongRef);
			
			if autoRespawn then task.spawn(autoRespawn, name) end;
		end)
		
	end;
	
	return npcPrefab;
end

local templateSpawnSrc = game.ServerScriptService.ServerScripts:WaitForChild("NpcEngine");
Npc.Spawn = function(name: string, cframe: CFrame?, preloadCallback: (prefab: (Model | Actor), npcModule: modNpcComponent.NpcModule) -> (Model | Actor), customNpcModule)
	if RunService:IsStudio() then
		return Npc.DoSpawn(name, cframe, preloadCallback, customNpcModule);
	else
		return templateSpawnSrc.Function:Invoke(name, cframe, preloadCallback, customNpcModule);
	end
end

function Npc.GetCFrameFromPlatform(platform)
	local worldSpaceSize = platform.CFrame:vectorToWorldSpace(platform.Size);
	worldSpaceSize = Vector3.new(math.abs(worldSpaceSize.X), math.abs(worldSpaceSize.Y), math.abs(worldSpaceSize.Z));
		
	local pointMin = Vector3.new(platform.Position.X-worldSpaceSize.X/2, platform.Position.Y+worldSpaceSize.Y/2, platform.Position.Z-worldSpaceSize.Z/2);
	local pointMax = Vector3.new(platform.Position.X+worldSpaceSize.X/2, platform.Position.Y+worldSpaceSize.Y/2, platform.Position.Z+worldSpaceSize.Z/2);
	
	return CFrame.new(
		Vector3.new(
			math.random(pointMin.X *100, pointMax.X *100)/100, 
			pointMin.Y+2.1, 
			math.random(pointMin.Z *100, pointMax.Z *100)/100
		)
	) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);	
end

function Npc.init(entity)
	setmetatable(Npc, entity);
end


workspace:WaitForChild("Entity").ChildRemoved:Connect(function(child)
	for a=#Npc.NpcModules, 1, -1 do
		if Npc.NpcModules[a] and Npc.NpcModules[a].Prefab == child and not child:IsDescendantOf(workspace.Entity) then
			table.remove(Npc.NpcModules, a);
			break;
		end;
	end
	for a=#Npc.PlayerNpcs, 1, -1 do
		if Npc.PlayerNpcs[a] and Npc.PlayerNpcs[a].Prefab == child and not child:IsDescendantOf(workspace.Entity) then
			table.remove(Npc.PlayerNpcs, a);
			break;
		end;
	end
end)


task.spawn(function()
	while true do
		for a=#Npc.NpcModules, 1, -1 do
			local npcModule = Npc.NpcModules[a] and Npc.NpcModules[a].Module;

			if npcModule and npcModule.IsDead ~= true then
				local fireThinkS, _fireThinkE = pcall(function()
					Npc.NpcModules[a].Module.Think:Fire();
				end);
				if not fireThinkS then
					Debugger:Warn("Failed to think", Npc.NpcModules[a].Module.Name);
				end;
			end;

		end

		task.wait(modConfigurations.NpcThinkCycle or 15);
	end
end)

Npc.Script = script;
return Npc;