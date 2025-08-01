local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local MISSION_ID = 50;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	triggerLightBarrel = script.Parent:WaitForChild("lightFirebarrel");
	bmSpawn = CFrame.new(-26.1658859, 2.54966354, -114.670898, -1, 0, 0, 0, 1, 0, 0, 0, -1);

else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("EasterButchery") then

		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;

			if not modMission:IsComplete(player, MISSION_ID) then
				if mission.ProgressionPoint < 7 then
					modMission:Progress(player, MISSION_ID, function(mission)
						mission.ProgressionPoint = 2;
					end)
				end
			end
		end)
		
		return;
	end;

	local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);
	local modPlayers = shared.modPlayers;

	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;

		local playerClass: PlayerClass = modPlayers.get(player);
			

		local bunnymanModule = modNpcs.getPlayerNpc(player, "Bunny Man");
		if bunnymanModule == nil then
			local npc = modNpcs.spawn("Bunny Man", bmSpawn, function(npc, npcModule)
				npcModule.Player = player;
				bunnymanModule = npcModule;
			end);
			modReplicationManager.ReplicateOut(player, npc);
		end
		
		local character;
		repeat
			character = player.Character;
			task.wait(0.1);
		until character ~= nil;
		
		playerClass.CharacterGarbage:Tag(playerClass.OnIsDeadChanged:Connect(function(isDead)
			if not isDead then return end;
			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint <= 7 then
					mission.ProgressionPoint = 2;
				end;
			end)
		end))
		
		if modMission:IsComplete(player, 50) then return end;
		
		
		local newTrigger;
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				if firstRun and mission.ProgressionPoint <= 7 then
					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint <= 7 then
							mission.ProgressionPoint = 2;
						end;
					end)
					return;
				end
				
				if mission.ProgressionPoint == 1 then

				elseif mission.ProgressionPoint == 2 then
					bunnymanModule.Interactable.Parent = bunnymanModule.Prefab;
					for _, obj in pairs(workspace.Entity:GetChildren()) do
						if obj.Name == "Cultist" then
							obj:Destroy();
						end
					end
					bunnymanModule.Actions:Teleport(bmSpawn);
					bunnymanModule.Chat(bunnymanModule.Player);
					bunnymanModule.Wield.Unequip();
					
				elseif mission.ProgressionPoint == 3 then
					bunnymanModule.Interactable.Parent = script;
					wait(1);
					bunnymanModule.Movement:Move(Vector3.new(-32.4848175, 2.54966402, -108.732132)):Wait(1);
					bunnymanModule.Actions:Teleport(CFrame.new(-32.4848175, 2.54966402, -108.732132, 0, 0, 1, 0, 1, 0, -1, 0, 0));
					
					wait(1.5);
					bunnymanModule.Actions:Teleport(CFrame.new(-58.9206924, 2.54966402, -108.732132, 0, 0, 1, 0, 1, 0, -1, 0, 0));
					
				elseif mission.ProgressionPoint == 4 then
					wait(1);
					bunnymanModule.Movement:Move(Vector3.new(-188.224518, 2.70417404, 7.9118042)):Wait(20);
					bunnymanModule.Movement:Face(Vector3.new(-183.797638, 2.70417881, 2.54900455));
					
					bunnymanModule.Actions:WaitForOwner(30);
					modMission:Progress(player, 50, function(mission)
						if mission.ProgressionPoint == 4 then
							mission.ProgressionPoint = 5;
						end;
					end)
					
				elseif mission.ProgressionPoint == 5 then
					bunnymanModule.Chat(bunnymanModule.Player, "Light it up.");

					newTrigger = triggerLightBarrel:Clone();
					newTrigger.Parent = workspace.Interactables;
					modReplicationManager.ReplicateOut(player, newTrigger);

				elseif mission.ProgressionPoint == 6 then
					if newTrigger then
						newTrigger:Destroy();
					end
					
					local fireBarrel = workspace.Environment:WaitForChild("Cutscene"):WaitForChild("Firebarrel");
					fireBarrel._lightSource._lightPoint.PointLight.Enabled = true;
					fireBarrel._lightSource.firePoint.Fire.Enabled = true;
					
					wait(1);
					bunnymanModule.Chat(bunnymanModule.Player, "Well done.");
					wait(3);
					bunnymanModule.Chat(bunnymanModule.Player, "Now we wait...");
					
					wait(20);
					if not character:IsDescendantOf(workspace) then return end;
					local origin = CFrame.new(-229.88, 9.397, 7.02);
					
					for a=1, 3 do
						local projectileObject = modProjectile.Fire("fireworks", origin, Vector3.new());
						if projectileObject.Prefab:CanSetNetworkOwnership() then projectileObject.Prefab:SetNetworkOwner(nil); end

						modProjectile.ServerSimulate(projectileObject, origin.p, Vector3.new(0, 20, 0));
						wait(1);
					end
					
					local cultist1Module
					modNpcs.spawn("Cultist", CFrame.new(-59.21, 2.53, -8.22, 0, 0, 1, 0, 1, 0, -1, 0, 0), function(npc, npcModule)
						cultist1Module = npcModule;
						cultist1Module.Immunity = 1;
						cultist1Module.CutsceneMode = true;
						cultist1Module.Player = player;
					end);
					
					cultist1Module.Move:MoveTo(Vector3.new(-160.850769, 2.70417881, 2.4058733));
					cultist1Module.Move.OnMoveToEnded:Wait(3);
					
					bunnymanModule.Movement:Move(Vector3.new(-170.911606, 2.70417905, 2.40587401)):Wait(5);
					wait(1);
					cultist1Module.Chat(cultist1Module.Player, "Hey, wait a minute.. You aren't cultists.. What do you want?!");
					wait(5);
					if not character:IsDescendantOf(workspace) then return end;
					bunnymanModule.Chat(bunnymanModule.Player, "April first shall prevail..");
					wait(5);
					if not character:IsDescendantOf(workspace) then return end;
					cultist1Module.Chat(cultist1Module.Player, "Wait, how did you know our phrase?! Were you one of us?");
					wait(5);
					if not character:IsDescendantOf(workspace) then return end;
					bunnymanModule.Chat(bunnymanModule.Player, "Foolish rookie, tell me. Is omega still one of your active leaders?");
					wait(5);
					if not character:IsDescendantOf(workspace) then return end;
					cultist1Module.Chat(cultist1Module.Player, "Err yes. However, psi wants to over haul the rankings.");
					wait(5);
					if not character:IsDescendantOf(workspace) then return end;
					bunnymanModule.Chat(bunnymanModule.Player, "Good, good.. Your life ends here now!");
					wait(3);
					if not character:IsDescendantOf(workspace) then return end;
					cultist1Module.Chat(cultist1Module.Player, "Wait what?! *whistles*");
					wait(0.5);
					if not character:IsDescendantOf(workspace) then return end;
					
					bunnymanModule.Wield.Equip("czevo3");
					bunnymanModule.Wield.Targetable.Cultist = 1;
					cultist1Module.Immortal = nil;
					cultist1Module.Immunity = nil;
					
					repeat
						bunnymanModule.Wield.SetEnemyHumanoid(cultist1Module.Humanoid);
						bunnymanModule.Movement:Face(cultist1Module.RootPart.Position);
						bunnymanModule.Wield.PrimaryFireRequest();
						wait(0.1);
						if not character:IsDescendantOf(workspace) then return end;
					until cultist1Module.IsDead;

					wait(2);
					if not character:IsDescendantOf(workspace) then return end;
					spawn(function()
						local cultspawns = workspace.Environment.Cutscene.Spawns:GetChildren();
						local timer = tick();

						while true do
							modNpcs.spawn("Cultist", cultspawns[math.random(1, #cultspawns)].CFrame, function(npc, npcModule)
								npcModule.Properties.TargetableDistance = 4096;
								npcModule.OnTarget(player);
							end);
							wait(0.1);
							if tick()-timer > 5 then break; end;
							if not character:IsDescendantOf(workspace) then break end;
						end
					end)
					
					bunnymanModule.Chat(bunnymanModule.Player, "Incoming!");
					modMission:Progress(player, 50, function(mission)
						if mission.ProgressionPoint == 6 then
							mission.ProgressionPoint = 7;
						end;
					end)
					
				elseif mission.ProgressionPoint == 7 then
					bunnymanModule.Actions:FollowOwner(function()
						if bunnymanModule.Target then
							local enemyHumanoid = bunnymanModule.Target:FindFirstChildWhichIsA("Humanoid");
							if enemyHumanoid and enemyHumanoid.Health > 0 and enemyHumanoid.RootPart and bunnymanModule.IsInVision(enemyHumanoid.RootPart) then
								bunnymanModule.Wield.SetEnemyHumanoid(enemyHumanoid);
								bunnymanModule.Movement:Face(enemyHumanoid.RootPart.Position);
								bunnymanModule.Wield.PrimaryFireRequest();
							else
								bunnymanModule.Target = nil;
							end
						else
							bunnymanModule.Wield.ReloadRequest();
						end
						return mission.ProgressionPoint == 7;
					end);
					spawn(function()
						while true do
							local endLoop = true;
							for _, obj in pairs(workspace.Entity:GetChildren()) do
								if obj.Name == "Cultist" then
									endLoop = false;
									break;
								end
							end
							if endLoop then break; end;
							if not character:IsDescendantOf(workspace) then return end;
							wait(1);
							print("cultist alive");
						end

						modMission:Progress(player, 50, function(mission)
							if mission.ProgressionPoint == 7 then
								mission.ProgressionPoint = 8;
							end;
						end)
					end)

				elseif mission.ProgressionPoint == 8 then
					bunnymanModule.Interactable.Parent = bunnymanModule.Prefab;
					
					
				end
			elseif mission.Type == 3 then -- OnComplete

				mission.OnChanged:Disconnect(OnChanged);
			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
			
	end)
	
	return CutsceneSequence;
end;