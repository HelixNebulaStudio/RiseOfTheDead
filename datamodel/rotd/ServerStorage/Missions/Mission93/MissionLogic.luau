local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAoeHighlight = shared.require(game.ReplicatedStorage.Particles.AoeHighlight);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);
local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);

local MISSION_ID = 93;

local MISSION_MARKER_COLOR = Color3.fromRGB(251, 255, 0);
local AREAS_TO_SECURE = {
	["BioXResearch"] = {
		BarricadePileSpawnCFrame = CFrame.new(55.335, -18.85, 18.39);
		RegionCFrame = CFrame.new(44.141, -14.517, 32.463);
		RegionSize = Vector3.new(27.774, 8.867, 24.354);
	};
	["outside Sector F near Sewer Exit to W.D. Warehouse"] = {
		RegionCFrame = CFrame.new(12.869, 14.516, -54.53);
		RegionSize = Vector3.new(69.266, 18.368, 31.173);
	};
	["inside the Train Station near W.D. Mall entrance"] = {
		BarricadePileSpawnCFrame = CFrame.new(286.334, 23.9, -191.594) * CFrame.Angles(0, math.rad(180), 0);
		RegionCFrame = CFrame.new(253.374, 47.225, -218.759);
		RegionSize = Vector3.new(71.149, 46.85, 87.121);
	};
	["outside Radio Station near W.D. Mall"] = {
		BarricadePileSpawnCFrame = CFrame.new(1072.629, 94.465, -654.818);
		RegionCFrame = CFrame.new(1129.433, 98.828, -655.214);
		RegionSize = Vector3.new(118.619, 11.074, 166.618);
	};
	["in Bunker Inc. near Residentials Safehouse"] = {
		BarricadePileSpawnCFrame = CFrame.new(910.012, 55.4, -80.148);
		RegionCFrame = CFrame.new(928.75, 56.301, -116.637);
		RegionSize = Vector3.new(42.681, 32.152, 97.751);
	};
	["outside the Harbor Substation near the Golden Bridge"] = {
		BarricadePileSpawnCFrame = CFrame.new(-630.45, 60.695, 211.009) * CFrame.Angles(0, math.rad(90), 0);
		RegionCFrame = CFrame.new(-680.381, 66.979, 158.116);
		RegionSize = Vector3.new(128.853, 13.082, 109.842);
	};
};
local DEFAULT_AREA = next(AREAS_TO_SECURE);
local METAL_BARRICADE_PREFAB;

local MissionLogic = {};
--==

function MissionLogic.onRequire()
	if RunService:IsServer() then
		cutsceneAssets = script.Parent:WaitForChild("CutsceneAssets");
		modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		
		shared.modEventService:OnInvoked("Npcs_BindDeath", function(eventPacket: EventPacket, ...)
			local npcClass: NpcClass = ...;
			if npcClass == nil or npcClass.HumanoidType ~= "Zombie" then return end;
			
			local spawnCf = npcClass.SpawnCFrame;

			task.spawn(function()
				local mapLayerName = npcClass.Properties.MapLayerName;
				if mapLayerName == nil then return end;

				local areaDiff = npcClass.Properties.AreaDifficulty;
				
				local playerMissions = modMission.getPlayersWithMission(MISSION_ID, 1);
				if #playerMissions <= 0 then return end;

				local shouldSpawn = false;
				local targetMission = nil;

				modTables.shuffle(playerMissions);
				for a=1, #playerMissions do
					local mission = playerMissions[a];
					if mission.SaveData.Spawns and mission.SaveData.Spawns > 0 then
						targetMission = mission;
						shouldSpawn = true;
						break;
					end
				end

				if not shouldSpawn or targetMission == nil then return end; 

				targetMission.SaveData.Spawns -= 1;
				local targetPlayer = targetMission.Player;

				task.wait(math.random(2, 7));
				if targetMission.Type ~= 1 or not game.Players:IsAncestorOf(targetPlayer) then return end;

				local activeParametersKey = targetMission.SaveData.Area;	
				local areaInfo = activeParametersKey and AREAS_TO_SECURE[activeParametersKey];

				local zoneRegion;
				if areaInfo then
					zoneRegion = {
						CFrame = areaInfo.RegionCFrame;
						Size = areaInfo.RegionSize;
					};
				end

				shared.modNpcs.spawn2{
					Name = ({"Zombie"; "Ticks"; "Heavy"})[math.random(1, 3)];
					CFrame = spawnCf * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);
					Properties = {
						MapLayerName = mapLayerName;
						AreaDifficulty = areaDiff;
						TargetableDistance = 128;
						HordeAggression = true;
						ZoneRegion = zoneRegion;
						ThinkCycle = 0.5;
					};
					BindSetup = function(npcClass: NpcClass)
						local targetHandlerComp = npcClass:GetComponent("TargetHandler");
						if targetHandlerComp and targetPlayer and targetPlayer.Character then
							targetHandlerComp:AddTarget(targetPlayer.Character);
						end

						npcClass.OnThink:Fire();
					end
				};

			end)
		end)
	end
end


