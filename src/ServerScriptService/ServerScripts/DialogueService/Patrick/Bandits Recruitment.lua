local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);

--==
return function(player, dialog, data, mission)
	if mission.Type == 2 then -- Available
		if mission.ProgressionPoint == 1 then
			dialog:SetInitiateTag("safehomeInit");
			dialog:AddChoice("theRecruit_settleB", function(dialog)
				dialog:AddChoice("theRecruit_settle2B", function(dialog)
					dialog:AddChoice("theRecruit_zark1", function(dialog)
						modMission:StartMission(player, 63);
					end)
				end)
				
				--local newDialog = {
				--	Face="Surprise";
				--	Dialogue="Hear anything about the Bandits or the Rats?";
				--	Reply="Yes, in fact, the Bandits has been recruiting lately. They are looking for the one who helped them during the cargo ship disaster.";
				--};
				
				--dialog:AddDialog(newDialog, function(dialog)
				--end);
			end);

		end

	elseif mission.Type == 1 then -- Active
		if mission.ProgressionPoint == 1 then
			
		end
		
	end
end
