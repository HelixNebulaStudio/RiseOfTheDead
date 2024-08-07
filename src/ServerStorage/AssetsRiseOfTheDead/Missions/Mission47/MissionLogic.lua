local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local missionId = 47;
if RunService:IsServer() then
	local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
	if not modBranchConfigs.IsWorld("TheWarehouse") then return {} end;


	modOnGameEvents:ConnectEvent("OnInstrumentPlay", function(player, instrumentType, notesChanged)
		local carlosPrefab = workspace.Entity:FindFirstChild("Carlos");
		if carlosPrefab == nil or carlosPrefab.PrimaryPart == nil then return end;

		local profile = shared.modProfile:Get(player);
		if profile == nil or profile.Junk == nil then return end;
		
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
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint == 2 then
							shared.Notify(player, "[Carlos] Wow, you did it!", "Message");
							mission.ProgressionPoint = 3;
						end;
					end)
					
				elseif activeNote ~= nil and a == #profile.Junk.M47List then
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint == 2 then
							shared.Notify(player, "[Carlos] Nice, now play the ["..songNotes[a+1].."] note.", "Message");
						end;
					end)
					
				end
			else
				modMission:Progress(player, missionId, function(mission)
					if mission.ProgressionPoint == 2 then
						shared.Notify(player, "[Carlos] Oh, that was the wrong note "..player.Name..", let's try that again.", "Message");
					end;
				end)
				profile.Junk.M47List = {};
				break;
			end
		end
			
	end)
end

return MissionLogic;