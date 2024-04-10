local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);

return function(player, dialog, dialogueData)
	local mission10 = modMission:GetMission(player, 10);
	if mission10 == nil then
		dialog:SetInitiate("GET BACK! Stay away from me, I am infected.");
		dialog:AddChoice("infected_letmehelp", function(dialog)
			dialog:AddChoice("infected_insist", function(dialog)
				modMission:StartMission(player, 10);
			end)
		end)
		
	end
	
	--if modMission:Progress(player, 10) then
	--	--dialog:SetInitiate("Found the antibiotics yet?");
	--	--local mission = modMission:GetMission(player, 10);
	--	--local item, storage = modStorage.FindItemIdFromStorages("antibiotics", player);
		
	--	--if item then
	--	--	dialog:AddChoice("infected_foundit", function(dialog)
	--	--		storage:Remove(item.ID);
	--	--		modMission:CompleteMission(player, 10);
	--	--		local profile = modProfile:Get(player);
	--	--		profile:Unlock("ColorPacks", "Army", true);
	--	--	end);
	--	--elseif (os.time()-mission.StartTime) > 300 then
	--	--	dialog:AddChoice("infected_helper", function(dialog)
	--	--		if modEvents:GetEvent(player, "mission10_antibiotics") == nil then
	--	--			modEvents:NewEvent(player, {Id="mission10_antibiotics"});
	--	--		end
	--	--	end);
	--	--end
		
	--elseif modMission:IsComplete(player, 10) then
	--	--dialog:SetInitiate("Thanks again, you can leave me here for now.. I'll be fine.");
		
	--else
	--	dialog:SetInitiate("GET BACK! Stay away from me, I am infected.");
	--	dialog:AddChoice("infected_letmehelp", function(dialog)
	--		dialog:AddChoice("infected_insist", function(dialog)
	--			modMission:StartMission(player, 10);
	--		end)
	--	end)
		
	--end
end
