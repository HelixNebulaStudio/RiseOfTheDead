local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);

if RunService:IsServer() then
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

local MISSION_ID = 92;

local DEFAULTSPAWN = "outside W.D. Warehouse: Office";
local PATHOROTH_SPAWNS = {
	["bioxresearch"] = {
		WorldName = "BioXResearch";
		Position = Vector3.new(-139.885, -16.549, 89.765);
	};
	["outside W.D. Warehouse: Office"] = {
		WorldName = "TheWarehouse";
		Position = Vector3.new(599.512, 57.701, 280.441);
	};
	["outside W.D. Warehouse: Sundays"] = {
		WorldName = "TheWarehouse";
		Position = Vector3.new(483.35, 57.848, -65.021);
	};
	["inside W.D. Warehouse: Bloxmart"] = {
		WorldName = "TheWarehouse";
		Position = Vector3.new(282.338, 57.848, 7.252);
	};
	["outside Underbridge Safehouse"] = {
		WorldName = "TheUnderground";
		Position = Vector3.new(-10.881, 8.794, 159.935);
	};
	["outside Train Station Safehouse"] = {
		WorldName = "TheUnderground";
		Position = Vector3.new(289.505, -17.252, -104.435);
	};
	["above Train Station Safehouse"] = {
		WorldName = "TheUnderground";
		Position = Vector3.new(237.934, 26.248, -141.13);
	};
	["outside W.D. Mall Safehouse"] = {
		WorldName = "TheMall";
		Position = Vector3.new(812.653, 98.689, -767.595);
	};
	["near W.D. Mall Epic Cakery"] = {
		WorldName = "TheMall";
		Position = Vector3.new(416.143, 96.804, -886.671);
	};
	["outside W.D. Mall"] = {
		WorldName = "TheMall";
		Position = Vector3.new(721.055, 101.808, -944.576);
	};
	["outside Radio Station"] = {
		WorldName = "TheResidentials";
		Position = Vector3.new(1093.538, 63.832, -424.147);
	};
	["inside Fin's Automobile"] = {
		WorldName = "TheResidentials";
		Position = Vector3.new(1208.256, 56.848, 358.526);
	};
	["outside Hazelnut Cafe"] = {
		WorldName = "TheResidentials";
		Position = Vector3.new(965.905, 57.763, 67.69);
	};
};
--==

return function(CutsceneSequence)
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
		
		local loopActive = false;
		local spawned = false;
		
		local playerClass: PlayerClass = shared.modPlayers.get(player);

		local function OnChanged(firstRun)
			local area = mission.SaveData.Area or DEFAULTSPAWN;

			if RunService:IsStudio() and shared.WorldName == "BioXResearch" then
				area = "bioxresearch";
			end
			
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				Debugger:Warn("mission", mission);

				if mission.ProgressionPoint == 1 then

					if loopActive then return end;
					loopActive = true;

					task.spawn(function()
						local spawnInfo = PATHOROTH_SPAWNS[area];
						if shared.WorldName ~= spawnInfo.WorldName then 
							Debugger:StudioWarn(`Wrong world for Pathoroth search.`);
							return
						end;

						while loopActive do
							if not game.Players:IsAncestorOf(player) then break; end;
							if mission.Type ~= 1 then break; end;
							if mission.ProgressionPoint ~= 1 then break; end;

							local spawnPos = spawnInfo.Position;
							local spawnDist = playerClass:DistanceFrom(spawnPos);

							if spawnDist <= 100 then
								loopActive = false;

								modMission:Progress(player, MISSION_ID, function(mission)
									if mission.ProgressionPoint ~= 1 then return; end;
									mission.ProgressionPoint = 2;
								end)
							end
							
							task.wait(1);
						end
					end)

				elseif mission.ProgressionPoint == 2 then
					if firstRun then
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 1;
						end)

						return;
					end

					if spawned then return end;
					spawned = true;

					local profile = shared.modProfile:Get(player);
					local gameSave = profile:GetActiveSave();
					local playerLevel = gameSave:GetStat("Level") or 0;

					local spawnInfo = PATHOROTH_SPAWNS[area];
					if shared.WorldName ~= spawnInfo.WorldName then
							Debugger:StudioWarn(`Wrong world for Pathoroth spawn.`);
						return;
					end
					local spawnPos = spawnInfo.Position;
					
					shared.modNpcs.spawn2{
						Name = "Pathoroth";
						CFrame = CFrame.new(spawnPos) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);
						Properties = {
							Level = modGlobalVars.GetLevelToFocus(playerLevel);
							HordeAggression = true;
						};
						NetworkOwners = {player};
						BindSetup = function(npcClass: NpcClass) 
							playerClass.CharacterGarbage:Tag(npcClass.Character);

							npcClass.HealthComp.OnIsDeadChanged:Connect(function(isDead, oldIsDead, damageData)
								if not isDead then return end;

								if damageData == nil or damageData.DamageBy == nil then
									modMission:FailMission(player, MISSION_ID, `Pathoroth got away..`);
									return;
								end

								modMission:CompleteMission(player, MISSION_ID);
							end)

							local targetHandlerComp = npcClass:GetComponent("TargetHandler");
							targetHandlerComp:AddTarget(playerClass.Character);
						end
					};

				end
			elseif mission.Type == 3 then -- OnComplete


			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;