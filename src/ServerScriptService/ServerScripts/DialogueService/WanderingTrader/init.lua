local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modDatabaseService = require(game.ServerScriptService.ServerLibrary.DatabaseService);
local modNpcProfileLibrary = require(game.ReplicatedStorage.BaseLibrary.NpcProfileLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modTradingService = Debugger:Require(game.ServerScriptService.ServerLibrary.TradingService);
local modFormatNumber = require(game.ReplicatedStorage.Library.FormatNumber);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);

local remotes = game.ReplicatedStorage.Remotes;
local remoteSetHeadIcon = remotes:WaitForChild("SetHeadIcon");

local tradeEnabledCache = {Tick=0; Enabled=false;};
return function(player, dialog, data)
	local profile = shared.modProfile:Get(player);

	local npcName = dialog.Name;
	local safehomeData = profile.Safehome;
	
	local npcLib = modNpcProfileLibrary:Find(npcName);
	
	local npcData = safehomeData:GetNpc(npcName);	
	local traderMem = modDatabaseService:GetDatabase(npcName);
	
	if modBranchConfigs.CurrentBranch.Name == "Dev" or player.UserId == 16170943 then
		local reportDialog = {
			Face="Skeptical";
			Dialogue=(modBranchConfigs.CurrentBranch.Name == "Dev" and "[Dev Branch]" or "[Dev]").." Status report";
			Reply="Arr, what report?"
		};

		local traderGold = traderMem:Get("Gold") or 0;
		
		reportDialog.Reply = "I have "..modFormatNumber.Beautify(traderGold).." gold.";
		
		dialog:AddDialog(reportDialog, function(dialog)
			npcData:CalculateHappiness();
			Debugger:WarnClient(player, npcData);
		end);
	end
	
	local npcLevel = npcData.Level or 0;
	local levelUpTimer = npcLevel * 60
	
	if modBranchConfigs.CurrentBranch.Name == "Dev" then levelUpTimer = 10; end;
	
	if npcData.LevelUpTime == nil then return end
	local unlockTime = npcData.LevelUpTime + (levelUpTimer);
	
	local playerSave = profile:GetActiveSave();
	
	local inventory = playerSave.Inventory;
	local traderProfile = profile and profile.Trader;
	
	local playerLevel = playerSave and playerSave:GetStat("Level") or 1;
	
	if npcLib.Class == "Trader" then
		if npcLevel == 0 then
			dialog:SetInitiateTag("trader_lvl0_init");
			
			local total, itemList = inventory:ListQuantity("cannedfish", 1);
			if total >= 1 then
				dialog:AddChoice("trader_lvl0_accept", function(dialog)
					
					for a=1, #itemList do
						inventory:Remove(itemList[a].ID, itemList[a].Quantity);
						shared.Notify(player, "1 Canned Sardines removed from your Inventory.", "Negative");
					end
					
					npcData:SetLevel(1);
				end)
				
			else
				dialog:AddChoice("trader_lvl0_decline");
				
			end
			
		elseif npcLevel == 1 then
			dialog:SetInitiateTag("trader_lvl1_init");
			
			dialog:AddChoice("trader_lvl1_choice1", function(dialog)
				if os.time() >= unlockTime then
					dialog:AddChoice("trader_lvl1_a")
					dialog:AddChoice("trader_lvl1_b")
					dialog:AddChoice("trader_lvl1_c", function(dialog)
						
						local hasSpace = inventory:SpaceCheck{
							{ItemId="explosives"; Data={Quantity=1}};
						};
						
						if hasSpace then
							inventory:Add("explosives");
							shared.Notify(player, "You have received Explosives!", "Positive");
							npcData:SetLevel(2);
							
						else
							shared.Notify(player, "Inventory is full!", "Negative");
						end
					end)
				end
			end, {ChoiceUnlockTime=unlockTime});
			
		elseif npcLevel == 2 then
			dialog:SetInitiateTag("trader_lvl2_init");
			
			local function unlock(dialog)
				npcData:SetLevel(3);
				shared.Notify(player, "You have unlocked trading with the wanderering trader.", "Reward");
			end
			
			dialog:AddChoice("trader_lvl2_a", unlock, {ChoiceUnlockTime=unlockTime});
			dialog:AddChoice("trader_lvl2_b", unlock, {ChoiceUnlockTime=unlockTime});
			
		elseif npcLevel == 3 then

			local traderTradeEnabled = false;
			if tick()-tradeEnabledCache.Tick >= 300 then
				tradeEnabledCache.Enabled = traderMem:Get("TradeEnabled") == true;
			end
			traderTradeEnabled = tradeEnabledCache.Enabled;
			
			if traderTradeEnabled then
				require(script.DailyTrades)(player, dialog, data);
				require(script.Broker)(player, dialog, data);
				
			else
				dialog:AddChoice("trader_tradeDisabled");
			end

			require(script.PurchaseFortuneSkinPerm)(player, dialog, data);
			require(script.SuspiciousKey)(player, dialog, data);
			
			dialog:AddDialog({
				Face="Skeptical";
				Dialogue="What's on the market at the moment?";
				Reply="Have a look.";
				ToggleWindow="GoldMenu";
			});
		end
	end
end
