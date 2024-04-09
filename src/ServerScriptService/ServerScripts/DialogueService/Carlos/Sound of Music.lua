local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);

--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		local stage = mission.ProgressionPoint;
		if stage == 1 then

			local profile = modProfile:Get(player);
			local activeInventory = profile.ActiveInventory;

			local hasSpace = activeInventory:SpaceCheck{{ItemId="flute"}};
			if not hasSpace then
				dialog:AddChoice("soundOfMusic_full");

			else
				dialog:AddChoice("soundOfMusic_take", function(dialog)
					if mission.ProgressionPoint == 1 then mission.ProgressionPoint = 2; end;
					activeInventory:Add("flute");
					shared.Notify(player, "You recieved a Flute.", "Reward");
				end)

			end
			
			modMission:Progress(player, 14, function(mission)
				if mission.ProgressionPoint < 3 then
					mission.ProgressionPoint = 3;
				end;
			end)
			
		elseif stage == 3 then
			dialog:AddChoice("soundOfMusic_done", function(dialog)
				modMission:CompleteMission(player, 47);
			end)
			
		end
		dialog:AddChoice("soundOfMusic_how");
		
	elseif mission.Type == 2 then -- Available;
		dialog:AddChoice("soundOfMusic_get", function(dialog)
			dialog:AddChoice("soundOfMusic_sure", function(dialog)
				modMission:StartMission(player, 47);
			end)
		end)
		
	end
end
