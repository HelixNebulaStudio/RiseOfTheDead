local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

--== When something happens;
return function(player, userWorkbench, processPacket)
	local modSyncTime = require(game.ReplicatedStorage.Library:WaitForChild("SyncTime"));
	local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	
	local itemId = processPacket.ItemId;
	
	if itemId == "pistoldamagebp" then
		if modMission:Progress(player, 5) then
			modMission:Progress(player, 5, function(mission)
				if mission.ProgressionPoint == 3 or mission.ProgressionPoint == 4 then
					mission.ProgressionPoint = 5;
					
					local buildDuration = 10;
					processPacket.BT=modSyncTime.GetTime()+buildDuration;
					userWorkbench:Sync();
					
					task.delay(buildDuration-1, function()
						modMission:Progress(player, 5, function(mission)
							if mission.ProgressionPoint == 4 or mission.ProgressionPoint == 5 then
								mission.ProgressionPoint = 6;
							end
						end)
					end)
				end;
			end)
		end
	end
	
end;