local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local MISSION_ID = 50;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	triggerLightBarrel = script.Parent:WaitForChild("lightFirebarrel");
	bmSpawn = CFrame.new(-26.1658859, 2.54966354, -114.670898, -1, 0, 0, 0, 1, 0, 0, 0, -1);

	shared.modEventService:OnInvoked("Interactables_BindDoorInteract", function(eventPacket: EventPacket, ...)
        local player: Player? = eventPacket.Player;
        if player == nil then return end;

        local interactable: InteractableInstance = ...;

        if interactable.Id == "eb2Door" then
            modMission:Progress(player, MISSION_ID, function(mission)
                if mission.ProgressionPoint == 3 then
					mission.ProgressionPoint = 4;
				end;
            end)
        end
    end)

	if modBranchConfigurations.IsWorld("EasterButchery") then
		shared.modEventService:OnInvoked("Generic_BindTrigger", function(event: EventPacket, ...)
			local player: Player? = event.Player;
			if player == nil then return end;

			local triggerId: string = ...;
			if triggerId == "lightFirebarrel" then 
				local mission = modMission:Progress(player, MISSION_ID);
				if mission and mission.ProgressionPoint == 5 then
					modMission:Progress(player, MISSION_ID, function(mission)
						mission.ProgressionPoint = 6;
					end)
				end
			end;

		end)

	end

