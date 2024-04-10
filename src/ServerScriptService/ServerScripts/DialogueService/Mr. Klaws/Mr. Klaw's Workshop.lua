local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);

--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		if mission.ProgressionPoint == 3 then
			dialog:AddChoice("klawsWorkshop_done", function(dialog)
				modMission:CompleteMission(player, 57);
			end)
		end
	
	elseif mission.Type == 2 then -- Available

		dialog:SetInitiate("Darn it, I just realized I left my journal in my workshop. Can you help me get it?", "Ugh");
		dialog:AddChoice("klawsWorkshop_init", function(dialog)
			
			local profile = shared.modProfile:Get(player);
			local activeInventory = profile.ActiveInventory;
			local hasSpace = activeInventory:SpaceCheck{
				{ItemId="klawsmap"; Data={Quantity=1}};
			};
			
			if hasSpace then
				activeInventory:Add("klawsmap");
				modMission:StartMission(player, 57);
				shared.Notify(player, "You have received Mr. Klaw's Workshop Map!", "Positive");
				
			else
				shared.Notify(player, "Inventory is full!", "Negative");
			end
		end);
		
	end
end
