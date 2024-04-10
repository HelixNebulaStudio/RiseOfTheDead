local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);

--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		local stage = mission.ProgressionPoint;
		
		dialog:SetInitiate("Well..?");
		if stage == 2 then
			dialog:AddChoice("missingbody_voodoo", function(dialog)
				local profile = modProfile:Get(player);
				local activeInventory = profile.ActiveInventory;

				local hasSpace = activeInventory:SpaceCheck{{ItemId="voodoodoll"}};
				if not hasSpace then
					dialog:AddChoice("missingbody_invfull");
					
				else
					dialog:AddChoice("missingbody_takevoodoo", function(dialog)
						if mission.ProgressionPoint == 2 then mission.ProgressionPoint = 3; end;
						activeInventory:Add("voodoodoll");
						shared.Notify(player, "You recieved a Voodoo Doll.", "Reward");
					end)
					
				end
			end);
			
		elseif stage == 3 then
			
		end
		
	elseif mission.Type == 2 then -- Available
		dialog:SetInitiate("Memories.. Last breath.. Where?..", "Happy");
		dialog:AddChoice("missingbody_init", function(dialog)
			modMission:StartMission(player, 43);
		end);
		
	end
end
