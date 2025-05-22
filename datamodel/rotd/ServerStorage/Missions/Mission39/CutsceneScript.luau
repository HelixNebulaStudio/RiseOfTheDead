local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local MISSION_ID = 39;

if RunService:IsServer() then
	wallTriggers = script.Parent:WaitForChild("WallTriggers");
	templateInteractable = script.Parent:WaitForChild("Interactable");

	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheMall") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
			

		local loaded = false;
		local function load()
			if loaded then return end;
			loaded = true;
			for _, obj in pairs(wallTriggers:GetChildren()) do
				local newObj = obj:Clone();
				local built = mission.ObjectivesCompleted[obj.Name];
				
				if built ~= true then
					local parts = newObj:WaitForChild("Objects"):GetDescendants();
					for a=1, #parts do
						if parts[a]:IsA("BasePart") then
							parts[a].CanCollide = false;
							parts[a].Transparency = 0.5;
						end
					end
					local newInteractable = templateInteractable:Clone();
					newInteractable.Parent = newObj;
					
					local modInteractable = shared.require(newInteractable);
					modInteractable.Object = newObj;
					modInteractable.SubId = obj.Name;
					modInteractable.Label = "Build spiked fence with 20 wood";
					
					modReplicationManager.ReplicateIn(player, newObj, workspace.Interactables);
					modInteractable:Sync();
				else
					modReplicationManager.ReplicateIn(player, newObj:WaitForChild("Objects"), workspace.Environment);
					if newObj:FindFirstChild("Interactables") then
						modReplicationManager.ReplicateIn(player, newObj.Interactables, workspace.Interactables);
					end
				end
			end
		end


		if modMission:IsComplete(player, MISSION_ID) then
			load();
			return;
		end
		
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				load();
			elseif mission.Type == 3 then -- OnComplete
				mission.OnChanged:Disconnect(OnChanged);
			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;