local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Rachel={};
};

local missionId = 76;
local cache = {};

--==

-- !outline: Rachel Dialogues
Dialogues.Rachel.Dialogues = function()
	return {
		{ Tag="ziphon_create"; Dialogue="I got some material to make some Ziphoning Serum.";
			Face="Happy"; Reply="Alright"};
		

		{Tag="ziphon_init";
			Face="Happy"; Reply="$PlayerName, I managed to make use of our research. I just need some stuff to create a serum.";};
		{Tag="ziphon_serum"; Dialogue="Oh cool, a serum?";
			Face="Smirk"; Reply="Yes, upon consumption, it cleanses adverse health effects and also provides a temporary healing property. Tested it myself.."};
		{Tag="ziphon_serum2"; Dialogue="Wow, that's useful. What do you need?";
			Face="Happy"; Reply="If you could bring me these items on the checklist and come back to me. I can whip up a couple bottles."};
		{Tag="ziphon_serum3"; Dialogue="Sure!";
			Face="Happy"; Reply="Wonderful!"};
	};
end

if RunService:IsServer() then
	-- !outline: Rachel Handler
	Dialogues.Rachel.DialogueHandler = function(player, dialog, data, mission)
		local npcName = dialog.Name;
		
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
		local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
		local modTradingService = require(game.ServerScriptService.ServerLibrary.TradingService);

		if mission.Type == 2 then -- Available;

			
			
		elseif mission.Type == 1 then -- Active
			
			if mission.ProgressionPoint == 1 then

				if modEvents:GetEvent(player, "medbreFirstZiphon") then
					dialog:SetInitiateTag("ziphon_init");
					
					dialog:AddChoice("ziphon_serum", function(dialog)
						dialog:AddChoice("ziphon_serum2", function(dialog)
							dialog:AddChoice("ziphon_serum3", function(dialog)
								modEvents:RemoveEvent(player, "medbreFirstZiphon")
							end)
						end)
					end)
					return;
				end
				
				dialog:AddChoice("ziphon_create", function(dialog)
					-- Trade session;
					local tradingSession = modTradingService:NewComputerSession(player, npcName);
					tradingSession:SetData(npcName, "HideGold", true);

					local npcTradeStorage = tradingSession.Storages[npcName];
					
					local requiredItems = {
						{ItemId="nekronscales"; Quantity=6; };
						{ItemId="nekronparticulate"; Quantity=3;};
					};
					
					tradingSession:SetData(npcName, "Demands", requiredItems);

					tradingSession:BindStateUpdate(function()
						Debugger:Warn("Tradding State", tradingSession.State);
						if tradingSession.State == 3 then
							modMission:CompleteMission(player, 76);
						end
					end)

					local validTrade = 0;
					tradingSession:BindConfirmSet(function(self, playerObj)

						if playerObj.Confirm then
							if validTrade == 1 then
								tradingSession:SetData(npcName, "Message", "Wonderful! Here's the Ziphoning Serum.");
								tradingSession:SetConfirm(npcName, true);

							end

							tradingSession:Sync("tradesession");
						else
							tradingSession:SetConfirm(npcName, false);
							if tradingSession.State == 2 then
								tradingSession:SetData(npcName, "Message", "Hmm?");
								tradingSession:Sync("tradesession");
							end
						end
					end)

					local function processTrade(self, playerObj)
						validTrade = 0;
						npcTradeStorage:Wipe();
						

						local depositStorage = tradingSession.Storages[player.Name];
						
						local matchList = true;
						local quantityList = {};
						local itemCount = depositStorage:Loop(function(storageItem)
							local found = false;
							for a=1, #requiredItems do
								if storageItem.ItemId ~= requiredItems[a].ItemId then continue; end;
								found = true;
								if storageItem.Quantity == requiredItems[a].Quantity then
									quantityList[storageItem.ItemId] = requiredItems[a].Quantity;
									break;
								else
									matchList = false;
									break;
								end;
							end
							if not found then
								matchList = false;
							end
						end)
						if matchList then
							for a=1, #requiredItems do
								if quantityList[requiredItems[a].ItemId] ~= requiredItems[a].Quantity then
									matchList = false;
									break;
								end
							end
						end
						
						if matchList then
							validTrade = 1;
						end
						
						if playerObj.Gold ~= 0 then
							validTrade = 2;
						end
						
						if itemCount <= 0 then
							validTrade = 0;
						end
						
						-- Evaluate
						if validTrade == 1 then
							npcTradeStorage:Insert{ItemId="ziphoningserum"; Data={Quantity=5;}};
							tradingSession:SetData(npcName, "Message", "Yep, that's what I need.");
							
						elseif validTrade == 2 then
							tradingSession:SetData(npcName, "Message", "Thanks but I don't need the gold.");
							
						else
							tradingSession:SetData(npcName, "Message", "I need these items.");
						end
						
						tradingSession:Sync("tradesession");
					end


					tradingSession:BindGoldUpdate(processTrade);
					tradingSession:BindStorageUpdate(processTrade);

					tradingSession:Sync("tradesession", true);
					
				end)
				
			end
			
		elseif mission.Type == 4 then -- Failed
			
		end
	end

end


return Dialogues;