else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigurations.IsWorld("EasterButchery") then

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
			

		local bunnymanNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Bunny Man");
		if bunnymanNpcClass == nil then
			bunnymanNpcClass = modNpcs.spawn2{
				Name = "Bunny Man";
				CFrame = bmSpawn;
				Player = player;
				ReplicateOut = true;
			};
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
		
		if modMission:IsComplete(player, MISSION_ID) then return end;
		
		
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
					bunnymanNpcClass:ToggleInteractable(true);
					for _, obj in pairs(workspace.Entity:GetChildren()) do
						if obj.Name == "Cultist" then
							obj:Destroy();
						end
					end
					
					bunnymanNpcClass:SetCFrame(bmSpawn);
					bunnymanNpcClass.WieldComp:Unequip();
					
				elseif mission.ProgressionPoint == 3 then
					bunnymanNpcClass:ToggleInteractable(false);
					wait(1);
					bunnymanNpcClass.Move:MoveTo(Vector3.new(-32.4848175, 2.54966402, -108.732132));
					bunnymanNpcClass.Move.OnMoveToEnded:Wait(1);
					bunnymanNpcClass:SetCFrame(CFrame.new(-32.4848175, 2.54966402, -108.732132, 0, 0, 1, 0, 1, 0, -1, 0, 0));
					
					wait(1.5);
					bunnymanNpcClass:SetCFrame(CFrame.new(-58.9206924, 2.54966402, -108.732132, 0, 0, 1, 0, 1, 0, -1, 0, 0));
					
				elseif mission.ProgressionPoint == 4 then
					wait(1);
					bunnymanNpcClass.Move:MoveTo(Vector3.new(-188.224518, 2.70417404, 7.9118042));
					bunnymanNpcClass.Move.OnMoveToEnded:Wait(20);
					bunnymanNpcClass.Move:Face(Vector3.new(-183.797638, 2.70417881, 2.54900455));
					
					bunnymanNpcClass:GetComponent("WaitForPlayer")(30);
					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint == 4 then
							mission.ProgressionPoint = 5;
						end;
					end)
					
				elseif mission.ProgressionPoint == 5 then
					bunnymanNpcClass.Chat(bunnymanNpcClass.Player, "Light it up.");

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
					bunnymanNpcClass.Chat(bunnymanNpcClass.Player, "Well done.");
					wait(5);
					bunnymanNpcClass.Chat(bunnymanNpcClass.Player, "Now we wait...");
					
					wait(20);
					if not character:IsDescendantOf(workspace) then return end;

					local origin = CFrame.new(-229.88, 9.397, 7.02);
				
					for a=1, 3 do

						local projectileInstance: ProjectileInstance = modProjectile.fire("fireworks", {
							OriginCFrame = origin;
						});
						modProjectile.serverSimulate(projectileInstance, {
							Velocity = Vector3.new(0, 20, 0);
						});

						wait(1);
					end
					
					local cultistNpcClass: NpcClass = modNpcs.spawn2{
						Name = "Cultist";
						CFrame = CFrame.new(-59.21, 2.53, -8.22, 0, 0, 1, 0, 1, 0, -1, 0, 0);
						Player = player;
						BindSetup = function(npcClass: NpcClass)
							npcClass.Properties.Immunity = 1;
							npcClass.Properties.CutsceneActive = true;
						end;
					};
					
					cultistNpcClass.Move:MoveTo(Vector3.new(-160.850769, 2.70417881, 2.4058733));
					cultistNpcClass.Move.OnMoveToEnded:Wait(3);
					
					bunnymanNpcClass.Move:MoveTo(Vector3.new(-170.911606, 2.70417905, 2.40587401));
					bunnymanNpcClass.Move.OnMoveToEnded:Wait(5);
					wait(1);
					cultistNpcClass.Chat(cultistNpcClass.Player, "Hey, wait a minute.. You aren't cultists.. What do you want?!");
					wait(7);
					if not character:IsDescendantOf(workspace) then return end;
					bunnymanNpcClass.Chat(bunnymanNpcClass.Player, "April first shall prevail..");
					wait(5);
					if not character:IsDescendantOf(workspace) then return end;
					cultistNpcClass.Chat(cultistNpcClass.Player, "Wait, how did you know our phrase?! Were you one of us?");
					wait(6);
					if not character:IsDescendantOf(workspace) then return end;
					bunnymanNpcClass.Chat(bunnymanNpcClass.Player, "Foolish rookie, tell me. Is omega still one of your active leaders?");
					wait(8);
					if not character:IsDescendantOf(workspace) then return end;
					cultistNpcClass.Chat(cultistNpcClass.Player, "Err yes. However, psi wants to over haul the rankings.");
					wait(6);
					if not character:IsDescendantOf(workspace) then return end;
					bunnymanNpcClass.Chat(bunnymanNpcClass.Player, "Good, good.. Your life ends here now!");
					wait(5);
					if not character:IsDescendantOf(workspace) then return end;
					cultistNpcClass.Chat(cultistNpcClass.Player, "Wait what?! *whistles*");
					wait(4);
					if not character:IsDescendantOf(workspace) then return end;
					
					bunnymanNpcClass.WieldComp:Equip{
						ItemId = "czevo3";
					};
					
					cultistNpcClass.Properties.Immortal = nil;
					cultistNpcClass.Properties.Immunity = nil;
					
					repeat
						bunnymanNpcClass.WieldComp:InvokeToolAction("PrimaryFireRequest", nil, cultistNpcClass.Humanoid);
						wait(0.1);
						if not character:IsDescendantOf(workspace) then return end;
					until cultistNpcClass.HealthComp.IsDead;

					wait(2);
					if not character:IsDescendantOf(workspace) then return end;
					spawn(function()
						local cultspawns = workspace.Environment.Cutscene.Spawns:GetChildren();
						local timer = tick();

						while true do
							modNpcs.spawn2{
								Name = "Cultist";
								CFrame = cultspawns[math.random(1, #cultspawns)].CFrame;
								BindSetup = function(npcClass: NpcClass)
									npcClass.Properties.TargetableDistance = 4096;
									npcClass:GetComponent("TargetHandler"):AddTarget(playerClass.Character);
								end;
							};
							wait(0.1);
							if tick()-timer > 5 then break; end;
							if not character:IsDescendantOf(workspace) then break end;
						end
					end)
					
					bunnymanNpcClass.Chat(bunnymanNpcClass.Player, "Incoming!");
					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint == 6 then
							mission.ProgressionPoint = 7;
						end;
					end)
					
				elseif mission.ProgressionPoint == 7 then
					bunnymanNpcClass:GetComponent("ProtectPlayer")(function() 
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

						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint == 7 then
								mission.ProgressionPoint = 8;
							end;
						end)
					end)

				elseif mission.ProgressionPoint == 8 then
					bunnymanNpcClass:ToggleInteractable(true);
					
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