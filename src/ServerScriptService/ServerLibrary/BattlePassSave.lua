local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local BattlePassSave = {};
BattlePassSave.__index = BattlePassSave;
--==

local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modBattlePassLibrary = require(game.ReplicatedStorage.Library.BattlePassLibrary);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modDropRateCalculator = require(game.ReplicatedStorage.Library.DropRateCalculator);
local modSerializer = require(game.ReplicatedStorage.Library.Serializer);

local modDatabaseService = require(game.ServerScriptService.ServerLibrary.DatabaseService);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);


local goldPoolMem = modDatabaseService:GetDatabase("BpGoldPool");
local goldPoolSerializer = modSerializer.new();


local remoteHudNotification = modRemotesManager:Get("HudNotification");
local remoteBattlepassRemote = modRemotesManager:Get("BattlepassRemote");


--== GoldPool;
local GoldPoolData = {};
GoldPoolData.__index = GoldPoolData;
GoldPoolData.ClassType = "GoldPoolData";

function GoldPoolData.new()
	local meta = {};
	meta.__index = meta;

	local self = {
		Gain=0;
		Claim=0;
		Pool=0;
	};

	setmetatable(self, meta);
	setmetatable(meta, GoldPoolData);
	return self;
end

goldPoolSerializer:AddClass(GoldPoolData.ClassType, GoldPoolData.new);	--For saving and loading classes.

goldPoolMem:BindSerializer(goldPoolSerializer);

-- GoldPoolMem
goldPoolMem:OnUpdateRequest("gain", function(requestPacket)
	local poolData = requestPacket.Data or GoldPoolData.new();
	local inputValues = requestPacket.Values; 
	
	poolData.Gain = poolData.Gain + inputValues.Amount;
	poolData.Pool = poolData.Pool + inputValues.Amount;
	
	return poolData;
end);

goldPoolMem:OnUpdateRequest("claim", function(requestPacket)
	local poolData = requestPacket.Data;
	local inputValues = requestPacket.Values; 
	
	if poolData == nil then
		requestPacket.FailMsg = "Gold is unavailable to claim at the moment.";
		return nil;
	end
	
	if poolData.Pool < inputValues.Amount then
		requestPacket.FailMsg = "Gold is out of stock at the moment, try again later.";
		return nil;
	end

	poolData.Claim = poolData.Claim + inputValues.Amount;
	poolData.Pool = poolData.Pool - inputValues.Amount;
	
	return poolData;
end)

goldPoolMem:OnUpdateRequest("add", function(requestPacket)
	local poolData = requestPacket.Data or GoldPoolData.new();
	local inputValues = requestPacket.Values; 

	poolData.Pool = poolData.Pool + inputValues.Amount;

	return poolData;
end);


--== Script;
function BattlePassSave.new(profile, syncFunc)
	local meta = {
		Player=profile.Player;
		Profile=profile;
		Sync = function(self)

			local activeId = modBattlePassLibrary.Active;
			local passData = self:GetPassData(activeId);
			if passData then
				profile.AllTimeStats.AllTimeMp = passData.Level or 0;
			else
				profile.AllTimeStats.AllTimeMp = 0;
			end
			
			syncFunc();
		end;
	};
	meta.__index=meta;
	
	local self = {
		Passes = {};
	};
	
	setmetatable(self, meta);
	setmetatable(meta, BattlePassSave);
	
	return self;
end

function BattlePassSave:Load(data)
	for k, v in pairs(data) do
		if k == "Passes" then
			for bpId, rawPassData in pairs(v) do
				local newPass = BattlePassSave.newPassData()
				
				for pDK, pDV in pairs(rawPassData) do
					newPass[pDK] = pDV;
				end
				
				self.Passes[bpId] = newPass;
			end
			
		else
			self[k] = v;
		end
	end
	
	return self;
end

function BattlePassSave.newPassData()
	local passData = {
		Completed = false;
		Owned = false;
		Level = 0;
		Claim = {};
		PostRewards = {};
	}
	
	return passData;
end

function BattlePassSave:GetPassData(bpId)
	local bpLib = modBattlePassLibrary:Find(bpId);
	if bpLib == nil then
		return;
	end

	if self.Passes[bpId] == nil then
		local unixTime = DateTime.now().UnixTimestamp;
		if unixTime > bpLib.EndUnixTime then return end;
		
		self.Passes[bpId] = BattlePassSave.newPassData();
	end
	return self.Passes[bpId];
end

