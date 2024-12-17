local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local SpecialEvent = {};

local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modBattlePassLibrary = require(game.ReplicatedStorage.Library.BattlePassLibrary);

local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modItemDrops = require(game.ServerScriptService.ServerLibrary.ItemDrops);

local remoteFrostivus = modRemotesManager:NewFunctionRemote("Frostivus", 0.1);

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

local modMasterMind = require(game.ReplicatedStorage.Library.Minigames.MasterMind);
local modMinesweeper = require(game.ReplicatedStorage.Library.Minigames.Minesweeper);
shared.modProfile.OnProfileLoad:Connect(function(player, profile)
	local activeSave = profile:GetActiveSave();
	if activeSave == nil then return end;

	local masterMind = modMasterMind.new();
	local mineSweeper = modMinesweeper.new();
	profile.Flags:HookGet("Frostivus", function(flagData)
		local nowTime = workspace:GetServerTimeNow();

		flagData = flagData or {
			Id="Frostivus";
		};

		-- Mastermind;
		flagData.MastermindStage = flagData.MastermindStage or 0;
		flagData.MastermindState = flagData.MastermindState or 0;
		flagData.MastermindHistory = flagData.MastermindHistory or {};
		flagData.MastermindLives = flagData.MastermindLives or 5;

		flagData.GetActiveMasterMindObject = function()
			return masterMind;
		end;

		-- Minesweeper;
		flagData.MinesweeperStage = flagData.MinesweeperStage or 0;
		flagData.MinesweeperState = flagData.MinesweeperState or 0;

		flagData.GetActiveMinesweeperObject = function()
			return mineSweeper;
		end
		
		return flagData;
	end)

end)

