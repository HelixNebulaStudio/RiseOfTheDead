local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modTradingService = require(game.ServerScriptService.ServerLibrary.TradingService);
local modDropRateCalculator = require(game.ReplicatedStorage.Library.DropRateCalculator);
local modGlobalVars = require(game.ReplicatedStorage.GlobalVariables);
local modMath = require(game.ReplicatedStorage.Library.Util.Math);

return function(dialog)
	local player = dialog.Player;
	local npcDialogData = dialog.NpcDialogData;
	local npcName = dialog.Name;
	
	--==
	local tradingSession = modTradingService:NewComputerSession(player, npcName);
	local npcTradeStorage = tradingSession.Storages[npcName];

	tradingSession:SetData(npcName, "HideGold", true);
	
	local validTrade = 0;
	tradingSession:BindConfirmSet(function(self, playerObj)

		if playerObj.Confirm then
			if validTrade == 1 then
				tradingSession:SetData(npcName, "Message", "Another fair exchange, enjoy.");
				tradingSession:SetConfirm(npcName, true);
			end

			tradingSession:Sync("tradesession");
		else
			tradingSession:SetConfirm(npcName, false);
			if tradingSession.State == 2 then
				tradingSession:SetData(npcName, "Message", "What's wrong?");
				tradingSession:Sync("tradesession");
			end
		end
	end)

	local function processTrade(self, playerObj)
		if self.Ended or self.Processing then return end;
		
		validTrade = 0;
		npcTradeStorage:Wipe();
		
		local crateIdList = {};
		local recyclablesTotal = 0;
		
		local rollLib = {
			Id="recycler";
			Rewards={
				--{Choice="a"; Chance=1/1};
			};
		};
		
		local playerDeposits = tradingSession.Storages[player.Name];
		playerDeposits:Loop(function(storageItem)
			if storageItem.Properties.Recyclable then
				local qnty = (storageItem.Quantity or 1);
				
				for a=1, #storageItem.Properties.CrateList do
					local crateKey = storageItem.Properties.CrateList[a];
					crateIdList[crateKey] = (crateIdList[crateKey] or 0) + qnty;
				end
				recyclablesTotal = recyclablesTotal + qnty;
				
			else
				validTrade = 2;
				
			end
		end);
		
		local maxChance = 0;
		for crateItemId, crateCount in pairs(crateIdList) do
			local new = {Choice=crateItemId; Chance=crateCount/recyclablesTotal};
			table.insert(rollLib.Rewards, new);
			
			if new.Chance > maxChance then
				maxChance = new.Chance;
			end
		end
		for a=1, #rollLib.Rewards do
			local rewardInfo = rollLib.Rewards[a];
			rewardInfo.Chance = modMath.MapNum(rewardInfo.Chance, 0, maxChance, 0, 1);
		end
		
		
		local cratesTotal = math.floor(recyclablesTotal/4);
		Debugger:Log("recyclablesTotal", recyclablesTotal, "cratesTotal", cratesTotal ,"rollLib", rollLib);
		
		if playerObj.Gold ~= 0 then
			validTrade = 3;
		end
		
		-- Evaluate;
		if validTrade == 0 and cratesTotal > 0 then
			validTrade = 1;
			
			tradingSession:BindOnSwapContainers(function(playerStorage, targetStorage)
				Debugger:Log("playerStorage.Id", playerStorage.Id);
				Debugger:Log("targetStorage.Id", targetStorage.Id);
				targetStorage:Wipe();
				
				for a=1, cratesTotal do
					local roll = modDropRateCalculator.RollDrop(rollLib, player);

					if roll and #roll > 0 then
						local choice = roll[1].Choice;
						targetStorage:Add(choice);
					end
				end
			end)
			
			npcTradeStorage:Insert{ItemId="unknowncrate"; Data={Quantity=cratesTotal;}};
			tradingSession:SetData(npcName, "Message", "That's "..recyclablesTotal.." recyclables for " ..(cratesTotal > 1 and cratesTotal.. " crates.." or cratesTotal.." crate."));
			
		elseif validTrade == 2 or validTrade == 3 then
			tradingSession:SetData(npcName, "Message", "Hmmm.. Something ain't right.");
			
		elseif recyclablesTotal > 0 then
			tradingSession:SetData(npcName, "Message", "It's going to require ".. 4-recyclablesTotal .." more recyclables.");
			
		else
			tradingSession:SetData(npcName, "Message", "What recyclables you got?");
			
		end

		tradingSession:Sync("tradesession");
	end


	tradingSession:BindGoldUpdate(processTrade);
	tradingSession:BindStorageUpdate(processTrade);

	tradingSession:Sync("tradesession", true);
end