function BattlePassSave:AddLevel(bpId, addAmt)
	local passData = self:GetPassData(bpId);
	local bpLib = modBattlePassLibrary:Find(bpId);

	local treeList = bpLib.Tree;

	local currentLevel = passData.Level;
	local leafInfo = treeList[currentLevel] or {};
	
	addAmt = addAmt or 1;
	local newLevel = passData.Level + addAmt;
	passData.Level = newLevel;
	
	if passData.Level >= #treeList then
		if passData.Completed == false then
			passData.Completed = true;

			local activeSave = self.Profile:GetActiveSave();
			activeSave:AwardAchievement(bpLib.Id);

			remoteHudNotification:FireClient(self.Player, "BattlePassComplete", {Title=bpLib.Title;});
		end
		
		self.Profile:RefreshPlayerTitle();

		local serverTime = workspace:GetServerTimeNow();

		local rewardsLib = modRewardsLibrary:Find(bpId);
		if newLevel >= #treeList and rewardsLib then
			
			for lvl=(currentLevel+1), newLevel do
				local postLvls = lvl-#treeList;

				local isFmodLvl = math.fmod(postLvls, modBattlePassLibrary.PostRewardLvlFmod);
				if isFmodLvl == 0 then
					local lvlStr = tostring(lvl);
					if passData.PostRewards[lvlStr] == nil then

						local rewards = modDropRateCalculator.RollDrop(rewardsLib);
						local rewardInfo = rewards[1];
						
						if rewardInfo then
							rewardInfo.ExpireTime = serverTime+shared.Const.OneDaySecs;
							passData.PostRewards[lvlStr] = rewardInfo;
						end
					end
				end
			end
			
		end
		
		for lvlStr, rewardInfo in pairs(passData.PostRewards) do
			if serverTime <= rewardInfo.ExpireTime then continue end;
			passData.PostRewards[lvlStr] = nil;
		end

	else
		passData.LastLevelUpTime = workspace:GetServerTimeNow();
		remoteHudNotification:FireClient(self.Player, "BattlePassLevelUp", {Level=passData.Level; HasRewards=(leafInfo.Reward ~= nil);});

	end
	self:Sync();
	
end

function BattlePassSave:OnMissionComplete(mission)
	if mission == nil then return end;
	if modBattlePassLibrary.Active == nil then return end;
	
	local unixTime = DateTime.now().UnixTimestamp;
	
	local activeId = modBattlePassLibrary.Active;
	
	local bpLib = modBattlePassLibrary:Find(activeId);
	if bpLib == nil then return end;
	if unixTime > bpLib.EndUnixTime then return end;

	local playerSave = self.Profile:GetActiveSave();
	
	
	local passData = self:GetPassData(activeId);
	
	local currentLevel = passData.Level;
	
	local treeList = bpLib.Tree;
	local leafInfo = treeList[currentLevel];
	
	local canLevelUp = false;
	if leafInfo and leafInfo.Requirements then
		canLevelUp = true;
		
		for a=1, #leafInfo.Requirements do
			local requirementInfo = leafInfo.Requirements[a];
			
			if requirementInfo.Type == "Stats" then
				if playerSave:GetStat(requirementInfo.Key) < requirementInfo.Value then
					canLevelUp = false;
				end
				
			elseif requirementInfo.Type == "Mission" then
				local rMission = modMission:GetMission(self.Player, requirementInfo.Key);
				if requirementInfo.Value == "Complete" and (rMission == nil or rMission.Type ~= 3) then
					canLevelUp = false;
				end
				
			elseif requirementInfo.Type == "Premium" then
				if self.Profile.Premium ~= true then
					canLevelUp = false;
				end
				
			end
			
			if not canLevelUp then break; end;
		end
		
	else
		canLevelUp = true;
		
	end
	
	if canLevelUp then
		self:AddLevel(activeId);
	end
end

