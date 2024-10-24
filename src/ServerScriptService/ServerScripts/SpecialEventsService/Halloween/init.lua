local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local SpecialEvent = {};

local Keys = {
	MemMap = "Halloween2023";
	EventId = "halloween2023Candies";
}

local MemoryStoreService = game:GetService("MemoryStoreService");
local halloweenMemory = MemoryStoreService:GetHashMap(Keys.MemMap);

local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modBattlePassLibrary = require(game.ReplicatedStorage.Library.BattlePassLibrary);
local modDropRateCalculator = require(game.ReplicatedStorage.Library.DropRateCalculator);
local modDialogueService = require(game.ReplicatedStorage.Library.DialogueService);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);

local remoteHalloween = modRemotesManager:NewFunctionRemote("Halloween", 1);

local rewardLib = modRewardsLibrary:Find("slaughterfestcandyrecipes24");

SpecialEvent.Cache = {
	CandyPool = 0;	
};

local candyTypes = {
	"zombiejello";
	"eyeballgummies";
	"spookmallow";
	"cherrybloodbar";
	"wickedtaffy";
};

SpecialEvent.SlaughterfestGetCandyTrade = nil;
--==
repeat wait() until shared.modProfile;

local loadedDialogues = {};
function SpecialEvent.LoadSlaughterfestDialogues(npcList)
	for npcName, dialogueHandlerFunc in pairs(loadedDialogues) do
		modDialogueService:ClearHandler(npcName, dialogueHandlerFunc);
	end
	table.clear(loadedDialogues);

	for a=1, #npcList do
		local npcInfo = npcList[a];
		local npcName = npcInfo.Id;

		local fulfillLists = SpecialEvent.SlaughterfestGetCandyTrade(npcName);
		if fulfillLists == nil then continue end;

		local requireList = fulfillLists.RequireList;
		local rewardsList = fulfillLists.RewardList;

		local requireStr = {};
		for a=1, #requireList do
			local itemLib = modItemsLibrary:Find(requireList[a].ItemId);
			local amt = requireList[a].Amount;
			table.insert(requireStr, `{amt} x {itemLib.Name}`);
		end
		
		local rewardStr = {};
		for a=1, #rewardsList do
			local itemLib = modItemsLibrary:Find(rewardsList[a].ItemId);
			local amt = rewardsList[a].Amount;
			table.insert(rewardStr, `{amt} x {itemLib.Name}`);
		end

		local dialogueHandlerFunc = function(player, dialog, data)
			local profile = shared.modProfile:Get(player);
			local activeInventory = profile.ActiveInventory;

			dialog:AddDialog({
				Face="Happy";
				Say="Trick or treat, want to exchange candies?";
				Reply=`Sure, I'm looking for:\n{table.concat(requireStr, ",  ")}\nIn return:\n{table.concat(rewardStr, ",  ")}`;

			}, function(dialog)
				Debugger:StudioWarn(npcName, "fulfillLists", fulfillLists);

				-- Check space;
				local spaceCheckList = {};
				for a=1, #requireList do
					local itemId = requireList[a].ItemId;
					local amt = requireList[a].Amount;
					table.insert(spaceCheckList, {ItemId=itemId; Data={Quantity=amt};});
				end
				local hasSpace = activeInventory:SpaceCheck(spaceCheckList);
				if not hasSpace then
					dialog:AddDialog({
						Face="Happy";
						Say="*Exchange*";
						Reply="Your inventory too full to exchange.";
		
					}, function(dialog)
					end);
					return;
				end

				-- Check fulfill;
				local fulfill, itemsList = shared.modStorage.FulfillList(player, requireList);
				if not fulfill then
					local missingStr = {};
					for _, candyItem in pairs(itemsList) do
						local itemLib = modItemsLibrary:Find(candyItem.ItemId);
						table.insert(missingStr, `{candyItem.Amount} x {itemLib.Name}`);
					end
					
					dialog:AddDialog({
						Face="Happy";
						Say="*Exchange*";
						Reply=`You are missing {table.concat(missingStr, ",  ")}!`;
		
					}, function(dialog)
					end);
					return;
				end;

				dialog:AddDialog({
					Face="Happy";
					Say="*Exchange*";
					Reply="Thanks! Happy Slaughterfest!";
	
				}, function(dialog)
					shared.modStorage.ConsumeList(itemsList);
					for a=1, #rewardsList do
						local itemId = rewardsList[a].ItemId;
						local amt = rewardsList[a].Amount;
						local itemLib = modItemsLibrary:Find(itemId);

						activeInventory:Add(itemId, {Quantity=amt}, function()
							shared.Notify(player, `You received {amt} {itemLib.Name}.`, "Reward");
						end);
					end

				end);
			end);

		end

		modDialogueService:AddHandler(npcName, dialogueHandlerFunc);
	end
