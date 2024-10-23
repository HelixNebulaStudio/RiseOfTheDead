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

local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);

local remoteHalloween = modRemotesManager:NewFunctionRemote("Halloween", 1);

local rewardLib = modRewardsLibrary:Find("slaughterfestcandyrecipes24");

SpecialEvent.Cache = {
	CandyPool = 0;	
};

--==
repeat wait() until shared.modProfile;

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

		local candyTypes = {
			"zombiejello";
			"eyeballgummies";
			"spookmallow";
			"cherrybloodbar";
			"wickedtaffy";
		};
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
		/slaughterfest addreroll
		/slaughterfest uprerolltimer
		]];

		RequiredArgs = 0;
		UsageInfo = "/slaughterfest cmd";
		Function = function(player, args)
			local profile = shared.modProfile:Get(player);
			local slaughterfestData = profile.Flags:Get("Slaughterfest");

			local actionId = args[1];

			if actionId == "addreroll" then
				slaughterfestData.ShopReroll = slaughterfestData.ShopReroll +1;
				profile.Flags:Sync("Slaughterfest");

				shared.Notify(player, "addreroll", "Inform");

			elseif actionId == "uprerolltimer" then
				slaughterfestData.ShopLastRestock = workspace:GetServerTimeNow()-(18000-20);
				profile.Flags:Sync("Slaughterfest");

				shared.Notify(player, "uprerolltimer", "Inform");
			end

			return true;
		end;
	});
end)


return SpecialEvent;
