local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modNpcProfileLibrary = require(game.ReplicatedStorage.Library.NpcProfileLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);

local remotes = game.ReplicatedStorage.Remotes;
local remoteSetHeadIcon = remotes:WaitForChild("SetHeadIcon");

return function(player, dialog, data)
	local npcName = dialog.Name;
	
	local profile = shared.modProfile:Get(player);
	local safehomeData = profile.Safehome;
	
	local npcData = safehomeData:GetNpc(npcName);
	if npcData == nil then return end
	
	if modBranchConfigs.CurrentBranch.Name == "Dev" then
		dialog:AddChoice("shelter_report", function(dialog)
			Debugger:Log("npcData", npcData);
			npcData:CalculateHappiness();
			Debugger:WarnClient(player, npcData);
		end);
	end
	
	local npcLib = modNpcProfileLibrary:Find(npcName);
	local npcLevel = npcData.Level or 0;
	local npcHappiness = npcData.Happiness or 0;
	local levelUpTimer = npcLevel * 60;
	
	if modBranchConfigs.CurrentBranch.Name == "Dev" then levelUpTimer = 6; end;
	
	if npcData.LevelUpTime == nil then return end
	local unlockTime = npcData.LevelUpTime + (levelUpTimer);
	
	--============================= Medic Class 
	if npcLib.Class == "Medic" then
		if npcLevel == 1 then
			dialog:SetInitiateTag("shelter_lvl1_init");
			
			dialog:AddChoice("shelter_lvl1_choice1", function(dialog)
				local playerSave = profile:GetActiveSave();
				local inventory = playerSave.Inventory;
				local total, itemList = inventory:ListQuantity("medkit", 2);
				if total >= 2 then
					dialog:AddChoice("shelter_lvl1_a", function(dialog)
						for a=1, #itemList do
							inventory:Remove(itemList[a].ID, itemList[a].Quantity);
							shared.Notify(player, "2 Medkits removed from your Inventory.", "Negative");
						end
						
						npcData:SetLevel(2);
					end)
				else
					dialog:AddChoice("shelter_lvl1_b");
				end
			end)
			
		elseif npcLevel == 2 then
			dialog:SetInitiateTag("shelter_lvl2_init");
			
			dialog:AddChoice("shelter_lvl2_choice1", function(dialog)
				if os.time() >= unlockTime then
					npcData:SetLevel(3);
				end
			end, {ChoiceUnlockTime=unlockTime});
			
		elseif npcLevel == 3 then
			
			if os.time() >= unlockTime then
				dialog:SetInitiateTag("shelter_lvl3_init");
				
				dialog:AddChoice("shelter_lvl3_choice1", function(dialog)
					if os.time() >= unlockTime then
						npcData:SetLevel(4);
					end
				end, {ChoiceUnlockTime=unlockTime});
			end
			dialog:AddChoice("shelter_lvl3_choice2", nil, {ChoiceUnlockTime=unlockTime});
			
		elseif npcLevel == 4 then
			
			if os.time() >= unlockTime then
				dialog:SetInitiateTag("shelter_lvl4_init");
				
				dialog:AddChoice("shelter_lvl4_choice1", function(dialog)
					if os.time() >= unlockTime then
						npcData:SetLevel(5);
						
						remoteSetHeadIcon:FireAllClients(0, npcName, "HideAll");
						remoteSetHeadIcon:FireAllClients(1, npcName, "Heal");
						shared.Notify(player, "You now have a new medic in your safehome.", "Reward");
					end
				end, {ChoiceUnlockTime=unlockTime});
			end
			dialog:AddChoice("shelter_lvl4_choice2", nil, {ChoiceUnlockTime=unlockTime});
			
		elseif npcLevel == 5 then
			
			dialog:AddChoice("shelter_medic", function()
				modStatusEffects.FullHeal(player);
			end)
			
		end

	--============================= RAT	
	elseif npcLib.Class == "RAT" then
		
		if npcLevel == 1 then
			dialog:SetInitiateTag("shelter_lvl1_init");
			
			dialog:AddChoice("shelter_lvl1_choice1", function(dialog)
				local playerSave = profile:GetActiveSave();
				local inventory = playerSave.Inventory;
				local total, itemList = inventory:ListQuantity("metal", 200);
				if total >= 200 then
					dialog:AddChoice("shelter_lvl1_a", function(dialog)
						for a=1, #itemList do
							inventory:Remove(itemList[a].ID, itemList[a].Quantity);
							shared.Notify(player, "200 Metal Scraps removed from your Inventory.", "Negative");
						end
						
						npcData:SetLevel(2);
					end)
				else
					dialog:AddChoice("shelter_lvl1_b");
				end
			end)
			
		elseif npcLevel == 2 then
			dialog:SetInitiateTag("shelter_lvl2_init");
			
			dialog:AddChoice("shelter_lvl2_choice1", function(dialog)
				if os.time() >= unlockTime then
					npcData:SetLevel(3);
				end
			end, {ChoiceUnlockTime=unlockTime});
			
		elseif npcLevel == 3 then
			
			if os.time() >= unlockTime then
				dialog:SetInitiateTag("shelter_lvl3_init");
				
				dialog:AddChoice("shelter_lvl3_choice1", function(dialog)
					local playerSave = profile:GetActiveSave();
					local inventory = playerSave.Inventory;
					local total, itemList = inventory:ListQuantity("wood", 60);
					if total >= 60 then
						dialog:AddChoice("shelter_lvl3_choice1_a", function(dialog)
							if os.time() >= unlockTime then
								npcData:SetLevel(4);
								
								for a=1, #itemList do
									inventory:Remove(itemList[a].ID, itemList[a].Quantity);
									shared.Notify(player, "60 Wooden Parts removed from your Inventory.", "Negative");
								end
							end
						end)
					end
				end, {ChoiceUnlockTime=unlockTime});
			end
			dialog:AddChoice("shelter_lvl3_choice2", nil, {ChoiceUnlockTime=unlockTime});
			
		elseif npcLevel == 4 then
			
			if os.time() >= unlockTime then
				dialog:SetInitiateTag("shelter_lvl4_init");
				
				dialog:AddChoice("shelter_lvl4_choice1", function(dialog)
					if os.time() >= unlockTime then
						npcData:SetLevel(5);
						
						remoteSetHeadIcon:FireAllClients(0, npcName, "HideAll");
						shared.Notify(player, "You now have a new R.A.T. shop keeper in your safehome.", "Reward");
					end
				end, {ChoiceUnlockTime=unlockTime});
			end
			dialog:AddChoice("shelter_lvl4_choice2", nil, {ChoiceUnlockTime=unlockTime});
			
		elseif npcLevel == 5 then
			
			dialog:AddChoice("shelter_shop");
			
		end

	--============================= Recycler
	elseif npcLib.Class == "Recycler" then

		if npcLevel == 1 then
			dialog:SetInitiateTag("shelter_lvl1_init");

			dialog:AddChoice("shelter_lvl1_choice1", function(dialog)
				local playerSave = profile:GetActiveSave();
				local inventory = playerSave.Inventory;
				local total, itemList = inventory:ListQuantity("gears", 2);
				if total >= 2 then
					dialog:AddChoice("shelter_lvl1_a", function(dialog)
						for a=1, #itemList do
							inventory:Remove(itemList[a].ID, itemList[a].Quantity);
							shared.Notify(player, "2 Gears removed from your Inventory.", "Negative");
						end

						npcData:SetLevel(2);
					end)
				else
					dialog:AddChoice("shelter_lvl1_b");
				end
			end)

		elseif npcLevel == 2 then
			dialog:SetInitiateTag("shelter_lvl2_init");

			dialog:AddChoice("shelter_lvl2_choice1", function(dialog)
				if os.time() >= unlockTime then
					npcData:SetLevel(3);
				end
			end, {ChoiceUnlockTime=unlockTime});


		elseif npcLevel == 3 then

			if os.time() >= unlockTime then
				dialog:SetInitiateTag("shelter_lvl3_init");

				dialog:AddChoice("shelter_lvl3_choice1", function(dialog)
					local playerSave = profile:GetActiveSave();
					local inventory = playerSave.Inventory;
					local total, itemList = inventory:ListQuantity("steelfragments", 4);
					if total >= 4 then
						dialog:AddChoice("shelter_lvl3_choice1_a", function(dialog)
							if os.time() >= unlockTime then
								npcData:SetLevel(4);

								for a=1, #itemList do
									inventory:Remove(itemList[a].ID, itemList[a].Quantity);
									shared.Notify(player, "4 Steel Fragments removed from your Inventory.", "Negative");
								end
							end
						end)
					end
				end, {ChoiceUnlockTime=unlockTime});
			end
			dialog:AddChoice("shelter_lvl3_choice2", nil, {ChoiceUnlockTime=unlockTime});

		elseif npcLevel == 4 then

			if os.time() >= unlockTime then
				dialog:SetInitiateTag("shelter_lvl4_init");

				dialog:AddChoice("shelter_lvl4_choice1", function(dialog)
					if os.time() >= unlockTime then
						npcData:SetLevel(5);

						remoteSetHeadIcon:FireAllClients(0, npcName, "HideAll");
						shared.Notify(player, "You now have a new Recycler in your safehome.", "Reward");
					end
				end, {ChoiceUnlockTime=unlockTime});
			end
			dialog:AddChoice("shelter_lvl4_choice2", nil, {ChoiceUnlockTime=unlockTime});

		elseif npcLevel == 5 then
			dialog:AddChoice("shelter_recycle", require(script.Parent.DialogueModules:WaitForChild("RecyclerDialog")));
			
		end
		
	--============================= FortuneTeller	
	elseif npcLib.Class == "FortuneTeller" then
		
		if npcLevel == 1 then
			dialog:SetInitiateTag("shelter_lvl1_init");
			
			dialog:AddChoice("shelter_lvl1_choice1", function(dialog)
				local playerSave = profile:GetActiveSave();
				local inventory = playerSave.Inventory;
				local total, itemList = inventory:ListQuantity("bloxycola", 1);
				if total >= 1 then
					dialog:AddChoice("shelter_lvl1_a", function(dialog)
						for a=1, #itemList do
							inventory:Remove(itemList[a].ID, itemList[a].Quantity);
							shared.Notify(player, "Bloxy Cola removed from your Inventory.", "Negative");
						end
						
						npcData:SetLevel(2);
					end)
				else
					dialog:AddChoice("shelter_lvl1_b");
				end
			end)
			
		elseif npcLevel == 2 then
			dialog:SetInitiateTag("shelter_lvl2_init");
			
			dialog:AddChoice("shelter_lvl2_choice1", function(dialog)
				if os.time() >= unlockTime then
					npcData:SetLevel(3);
				end
			end, {ChoiceUnlockTime=unlockTime});
			
		elseif npcLevel == 3 then
			
			if os.time() >= unlockTime then
				dialog:SetInitiateTag("shelter_lvl3_init");
				
				dialog:AddChoice("shelter_lvl3_choice1", function(dialog)
					local playerSave = profile:GetActiveSave();
					local inventory = playerSave.Inventory;
					local total, itemList = inventory:ListQuantity("purplelemon", 1);
					if total >= 1 then
						dialog:AddChoice("shelter_lvl3_choice1_a", function(dialog)
							if os.time() >= unlockTime then
								npcData:SetLevel(4);
								
								for a=1, #itemList do
									inventory:Remove(itemList[a].ID, itemList[a].Quantity);
									shared.Notify(player, "Purple Lemon removed from your Inventory.", "Negative");
								end
							end
						end)
					else
						dialog:AddChoice("shelter_lvl3_choice1_b");
					end
				end, {ChoiceUnlockTime=unlockTime});
			end
			dialog:AddChoice("shelter_lvl3_choice2", nil, {ChoiceUnlockTime=unlockTime});
			
		elseif npcLevel == 4 then
			
			if os.time() >= unlockTime then
				dialog:SetInitiateTag("shelter_lvl4_init");
				
				dialog:AddChoice("shelter_lvl4_choice1", function(dialog)
					if os.time() >= unlockTime then
						npcData:SetLevel(5);
						
						remoteSetHeadIcon:FireAllClients(0, npcName, "HideAll");
						shared.Notify(player, "You now have a new Fortune Teller in your safehome.", "Reward");
					end
				end, {ChoiceUnlockTime=unlockTime});
			end
			dialog:AddChoice("shelter_lvl4_choice2", nil, {ChoiceUnlockTime=unlockTime});
			
		elseif npcLevel == 5 then
			dialog:SetInitiateTag("shelter_fortunetell");
			
		end
		
	end
	
	
	--if os.time()-npcData.Active >= 3600 then
	--	dialog:AddChoice("shelter_leave", function(dialog)
	--		dialog:AddChoice("shelter_leavec", function(dialog)
	--			npcData.Active = nil;
	--		end)
	--	end)
	--end
end
