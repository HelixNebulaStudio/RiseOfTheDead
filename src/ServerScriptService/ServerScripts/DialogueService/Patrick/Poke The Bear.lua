local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);

--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		if mission.ProgressionPoint == 7 then
			dialog:SetInitiate("What do you want?!", "Angry");
			dialog:AddChoice("pokeTheBear_start", function(dialog)
				local function bribe(dialog, isAggressive)
					dialog:AddChoice("pokeTheBear_bribe", function(dialog)
						
						data:Set("pokeTheBeat_isAggressive", isAggressive == true);
						modMission:Progress(player, 30, function(mission)
							if mission.ProgressionPoint <= 7 then
								mission.ProgressionPoint = 8;
							end;
						end)
					end);
				end
				
				data:Set("pokeTheBear_A", 1);
				data:Set("pokeTheBear_P", 1);
			
				local function loadChoices(dialog)
					local AState = data:Get("pokeTheBear_A") or 1;
					local PState = data:Get("pokeTheBear_P") or 1;
					dialog:AddChoice("pokeTheBear_A"..AState, function(dialog)
						data:Set("pokeTheBear_A", AState+1);
						if AState >= 3 then
							bribe(dialog, true);
						else
							loadChoices(dialog);
						end
					end);
					dialog:AddChoice("pokeTheBear_P"..PState, function(dialog)
						data:Set("pokeTheBear_P", PState+1);
						if PState >= 2 then
							bribe(dialog, false);
						else
							loadChoices(dialog);
						end
					end);
				end
				
				loadChoices(dialog);
			end);
			
		elseif mission.ProgressionPoint == 8 then
			local profile = modProfile:Get(player);
			local playerSave = profile:GetActiveSave();
			local inventory = playerSave.Inventory;
			local total, itemList = inventory:ListQuantity("cannedbeans", 3);
			
			dialog:SetInitiate("Well? Got any food or not?", "Skeptical");
			if total > 0 then
				local function giveFood(amt)
					local total, itemList = inventory:ListQuantity("cannedbeans", amt);
					if itemList then
						data:Set("pokeTheBear_beans", amt);
						for a=1, #itemList do
							inventory:Remove(itemList[a].ID, itemList[a].Quantity);
							shared.Notify(player, ("$AmountCanned Beans removed from your Inventory."):gsub("$Amount", itemList[a].Quantity > 1 and itemList[a].Quantity.." " or ""), "Negative");
						
						end
						modMission:Progress(player, 30, function(mission)
							if mission.ProgressionPoint <= 8 then
								mission.ProgressionPoint = 9;
							end;
						end)
					else
						shared.Notify(player, ("Unable to find items from inventory."), "Negative");
					end
				end
				
				dialog:AddChoice("pokeTheBear_beans1", function(dialog)
					giveFood(1);
				end)
				if total > 1 then
					dialog:AddChoice("pokeTheBear_beans2", function(dialog)
						giveFood(2);
					end)
					if total > 2 then
						dialog:AddChoice("pokeTheBear_beans3", function(dialog)
							giveFood(3);
						end)
					end
				end
			end
			
		end
		
	end
end