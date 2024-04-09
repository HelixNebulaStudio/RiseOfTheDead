local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local Projectile = {ProjectileNum=0;};
local pool = {};

local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local CollectionService = game:GetService("CollectionService");

local modArcTracing = require(game.ReplicatedStorage.Library.ArcTracing);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

local dirRemotes = game.ReplicatedStorage.Remotes;
local bindIsInDuel = dirRemotes.IsInDuel;

local remoteSimulateProjectile = modRemotesManager:Get("SimulateProjectile");
local remoteClientProjectileHit = modRemotesManager:Get("ClientProjectileHit");

--== Script;

function Projectile.Get(projectileId)
	local projectilePool = pool[projectileId];
	if projectilePool == nil then projectilePool = Projectile.Load(projectileId) end;
	
	local projectileObject = Projectile.New(projectileId);
	return projectileObject;
end

function Projectile.Fire(projectileId, origin, rotation, spreadedDirection, owner, weaponModule)
	local projectilePool = pool[projectileId];
	if projectilePool == nil then projectilePool = Projectile.Load(projectileId) end;
	
	local projectileObject = Projectile.New(projectileId);
	projectileObject:Init(owner, weaponModule);
	projectileObject.Id = projectileId;
	projectileObject.Owner = owner;
	
	local projectilePrefab = projectileObject.Prefab;
	CollectionService:AddTag(projectilePrefab, "Projectile");
	
	if projectileObject.Load then 
		projectileObject:Load();
	end;
	
	local arcTracer = modArcTracing.new();
	projectileObject.ArcTracer = arcTracer;
	
	for k, v in pairs(projectileObject.ArcTracerConfig) do
		arcTracer[k] = v;
	end
	
	if projectileObject.WeaponModule and projectileObject.WeaponModule.ArcTracerConfig then
		for k, v in pairs(projectileObject.WeaponModule.ArcTracerConfig) do
			arcTracer[k] = v;
		end
	end
	
	projectilePrefab.Anchored = false;
	projectilePrefab.CFrame = origin;
	projectilePrefab.Orientation = rotation or Vector3.new();
	if spreadedDirection then
		projectilePrefab.Velocity = spreadedDirection * (arcTracer.Velocity or 50);
	end
	projectilePrefab.Parent = workspace.Entities;
	
	local despawnTime = arcTracer.LifeTime or 10;
	projectilePrefab:SetAttribute("DespawnTime", tick()+despawnTime);
	
	local function despawn()
		local despawnTick = projectilePrefab:GetAttribute("DespawnTime");
		despawnTick = despawnTick and despawnTick-0.1 or nil;
		
		if despawnTick == nil or (tick() >= despawnTick) then
			Debugger.Expire(projectilePrefab);
			if projectileObject.Destroy then
				projectileObject:Destroy();
			end
			
		else
			task.delay(despawnTick-tick(), despawn);
			
		end
	end
	
	task.delay(despawnTime, despawn);
	
	if projectileObject.Activate then 
		task.spawn(function()
			projectileObject:Activate();
		end)
	end;
	
	if RunService:IsClient() then
		Projectile.ProjectileNum = Projectile.ProjectileNum + 1;
		projectileObject.ClientProjNum = Projectile.ProjectileNum;
	end
	return projectileObject;
end


