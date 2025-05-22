local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionFunctions = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modMapLibrary = shared.require(game.ReplicatedStorage.Library.MapLibrary);

local missionId = 75;
if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	function MissionFunctions.Init(missionProfile, mission)
		Debugger:StudioLog("MissionFunctions: ", mission)
		local player = missionProfile.Player;

		local clinicLoop = false;
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable

			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 2 then
					if modBranchConfigs.IsWorld("TheMall") then
						if clinicLoop == false then
							clinicLoop = true;
							
							task.spawn(function()
								while clinicLoop do
									task.wait(2.5);
									if not game.Players:IsAncestorOf(player) then break; end;
									
									local classPlayer = shared.modPlayers.get(player);

									local layerName, layerData = modMapLibrary:GetLayer(classPlayer:GetCFrame().Position);
									if layerName == "Clinic Safehouse" then
										modMission:Progress(player, missionId, function(mission)
											if mission.ProgressionPoint <= 3 then
												mission.ProgressionPoint = 3;
											end
										end);
										break;
									end

								end
							end)
						end
					end
					
				elseif mission.ProgressionPoint >= 4 and mission.ProgressionPoint <= 11 and not modBranchConfigs.IsWorld("MedicalBreakthrough") then
					modMission:Progress(player, missionId, function(mission)
						mission.ProgressionPoint = 3;
					end);
					
				end
			elseif mission.Type == 3 then -- OnComplete


			end
		end
		
		mission.Changed:Connect(OnChanged);
		OnChanged(true);
	end
end

return MissionFunctions;