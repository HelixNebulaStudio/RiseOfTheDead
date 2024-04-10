local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		local stage = mission.ProgressionPoint;
		dialog:SetInitiate("Have you made contact yet?");
		if stage == 1 then
			dialog:AddChoice("qa1_notyet");
			
		elseif stage == 6 then
			dialog:AddChoice("qa1_done", function(dialog)
				dialog:AddChoice("qa1_done2", function(dialog)
					dialog:AddChoice("qa1_done3", function(dialog)
						modMission:CompleteMission(player, 51);
					end)
				end)
			end)
		end
		
	elseif mission.Type == 2 then -- Available
		dialog:SetInitiate("$PlayerName, I need your help quick.");
		dialog:AddChoice("qa1_hq", function(dialog)
			dialog:AddChoice("qa1_no", function(dialog)
				dialog:AddChoice("qa1_sample", function(dialog)
					dialog:AddChoice("qa1_contact", function(dialog)
						dialog:AddChoice("qa1_radio", function(dialog)
							modMission:StartMission(player, 51);
						end)
					end)
				end)
			end)
		end)
		
	end
end
