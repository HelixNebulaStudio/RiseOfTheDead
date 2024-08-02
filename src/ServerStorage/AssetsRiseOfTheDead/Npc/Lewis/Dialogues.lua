local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Should have burned this place down when I had the chance.";
	};
	["init2"]={
		Reply="Easy come, easy go, as they say..";
	};
	["init3"]={
		Reply="Jesus H. Christ, I'm getting old..";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["shop_ratShop"]={
		Say="Do you sell anything?";
		Reply="Yes, that's what I do here.";
		ReplyFunction=function(dialogPacket)
			local npcModel = dialogPacket.Prefab;
		if npcModel:FindFirstChild("shopInteractable") then
				local localPlayer = game.Players.LocalPlayer;
				local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);

				modData.InteractRequest(npcModel.shopInteractable, npcModel.PrimaryPart);
		end
		end};
	
	["general_steel"]={
		Say="Umm, do you know where I can get steel fragments?"; 
		Reply="Oh, you came to the right place, I can exchange steel fragments for blueprints.";
	};
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modTradingService = require(game.ServerScriptService.ServerLibrary.TradingService);
		local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
		
		local bpDemands = {
			{ItemId="revolver454bp";};
			{ItemId="grenadelauncherbp";};
			{ItemId="flamethrowerbp";};
			{ItemId="minigunbp";};
			{ItemId="mp7bp";};
			{ItemId="deaglebp";};
		};

		local npcName = dialog.Name;
		
		dialog:AddChoice("shop_ratShop");
		if modEvents:GetEvent(player, "lewis_purpose") == nil then
			dialog:AddChoice("general_steel", function()
				modEvents:NewEvent(player, {Id="lewis_purpose"});
			end);
			
		else
			dialog:AddDialog({
				Face="Skeptical";
				Dialogue="I want to trade for some steel fragments.";
				Reply="This is what I need..";
				ToggleWindow="Trade";
				
			}, function(dialog)
				local tradingSession = modTradingService:NewComputerSession(player, npcName);
				tradingSession:SetData(npcName, "HideGold", true);
				
				local npcTradeStorage = tradingSession.Storages[npcName];
				
				tradingSession:SetData(npcName, "Demands", bpDemands);
				
				tradingSession:BindStateUpdate(function()
					
				end)
				
				local validTrade = 0;
				tradingSession:BindConfirmSet(function(self, playerObj)
					
					if playerObj.Confirm then
						if validTrade == 1 then
							tradingSession:SetData(npcName, "Message", "Glad we could work something out buddy.");
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
					validTrade = 0;
					npcTradeStorage:Wipe();
					
					local bpQuantity = 0;
					
					local playerDeposits = tradingSession.Storages[player.Name];
					local _itemCount = playerDeposits:Loop(function(storageItem)
						local accepted = false;
						for a=1, #bpDemands do
							if storageItem.ItemId == bpDemands[a].ItemId then
								accepted = true;
								break;
							end
						end
						
						if accepted then
							bpQuantity = bpQuantity + storageItem.Quantity;
						else
							validTrade = 2;
						end
					end);
					
					if playerObj.Gold ~= 0 then
						validTrade = 2;
					end
					
					-- Evaluate;
					if validTrade == 0 and bpQuantity > 0 then
						validTrade = 1;
						npcTradeStorage:Insert{ItemId="steelfragments"; Data={Quantity=(bpQuantity * 4);}};
						tradingSession:SetData(npcName, "Message", "Looks pretty good to me..");
						
					elseif bpQuantity <= 0 then
						tradingSession:SetData(npcName, "Message", "I just need these blueprints.");
						
					else
						tradingSession:SetData(npcName, "Message", "Umm, what's going on?");
						
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