local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionFunctions = {};
local RunService = game:GetService("RunService");
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local MISSION_ID = 75;
if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	function MissionFunctions.Init(missionProfile, mission)
		Debugger:StudioLog("MissionFunctions: ", mission)
		local player = missionProfile.Player;

		local clinicLoop = false;
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable

			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint > 1 and mission.ProgressionPoint <= 11 and shared.WorldName ~= "MedicalBreakthrough" then
					if mission.ProgressionPoint == 2 and shared.WorldName == "TheMall" then
						if clinicLoop == false then
							clinicLoop = true;
							
							task.spawn(function()
								while clinicLoop do
									task.wait(2.5);
									if not game.Players:IsAncestorOf(player) then break; end;
									
									local location = player:GetAttribute("Location");
									if location == "Clinic Safehouse" then 
										modMission:Progress(player, MISSION_ID, function(mission)
											if mission.ProgressionPoint <= 3 then
												mission.ProgressionPoint = 3;
											end
										end)
									end
								end
							end)
						end
					end
					
					local profile = shared.modProfile:Get(player);
					local inventory = profile.ActiveInventory;
					local _, bloodSamplesList = inventory:ListQuantity("bloodsample", 1);

					if bloodSamplesList == nil or #bloodSamplesList <= 0 then
						clinicLoop = false;
						modMission:FailMission(player, MISSION_ID, "Stan's blood samples were destroyed.");
						return;
					end

				elseif mission.ProgressionPoint >= 4 and mission.ProgressionPoint <= 11 and shared.WorldName ~= "MedicalBreakthrough" then
					modMission:Progress(player, MISSION_ID, function(mission)
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