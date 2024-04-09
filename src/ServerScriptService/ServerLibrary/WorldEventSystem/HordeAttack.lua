local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local WorldEventSystem = {};
local HordeAttack = {}
local AttackLocations = {};
local LocationsList = {};

local RunService = game:GetService("RunService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modPlayers = require(game.ReplicatedStorage.Library.Players);

local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);

local remoteHudNotification = modRemotesManager:Get("HudNotification");

local HordeTypes = {
	["Zombie"]="Zombie";
}

local random = Random.new();
--==
function HordeAttack.Initialize(worldEventSystem)
	if workspace:FindFirstChild("HordeAttack") == nil then return false; end;
	
	WorldEventSystem = worldEventSystem;
	for _, locationPart in pairs(workspace.HordeAttack:GetChildren()) do
		if AttackLocations[locationPart.Name] == nil then
			AttackLocations[locationPart.Name] = {Regions={};}
			table.insert(LocationsList, locationPart.Name);
		end;
		local locationInfo = AttackLocations[locationPart.Name];
		
		local worldSpaceSize = locationPart.CFrame:vectorToWorldSpace(locationPart.Size);
		worldSpaceSize = Vector3.new(math.abs(worldSpaceSize.X), math.abs(worldSpaceSize.Y), math.abs(worldSpaceSize.Z));
		
		local pointMin = Vector3.new(locationPart.Position.X-worldSpaceSize.X/2,
			locationPart.Position.Y-worldSpaceSize.Y/2,
			locationPart.Position.Z-worldSpaceSize.Z/2);
		local pointMax = Vector3.new(locationPart.Position.X+worldSpaceSize.X/2,
			locationPart.Position.Y+worldSpaceSize.Y/2,
			locationPart.Position.Z+worldSpaceSize.Z/2);
		
		table.insert(locationInfo.Regions, {Min=pointMin; Max=pointMax;});
		locationPart:Destroy();
	end
	return true;
end

function HordeAttack.Start()
	WorldEventSystem.NextEventTick = os.time()+random:NextNumber(1600, 1800);
	
	local safehouse = LocationsList[random:NextInteger(1, #LocationsList)];
	if safehouse == nil then return end;
	
	local locationInfo = AttackLocations[safehouse];
	remoteHudNotification:FireAllClients("HordeAttack", {Name=safehouse});
	shared.Notify(game.Players:GetPlayers(), "There will be a Horde Attack at the "..safehouse.."!", "Defeated");
	shared.Notify(game.Players:GetPlayers(), "Hordes will have a chance to drop special loot..", "Defeated");

	local zombies = 0;
	local function UpdateNpc(npcModule)
		if npcModule == nil then return end;
		if HordeTypes[npcModule.Name] == nil then return end;

		if npcModule.FakeSpawnPoint then
			return
		end
		
		local randomRegion = locationInfo.Regions[random:NextInteger(1, #locationInfo.Regions)];
		local randomPoint = Vector3.new(
			random:NextNumber(randomRegion.Min.X, randomRegion.Max.X),
			randomRegion.Max.Y,
			random:NextNumber(randomRegion.Min.Z, randomRegion.Max.Z));

		local groundRay = Ray.new(randomPoint, Vector3.new(0, -20, 0));
		local groundHit, groundPoint = workspace:FindPartOnRayWithWhitelist(groundRay, {workspace.Environment; workspace.Terrain}, true);
		
		if groundHit == nil then return end;
		
		npcModule.FakeSpawnPoint = CFrame.new(groundPoint);
		
		npcModule.Configuration.DefaultResourceDrop = npcModule.Configuration.ResourceDrop;
		npcModule.Configuration.ResourceDrop = modGlobalVars.CloneTable(npcModule.Configuration.DefaultResourceDrop);
		
		table.insert(npcModule.Configuration.ResourceDrop.Rewards, 
			{Type=modGlobalVars.ItemDropsTypes.Blueprint; ItemId="scarecrowbp"; Chance=1/10;});
		table.insert(npcModule.Configuration.ResourceDrop.Rewards, 
			{Type=modGlobalVars.ItemDropsTypes.Blueprint; ItemId="gastankiedbp"; Chance=1/10;});
		table.insert(npcModule.Configuration.ResourceDrop.Rewards, 
			{Type=modGlobalVars.ItemDropsTypes.Blueprint; ItemId="metalbarricadebp"; Chance=1/10;});
			
		table.insert(npcModule.Configuration.ResourceDrop.Rewards, 
			{Type=modGlobalVars.ItemDropsTypes.Tool; ItemId="stickygrenade"; Chance=1/32;});
		table.insert(npcModule.Configuration.ResourceDrop.Rewards, 
			{Type=modGlobalVars.ItemDropsTypes.Tool; ItemId="mk2grenade"; Chance=1/32;});
			
		zombies = zombies+1;
		
	end
	
	for a=1, #modNpc.NpcModules do
		if modNpc.NpcModules[a] and random:NextInteger(1, 3) == 1 then
			UpdateNpc(modNpc.NpcModules[a].Module)
		end
	end
	
	local playersAlive = game.Players:GetPlayers();
	
	modNpc.OnNpcSpawn:Connect(UpdateNpc);
	
	local complete = false;
	local duration = 480;
	local startTime = os.time()+duration;
	
	local function announceTimeLeft()
		if complete then return end;
		local timeLeft = startTime - os.time();
		if timeLeft > 60 then
			shared.Notify(game.Players:GetPlayers(), "The Horde Attack will end in "..math.ceil(timeLeft/60).." minutes!", "Defeated");
		else
			shared.Notify(game.Players:GetPlayers(), "The Horde Attack will end in "..math.floor(timeLeft).." seconds!", "Defeated");
		end
	end
	
	delay(duration, function() WorldEventSystem.EndBind:Fire(); end)
	delay(duration-300, announceTimeLeft);
	delay(duration-120, announceTimeLeft);
	delay(duration-60, announceTimeLeft);
	WorldEventSystem.EndBind.Event:Wait();
	
	if not complete then 
		modNpc.OnNpcSpawn:Disconnect(UpdateNpc);
		
		for a=1, #modNpc.NpcModules do
			if HordeTypes[modNpc.NpcModules[a].Module.Name] then
				modNpc.NpcModules[a].Module.FakeSpawnPoint = nil;
				if modNpc.NpcModules[a].Module.Configuration.DefaultResourceDrop then
					modNpc.NpcModules[a].Module.Configuration.ResourceDrop = modNpc.NpcModules[a].Module.Configuration.DefaultResourceDrop;
				end
			end
		end
		complete = true;
	end;
end

return HordeAttack;
