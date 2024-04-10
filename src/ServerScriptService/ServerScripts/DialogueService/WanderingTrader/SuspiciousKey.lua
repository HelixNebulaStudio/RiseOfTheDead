local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modFormatNumber = require(game.ReplicatedStorage.Library.FormatNumber);
local modWorkbenchLibrary = require(game.ReplicatedStorage.Library.WorkbenchLibrary);

local modTradingService = Debugger:Require(game.ServerScriptService.ServerLibrary.TradingService);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);

return function(player, dialog, data)
	local profile = shared.modProfile:Get(player);
	local playerSave = profile:GetActiveSave();
	local traderProfile = profile and profile.Trader;
	local inventory = playerSave.Inventory;

	local npcName = dialog.Name;
	
	dialog:AddDialog({
		Face="Skeptical";
		Dialogue="How much do you want for that Suspicious Key?";
		Reply="Let's see..";
		ToggleWindow="Trade";

	}, function(dialog)
		local tradingSession = modTradingService:NewComputerSession(player, npcName);

		local npcTradeStorage = tradingSession.Storages[npcName];
		tradingSession:SetData(npcName, "HideGold", true);

		tradingSession:BindStateUpdate(function()
			if tradingSession.State == 3 then
				modAnalytics.RecordResource(player.UserId, 20, "Sink", "Gold", "Usage", "cultistkey1");
			end
		end)

		local validTrade = false;
		tradingSession:BindConfirmSet(function(self, playerObj)

			if playerObj.Confirm then
				if validTrade then
					tradingSession:SetData(npcName, "Message", "Very well, one person's trash is another person's treasure.. I guess.");
					tradingSession:SetConfirm(npcName, true);

				else
					tradingSession:SetData(npcName, "Message", "Arrr, quit fooling around.");

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

		local supplyInfo = {ItemId="cultistkey1"; Price=20;};
		local function processTrade(self, playerObj)
			validTrade = false;
			npcTradeStorage:Wipe();

			local buyValid = nil;

			-- Buy Section
			if playerObj.Gold == 20 then
				npcTradeStorage:Wipe();

				npcTradeStorage:Insert{ItemId=supplyInfo.ItemId; Data={Values={GoldPrice=supplyInfo.Price;}}};
				buyValid = supplyInfo;
			else
				buyValid = 1;
			end

			-- Evaluate;
			local goldHeaderTag = '<font color="rgb(255, 205, 79)">';
			if buyValid == 1 then
				tradingSession:SetData(npcName, "Message", "<b>20 "..goldHeaderTag.."Gold</font></b>.. Take it or leave it..");

			elseif typeof(buyValid) == "table" and buyValid.Price then
				local itemLib = modItemsLibrary:Find(buyValid.ItemId);
				tradingSession:SetData(npcName, "Message", "What's so special about it anyways..?");
				validTrade = true;

			else
				tradingSession:SetData(npcName, "Message", "Hmmm.. I'll give it to you for <b>20"..goldHeaderTag.."Gold</font></b>.");

			end

			if not validTrade then
				npcTradeStorage:Insert{ItemId=supplyInfo.ItemId; Data={Values={GoldPrice=supplyInfo.Price;}}};
			end

			tradingSession:Sync("tradesession");
		end


		tradingSession:BindGoldUpdate(processTrade);
		tradingSession:BindStorageUpdate(processTrade);

		tradingSession:Sync("tradesession", true);
	end);
	
end