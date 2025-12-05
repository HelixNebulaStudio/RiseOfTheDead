local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

local MISSION_ID = 62;

local MissionLogic = {};
--==

if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	local modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);
	local modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
	
	local logicAssets = script.Parent:WaitForChild("LogicAssets");

	if modBranchConfigs.IsWorld("TheUnderground") then
		shared.modEventService:OnInvoked("Interactables_BindTrigger", function(eventPacket: EventPacket, interactData, packet)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;
			
			local triggerId = interactData.TriggerTag;

			if triggerId == "RatsRecruitment_SectorF" then
				modServerManager:TeleportToPrivateServer(
					"SectorF", 
					modServerManager:CreatePrivateServer("SectorF"), 
					{player}
				);
			end
		end);
	end
	
	function MissionLogic.Init(missionProfile, mission)
		local player: Player = missionProfile.Player;

		local function OnChanged(firstRun)
			if mission.Type == 1 then -- OnActive
			
				if modBranchConfigs.IsWorld("SectorE") then

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
				
				if modBranchConfigs.IsWorld("SectorF") and modGameModeManager.IsGameWorld ~= true then
					if mission.ProgressionPoint >= 13 then
						--game.Debris:AddItem(workspace.Interactables:FindFirstChild("gameExit"), 0);
						
						local researchPaper = workspace.Interactables:WaitForChild("researchPapers");
						
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
						
						if mission.ProgressionPoint == 15 then
							local newExit = logicAssets:WaitForChild("Travel_TheUnderground"):Clone();
							newExit.Parent = workspace.Interactables;
							
						end
					end
					
				elseif modBranchConfigs.IsWorld("TheUnderground") then
					if mission.ProgressionPoint == 12 then
						local secFEntrance = logicAssets:WaitForChild("sectorFEntrance"):Clone();
						secFEntrance.Parent = workspace.Interactables;
						
						modReplicationManager.ReplicateOut(player, secFEntrance);
					end
					
				end
			
			end
		end
		
		mission.Changed:Connect(OnChanged);
		OnChanged(true);
	end
end

return MissionLogic;