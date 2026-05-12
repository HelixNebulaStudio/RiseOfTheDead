local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local WorldEventSystem = {} :: anydict;
local HordeAttack = {}
local AttackLocations = {};
local LocationsList = {};

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);
local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);

local modNpcs = shared.modNpcs;
local modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);

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

	shared.modEventService:OnInvoked("NpcComponent_BindDropReward", function(eventPacket: EventPacket, ...)
		local dropRewardComp, spawnCf = ...;
		if dropRewardComp == nil then return end;
		
		local npcClass: NpcClass = dropRewardComp.NpcClass;
		if npcClass == nil then return end;

		if npcClass.Properties.HordeAttack ~= true then return end;

		local rewardLib = modRewardsLibrary:Find("hordeattack_default");
		local chosenDrop = modItemDrops.ChooseDrop(rewardLib);
		if chosenDrop then
			modItemDrops.spawn{
				ItemId = chosenDrop.ItemId;
				Quantity = chosenDrop.Quantity;
				ItemValues = chosenDrop.ItemValues;
				SpawnCFrame = spawnCf;
				SharedDrop = true;
			};
		end;
	end)

	return true;
end

function HordeAttack.Start()
	WorldEventSystem.NextEventTick = os.time()+random:NextNumber(1600, 1800);
	
	local safehouse = LocationsList[random:NextInteger(1, #LocationsList)];
	if safehouse == nil then return end;
	
	local locationInfo = AttackLocations[safehouse];
	remoteHudNotification:FireAllClients("HordeAttack", {Name=safehouse});
	shared.Notify(game.Players:GetPlayers(), "There will be a Horde Attack at the "..safehouse.."!", ("Defeated" :: any));
	shared.Notify(game.Players:GetPlayers(), "Hordes will have a chance to drop special loot..", ("Defeated" :: any));

	local zombies = 0;
	local function UpdateNpc(npcClass: NpcClass)
		if npcClass == nil then return end;
		if HordeTypes[npcClass.Name] == nil then return end;

		local properties = npcClass.Properties;
		if properties.FakeSpawnPoint then
			return
		end
		
		local randomRegion = locationInfo.Regions[random:NextInteger(1, #locationInfo.Regions)];
		local randomPoint = Vector3.new(
			random:NextNumber(randomRegion.Min.X, randomRegion.Max.X),
			randomRegion.Max.Y,
			random:NextNumber(randomRegion.Min.Z, randomRegion.Max.Z)
		);

		if modVector.DistanceSqrdXZ(npcClass.SpawnCFrame.Position, randomPoint) > math.pow(250, 2) then return end;
		
		local groundRay = Ray.new(randomPoint, Vector3.new(0, -20, 0));
		local groundHit, groundPoint = workspace:FindPartOnRayWithWhitelist(groundRay, {workspace.Environment; workspace.Terrain}, true);
		
		if groundHit == nil then return end;
		
		properties.HordeAttack = true;
		properties.FakeSpawnPoint = CFrame.new(groundPoint);
		
		zombies = zombies+1;
	end
	
	for a=1, #modNpcs.ActiveNpcClasses do
		if modNpcs.ActiveNpcClasses[a] and random:NextInteger(1, 3) == 1 then
			UpdateNpc(modNpcs.ActiveNpcClasses[a])
		end
	end
	
	local _playersAlive = game.Players:GetPlayers();
	
	modNpcs.OnNpcSpawn:Connect(UpdateNpc);
	
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
	
	task.delay(duration, function() WorldEventSystem.EndBind:Fire(); end)
	task.delay(duration-300, announceTimeLeft);
	task.delay(duration-120, announceTimeLeft);
	task.delay(duration-60, announceTimeLeft);
	WorldEventSystem.EndBind.Event:Wait();
	
	if not complete then 
		modNpcs.OnNpcSpawn:Disconnect(UpdateNpc);
		for a=1, #modNpcs.ActiveNpcClasses do
			local npcClass: NpcClass = modNpcs.ActiveNpcClasses[a];
			if HordeTypes[npcClass.Name] then
				npcClass.Properties.FakeSpawnPoint = nil;
				npcClass.Properties.HordeAttack = nil;
			end
		end
		complete = true;
	end;
end

return HordeAttack;
