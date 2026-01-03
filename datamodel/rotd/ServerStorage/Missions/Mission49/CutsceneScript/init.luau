local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local MISSION_ID = 49;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheWarehouse") then return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
		
		
		if not modMission:IsComplete(player, MISSION_ID) then
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 4 then
						local new = script.Parent:WaitForChild("Vehicle Repair Manual"):Clone();
						new.Parent = workspace.Interactables;

						local newInteractConfig = modInteractables.createInteractable("Collectible");
						newInteractConfig:SetAttribute("_Id", "vrm");
						newInteractConfig:SetAttribute("Label", "Vehicle Repair Manual");
						newInteractConfig.Parent = new;
						
						modReplicationManager.ReplicateOut(player, new);
					end

				elseif mission.Type == 3 then -- OnComplete


				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end
	end)
	
	return CutsceneSequence;
end;