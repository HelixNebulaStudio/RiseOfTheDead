local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

--==
return function(player, dialog, data, mission)
	if mission.Type == 2 then -- Available
		dialog:SetInitiate("Yo! Stop right there.. Who are you?", "Angry");
		dialog:AddChoice("pokeTheBear_who", function(dialog)
			dialog:AddChoice("pokeTheBear_help", function(dialog)
				dialog:AddChoice("pokeTheBear_sure", function(dialog)
					modMission:StartMission(player, 30);
				end)
			end)
		end)
		
	elseif mission.Type == 1 then -- Active
		if mission.ProgressionPoint == 2 then
			dialog:SetInitiate("We're going to the Wrighton Dale Mall, I heard the Bandits set up camp there. They took over the place. You ready?", "Confident");
			dialog:AddChoice("pokeTheBear_mall", function(dialog)
				modMission:Progress(player, 30, function(mission)
					if mission.ProgressionPoint <= 2 then
						mission.ProgressionPoint = 3;
					end;
				end)
			end);
			
		elseif mission.ProgressionPoint == 4 then
			dialog:SetInitiate("Welcome to the Wrighton Dale Mall.. If the apocalypse didn't happen, the mall would've been completed by now.", "Sad");
			dialog:AddChoice("pokeTheBear_mallInfo", function(dialog)
				modMission:Progress(player, 30, function(mission)
					if mission.ProgressionPoint <= 4 then
						mission.ProgressionPoint = 5;
					end;
				end)
			end);
			
		elseif mission.ProgressionPoint == 9 then
			dialog:SetInitiate("Is he going to let us in?", "Joyful");
			dialog:AddChoice("pokeTheBear_wait", function(dialog)
				modMission:Progress(player, 30, function(mission)
					if mission.ProgressionPoint <= 9 then
						mission.ProgressionPoint = 10;
					end;
				end)
			end);
		end
		
	end
end
