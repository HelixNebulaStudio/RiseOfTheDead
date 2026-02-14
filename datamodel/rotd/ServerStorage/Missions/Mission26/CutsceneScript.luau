local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

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
	if not modBranchConfigurations.IsWorld("TheUnderground") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
			
		local dianaNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Diana");
		if dianaNpcClass == nil then
			dianaNpcClass = modNpcs.spawn2{
				Name = "Diana";
				Player = player;
				ReplicateOut = true;
			};
		end
		local shopStandCFrame = CFrame.new(-130.710892, 10.5228786, 284.348938, 0, 0, -1, 0, 1, 0, 1, 0, 0);

		if not modMission:IsComplete(player, MISSION_ID) then
			local function OnChanged(firstRun)
				dianaNpcClass.StopAnimation("leanforward");

				if mission.Type == 2 then -- OnAvailable
					dianaNpcClass.Properties.CutsceneActive = true;
					dianaNpcClass:SetCFrame(shopStandCFrame);
					
					dianaNpcClass.Move:MoveTo(Vector3.new(-137.6, 10.5, 275.6));
					dianaNpcClass.Move.OnMoveToEnded:Wait(5);
					
					wait(0.3);
					dianaNpcClass:SetCFrame(CFrame.new(-136.80545, 10.5228777, 268.696259, 0.866024852, 0, -0.500000954, 0, 1, 0, 0.500000954, 0, 0.866024852));
					
					dianaNpcClass.Move:MoveTo(Vector3.new(-123.7, 10.5, 276.9));
					dianaNpcClass.Move.OnMoveToEnded:Wait(5);
					
					dianaNpcClass.Move:Face(Vector3.new(-118.4, 10.5, 276.9));
					
				elseif mission.Type == 1 then -- OnActive
					dianaNpcClass.Properties.CutsceneActive = true;
					dianaNpcClass:SetCFrame(CFrame.new(-123.7, 10.5, 276.9, -0.30901897, 0, -0.951055884, 0, 1, 0, 0.951055884, 0, -0.30901897));
					
				elseif mission.Type == 3 then -- OnComplete
					mission.OnChanged:Disconnect(OnChanged);
					
					dianaNpcClass.Move:MoveTo(Vector3.new(-136.8, 10.5, 268.7));
					dianaNpcClass.Move.OnMoveToEnded:Wait(5);
					
					wait(0.3);
					dianaNpcClass:SetCFrame(CFrame.new(-137.6, 10.5, 275.6));
					
					dianaNpcClass.Move:MoveTo(shopStandCFrame.Position);
					dianaNpcClass.Move.OnMoveToEnded:Wait(5);
					
					dianaNpcClass:SetCFrame(shopStandCFrame);
					dianaNpcClass.Properties.CutsceneActive = false;
					dianaNpcClass.PlayAnimation("leanforward");
					
				end
			end
			
			local lastWave = tick();
			local disConnFunc;
			disConnFunc = dianaNpcClass.OnThink:Connect(function()
				if mission.Type == 3 then 
					disConnFunc();
					return
				end;
				
				if mission.Type == 1 then
					if mission.ObjectivesCompleted["Search"] == true then
						if tick() > lastWave then
							lastWave = tick()+math.random(30, 120)/10;

							dianaNpcClass.PlayAnimation("Wave");
						end
					end

					dianaNpcClass.Move:Face("Player");
				end
			end)
			
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end
	end)
	
	return CutsceneSequence;
end;