function Projectile.Simulate(projectile, origin, velocity, rayWhitelist)
	local player = projectile.Owner;
	local prefab = projectile.Prefab;
	local arcTracer =  projectile.ArcTracer or modArcTracing.new();
	
	if rayWhitelist then
		arcTracer.RayWhitelist = rayWhitelist;
	end
	
	if arcTracer.IgnoreEntities ~= true then
		table.insert(arcTracer.RayWhitelist, workspace.Entity);
		
		local charactersList = CollectionService:GetTagged("PlayerCharacters");
		if charactersList then 
			for a=1, #charactersList do
				if player == nil or not player:IsA("Player") then
					table.insert(arcTracer.RayWhitelist, charactersList[a]);
					
				elseif player:IsA("Player") and charactersList[a] ~= player.Character then
					table.insert(arcTracer.RayWhitelist, charactersList[a]);
					
				end
			end
		end
	end
	
	local arcPoints;
	
	local projHitConn; 
	if projectile.TrustClientProjectile then
		projHitConn = remoteClientProjectileHit.OnServerEvent:Connect(function(client, projNum, arcPoint)
			for k, v in pairs(arcPoint) do
				if not rawequal(v, v) then
					Debugger:Warn("Dropping illegal remoteClientProjectileHit input.");
					return;
				end
			end
			
			if player == client and projectile.ServerProjNum == projNum then
				arcPoint.Client = true;
				projectile:OnContact(arcPoint);
			end
		end)
	end
	
	arcPoints = arcTracer:GeneratePath(origin, velocity);
	
	prefab:SetAttribute("SyncMotion", true);
	
	arcTracer:FollowPath(arcPoints, prefab, false, function(arcPoint)
		arcPoint:Recast();
		if projectile.OnStepped then
			projectile:OnStepped(arcPoint);
		end
		if (arcPoint.Hit or arcPoint.LastPoint) and projectile.OnContact then
			return projectile:OnContact(arcPoint);
		end
		
	end, function()
		prefab:SetAttribute("SyncMotion");
		if projectile.OnComplete then
			projectile:OnComplete();
		end
		if projHitConn then projHitConn:Disconnect(); end;
	end)
	
	
	local players = game.Players:GetPlayers();
	for a=1, #players do
		if players[a] ~= player then
			remoteSimulateProjectile:FireClient(players[a], prefab);
		end
	end
end

function Projectile.ClientSimulate(projectile, arcTracer, arcPoints, prefab)
	local prefab = projectile.Prefab;
	
	arcTracer:FollowPath(arcPoints, prefab, true, function(arcPoint)
		if projectile.OnStepped then
			projectile:OnStepped(arcPoint);
		end
		if (arcPoint.Hit or arcPoint.LastPoint) then
			if projectile.OnContact then
				task.spawn(function()
					if arcPoint.Hit == nil then return end;
					
					local modInterface = require(game.Players.LocalPlayer.PlayerGui:WaitForChild("MainInterface"):WaitForChild("InterfaceModule"));
					modInterface.modEntityHealthHudInterface.TryHookEntity(arcPoint.Hit.Parent);
				end)
				
				if projectile.TrustClientProjectile then
					remoteClientProjectileHit:FireServer(projectile.ClientProjNum, arcPoint);
				end
				return projectile:OnContact(arcPoint, arcTracer);
			end
		end
	end, function()
		if projectile.OnComplete then
			projectile:OnComplete();
		end
	end);
end

