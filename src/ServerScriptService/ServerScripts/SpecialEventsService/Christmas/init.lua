local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local SpecialEvent = {};

local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);
local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modItemDrops = require(game.ServerScriptService.ServerLibrary.ItemDrops);

local EventSpawns = workspace:WaitForChild("Event");

local mrKlawsSpawn = EventSpawns:WaitForChild("Mr. Klaws");
--==
modNpc.Spawn("Mr. Klaws", mrKlawsSpawn.CFrame * CFrame.Angles(0, math.rad(-90), 0) + Vector3.new(0, 2.3, 0));
Debugger.AwaitShared("modProfile");

local folderMapEvent = game.ServerStorage:FindFirstChild("MapEvents");
if folderMapEvent then
	local mapDecor = folderMapEvent:FindFirstChild("ChristmasEvent");
	if mapDecor then
		mapDecor.Parent = workspace.Environment;
		
		task.spawn(function()
			local winterTreelumSpawns = mapDecor:WaitForChild("WinterTreelumSpawns");
			winterTreelumSpawns = winterTreelumSpawns:GetChildren();
			
			while true do
				if workspace.Interactables:FindFirstChild("TreelumSapling") == nil then
					local newSpawn = winterTreelumSpawns[math.random(1, #winterTreelumSpawns)];
					
					local new = script.TreelumSapling:Clone();
					new:PivotTo(newSpawn.WorldCFrame);
					new.Parent = workspace.Interactables;
					
				end
				task.wait(60);
			end
		end)
		
	end
end

function SpecialEvent.GetPlayerGiftDropItemId(player, param): (string?, number?)
	param = param or {};
	param.MaxQuantity = param.MaxQuantity or 1;

	local profile = shared.modProfile:Get(player);
	local playerSave = profile and profile:GetActiveSave();
	if playerSave == nil then return; end;

	local dropOdds = {
		bluegift=1;
		redgift=1;
		yellowgift=1;
		greengift=1;
	}

	local clothingStorage = playerSave.Clothing;
	if clothingStorage then
		local santaHatStorageItem = clothingStorage:FindByItemId("santahat");
		
		if santaHatStorageItem then
			local activeSkin = santaHatStorageItem:GetValues("ActiveSkin");

			if activeSkin == "santahatblue" then
				dropOdds.bluegift = dropOdds.bluegift + 1;
			elseif activeSkin == "santahatred" then
				dropOdds.redgift = dropOdds.redgift + 1;
			elseif activeSkin == "santahatyellow" then
				dropOdds.yellowgift = dropOdds.yellowgift + 1;
			elseif activeSkin == "santahatgreen" then
				dropOdds.greengift = dropOdds.greengift + 1;
			else
				dropOdds.redgift = dropOdds.redgift + 1;
			end

		elseif clothingStorage:FindByItemId("greensantahat") then
			dropOdds.greengift = dropOdds.greengift+1;

		end
	end
	
	local spawnMax = math.max(param.MaxQuantity, 1)+1;
	local spawnAmount = math.random(1, spawnMax);

	local dropTable = {};
	local total = 0;
	for itemId, odds in pairs(dropOdds) do
		total = total + odds;
		table.insert(dropTable, {
			ItemId = itemId;
			RangeMin=total-odds;
			RangeMax=total;
		});
	end

	local roll = math.random(1, total);
	local pickItemId = nil;
	for a=1, #dropTable do
		if roll > dropTable[a].RangeMin and roll <= dropTable[a].RangeMax then
			pickItemId = dropTable[a].ItemId;
			break;
		end
	end

	dropTable[1].Total = total;
	return pickItemId, spawnAmount, dropTable;
end

modOnGameEvents:ConnectEvent("OnCrateSpawn", function(newPrefab, interactData, whitelist)
	local storageId = interactData.StorageId;

	for _, player in pairs(whitelist) do
		local profile = shared.modProfile:Get(player);
		local playerSave = profile and profile:GetActiveSave();
		if playerSave == nil then continue end;

		local storages = profile:GetCacheStorages();
		local crateStorage = storages[storageId];
		if crateStorage == nil then continue end;

		local pickItemId, spawnAmount = SpecialEvent.GetPlayerGiftDropItemId(player, {
			MaxQuantity=math.ceil((interactData.LevelRequired or 1)/100);
		});

		if pickItemId then
			crateStorage:Add(pickItemId, {Quantity=spawnAmount;}, function(event, remains)
				if event ~= "Success" then
					Debugger:Warn(`Failed to spawn ({pickItemId}x{spawnAmount}) with its contents.`, remains);
				end;
			end)
		end
	end
	
end)

modOnGameEvents:ConnectEvent("OnDropReward", function(npcModule, deathCframe: CFrame)
	if math.random(1, 50) ~= 1 then return end;
	local playerTags = modDamageTag:Get(npcModule.Prefab, "Player");
	local killerPlayer: Player;
	
	for _, playerTag in pairs(playerTags) do
		killerPlayer = playerTag.Player;
		if killerPlayer then break; end;
	end

	if killerPlayer == nil then return end;
	local _, _, dropTable = SpecialEvent.GetPlayerGiftDropItemId(killerPlayer);

	if dropTable == nil then return end;

	local rollTotal = dropTable[1].Total;

	local function roll()
		local roll = math.random(1, rollTotal);
		local pickItemId = nil;
		for a=1, #dropTable do
			if roll > dropTable[a].RangeMin and roll <= dropTable[a].RangeMax then
				pickItemId = dropTable[a].ItemId;
				break;
			end
		end
		return pickItemId;
	end

	local newDrops = {};
	for a=1, 3 do
		local itemId = roll();
		newDrops[itemId] = (newDrops[itemId] or 0) + 1;
	end
	
	for itemId, quantity in pairs(newDrops) do
		modItemDrops.Spawn({Type=itemId; Quantity=quantity}, deathCframe, nil, nil, {
			ApplyForce = 1;
		});
	end
end)


task.spawn(function()
	Debugger.AwaitShared("modCommandsLibrary");

	shared.modCommandsLibrary:HookChatCommand("frostivus", {
		Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
		Description = [[Frostivus commands.
		/frostivus 
		]];

		RequiredArgs = 0;
		UsageInfo = "/frostivus cmd";
		Function = function(player, args)
			local profile = shared.modProfile:Get(player);
			--local slaughterfestData = profile.Flags:Get("Slaughterfest");

			local actionId = args[1];

			if actionId == " " then
			end

			return true;
		end;
	});
end)

Debugger:Warn("Activate Christmas Event");

return SpecialEvent;
