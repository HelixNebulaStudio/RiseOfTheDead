local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

--=
local Dialogues = {
	Lydia={};
};

local missionId = 78;
--==

-- MARK: Lydia Dialogues
Dialogues.Lydia.Dialogues = function()
	return {
		{Tag="killhue_init";
			Face="Happy"; Reply="Hi $PlayerName!";};

		{CheckMission=missionId; Tag="killhue_start"; Dialogue="Hey Lydia, how are you doing?";
			Face="Worried"; Reply="I'm alright.. But since you're here, I have a request.";
			FailResponses = {
				{Reply="Hmm, actually nevermind.."};
			};
		};
		{Tag="killhue_start2"; Dialogue="Oh, what are you requesting?";
			Face="Worried"; Reply="I've been wanting to kill zombies, but I've never used a gun before."};
		{Tag="killhue_start3"; Dialogue="I could teach you how to use a gun.";
			Face="Happy"; Reply="Yay! Oh, but I don't actually have a gun."};
		{Tag="killhue_start4"; Dialogue="Don't worry, I will get you a gun.";
			Face="Happy"; Reply="Oooo. Sure, I'll wait here."};

		{Tag="killhue_giveGun"; Dialogue="Hey, I got a gun for you.";
			Face="Happy"; Reply="Yay!"};

		{Tag="killhue_finInit";
			Face="Joyful"; Reply="That was really fun, thanks for letting me learn and shoot some zombies!";};
		{Tag="killhue_fin1"; Dialogue="You did pretty good! Now you can defend yourself with the gun.";
			Face="Suspicious"; Reply="Mhm! Hmmmm, Something does bother me. Nothing too important but.."};
		{Tag="killhue_fin2"; Dialogue="..? What's bothering you?";
			Face="Oops"; Reply="The colors of the gun.. Hahah! I like to decorate the things I have.."};
		{Tag="killhue_fin3"; Dialogue="Ohh";
			Face="Oops"; Reply="You know what, since you taught me how to shoot, how about I scavenge some new colors for your weapons?"};
		{Tag="killhue_fin4"; Dialogue="Sure, I guess..";
			Face="Happy"; Reply="Yay! I'll see what I can find."};
	};
end

if RunService:IsServer() then
	local npcName = "Lydia";
	-- MARK: Lydia Handler
	Dialogues.Lydia.DialogueHandler = function(player, dialog, data, mission)
		local modTradingService = require(game.ServerScriptService.ServerLibrary.TradingService);
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
		local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);

		local lydiaModule = modNpc.GetNpcModule(dialog.Prefab)
		if lydiaModule == nil or lydiaModule.Owner ~= player then
			shared.Notify(player, "[The Killer Hues] You are not in your safehome for this mission.", "Inform"); 
			return;
		end;

		if mission.Type == 2 then -- Available
			dialog:SetInitiateTag("killhue_init");
			dialog:AddChoice("killhue_start", function(dialog)
				dialog:AddChoice("killhue_start2", function(dialog)
					dialog:AddChoice("killhue_start3", function(dialog)
						dialog:AddChoice("killhue_start4", function(dialog)
							modMission:StartMission(player, missionId);
						end);
					end);
				end);
			end);

		elseif mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 1 then
				dialog:AddChoice("killhue_giveGun", function(dialog)
					local tradingSession = modTradingService:NewComputerSession(player, npcName);
					tradingSession:SetData(npcName, "HideGold", true);
					
					local npcTradeStorage = tradingSession.Storages[npcName];
					
					local failTrade = nil;
					local weaponStorageItem = nil;
					tradingSession:BindStateUpdate(function()
						if tradingSession.State == 3 then
							Debugger:Warn("Give Lydia", weaponStorageItem);
							
							local profile = shared.modProfile:Get(player);
							local safehomeData = profile.Safehome;
							
							local npcData = safehomeData:GetNpc(npcName);
							npcData.Weapon = weaponStorageItem;
	
							modMission:Progress(player, missionId, function(mission)
								if mission.ProgressionPoint == 1 then
									mission.ProgressionPoint = 2;
								end
							end)
						end
					end)
					
					tradingSession:BindConfirmSet(function(self, playerObj)
						if playerObj.Confirm then
							if weaponStorageItem  then
								tradingSession:SetData(npcName, "Message", "Yay, let's go zombies hunting!");
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
						npcTradeStorage:Wipe();
						weaponStorageItem = nil;
						
						local playerDeposits = tradingSession.Storages[player.Name];
						local itemCount = playerDeposits:Loop(function(storageItem)
							if modItemsLibrary:HasTag(storageItem.ItemId, "Gun") ~= true then
								failTrade = "This doesn't look like a gun.";
								return;
							end
							
							if modItemsLibrary:HasTag(storageItem.ItemId, "Pistol")
							or modItemsLibrary:HasTag(storageItem.ItemId, "Shotgun")
							or modItemsLibrary:HasTag(storageItem.ItemId, "Submachine gun")
							or modItemsLibrary:HasTag(storageItem.ItemId, "Rifle") then
								weaponStorageItem = storageItem;
								failTrade = nil;
	
							else
								failTrade = "That gun looks cool, but it looks too complicated for me, can I have something simpler?";
	
							end
						end);
						
						if itemCount >= 2 then
							failTrade = "Why is there more than one items??";
						end
						if playerObj.Gold ~= 0 then
							failTrade = "Why is there gold??";
						end
						
						-- Evaluate;
						if failTrade then
							weaponStorageItem = nil;
							tradingSession:SetData(npcName, "Message", failTrade);
	
						elseif weaponStorageItem == nil then
							tradingSession:SetData(npcName, "Message", "I hope the gun is pretty. :3");
	
						elseif weaponStorageItem ~= nil then
							tradingSession:SetData(npcName, "Message", "Ooo, that's a cool gun!");
							
						end
	
						tradingSession:Sync("tradesession");
					end
					
					tradingSession:BindGoldUpdate(processTrade);
					tradingSession:BindStorageUpdate(processTrade);
	
					tradingSession:Sync("tradesession", true);
				end);
				
			elseif mission.ProgressionPoint == 5 then
				dialog:SetInitiateTag("killhue_finInit");
				dialog:AddChoice("killhue_fin1", function(dialog)
					dialog:AddChoice("killhue_fin2", function(dialog)
						dialog:AddChoice("killhue_fin3", function(dialog)
							dialog:AddChoice("killhue_fin4", function(dialog)
								modMission:CompleteMission(player, missionId);
								shared.Notify(player, "Lydia can now scavenge custom colors to unlock for customizing your weapons.", "Inform");
							end)
						end)
					end)
				end)

			end
			
		end
	end
end


return Dialogues;