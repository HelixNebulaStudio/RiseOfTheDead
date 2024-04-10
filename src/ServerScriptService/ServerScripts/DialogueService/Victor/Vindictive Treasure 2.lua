local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modGameModeManager = require(game.ServerScriptService.ServerLibrary.GameModeManager);

--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active;
		if mission.ProgressionPoint == 3 then
			local gaveMask = data:Get("gaveMask");
			if gaveMask then
				dialog:SetInitiate("What's up?", "Bored");
			else
				dialog:SetInitiate("What do you want?", "Bored");
			end
			
			dialog:AddChoice("vt2_cultist", function(dialog)
				dialog:AddChoice("vt2_cultist2", function(dialog)
					dialog:AddChoice("vt2_cultist3", function(dialog)
						dialog:AddChoice("vt2_outfit", function(dialog)
							modMission:Progress(player, 41, function(mission)
								if mission.ProgressionPoint <= 3 then
									mission.ProgressionPoint = 4;
								end;
							end)
						end)
					end)
				end)
			end)
			
		else
			dialog:SetInitiate("Hmmm..", "Bored");
			
		end
		
	end
end