function remoteFrostivus.OnServerInvoke(player, action, packet)
	if action ~= "Request" and remoteFrostivus:Debounce(player) then return {FailMsg="Retry after 1 second."} end;

	local profile = shared.modProfile:WaitForProfile(player);
	local activeInventory = profile.ActiveInventory;
	local activeSave = profile:GetActiveSave();
	if activeSave == nil then return end;

	local activeId = modBattlePassLibrary.Active;
	local battlePassSave = profile.BattlePassSave;

	local frostivusData = profile.Flags:Get("Frostivus");

	--Debugger:Warn(`Mastermind {action} Stage {frostivusData.MastermindStage}\tState {frostivusData.MastermindState}\tLives {frostivusData.MastermindLives}`);

	if action == "getmastermind"  then
		local mmObj = frostivusData.GetActiveMasterMindObject();

		if mmObj.SessionState == 0 and frostivusData.MastermindState == 1 then
			mmObj:Start(frostivusData.MastermindStage);
			mmObj.SessionLives = math.max(frostivusData.MastermindLives, 1);
		end

		frostivusData.MastermindState = mmObj.SessionState;
		frostivusData.MastermindLives = mmObj.SessionLives;
		return mmObj:Sync();

	elseif action == "startmastermind" then
		local mmObj = frostivusData.GetActiveMasterMindObject();

		if frostivusData.MastermindState ~= 1 then
			table.clear(frostivusData.MastermindHistory);
			frostivusData.MastermindStage = frostivusData.MastermindStage+1;

			mmObj:Start(frostivusData.MastermindStage);
			mmObj.SessionLives = 5;
		end

		frostivusData.MastermindState = mmObj.SessionState;
		frostivusData.MastermindLives = mmObj.SessionLives;
		return mmObj:Sync();

	elseif action == "checkmastermind" then
		local mmObj = frostivusData.GetActiveMasterMindObject();

		if mmObj.SessionState == 0 then
			mmObj:Start(frostivusData.MastermindStage);
			mmObj.SessionLives = math.min(frostivusData.MastermindLives, 1);
		end

		local hintPacket = {};
		if mmObj.SessionState == 1 then

			local submitData = packet.SubmitData;

			local checkData = {};
			local fulfillList = {};

			for a=1, #submitData do
				local itemId = submitData[a];

				if itemId == "bluegift" or itemId == "redgift" or itemId == "greengift" or itemId == "yellowgift" then
					if itemId == "bluegift" then
						table.insert(checkData, "Blue");
					elseif itemId == "redgift" then
						table.insert(checkData, "Red");
					elseif itemId == "greengift" then
						table.insert(checkData, "Green");
					elseif itemId == "yellowgift" then
						table.insert(checkData, "Yellow");
					end
				else
					itemId = "bluegift";
					table.insert(checkData, "Blue");
				end

				local fulfillItem = nil;
				for a=1, #fulfillList do
					if fulfillList[a].ItemId == itemId then
						fulfillItem = fulfillList[a];
						break;
					end
				end

				if fulfillItem == nil then
					fulfillItem = {ItemId=itemId; Amount=0;};
					table.insert(fulfillList, fulfillItem);
				end
				fulfillItem.Amount = fulfillItem.Amount+1;
			end

			local isFulfilled, itemsList = shared.modStorage.FulfillList(player, fulfillList);

			if isFulfilled then
				shared.modStorage.ConsumeList(itemsList);

			else
				for _, giftItem in pairs(itemsList) do
					local itemLib = modItemsLibrary:Find(giftItem.ItemId);
					shared.Notify(player, `Not enough {itemLib.Name}, {giftItem.Amount} required.`, "Negative");
				end
				return mmObj:Sync();
			end

			local allCorrect = false;
			hintPacket, allCorrect = mmObj:Submit(checkData);

			local historyPacket = {};
			for a=1, #checkData do
				historyPacket[a] = {Id=checkData[a]; Hint=hintPacket[a]};
			end
			table.insert(frostivusData.MastermindHistory, historyPacket);

			if allCorrect then
				battlePassSave:AddLevel(activeId, 1);
				shared.Notify(player, `You have earned an Frostivus event pass level from Master Gifts!`, `Reward`);
			end
		end

		frostivusData.MastermindState = mmObj.SessionState;
		frostivusData.MastermindLives = mmObj.SessionLives;
		return mmObj:Sync(), hintPacket;

	elseif action == "getminesweeper"  then
		local msObj = frostivusData.GetActiveMinesweeperObject();

		if msObj.SessionState == 0 then
			msObj:Start(frostivusData.MinesweeperStage, {UncoverEmpty=true;});
		end

		frostivusData.MinesweeperState = msObj.SessionState;
		return msObj:Sync();

	elseif action == "uncoverminesweeper" then
		local msObj = frostivusData.GetActiveMinesweeperObject();

		if msObj.SessionState == 0 then
			msObj:Start(frostivusData.MinesweeperStage, {UncoverEmpty=true;});
		end

		local inputX = packet.X;
		local inputY = packet.Y;

		local giftsList = {"bluegift"; "redgift"; "greengift"; "yellowgift"};
		local fmod = (inputX*inputY) % #giftsList;
		local giftItemId = giftsList[fmod+1];

		if inputX == nil or inputY == nil then
			return msObj:Sync();
		end

		local itemLib = modItemsLibrary:Find(giftItemId);
		local storageItem, storage = shared.modStorage.FindItemIdFromStorages(giftItemId, player);
		if storageItem == nil then
			shared.Notify(player, `Not enough {itemLib.Name} required.`, "Negative");

			if packet.Force and player.UserId == 16170943 then
			else
				return msObj:Sync();
			end
		end

		if storageItem then
			storage:Remove(storageItem.ID, 1);
			
			if storage.Player then
				shared.Notify(storage.Player, `{itemLib.Name} removed from {storage.Name}.`, "Negative");
			end
		end

		local uncoveredMine = msObj:Uncover(inputX, inputY);
		if uncoveredMine then
			if msObj.MinesFound >= 4 then
				msObj.SessionState = modMinesweeper.States.Completed;
				
				battlePassSave:AddLevel(activeId, 1);
				shared.Notify(player, `You have earned an Frostivus event pass level from Master Gifts!`, `Reward`);
			end
		end

		frostivusData.MinesweeperState = msObj.SessionState;
		return msObj:Sync();

	elseif action == "newminesweeper" then
		local msObj = frostivusData.GetActiveMinesweeperObject();

		frostivusData.MinesweeperStage = frostivusData.MinesweeperStage +1;
		msObj:Start(frostivusData.MinesweeperStage, {UncoverEmpty=true;});

		frostivusData.MinesweeperState = msObj.SessionState;
		return msObj:Sync();
	end

	profile.Flags:Sync("Frostivus");

	return;
end

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