function MissionLogic.Init(missionProfile: MissionsProfile, mission: Mission)
	local player: Player = missionProfile.Player;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local regionLoop = false;

	local regionHighlight;
	
	if RunService:IsServer() then
    	METAL_BARRICADE_PREFAB = cutsceneAssets:WaitForChild("MetalBarricadePile");
	end

	local function OnChanged(firstRun)
		if mission.Type ~= 1 then return; end

		local activeParametersKey = mission.SaveData.Area or DEFAULT_AREA;
		local areaInfo = AREAS_TO_SECURE[activeParametersKey] or AREAS_TO_SECURE[DEFAULT_AREA];

		if RunService:IsServer() then
			-- MARK: IsServer
			if areaInfo.BarricadePileSpawnCFrame then
				local new = METAL_BARRICADE_PREFAB:Clone();
				new:PivotTo(areaInfo.BarricadePileSpawnCFrame);
				new.Parent = workspace.Environment;

				local config = new:WaitForChild("Interactable");
				config:SetAttribute("AutoDespawnDuration", 300);

				mission.Garbage:Tag(new);

				modReplicationManager.ReplicateOut({player}, new);
			end


			if mission.SaveData.Bars == nil then
				mission.SaveData.Bars = {};
			end
			if mission.SaveData.Spawns == nil then
				mission.SaveData.Spawns = 20;
			end
			

			local lastAggroTick = tick();
			task.spawn(function()
				if regionLoop then return end;
				regionLoop = true;

				local keepOffStr = "Keep all enemies off the parameters";
				local enemiesInParametersStr = "There are enemies on the parameters!";

				while true do
					local delta = task.wait(0.1);

					if not game.Players:IsAncestorOf(player) then break; end;
					if mission.Type ~= 1 then break; end;

					local playerCf = playerClass:GetCFrame();
					local isPlayerInRegion = modVector.isInBoundingBox(
						areaInfo.RegionCFrame, 
						areaInfo.RegionSize, 
						playerCf.Position
					);

					local saveDataChanged = false;

					if isPlayerInRegion and mission.SaveData.Bars.T1 == nil then
						mission.SaveData.Bars.T1 = {
							Text = keepOffStr;
							TextAlpha = 0;
							TextFlashing = false;

							Alpha = 1;

							Seconds = 60;
							Duration = 60;
						};
						saveDataChanged = true;
					end

					local t1Bar = mission.SaveData.Bars.T1;
					if t1Bar then
						local entitiesInRegion = shared.modNpcs.listNpcClasses(function(npcClass: NpcClass)
							local npcCf = npcClass:GetCFrame();
							
							local isCharInRegion = modVector.isInBoundingBox(
								areaInfo.RegionCFrame, 
								areaInfo.RegionSize, 
								npcCf.Position
							);
							if not isCharInRegion then return false; end;
							if not playerClass.HealthComp:CanTakeDamageFrom(npcClass) then return false; end;

							return true;
						end)

						local isEnemiesInRegion = #entitiesInRegion > 0;

						if isEnemiesInRegion then
							t1Bar.Text = enemiesInParametersStr;
							if t1Bar.Alpha > 0 then
								t1Bar.Alpha -= delta;
								saveDataChanged = true;

							elseif t1Bar.TextFlashing == false then
								t1Bar.Alpha = 0;
								t1Bar.TextFlashing = true;
								saveDataChanged = true;
							end

						elseif t1Bar.Alpha < 1 then
							t1Bar.Alpha += delta/5;
							saveDataChanged = true;

						else
							t1Bar.Text = keepOffStr;
							if t1Bar.TextFlashing then
								t1Bar.TextFlashing = false;
								saveDataChanged = true;
							end

							if t1Bar.Seconds > 0 then
								t1Bar.Seconds -= delta;
								saveDataChanged = true;

							else
								saveDataChanged = true;
							end

						end

						if t1Bar.Seconds <= (t1Bar.Duration-10)
						and tick() > lastAggroTick then
							lastAggroTick = tick()+math.random(4, 8);

							local entitiesInRange: {NpcClass} = shared.modNpcs.listInRange(areaInfo.RegionCFrame.Position, 100);
							for a=1, #entitiesInRange do
								local npcClass: NpcClass = entitiesInRange[a];
								if npcClass.HealthComp == nil or npcClass.HealthComp.IsDead then continue end;
								if not playerClass.HealthComp:CanTakeDamageFrom(npcClass) then continue end;
								if math.random(1, 2) ~= 1 then continue end;

								if npcClass.Properties.ZoneRegion == nil then
									npcClass.Properties.ZoneRegion = {
										CFrame = areaInfo.RegionCFrame;
										Size = areaInfo.RegionSize;
									};
									task.delay(math.random(10, 60), function()
										npcClass.Properties.ZoneRegion = nil;
									end)
								end

								local targetHandlerComp = npcClass:GetComponent("TargetHandler");
								targetHandlerComp:AddTarget(playerClass.Character);
							end
						end
					end

					if not saveDataChanged then continue end;

					t1Bar.Alpha = math.clamp(t1Bar.Alpha, 0, 1);
					t1Bar.TextAlpha = math.clamp(t1Bar.Seconds / t1Bar.Duration, 0, 1);
					mission:Sync();

					if t1Bar and t1Bar.Seconds <= 0 then
						modMission:CompleteMission(player, MISSION_ID);
						break;
					end
				end
			end)


		else
			--MARK: IsClient
			if regionHighlight == nil then
				regionHighlight = modAoeHighlight.highlightRegion(areaInfo.RegionCFrame, areaInfo.RegionSize);
				regionHighlight.Color = MISSION_MARKER_COLOR;
				mission.Garbage:Tag(function()
					Debugger.Expire(regionHighlight);
					regionHighlight = nil;
				end);
			end

		end
	end
	
	mission.OnChanged:Connect(OnChanged);
	OnChanged(true);
end

return MissionLogic;