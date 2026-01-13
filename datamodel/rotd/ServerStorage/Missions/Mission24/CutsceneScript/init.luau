local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

--== Variables;
local MISSION_ID = 24;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	shared.modEventService:OnInvoked("Interactables_BindCollectibleInteract", function(eventPacket: EventPacket, ...)
		local player: Player? = eventPacket.Player;
		if player == nil then return end;

		local interactable: InteractableInstance = ...;

		if interactable.Id == "rb" then
			if modMission:Progress(player, MISSION_ID) then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint <= 2 then
						mission.ProgressionPoint = 3;
					end;
				end)
			end
		end
	
	end)

	shared.modEventService:OnInvoked("Generic_BindTrigger", function(eventPacket: EventPacket, ...)
		local id: string, interactable: InteractableInstance = ...;
		if id ~= "MissingInAction_BanditZombie" then return end;

		local player: Player? = eventPacket.Player;
		if player == nil then return end;

		if modMission:Progress(player, MISSION_ID) then
			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint == 4 then
					mission.ProgressionPoint = 5; 
				end;
			end)
		end

	end)

else
	modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheUnderground") then return end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
		
		local profile = shared.modProfile:Get(player);
		
		local banditZombieNpcClass;
		local wakeAnimationTrack;

		local function spawnEnemy()
			banditZombieNpcClass = shared.modNpcs.spawn2{
				Name = "Bandit Zombie";
				CFrame = CFrame.new(138.553329, 12.2096834, 87.6066055, 0, 0, 1, 0, 1, 0, -1, 0, 0);
				NetworkOwners = {player};
				ReplicateOut = true;
				BindSetup = function(npcClass: NpcClass)
					local interactConfig = script:WaitForChild("banditZombieInteractable"):Clone();
					interactConfig.Name = "Interactable";
					interactConfig.Parent = npcClass.Character;
					npcClass.Interactable = interactConfig;
					
					npcClass.Character:SetAttribute("LookAtClient", false);
					npcClass.RootPart.Anchored = true;
					npcClass.Properties.Immortal = 1;
				end
			};

			banditZombieNpcClass.HealthComp.OnIsDeadChanged:Connect(function()
				if not banditZombieNpcClass.HealthComp.IsDead then return end;

				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 5 then
						mission.ProgressionPoint = 6; 
					end;
				end)
			end)
		end
		
		local function OnChanged(firstRun)
			if mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 2 then
					if profile.Collectibles["rb"] then
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint <= 2 then
								mission.ProgressionPoint = 3;
							end;
						end)
						
					else
						local newBeanie = script:WaitForChild("robertsbeanie"):Clone();
						
						local newInteractConfig = modInteractables.createInteractable("Collectible");
						newInteractConfig:SetAttribute("_Id", "rb");
						newInteractConfig:SetAttribute("_Label", "Oh no... This is Robert's beanie...");
						newInteractConfig.Parent = newBeanie;

						mission.Cache.BeaniePrefab = newBeanie;
						modReplicationManager.ReplicateIn(player, mission.Cache.BeaniePrefab, workspace.Interactables);

					end
					
				elseif mission.ProgressionPoint == 3 then
					Debugger.Expire(mission.Cache.BeaniePrefab, 0);

				elseif mission.ProgressionPoint == 4 then
					spawnEnemy()
					if banditZombieNpcClass then
						banditZombieNpcClass.SetAnimation("Wake", {script.WakeAnimation});

						wakeAnimationTrack = banditZombieNpcClass.GetAnimation("Wake");
						wakeAnimationTrack:SetAttribute("CustomAnimate", true);

						for a=1, 14 do
							task.wait(0.5);
							if wakeAnimationTrack.Length > 0 then break; end;
						end

						wakeAnimationTrack:Play();
						wakeAnimationTrack:AdjustSpeed(0);
					end
					
				elseif mission.ProgressionPoint == 5 then
					if banditZombieNpcClass == nil then
						spawnEnemy();
					end
					if banditZombieNpcClass then
						banditZombieNpcClass:ToggleInteractable(false);
						banditZombieNpcClass.Chat(player, "It got me... arrggggggg.. errerrr..");

						task.wait(3);
						if banditZombieNpcClass.HealthComp.IsDead then return end;

						if wakeAnimationTrack then
							wakeAnimationTrack:AdjustSpeed(1);
						end

						task.wait(1.4);
						if banditZombieNpcClass.HealthComp.IsDead then return end;

						local playerClass: PlayerClass = shared.modPlayers.get(player);

						banditZombieNpcClass.RootPart.Anchored = false;
						banditZombieNpcClass.Move:Face(playerClass:GetCFrame().Position);
						task.wait(0.2);
						if banditZombieNpcClass.HealthComp.IsDead then return end;

						banditZombieNpcClass.WieldComp:Equip{
							ItemId = "tec9";
							OnSuccessFunc = function(toolHandler: ToolHandlerInstance)
								if toolHandler.EquipmentClass == nil then return end;
								local equipmentClass: EquipmentClass = toolHandler.EquipmentClass;

								local modifier: ConfigModifier = equipmentClass.Configurations.newModifier("npcDmg");
								modifier.SetValues.Damage = 2;
								modifier.SetValues.StandInaccuracy = 14;
								equipmentClass.Configurations:AddModifier(modifier, true);
							end;
						};

						repeat
							banditZombieNpcClass.Properties.Immortal = nil;

							if banditZombieNpcClass:IsInVision(playerClass.Character) then
								local playerPos = playerClass:GetCFrame().Position;
								local aimDir = (playerPos - banditZombieNpcClass.RootPart.Position).Unit;
								banditZombieNpcClass.WieldComp:InvokeToolAction("PrimaryFireRequest", aimDir);
								banditZombieNpcClass.Move:Face(playerPos);
							end

							RunService.Heartbeat:Wait();
						until banditZombieNpcClass.HealthComp.IsDead or mission.ProgressionPoint ~= 5;

					end					
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