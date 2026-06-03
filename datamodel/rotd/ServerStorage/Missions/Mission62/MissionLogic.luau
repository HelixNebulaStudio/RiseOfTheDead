local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

local MISSION_ID = 62;

local MissionLogic = {};
--==

if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	local modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);
	local modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
	
	cutsceneAssets = script.Parent:WaitForChild("CutsceneAssets");

	if shared.WorldName == "TheUnderground" then
        shared.modEventService:OnInvoked("Generic_BindTrigger", function(event: EventPacket, ...)
            local player: Player? = event.Player;
            if player == nil then return end;

			local triggerId: string, interactable: InteractableInstance = ...;

			task.spawn(function()
				if triggerId == "RatsRecruitment_SectorF" then
					modServerManager:TeleportToPrivateServer(
						"SectorF", 
						modServerManager:CreatePrivateServer("SectorF"), 
						{player}
					);
				end
			end)
		end);

	elseif shared.WorldName == "SectorF" then
		researchPaper = workspace.Interactables:WaitForChild("researchPapers");
	end
	
	function MissionLogic.Init(missionProfile, mission)
		local player: Player = missionProfile.Player;

		local function OnChanged(firstRun)
			if mission.Type == 1 then -- OnActive
			
				if modBranchConfigurations.IsWorld("SectorE") then

				else
					if mission.ProgressionPoint >= 3 and mission.ProgressionPoint <= 11 then
						if firstRun then
							modMission:Progress(player, MISSION_ID, function(mission)
								mission.ProgressionPoint = 2;
								Debugger:Log("Rewind mission 62 to point 2.");
							end)
						end
						
					elseif mission.ProgressionPoint == 12 then
						

					elseif mission.ProgressionPoint == 13 or mission.ProgressionPoint == 14 then
						if firstRun then
							modMission:Progress(player, MISSION_ID, function(mission)
								mission.ProgressionPoint = 12;
								Debugger:Log("Rewind mission 62 to point 12.");
							end)
						end
						
					end
				end
				
				if modBranchConfigurations.IsWorld("SectorF") and modGameModeManager.IsGameWorld ~= true then
					if mission.ProgressionPoint >= 13 then
						researchPaper.Parent = game.ReplicatedStorage.Replicated;
						
						if mission.ProgressionPoint == 13 
						and workspace.Interactables:FindFirstChild("mission62ResearchPapers") == nil then
							Debugger:Warn("Spawn research papers pickup")
							local newResearchPaper = researchPaper:Clone();
							newResearchPaper:WaitForChild("Interactable"):Destroy();
							
							local pickUpInteractConfig = modInteractables.createInteractable("Pickupable");
							pickUpInteractConfig:SetAttribute("_IndicatorPresist", true);
							pickUpInteractConfig:SetAttribute("ItemId", "researchpapers");
							pickUpInteractConfig.Parent = newResearchPaper;

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
						
					end
					
				elseif modBranchConfigurations.IsWorld("TheUnderground") then
					if mission.ProgressionPoint == 12 then
						local secFEntrance = cutsceneAssets:WaitForChild("sectorFEntrance"):Clone();

						local interactConfig = modInteractables.createInteractable("ButtonRotd");
						interactConfig:SetAttribute("_Id", "RatsRecruitment_SectorF");
						interactConfig:SetAttribute("_Label", "[Rats Recruitment] Enter Sector F");
						interactConfig:SetAttribute("_InteractDuration", 1);
						interactConfig.Parent = secFEntrance;

						secFEntrance.Parent = workspace.Interactables;
						
						modReplicationManager.ReplicateOut(player, secFEntrance);
					end
					
				end
			
			end
		end
		
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end
end

return MissionLogic;