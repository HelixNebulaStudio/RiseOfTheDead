local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);


--== When something happens;
return function(player, instrumentType, notesChanged)
	local profile = modProfile:Get(player);
	
	if profile and profile.Junk then
		local carlosPrefab = workspace.Entity:FindFirstChild("Carlos");
		if carlosPrefab == nil or carlosPrefab.PrimaryPart == nil then return end;
		if player:DistanceFromCharacter(carlosPrefab.PrimaryPart.Position) > 25 then return end;
		
		local songNotes = {"C:5"; "C:5"; "G:5"; "F:5"; "D#:5"; "D:5"; "D:5"; "D:5"; "F:5"; "D#:5"; "D:5"; "C:5"; "C:5"; "D#:5"; "D:5"; "D#:5"; "D:5"; "D#:5"};
		
		if profile.Junk.M47List == nil then
			profile.Junk.M47List = {};
		end
		
		local activeNote = nil;
		for k,_ in pairs(notesChanged) do
			if notesChanged[k] == true then
				activeNote = k;
				break;
			end
		end
		table.insert(profile.Junk.M47List, activeNote);
		
		for a=1, #profile.Junk.M47List do
			if profile.Junk.M47List[a] == songNotes[a] then
				if #songNotes == a then
					modMission:Progress(player, 47, function(mission)
						if mission.ProgressionPoint == 2 then
							shared.Notify(player, "[Carlos] Wow, you did it!", "Message");
							mission.ProgressionPoint = 3;
						end;
					end)
					
				elseif activeNote ~= nil and a == #profile.Junk.M47List then
					modMission:Progress(player, 47, function(mission)
						if mission.ProgressionPoint == 2 then
							shared.Notify(player, "[Carlos] Nice, now play the ["..songNotes[a+1].."] note.", "Message");
						end;
					end)
					
				end
			else
				modMission:Progress(player, 47, function(mission)
					if mission.ProgressionPoint == 2 then
						shared.Notify(player, "[Carlos] Oh, that was the wrong note "..player.Name..", let's try that again.", "Message");
					end;
				end)
				profile.Junk.M47List = {};
				break;
			end
		end
		
	end
end;