function Projectile.ServerSimulate(projectile, origin, velocity, rayWhitelist)
	local player = projectile.Owner;
	local prefab = projectile.Prefab;
	local arcTracer = projectile.ArcTracer or modArcTracing.new();

	if rayWhitelist then
		arcTracer.RayWhitelist = rayWhitelist;
	end
	
	if arcTracer.IgnoreEntities ~= true then
		table.insert(arcTracer.RayWhitelist, workspace.Entity);
		
		local charactersList = CollectionService:GetTagged("PlayerCharacters");
		if charactersList then 
			for a=1, #charactersList do
				if player == nil or not player:IsA("Player") then
					table.insert(arcTracer.RayWhitelist, charactersList[a]);
					
				elseif player:IsA("Player") and charactersList[a] ~= player.Character then
					table.insert(arcTracer.RayWhitelist, charactersList[a]);
					
				end
			end
		end
		
	end
	
	if arcTracer.AddIncludeTags then
		for _, tagId in pairs(arcTracer.AddIncludeTags) do
			local list = CollectionService:GetTagged(tagId);
			for a=1, #list do
				table.insert(arcTracer.RayWhitelist, list[a]);
			end
		end
	end
	
	local delta = arcTracer.Delta or 1/15;
	task.spawn(function()
		local tweenInfo = TweenInfo.new(delta+0.01, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0);
		prefab.Anchored = true;
		local spinCf = CFrame.new();
		
		--arcTracer.DebugArc = true;
		arcTracer:GeneratePath(origin, velocity, function(arcPoint)
			prefab.CFrame = CFrame.new(arcPoint.Origin, arcPoint.Origin + arcPoint.Direction) * spinCf;
			
			if arcTracer.AirSpin then
				spinCf = spinCf * CFrame.Angles(arcTracer.AirSpin, 0, 0);
			end;
			
			TweenService:Create(prefab, tweenInfo, {Position=arcPoint.Point;}):Play();

			if arcTracer.OnStepped then
				arcTracer.OnStepped(projectile, arcPoint);
			end
			if projectile.OnStepped then
				projectile:OnStepped(arcPoint);
			end
			if (arcPoint.Hit or arcPoint.LastPoint) and projectile.OnContact then
				return projectile:OnContact(arcPoint, arcTracer);
			end
			task.wait(delta);
		end);
		if projectile.OnComplete then
			projectile:OnComplete();
		end
	end)
	
end

if RunService:IsClient() then
	local delta = 1/15;
	local tweenInfo = TweenInfo.new(delta+0.01);
	
	remoteSimulateProjectile.OnClientEvent:Connect(function(projectilePrefab)
		if projectilePrefab then
			task.spawn(function()
				local dummyProjectile = projectilePrefab:Clone();
				
				local parentConn;
				parentConn = projectilePrefab:GetPropertyChangedSignal("Parent"):Connect(function()
					if projectilePrefab.Parent == nil then
						Debugger.Expire(dummyProjectile);
						parentConn:Disconnect();
					end
				end)
				
				dummyProjectile.Name = "client"..dummyProjectile.Name;
				dummyProjectile.Parent = workspace.Entities;
				
				local initTransparency = projectilePrefab.Transparency;
				projectilePrefab.Transparency = 1;
				
				for _, obj in pairs(projectilePrefab:GetDescendants()) do
					if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
						obj.Enabled = false;
					end
				end
				
				while projectilePrefab:GetAttribute("SyncMotion") and projectilePrefab:IsDescendantOf(workspace) do
					TweenService:Create(dummyProjectile, tweenInfo, {
						Position=projectilePrefab.Position;
						Orientation=projectilePrefab.Orientation;
					}):Play();
					task.wait(delta);
				end
				dummyProjectile.Transparency = 1;
				projectilePrefab.Transparency = initTransparency;
			end);
		end
	end)
	
end

function Projectile.New(projectileId)
	if pool[projectileId] == nil then Projectile.Load(projectileId) end;
	local projectilePool = pool[projectileId];
	if #pool[projectileId]-2 <= 0 then
		local newProjectile = projectilePool.new();
		newProjectile.Cache = {};
		table.insert(pool[projectileId], newProjectile);
	end;
	
	local newProjectile = pool[projectileId][1];
	table.remove(pool[projectileId], 1);
	return newProjectile;
end

function Projectile.Load(projectileId)
	if script:FindFirstChild(projectileId) == nil then Debugger:Warn("ProjectileId(",projectileId,") does not exist."); return end;
	if pool[projectileId] == nil then
		pool[projectileId] = setmetatable({}, require(script[projectileId]));
	end;
	if #pool[projectileId] > 0 then return end;
	
	local newProjectile = pool[projectileId].new();
	newProjectile.Cache = {};
	table.insert(pool[projectileId], newProjectile);
	return pool[projectileId];
end


local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetModule(script.Name);
if moddedSelf then moddedSelf:Init(Projectile, script); end

return Projectile;