function remoteBattlepassRemote.OnServerInvoke(player, action, ...)
	local returnPacket = {};
	
	local unixTime = DateTime.now().UnixTimestamp;

	local activeId = modBattlePassLibrary.Active;
	if activeId == nil then
		returnPacket.FailMsg = "No active mission pass";
		return returnPacket
	end;

	local bpLib = modBattlePassLibrary:Find(activeId);
	local treeList = bpLib.Tree;
	
	if unixTime > bpLib.EndUnixTime then
		returnPacket.FailMsg = "Mission Pass is over";
		return returnPacket
	end;
	
	local profile = shared.modProfile:Get(player);
	local activeInventory = profile.ActiveInventory;
	local traderProfile = profile.Trader;
	
	local battlePassSave = profile.BattlePassSave;

	local passData = battlePassSave:GetPassData(activeId);
	if passData == nil then
		returnPacket.FailMsg = "Invalid pass data";
		return returnPacket;
	end

	if action == "purchase" then
		if passData.Owned == true then
			returnPacket.FailMsg = "BattlePass already owned";
			return returnPacket;
		end

		local price = bpLib.Price;
		local playerGold = traderProfile.Gold;

		if playerGold < price then
			returnPacket.FailMsg = "Insufficient Gold";
			return returnPacket;
		end
		
		passData.Owned = true;
		battlePassSave:AddLevel(activeId);
		
		traderProfile:AddGold(-price);
		profile:AddPlayPoints(price/100);
		modAnalytics.RecordResource(player.UserId, price, "Sink", "Gold", "Purchase", activeId);
		returnPacket.Success = true;
		
		task.spawn(function()
			local goldPoolRp = goldPoolMem:UpdateRequest(activeId, "gain", {
				Amount=price;
			});
			Debugger:Warn("Purchase bp", activeId, "goldPoolRp:",goldPoolRp);
		end)
		
		return returnPacket;
		
	elseif action == "claim" then
		local claimLvl = ...;
		
		local currentLevel = passData.Level;
		claimLvl = math.clamp(claimLvl, 0, math.min(#treeList, currentLevel));
		
		local leafInfo = treeList[claimLvl];
		local rewardInfo = leafInfo.Reward;
		
		if rewardInfo.PassOwner == true and passData.Owned ~= true then
			returnPacket.FailMsg = "Requires Mission Pass";
			return returnPacket;
		end
		
		if rewardInfo.RequiresPremium == true and profile.Premium ~= true then
			returnPacket.FailMsg = "Requires Premium";
			return returnPacket;
		end
		
		if table.find(passData.Claim, claimLvl) then
			returnPacket.FailMsg = "Already Claimed";
			return returnPacket;
		end
		if currentLevel < claimLvl then
			returnPacket.FailMsg = "Insufficient Level";
			return returnPacket;
		end
		
		local rewardQuantity = (rewardInfo.Quantity or 1);
		
		if rewardInfo.ItemId == "gold" then

			local goldPoolRp = goldPoolMem:UpdateRequest(activeId, "claim", {
				Amount=rewardQuantity;
			});
			Debugger:Warn("Claim gold", activeId, "goldPoolRp:",goldPoolRp);
			
			if goldPoolRp.FailMsg then
				returnPacket.FailMsg = goldPoolRp.FailMsg;
				return returnPacket;
			end
			
			traderProfile:AddGold(rewardQuantity);
			profile:AddPlayPoints(rewardQuantity/100);
			modAnalytics.RecordResource(player.UserId, rewardQuantity, "Source", "Gold", "Gameplay", activeId);
			shared.Notify(player, "You recieved "..rewardQuantity.." Gold!", "Reward");
			
		else
			local hasSpace = activeInventory:SpaceCheck{
				{ItemId=rewardInfo.ItemId; Data={Quantity=rewardQuantity};}
			};
			if not hasSpace then
				returnPacket.FailMsg = "Inventory Full!";
				return returnPacket;
			end

			local itemLibrary = modItemsLibrary:Find(rewardInfo.ItemId);
			local rewardItemData = rewardInfo.Data or {};
			rewardItemData.Quantity = rewardQuantity;
			activeInventory:Add(rewardInfo.ItemId, rewardItemData, function(queueEvent, storageItem)
				shared.Notify(player, "You recieved "..(rewardQuantity > 1 and rewardQuantity.." "..itemLibrary.Name or "a "..itemLibrary.Name).."!", "Reward");
				
				modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
			end);
			
		end
		
		table.insert(passData.Claim, claimLvl);

		battlePassSave:Sync();
		returnPacket.Success = true;
		return returnPacket;
		
	elseif action == "purchaselvls" then
		local lvlamt = ...;
		lvlamt = tonumber(lvlamt)
		
		if lvlamt ~= 1 and lvlamt ~= 10 then
			returnPacket.FailMsg = "Invalid Input";
			return returnPacket;
		end
		
		local price = modBattlePassLibrary.BuyLevelCost * lvlamt;

		local playerGold = traderProfile.Gold;

		if playerGold < price then
			returnPacket.FailMsg = "Insufficient Gold";
			return returnPacket;
		end
		
		battlePassSave:AddLevel(activeId, lvlamt);

		traderProfile:AddGold(-price);
		profile:AddPlayPoints(price/100);
		modAnalytics.RecordResource(player.UserId, price, "Sink", "Gold", "Purchase", activeId.."Lvls");
		returnPacket.Success = true;

		task.spawn(function()
			local goldPoolRp = goldPoolMem:UpdateRequest(activeId, "gain", {
				Amount=price;
			});
			Debugger:Warn("Purchase lvls", activeId, "goldPoolRp:",goldPoolRp);
		end)
		
		shared.Notify(player, "Leveled up Mission Pass: ".. bpLib.Title .. " by ".. lvlamt .."!", "Reward");
		
		return returnPacket;
		
	elseif action == "claimpostreward" then
		local claimLvl = ...;
		
		local lvlStr = tostring(claimLvl);
		local rewardInfo = passData.PostRewards[lvlStr];
		
		if passData.PostRewards[lvlStr] == nil then
			returnPacket.FailMsg = "Already Claimed";
			return returnPacket;
		end
		
		local quantity = 1
		if typeof(rewardInfo.Quantity) == "table" then
			quantity = math.random(rewardInfo.Quantity.Min, rewardInfo.Quantity.Max);
		else
			quantity = rewardInfo.Quantity;
		end
		
		local rewardQuantity = quantity or 1;
		
		if rewardInfo.ItemId == "gold" then

			local goldPoolRp = goldPoolMem:UpdateRequest(activeId, "claim", {
				Amount=rewardQuantity;
			});
			Debugger:Warn("Claim gold", activeId, "goldPoolRp:",goldPoolRp);

			if goldPoolRp.FailMsg then
				returnPacket.FailMsg = goldPoolRp.FailMsg;
				return returnPacket;
			end

			traderProfile:AddGold(rewardQuantity);
			profile:AddPlayPoints(rewardQuantity/100);
			modAnalytics.RecordResource(player.UserId, rewardQuantity, "Source", "Gold", "Gameplay", activeId);
			shared.Notify(player, "You recieved "..rewardQuantity.." Gold!", "Reward");
			
		else
			local hasSpace = activeInventory:SpaceCheck{
				{ItemId=rewardInfo.ItemId; Data={Quantity=rewardQuantity};}
			};
			if not hasSpace then
				returnPacket.FailMsg = "Inventory Full!";
				return returnPacket;
			end

			local itemLibrary = modItemsLibrary:Find(rewardInfo.ItemId);
			activeInventory:Add(rewardInfo.ItemId, {Quantity=rewardQuantity;}, function(queueEvent, storageItem)
				shared.Notify(player, "You recieved "..(rewardQuantity > 1 and rewardQuantity.." "..itemLibrary.Name or "a "..itemLibrary.Name).."!", "Reward");
				modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
			end);
			
		end
		
		passData.PostRewards[lvlStr] = nil;

		battlePassSave:Sync();
		returnPacket.Success = true;
		
		return returnPacket;
		
	end

	return returnPacket;
end

task.spawn(function()
	Debugger.AwaitShared("modCommandsLibrary");
	shared.modCommandsLibrary:HookChatCommand("addmissionpasslevel", {
		Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;

		RequiredArgs = 0;
		UsageInfo = "/addmissionpasslevel [levels]";
		Function = function(player, args)
			local profile = shared.modProfile:Get(player);
			
			profile.BattlePassSave:AddLevel(modBattlePassLibrary.Active, args[1]);
			profile.BattlePassSave:Sync();
			
			return true;
		end;
	});
	
	shared.modCommandsLibrary:HookChatCommand("delmissionpass", {
		Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;

		RequiredArgs = 0;
		UsageInfo = "/delmissionpass [mpId]";
		Function = function(player, args)
			local profile = shared.modProfile:Get(player);
			
			local mpId = args[1];
			
			if mpId == nil then
				local ids = {};
				for id, _ in pairs(profile.BattlePassSave.Passes) do
					table.insert(ids, id);
				end
				
				shared.Notify(player, "Which mission pass do you want to delete? List: ".. table.concat(ids, ", "), "Inform");
				
			else
				if profile.BattlePassSave.Passes[mpId] == nil then
					shared.Notify(player, "Mission pass ".. mpId .." does not exist.", "Inform");

					
				else
					profile.BattlePassSave.Passes[mpId] = nil;
					profile.BattlePassSave:Sync();
					
				end
				
			end

			return true;
		end;
	});

	shared.modCommandsLibrary:HookChatCommand("addmissionpassgoldpool", {
		Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;

		RequiredArgs = 1;
		UsageInfo = "/addmissionpassgoldpool gold [bpkey]";
		Function = function(player, args)
			local amt = tonumber(args[1]) or 250;

			local bpKey = args[2] or modBattlePassLibrary.Active;

			local goldPoolRp = goldPoolMem:UpdateRequest(bpKey, "add", {
				Amount=amt;
			});

			shared.Notify(player, "Bp:(".. bpKey ..")".. Debugger:Stringify("Status: ", goldPoolRp) , "Inform");
			
			return true;
		end;
	});
	

end)

return BattlePassSave;
