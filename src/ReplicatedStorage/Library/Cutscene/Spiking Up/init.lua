local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);

local wallTriggers = script:WaitForChild("WallTriggers");
local templateInteractable = script:WaitForChild("Interactable");

local random = Random.new();
--== Server Variables;
if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	modDialogues = require(game.ServerScriptService.ServerLibrary.DialogueSave);
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheMall") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player = players[1];
		local mission = modMission:GetMission(player, 39);
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
					
					local modInteractable = require(newInteractable);
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
		
		if not modMission:IsComplete(player, 39) then
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					
				elseif mission.Type == 1 then -- OnActive
					load();
				elseif mission.Type == 3 then -- OnComplete
					mission.Changed:Disconnect(OnChanged);
				end
			end
			mission.Changed:Connect(OnChanged);
			OnChanged(true, mission);
			
		else -- Loading Completed
			load();
		end
	end)
	
	return CutsceneSequence;
end;