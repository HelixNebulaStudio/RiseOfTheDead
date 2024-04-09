local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionFunctions = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);

if RunService:IsServer() then
	local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);
	local modGameModeManager = require(game.ServerScriptService.ServerLibrary.GameModeManager);
	
	if modBranchConfigs.IsWorld("TheUnderground") then
		modOnGameEvents:ConnectEvent("OnTrigger", function(player, interactData, packet)
			local triggerId = interactData.TriggerTag;

			if triggerId == "RatsRecruitment_SectorF" then
				modServerManager:TeleportToPrivateServer("SectorF", modServerManager:CreatePrivateServer("SectorF"), {player});
				
			end
		end);
	end
	
	function MissionFunctions.Init(missionProfile, mission)
		Debugger:Log("MissionFunctions: ", mission)
		local player = missionProfile.Player;
		
		
		local function OnChanged(firstRun, mission)
			if mission.Type == 3 then
				
			else
				if mission.Type == 1 then -- OnActive
					if modBranchConfigs.IsWorld("SectorE") then

					else
						if mission.ProgressionPoint >= 3 and mission.ProgressionPoint <= 11 then
							if firstRun then
								modMission:Progress(player, 62, function(mission)
									mission.ProgressionPoint = 2;
									Debugger:Log("Rewind mission 62 to point 2.");
								end)
							end
							
						elseif mission.ProgressionPoint == 12 then
							

						elseif mission.ProgressionPoint == 13 or mission.ProgressionPoint == 14 then
							if firstRun then
								modMission:Progress(player, 62, function(mission)
									mission.ProgressionPoint = 12;
									Debugger:Log("Rewind mission 62 to point 12.");
								end)
							end
							
						end
					end
					
					if modBranchConfigs.IsWorld("SectorF") and modGameModeManager.GameWorld ~= true then
						if mission.ProgressionPoint >= 13 then
							--game.Debris:AddItem(workspace.Interactables:FindFirstChild("gameExit"), 0);
							
							local pickUpInteractable = script:WaitForChild("PickUpInteractable");
							local researchPaper = workspace.Interactables:WaitForChild("researchPapers");
							
							researchPaper.Parent = game.ReplicatedStorage.Replicated;
							
							if mission.ProgressionPoint == 13 and workspace.Interactables:FindFirstChild("mission62ResearchPapers") == nil then
								Debugger:Warn("Spawn research papers pickup")
								local newResearchPaper = researchPaper:Clone();
								newResearchPaper:WaitForChild("Interactable"):Destroy();
								
								local newInteractableModule = pickUpInteractable:Clone();
								newInteractableModule.Name = "Interactable";
								newInteractableModule.Parent = newResearchPaper;

								local pointLight = Instance.new("PointLight");
								pointLight.Color = Color3.fromRGB(255, 239, 158);
								pointLight.Brightness = 2;
								pointLight.Range = 4;
								pointLight.Shadows = false;
								pointLight.Parent = newResearchPaper:WaitForChild("Papers");
								
								newResearchPaper.Name = "mission62ResearchPapers";
								newResearchPaper.Parent = workspace.Interactables;
								
								modReplicationManager.ReplicateOut(player, newResearchPaper);
							end
							
							if mission.ProgressionPoint == 15 then
								local newExit = script:WaitForChild("Travel_TheUnderground"):Clone();
								newExit.Parent = workspace.Interactables;
								
							end
						end
						
					elseif modBranchConfigs.IsWorld("TheUnderground") then
						if mission.ProgressionPoint == 12 then
							local secFEntrance = script:WaitForChild("sectorFEntrance"):Clone();
							secFEntrance.Parent = workspace.Interactables;
							
							modReplicationManager.ReplicateOut(player, secFEntrance);
						end
						
					end

				end
			end
		end
		
		mission.Changed:Connect(OnChanged);
		OnChanged(true, mission);
	end
end

return MissionFunctions;