end

local npcSeedOverride = nil;
function SpecialEvent.SlaughterfestGetCandyTrade(npcName)
	local modNpcProfileLibrary = require(game.ReplicatedStorage.BaseLibrary.NpcProfileLibrary);

	local npcSeed = npcSeedOverride or modSyncTime.TimeOfEndOfDay();
	local npcRandom = Random.new(npcSeed);

	local survivorsList = modNpcProfileLibrary:ListByMatchFunc(function(libItem)
		if libItem.Class == "Survivor" and libItem.Id ~= "Stan" and libItem.Id ~= "Robert" then
			return true;
		end
		return false;
	end);
	local tradeNpcList = {};

	for a=1, 5 do
		local npcInfo = table.remove(survivorsList, npcRandom:NextInteger(1, #survivorsList));
		table.insert(tradeNpcList, npcInfo);
	end
	
	if npcName == nil then
		SpecialEvent.LoadSlaughterfestDialogues(tradeNpcList);
		return;
	end

	local npcInfo, npcIndex;
	for a=1, #tradeNpcList do
		if tradeNpcList[a].Id == npcName then
			npcInfo, npcIndex = tradeNpcList[a], a;
			break;
		end
	end
	if npcInfo == nil then return end;

	local candyRandom = Random.new(npcSeed+npcIndex);
	local biasRng = candyRandom:NextNumber();

	local candyWantAmt = candyRandom:NextInteger(3, 4);
	local candyForAmt = candyRandom:NextInteger(2, 4);

	if candyWantAmt > candyForAmt and biasRng > 0.4 then -- 60% chance to equal;
	candyWantAmt = candyWantAmt -1;
	end
	if candyForAmt > candyWantAmt and biasRng > 0.1 then -- 10% chance to better;
		candyWantAmt, candyForAmt = candyForAmt, candyWantAmt;
	end

	local candyWantList = {};
	local candyWantOrder = {};
	for b=1, candyWantAmt do
		local pickCandyItemId;
		if #candyWantOrder >= 3 then
			pickCandyItemId = candyWantOrder[candyRandom:NextInteger(1, #candyWantOrder)];
		else
			pickCandyItemId = candyTypes[candyRandom:NextInteger(1, #candyTypes)];
		end
		candyWantList[pickCandyItemId] = (candyWantList[pickCandyItemId] or 0) + 1;

		if table.find(candyWantOrder, pickCandyItemId) == nil then
			table.insert(candyWantOrder, pickCandyItemId);
		end
	end

	local candyForList = {};
	local candyForOrder = {};
	for b=1, #candyTypes do
		if table.find(candyWantOrder, candyTypes[b]) then continue end;
		table.insert(candyForOrder, candyTypes[b]);
	end
	for b=1, candyForAmt do
		local pickCandyItemId;
		if b <= #candyForOrder then
			pickCandyItemId = candyForOrder[b];
		else
			pickCandyItemId = candyForOrder[candyRandom:NextInteger(1, #candyForOrder)];
		end
		
		candyForList[pickCandyItemId] = (candyForList[pickCandyItemId] or 0) + 1;
	end
	for b=#candyForOrder, 1, -1 do
		if candyForList[candyForOrder[b]] == nil then
			table.remove(candyForOrder, b);
		end
	end

	local candyRequireList = {};
	for b=1, #candyWantOrder do
		local candyItemId = candyWantOrder[b];
		local candyAmt = candyWantList[candyItemId];

		local recipeCandyItem = nil;
		for a=1, #candyRequireList do
			if candyRequireList[a].ItemId == candyItemId then
				recipeCandyItem = candyRequireList[a];
				break;
			end
		end
		if recipeCandyItem == nil then
			recipeCandyItem = {
				ItemId = candyItemId;
				Amount = candyAmt;
			};
			table.insert(candyRequireList, recipeCandyItem);
		end
	end

	local candyRewardList = {};
	for b=1, #candyForOrder do
		local candyItemId = candyForOrder[b];
		local candyAmt = candyForList[candyItemId];

		local recipeCandyItem = nil;
		for a=1, #candyRewardList do
			if candyRewardList[a].ItemId == candyItemId then
				recipeCandyItem = candyRewardList[a];
				break;
			end
		end
		if recipeCandyItem == nil then
			recipeCandyItem = {
				ItemId = candyItemId;
				Amount = candyAmt;
			};
			table.insert(candyRewardList, recipeCandyItem);
		end
	end

	return {
		RequireList=candyRequireList;
		RewardList=candyRewardList;
	};
end

shared.modProfile.OnProfileSave:Connect(function(player, profile)
	Debugger:Log("OnProfileSave");
	
	local candySubmission = profile.Cache.SubmitHalloweenCandyCache or 0;
	if candySubmission >= 0 then
		
		local function trySubmit()
			--halloweenMemory:UpdateAsync("CandyPool", function(oldVal)
			--	local newVal = (oldVal or 0) + candySubmission;
			--	SpecialEvent.Cache.CandyPool = tonumber(newVal) or 0;
			--	return newVal;
			--end, oneMonthSecs);
			Debugger:Log("Sumitted SpecialEvent.Cache.CandyPool", SpecialEvent.Cache.CandyPool);
		end
		
		local s,e;
		repeat
			s, e = pcall(trySubmit)
			
			if not s then
				Debugger:Warn(e);
				wait(5);
			end
		until s == true;
		
		profile.Cache.SubmitHalloweenCandyCache = nil;
	end
end)

shared.modProfile.OnProfileLoad:Connect(function(player, profile)
	local activeSave = profile:GetActiveSave();
	Debugger:Log("OnProfileLoad", activeSave ~= nil);
	
	if activeSave == nil then return end;

	local maxRerolls = 10;
	local restockTimer = 18000;

	profile.Flags:HookGet("Slaughterfest", function(flagData)
		local nowTime = workspace:GetServerTimeNow();

		flagData = flagData or {
			Id="Slaughterfest";
			RollSeed=nowTime;
			Claimed={};
		};

		if flagData.ShopReroll == nil then
			flagData.ShopReroll = maxRerolls;
			flagData.ShopLastRestock = nowTime;

		elseif flagData.ShopReroll < maxRerolls then
			local needRerolls = maxRerolls-flagData.ShopReroll;
			for a=1, needRerolls do
				if flagData.ShopLastRestock+restockTimer <= nowTime then
					flagData.ShopReroll = flagData.ShopReroll +1;

					if flagData.ShopReroll == 10 then
						flagData.ShopLastRestock = nowTime;
					else
						flagData.ShopLastRestock = flagData.ShopLastRestock+restockTimer;
					end
				else
					break;
				end
			end

		end

		return flagData;
	end)

	if activeSave.Storages and activeSave.Storages.HalloweenCauldron == nil then
		activeSave.Storages.HalloweenCauldron = modStorage.new("HalloweenCauldron", "HalloweenCauldron", 1, player);

		local cauldronStorage = activeSave.Storages.HalloweenCauldron;
		cauldronStorage.Size = 1;
		cauldronStorage.Virtual = true;
		cauldronStorage.Settings.DepositOnly = true;
		cauldronStorage:ConnectCheck(function(packet)
			if packet.DragStorage == cauldronStorage then 
				packet.Allowed = false;
				return packet;
			end; -- If item's from itself
			
			if packet.TargetStorageItem and packet.DragStorageItem.ItemId == packet.TargetStorageItem.ItemId then
				packet.Allowed = true;
				return packet; 
			end;

			if packet.DragStorageItem and packet.DragStorageItem.ItemId == "halloweencandy" then
				packet.Allowed = true;
				return packet;
			end
			
			packet.Allowed = true;
			packet.FailMsg = "Only Halloween candies are allowed."
			
			return packet;
		end)
	end

	SpecialEvent.SlaughterfestGetCandyTrade();
end)

function SpecialEvent.LoadCache()
	if SpecialEvent.Cache.LoadTick and tick()-SpecialEvent.Cache.LoadTick <= 5 then return end;
	SpecialEvent.Cache.LoadTick = tick();
	
	local s, e = pcall(function()
		local rawCandyPool = halloweenMemory:GetAsync("CandyPool");
		SpecialEvent.Cache.CandyPool = tonumber(rawCandyPool) or 0;
	end)
	
	if not s then
		Debugger:Warn(e);
	end
end

local function loadCandyData(player)
	local candyData = {
		Id=Keys.EventId; 
		Candy=0;
		Claimed={};
	}
	
	local candyDataRaw = modEvents:GetEvent(player, Keys.EventId);
	if candyDataRaw then
		candyData.Candy = candyDataRaw.Candy;
		for k, v in pairs(candyDataRaw.Claimed or {}) do
			candyData.Claimed[k] = (v == true);
		end
	end
	
	return candyData;
end

function remoteHalloween.OnServerInvoke(player, packet)
	local action = packet.Action;
	if action ~= "Request" and remoteHalloween:Debounce(player) then return {FailMsg="Retry after 1 second."} end;
	
	local rPacket = {};
	rPacket.CommunityContributions = SpecialEvent.Cache.CandyPool
	
	local candyData = loadCandyData(player);
	
	SpecialEvent.LoadCache();
	
	local profile = shared.modProfile:WaitForProfile(player);
	local activeInventory = profile.ActiveInventory;
	local activeSave = profile:GetActiveSave();
	if activeSave == nil then return end;
	
	if action == "Reroll" then
		local slaughterfestData = profile.Flags:Get("Slaughterfest");
		local nowTime = workspace:GetServerTimeNow();
		if nowTime-slaughterfestData.RollSeed <= 1 then return end;

		if slaughterfestData.ShopReroll > 0 then
			if slaughterfestData.ShopReroll >= 10 then
				slaughterfestData.ShopLastRestock = nowTime;
			end
			slaughterfestData.ShopReroll = slaughterfestData.ShopReroll -1;
			slaughterfestData.RollSeed = nowTime;
			table.clear(slaughterfestData.Claimed);
		end

		profile.Flags:Sync("Slaughterfest");

		return rPacket;

	elseif action == "Cook" then
		if packet.ItemId == nil then return end;

		local slaughterfestData = profile.Flags:Get("Slaughterfest");
		local rollSeed = slaughterfestData.RollSeed;
		
		local shopRewardInfoList = {};

		for a=1, 10 do
			local rewardsData = modDropRateCalculator.RollDrop(rewardLib, rollSeed/a);
			local rewardInfo = rewardsData[1];
			if rewardInfo == nil then continue end;

			local exist = false;
			for b=1, #shopRewardInfoList do
				if shopRewardInfoList[b].ItemId == rewardInfo.ItemId then
					exist = true;
					break;
				end
			end

			if not exist then
				table.insert(shopRewardInfoList, rewardInfo);
			end

			if #shopRewardInfoList >= 3 then
				break;
			end
		end

		local chosenRewardInfo = nil;
		local chosenIndex = nil;
		for a=1, #shopRewardInfoList do
			if shopRewardInfoList[a].ItemId == packet.ItemId then
				chosenIndex = a;
				chosenRewardInfo = shopRewardInfoList[a];
				break;
			end
		end
		if chosenRewardInfo == nil then return end;

		if slaughterfestData.Claimed[chosenRewardInfo.ItemId] then
			shared.Notify(player, "Reward already claimed.", "Negative");
			return;
		end

		local tierRecipeCost = {
			[1] = 6;
			[2] = 8;
			[3] = 12;
			[4] = 16;
			[5] = 20;
		};

		local rewardTier = chosenRewardInfo.Tier;
		local recipeRandom = Random.new(rollSeed/chosenIndex);

		local recipeItems = {};
		local recipeCost = tierRecipeCost[rewardTier];

		for b=1, recipeCost do
			local pickCandyItemId = candyTypes[recipeRandom:NextInteger(1, #candyTypes)];

			local recipeCandyItem = nil;
			for a=1, #recipeItems do
				if recipeItems[a].ItemId == pickCandyItemId then
					recipeCandyItem = recipeItems[a];
					break;
				end
			end
			if recipeCandyItem == nil then
				recipeCandyItem = {
					ItemId = pickCandyItemId;
					Amount = 0;
				};
				table.insert(recipeItems, recipeCandyItem);
			end

			recipeCandyItem.Amount = recipeCandyItem.Amount +1;
		end
		Debugger:Warn("Cook",chosenRewardInfo.ItemId,"Recipe", recipeItems);

		local hasSpace = activeInventory:SpaceCheck({{ItemId=chosenRewardInfo.ItemId; Data={Quantity=1};}});
		if not hasSpace then
			shared.Notify(player, "Not enough inventory space.", "Negative");
			return;
		end

		local fulfill, itemsList = shared.modStorage.FulfillList(player, recipeItems);
		if not fulfill then
			for _, candyItem in pairs(itemsList) do
				local itemLib = modItemsLibrary:Find(candyItem.ItemId);
				shared.Notify(player, `Not enough {itemLib.Name}, {candyItem.Amount} required.`, "Negative");
			end
			return
		end;

		slaughterfestData.Claimed[chosenRewardInfo.ItemId] = true;

		shared.modStorage.ConsumeList(itemsList);
		activeInventory:Add(chosenRewardInfo.ItemId, nil, function()
			local itemLib = modItemsLibrary:Find(chosenRewardInfo.ItemId);
			shared.Notify(player, `You received a {itemLib.Name}.`, "Reward");
		end);

		profile.Flags:Sync("Slaughterfest");

		rPacket.Success = true;
		return rPacket;
	end

	local cauldronStorage = activeSave.Storages.HalloweenCauldron;	
	if cauldronStorage == nil then Debugger:Warn("Missing CauldronStorage!"); return end;

	--cauldronStorage.OnAccess:Connect(function(isOpen)
	--	if not isOpen then
	--		Debugger:Log("StorageClose submit candy");
	--	end
	--end)
	
	rPacket.Storage = cauldronStorage:Shrink();
	rPacket.CandyData = candyData;
	
	
	if action == "Request" then


	elseif action == "Submit" then
		candyData = loadCandyData(player);

		local candyCount = 0;
		cauldronStorage:Loop(function(storageItem)
			if storageItem.ItemId == "halloweencandy" then
				candyCount = candyCount + storageItem.Quantity;
			end
		end);
		
		if candyCount < 100 then
			rPacket.FailMsg = "You need at least 100 candies to submit!";
			return rPacket;
		end
		
		local candiesToSubmit = math.floor(candyCount/100)*100;

		local total, itemList = cauldronStorage:ListQuantity("halloweencandy", candiesToSubmit);

		if total >= candiesToSubmit then
			for a=1, #itemList do
				cauldronStorage:Remove(itemList[a].ID, itemList[a].Quantity);
			end
		end
		
		local bpLevelsAdd = math.clamp(math.round(candiesToSubmit/100), 0, 5);
		
		--cauldronStorage:Wipe();
		Debugger:Log("Submitting ",candiesToSubmit," candies");

		shared.Notify(player, "You submitted "..candiesToSubmit.." candies.", "Inform");
		candyData.Candy = candyData.Candy + candiesToSubmit;
		profile.Cache.SubmitHalloweenCandyCache = (profile.Cache.SubmitHalloweenCandyCache or 0) + candiesToSubmit;

		shared.Notify(player, "Event Pass: Slaughter Fest levelled up by "..bpLevelsAdd.."!", "Inform");
		profile.BattlePassSave:AddLevel(modBattlePassLibrary.Active, bpLevelsAdd);
		profile.BattlePassSave:Sync();
		
		modEvents:NewEvent(player, candyData);
		rPacket.Storage = cauldronStorage:Shrink();
		rPacket.Success = true;
		
		
	elseif action == "Join" then
		task.spawn(function()
			repeat
				modServerManager:Travel(player, "Slaughterfest");
				task.wait(5);
			until not player:IsDescendantOf(game.Players)
		end)
		
	elseif action == "Claim" then
		
		local itemId = packet.ItemId;
		if itemId == nil then rPacket.Error=1; return rPacket end;
		
		local reward;
		for a=1, #rewardLib do
			if rewardLib[a].ItemId == itemId then
				reward = rewardLib[a];
				break;
			end
		end
		if reward == nil then rPacket.Error=2; return rPacket end;
		
		if candyData.Candy < reward.Value then rPacket.Error=3; return rPacket; end;
			
		
		if candyData.Claimed[itemId] == true then rPacket.Error=4; return rPacket; end;
		
		local hasSpace = activeInventory:SpaceCheck{
			{ItemId=itemId; Data={Quantity=1};};
		};
		if not hasSpace then
			shared.Notify(player, "No inventory space!", "Negative");
			rPacket.Error=5;
			return rPacket;
		end
		
		local itemLibrary = modItemsLibrary:Find(reward.ItemId);
		activeInventory:Add(reward.ItemId, {Quantity=reward.Quantity;}, function()
			shared.Notify(player, "You recieved "..(reward.Quantity > 1 and reward.Quantity.." "..itemLibrary.Name or "a "..itemLibrary.Name)..".", "Reward");
		end);
		rPacket.ClaimSuccess = true;
		candyData.Claimed[itemId] = true;
	end
	
	modEvents:NewEvent(player, candyData);
	
	return rPacket;
end

--==
task.spawn(function()
	local EventSpawns = workspace:FindFirstChild("Event");
	for a=1, 10 do
		if EventSpawns == nil then
			task.wait(1);
			EventSpawns = workspace:FindFirstChild("Event");
		else
			break;
		end
	end
	
	if EventSpawns then
		local cauldronSpawn = EventSpawns:WaitForChild("HalloweenCaudronSpawn");
		local cauldronInteractObj = script:WaitForChild("HalloweenCauldron"); 

		local newCauldron = cauldronInteractObj:Clone();
		newCauldron.Parent = workspace.Environment;
		newCauldron:SetPrimaryPartCFrame(cauldronSpawn.WorldCFrame);
	end
end)

local folderMapEvent = game.ServerStorage:FindFirstChild("MapEvents");
if folderMapEvent then
	local halloweenMapDecor = folderMapEvent:FindFirstChild("HalloweenEvent");
	if halloweenMapDecor then
		halloweenMapDecor.Parent = workspace.Environment;
	end
end


task.spawn(function()
	Debugger.AwaitShared("modCommandsLibrary");

	shared.modCommandsLibrary:HookChatCommand("slaughterfest", {
		Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
		Description = [[Slaughterfest commands.
		/slaughterfest addreroll [amount]
		/slaughterfest skiprerolltimer
		]];

		RequiredArgs = 0;
		UsageInfo = "/slaughterfest cmd";
		Function = function(player, args)
			local profile = shared.modProfile:Get(player);
			local slaughterfestData = profile.Flags:Get("Slaughterfest");

			local actionId = args[1];

			if actionId == "addreroll" then
				local amt = tonumber(args[2] or 1);
				slaughterfestData.ShopReroll = slaughterfestData.ShopReroll +amt;
				profile.Flags:Sync("Slaughterfest");

				shared.Notify(player, "addreroll", "Inform");

			elseif actionId == "skiprerolltimer" then
				slaughterfestData.ShopLastRestock = workspace:GetServerTimeNow()-(18000-20);
				profile.Flags:Sync("Slaughterfest");

				shared.Notify(player, "skiprerolltimer", "Inform");

			elseif actionId == "npctrades" then
				local npcName = args[2];

				local fulfillLists = SpecialEvent.SlaughterfestGetCandyTrade(npcName);
				Debugger:Warn("fulfillLists", fulfillLists);

			elseif actionId == "settradeseed" then
				local seed = tonumber(args[2]);
				npcSeedOverride = seed;
				Debugger:Warn("setseed", npcSeedOverride);
				SpecialEvent.SlaughterfestGetCandyTrade();
			end

			return true;
		end;
	});
end)


return SpecialEvent;
