local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local MISSION_ID = 26;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheUnderground") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
			
		local dianaModule = modNpcs.getPlayerNpc(player, "Diana");
		if dianaModule == nil then
			local npc = modNpcs.spawn("Diana", nil, function(npc, npcModule)
				npcModule.Player = player;
				dianaModule = npcModule;
			end);
			modReplicationManager.ReplicateOut(player, npc);
		end
		local shopStandCFrame = CFrame.new(-130.710892, 10.5228786, 284.348938, 0, 0, -1, 0, 1, 0, 1, 0, 0);

		if not modMission:IsComplete(player, MISSION_ID) then
			local function OnChanged(firstRun)
				dianaModule.StopAnimation("leanforward");
				if mission.Type == 2 then -- OnAvailable
					dianaModule.InCutscene = true;
					dianaModule.Actions:Teleport(shopStandCFrame);
					
					dianaModule.Move:MoveTo(Vector3.new(-137.6, 10.5, 275.6));
					dianaModule.Move.OnMoveToEnded:Wait(5);
					
					wait(0.3);
					dianaModule.Actions:Teleport(CFrame.new(-136.80545, 10.5228777, 268.696259, 0.866024852, 0, -0.500000954, 0, 1, 0, 0.500000954, 0, 0.866024852));
					
					dianaModule.Move:MoveTo(Vector3.new(-123.7, 10.5, 276.9));
					dianaModule.Move.OnMoveToEnded:Wait(5);
					
					dianaModule.Move:Face(Vector3.new(-118.4, 10.5, 276.9));
					
				elseif mission.Type == 1 then -- OnActive
					dianaModule.InCutscene = true;
					dianaModule.Actions:Teleport(CFrame.new(-123.7, 10.5, 276.9, -0.30901897, 0, -0.951055884, 0, 1, 0, 0.951055884, 0, -0.30901897));
					
				elseif mission.Type == 3 then -- OnComplete
					mission.OnChanged:Disconnect(OnChanged);
					
					dianaModule.Move:MoveTo(Vector3.new(-136.8, 10.5, 268.7));
					dianaModule.Move.OnMoveToEnded:Wait(5);
					
					wait(0.3);
					dianaModule.Actions:Teleport(CFrame.new(-137.6, 10.5, 275.6));
					
					dianaModule.Move:MoveTo(shopStandCFrame.Position);
					dianaModule.Move.OnMoveToEnded:Wait(5);
					
					dianaModule.Actions:Teleport(shopStandCFrame);
					dianaModule.InCutscene = false;
					dianaModule.PlayAnimation("leanforward");
					
				end
			end
			
			local lastWave = tick();
			local disConnFunc;
			disConnFunc = dianaModule.Think:Connect(function()
				if mission.Type == 3 then 
					disConnFunc();
					return
				end;
				
				if mission.Type == 1 then
					if mission.ObjectivesCompleted["Search"] == true then
						if tick() > lastWave then
							lastWave = tick()+math.random(30, 120)/10;
							dianaModule.PlayAnimation("Wave");
						end
					end

					dianaModule.Actions:FaceOwner(false);
				end
			end)
			
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end
	end)
	
	return CutsceneSequence;
end;