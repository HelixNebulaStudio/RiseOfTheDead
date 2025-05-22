local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local MISSION_ID = 17;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheWarehouse") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
			
		local shopStandCFrame = CFrame.new(-11.3109531, 57.6494408, 18.8490143, 0, 0, -1, 0, 1, 0, 1, 0, 0);

		local jesseModule = modNpcs.get(player, "Jesse");
		if jesseModule == nil then
			local npc = modNpcs.spawn("Jesse", nil, function(npc, npcModule)
				npcModule.Owner = player;
				jesseModule = npcModule;
			end);
			modReplicationManager.ReplicateOut(player, npc);
		end

		if not modMission:IsComplete(player, MISSION_ID) then
			
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					
				elseif mission.Type == 1 then -- OnActive
					
					jesseModule.Move:MoveTo(Vector3.new(-14.4, 57, 29.7));
					jesseModule.Move.MoveToEnded:Wait(5);

					wait(0.1);
					jesseModule.Actions:Teleport(CFrame.new(-5.7, 57.6, 37.6));
					wait(2);
					jesseModule.Actions:Teleport(CFrame.new(4.8, 57, 37.6));

					jesseModule.Move:MoveTo(Vector3.new(7.18, 57.6, 30.76));
					jesseModule.Move.MoveToEnded:Wait(5);

					jesseModule.Move:Face(Vector3.new(9.56, 57.64, 29.6));
					task.wait(0.1);
					
					jesseModule.Actions:Teleport(CFrame.new(7.18, 57.6, 30.76, 0.438371062, 0, -0.898794115, 0, 1, 0, 0.898794115, 0, 0.438371062));
					
					if mission.ObjectivesCompleted["Search"] == true then
						jesseModule.Actions:WaitForOwner(60);
						jesseModule.Actions:FaceOwner();
						jesseModule.PlayAnimation("Wave");
					end
					
				elseif mission.Type == 3 then -- OnComplete
					mission.OnChanged:Disconnect(OnChanged);
					jesseModule.StopAnimation("Wave");
					
					task.wait(1);
					
					jesseModule.Move:MoveTo(Vector3.new(3.43, 57, 37.74));
					jesseModule.Move.MoveToEnded:Wait(5);
					
					wait(1);
					jesseModule.Actions:Teleport(CFrame.new(-5.7, 57.6, 37.6));
					wait(2);
					jesseModule.Actions:Teleport(CFrame.new(-14.4, 57, 29.7));
					
					jesseModule.Move:MoveTo(shopStandCFrame.Position);
					jesseModule.Move.MoveToEnded:Wait(5);
					
					jesseModule.Actions:Teleport(shopStandCFrame);
				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
			
		else -- Loading Completed
			jesseModule.StopAnimation("Wave");
			
		end
		
	end)
	
	return CutsceneSequence;
end;