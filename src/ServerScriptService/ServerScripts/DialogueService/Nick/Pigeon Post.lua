local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		if mission.ProgressionPoint <= 2 then
			dialog:SetInitiate("Please tell her the message as soon as you can.");
		else
			dialog:SetInitiate("Have you gotten the message to her?");
			dialog:AddChoice("pigeonPost_wrong", function(dialog)
				dialog:AddChoice("pigeonPost_didntKnow", function(dialog)
					dialog:AddChoice("pigeonPost_sayHi", function(dialog)
						modMission:CompleteMission(player, 14);
					end);
				end)
			end)
		end
		
	elseif mission.Type == 2 then -- Available
		dialog:SetInitiate("$PlayerName, could you help me with something?");
		dialog:AddChoice("pigeonPost_help", function(dialog)
			dialog:AddChoice("pigeonPost_hadfive", function(dialog)
				dialog:AddChoice("pigeonPost_yes", function(dialog)
					dialog:AddChoice("pigeonPost_sure", function(dialog)
						dialog:AddChoice("pigeonPost_gotit", function(dialog)
							modMission:StartMission(player, 14);
						end)
					end)
				end)
			end)
		end)
		
	end
end