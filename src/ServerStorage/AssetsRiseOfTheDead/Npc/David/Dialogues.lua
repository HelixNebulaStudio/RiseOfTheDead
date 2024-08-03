local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Ummmm, what should I do?";
	};
	["init2"]={
		Reply="Hey bro, should I honestly play this card or that card?";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["shop_ratShop"]={
		Say="What do you have for sale?";
		Reply="You'll honestly find everything you need here.";
		ReplyFunction=function(dialogPacket)
			local npcModel = dialogPacket.Prefab;
			if npcModel:FindFirstChild("shopInteractable") then
				local localPlayer = game.Players.LocalPlayer;
				local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);

				modData.InteractRequest(npcModel.shopInteractable, npcModel.PrimaryPart);
			end
		end
	};
	
	["general_fold"]={
		Say="You should fold."; 
		Reply="How do I fold!?";
	};
	
	["general_commodities"]={
		Say="What do you do around here?"; 
		Reply="I honestly just salvage commodities.. While we're in that topic, I could trade you some blueprints for your commodities..";
	};
};

if RunService:IsServer() then
	local demands = {
		{ItemId="wateringcan";};
		{ItemId="boombox";};
		{ItemId="binoculars";};
		{ItemId="spotlight";};
		{ItemId="walkietalkie";};
	};
	
	local supplys = {
		{ItemId="ladderbp";};
	};

	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modTradingService = require(game.ServerScriptService.ServerLibrary.TradingService);
		local modEvents = require(game.ServerScriptService.ServerLibrary.Events);

		local npcName = dialog.Name;
		
		dialog:AddChoice("shop_ratShop")
		dialog:AddChoice("general_fold")
		
		if modEvents:GetEvent(player, "david_purpose") == nil then
			dialog:AddChoice("general_commodities", function()
				modEvents:NewEvent(player, {Id="david_purpose"});
			end);
			
		else
			dialog:AddDialog({
				Face="Skeptical";
				Say="I got some commodities to trade.";
				Reply="Sure..";
				ToggleWindow="Trade";
				
			}, function(dialog)
				local tradingSession = modTradingService:NewComputerSession(player, npcName);
				
				local npcTradeStorage = tradingSession.Storages[npcName];

				tradingSession:SetData(npcName, "HideGold", true);
				tradingSession:SetData(npcName, "Demands", demands);
				
				tradingSession:BindStateUpdate(function()
					
				end)
				
				local validTrade = 0;
				tradingSession:BindConfirmSet(function(self, playerObj)
					
					if playerObj.Confirm then
						if validTrade == 1 then
							tradingSession:SetData(npcName, "Message", "Cool deal!");
							tradingSession:SetConfirm(npcName, true);
							
						end
						
						tradingSession:Sync("tradesession");
					else
						tradingSession:SetConfirm(npcName, false);
						if tradingSession.State == 2 then
							tradingSession:SetData(npcName, "Message", "Hmmmm?");
							tradingSession:Sync("tradesession");
						end
					end
				end)
				
				local randomOfTheDay = Random.new(workspace:GetAttribute("DayOfYear"));
				local offerIndex = randomOfTheDay:NextInteger(1, #supplys);
				
				local function processTrade(self, playerObj)
					validTrade = 0;
					npcTradeStorage:Wipe();
					
					local totalItemsCount = 0;
					
					local playerDeposits = tradingSession.Storages[player.Name];
					local _itemCount = playerDeposits:Loop(function(storageItem)
						local accepted = false;
						for a=1, #demands do
							if storageItem.ItemId == demands[a].ItemId then
								accepted = true;
								break;
							end
						end
						
						if accepted then
							totalItemsCount = totalItemsCount + storageItem.Quantity;
						else
							validTrade = 2;
						end
					end);
					
					if playerObj.Gold ~= 0 then
						validTrade = 2;
					end
					
					if totalItemsCount >= 2 then
						validTrade = 3;
					end
					
					-- Evaluate;
					if validTrade == 0 and totalItemsCount == 1 then
						validTrade = 1;
						
						npcTradeStorage:Insert{ItemId=supplys[offerIndex].ItemId; Data={Quantity=1;}};
						tradingSession:SetData(npcName, "Message", "Yeah, that looks good..");
						
					elseif validTrade == 3 then
						tradingSession:SetData(npcName, "Message", "Let's trade 1 commodity at a time.");
						
					elseif #totalItemsCount <= 0 then
						tradingSession:SetData(npcName, "Message", "I'm looking for these items below.");
						
					else
						tradingSession:SetData(npcName, "Message", "Errr.. These aren't commodities..");
						
					end
					
					tradingSession:Sync("tradesession");
				end
				
				
				tradingSession:BindGoldUpdate(processTrade);
				tradingSession:BindStorageUpdate(processTrade);
				
				tradingSession:Sync("tradesession", true);
			end);
		end

	end 
end

return Dialogues;