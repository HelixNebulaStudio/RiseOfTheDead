local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modPlayerNpcs = shared.require(game.ReplicatedStorage.Library.PlayerNpcs);

local MISSION_ID = 43;
--== Variables;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	cutsceneAssets = script.Parent:WaitForChild("CutsceneAssets");
	
	if shared.WorldName == "Office" then
		shared.modEventService:OnInvoked("GameModeManager_BindGameModeComplete", function(event: EventPacket, packet)
			local room = packet.Room;
			if room.Type ~= "Raid" or room.Stage ~= "Office" then return end;

			if event.Player == nil then return end;
			local player = event.Player;

			task.spawn(function() 
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint < 2 then
						mission.ProgressionPoint = 2;
					end;
				end)
			end)
		end)

	elseif shared.WorldName == "TheMall" then
		shared.modEventService:OnInvoked("Npcs_BindDeath", function(event: EventPacket, ...)
			local npcClass: NpcClass = ...;
			if npcClass == nil or npcClass.Name ~= "Zombie" then return end;
			if npcClass.Properties.JackReapZombie ~= true then return end;

			task.spawn(function() 
				local playerTags = modDamageTag:Get(npcClass.Character, "Player");
				for a=1, #playerTags do
					local playerTag = playerTags[a];
					local player: Player = playerTag.Player;
					if player == nil or not game.Players:IsAncestorOf(player) then continue end;
					
					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint == 5 then
							modMission:CompleteMission(player, MISSION_ID);
						end
					end)
				end
			end)
		end)


		shared.modEventService:OnInvoked("Generic_BindTrigger", function(event: EventPacket, ...)
			local player: Player? = event.Player;
			if player == nil then return end;

			local triggerId: string, interactable: InteractableInstance = ...;
			if triggerId ~= "Summon JackReap" then return end;

			task.spawn(function() 
				local playerClass: PlayerClass = shared.modPlayers.get(player);

				local profile = shared.modProfile:Get(player);
				local inventory = profile.ActiveInventory;

				if playerClass.WieldComp.ItemId ~= "voodoodoll" then return end;
				
				local hasSpace = inventory:SpaceCheck{{ItemId="jacksscythe"; Data={Quantity=1;}}};
				if hasSpace then
					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint < 5 then mission.ProgressionPoint = 5; end;
						game.Debris:AddItem(interactable.Part, 0);
					end)
					shared.Notify(player, "You hear a creepy sound behind you..", "Inform");
					
				else
					shared.Notify(player, "Inventory full!", "Negative");
					
				end
			
			end)
		end)

	end

else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if shared.WorldName == "TheWarehouse" then

		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
				
			if modMission:IsComplete(player, MISSION_ID) or mission.ProgressionPoint >= 4 then return end;
			
			local jackReapPlayerNpc: PlayerNpc = modPlayerNpcs.getPlayerNpc(player, "Jack Reap");
			jackReapPlayerNpc:SetCFrame{
				MissionId = MISSION_ID;
				CFrame = CFrame.new(654.246, 57.75, 262.849) * CFrame.Angles(0, math.rad(90), 0);
			};
		end)


	elseif shared.WorldName == "TheMall" then
		
		CutsceneSequence:Initialize(function()
			local triggerPrefab = cutsceneAssets:WaitForChild("summonTrigger");
			
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
				
			if modMission:IsComplete(player, MISSION_ID) then return end
		
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					
				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then

					elseif mission.ProgressionPoint == 2 then
						
					elseif mission.ProgressionPoint == 3 then
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 4;
						end)
						
					elseif mission.ProgressionPoint == 4 then
						local newSummon = triggerPrefab:Clone();

						local newInteractConfig = modInteractables.createInteractable("ButtonRotd");
						newInteractConfig:SetAttribute("_Id", "Summon JackReap");
						newInteractConfig:SetAttribute("_Label", "Point Voodoo Doll at Totem");
						newInteractConfig:SetAttribute("_EquipItemId", "voodoodoll");
						newInteractConfig:SetAttribute("_InteractDuration", 3);
						newInteractConfig.Parent = newSummon;

						newSummon.Parent = workspace.Interactables;
						modReplicationManager.ReplicateOut(player, newSummon);
						
					elseif mission.ProgressionPoint == 5 then
						modNpcs.spawn2{
							Name = "Zombie";
							CFrame = CFrame.new(440.02, 103.431, -651.14);
							Properties = {
								PresetShirt = {Id="rbxassetid://119132632"};
								PresetPants = {Id="rbxassetid://119133558"};
								JackReapZombie = true;
								ForgetEnemies = false;
								TargetableDistance = 4096;
								HordeAggression = true;
							};
							BindSetup = function(npcClass: NpcClass)
								npcClass.NetworkOwners = {player};

								local targetHandlerComp = npcClass:GetComponent("TargetHandler");
								targetHandlerComp:AddTarget(player.Character);

								modAudio.Play("Creepy3", npcClass.RootPart);

								task.delay(1, function() 
									npcClass.Move:MoveTo(Vector3.new(440.52, 97.691, -673.23));
								end)
							end;
							Player = player;
							ReplicateOut = true;
						};

					end
				elseif mission.Type == 3 then -- OnComplete
					mission.OnChanged:Disconnect(OnChanged);

				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);

				
		end)


	end

	
	return CutsceneSequence;
end;