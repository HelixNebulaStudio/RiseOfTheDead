local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

local MISSION_ID = 30;

--== Server Variables;
if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
end

--== Script;
return function(CutsceneSequence)
	if modBranchConfigs.IsWorld("TheUnderground") then
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
			
			local rachelPrefab = workspace.Entity:FindFirstChild("Rachel");
			local rachelModule = rachelPrefab and modNpcs.getByModel(rachelPrefab);
			
			local vladimirPrefab = workspace.Entity:FindFirstChild("Vladimir");
			local vladimirModule = vladimirPrefab and modNpcs.getByModel(vladimirPrefab);
			
			local stanModule = modNpcs.getByOwner(player, "Stan");
			if stanModule == nil then
				local npc = modNpcs.spawn("Stan", nil, function(npc, npcModule)
					npcModule.Owner = player;
					stanModule = npcModule;
				end);
				modReplicationManager.ReplicateOut(player, npc);
			end
			
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					stanModule.Actions:Teleport(CFrame.new(235.934204, -22.3296394, 92.4541245, 1, 0, 0, 0, 1, 0, 0, 0, 1));
					stanModule.Wield.Equip("czevo3");
					
					stanModule.Humanoid.Health = 60;
					stanModule.Actions:WaitForOwner(30);
					repeat
						stanModule.Humanoid.Health = math.random(59, 61);
						stanModule.Actions:FaceOwner();
						wait(0.5);
					until player == nil or mission == nil or player.Parent == nil or mission.Type ~= 2;
					
				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then
						stanModule.Interactable.Parent = script;
						wait(3);
						stanModule.Chat(stanModule.Owner, "Follow me...");
						
						stanModule.Movement:SetWalkSpeed("default", 25);
						stanModule.Movement:Move(Vector3.new(308.2, 9.83, 1.94)):Wait(20);
						
						stanModule.Actions:WaitForOwner(30);
						stanModule.Actions:EnterDoor("safehouse4Entrance");
						stanModule.Wield.Unequip();
						stanModule.Movement:SetWalkSpeed("default", 7);
						stanModule.Movement:Move(Vector3.new(280, 9.83, -6.45)):Wait(5);
						stanModule.Movement:Face(Vector3.new(287.25, 9.83, -6.54));
						wait(1);
						stanModule.Chat(stanModule.Owner, "Hey ehh, Rachel, I need to patch up again..");
						wait(1.5);
						if rachelModule then rachelModule.Chat(player, "You need to be careful out there.."); end;
						wait(1.5);
						for a=1, 5 do
							stanModule.Humanoid.Health = stanModule.Humanoid.Health +8;
							wait(0.5);
						end
						if rachelModule then rachelModule.Chat(player, "There, done."); end;
						wait(1)
						stanModule.Humanoid.Health = 100;
						stanModule.Chat(stanModule.Owner, "Thanks a lot.");
						wait(1)
						stanModule.Movement:SetWalkSpeed("default", 14);
						stanModule.Movement:Move(Vector3.new(224.28, 9.83, -10.46)):Wait(5);
						stanModule.Movement:SetWalkSpeed("default", 7);
						wait(1)
						stanModule.Chat(stanModule.Owner, "Yo Vald! When are you going to have stock of that item I wanted?!");
						wait(2)
						if vladimirModule then vladimirModule.Chat(player, "Ugh.. Not sure, stop asking please. Так раздражает.."); end
						wait(3)
						stanModule.Movement:Move(Vector3.new(235.3, 9.8, 10.4)):Wait(8);
						stanModule.Actions:FaceOwner();
						stanModule.Chat(stanModule.Owner, "Hey, "..player.Name);
						stanModule.Interactable.Parent = stanModule.Prefab;
						
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint <= 1 then
								mission.ProgressionPoint = 2;
							end;
						end)
						
					elseif mission.ProgressionPoint == 2 then
						stanModule.Actions:Teleport(CFrame.new(235.310089, 9.83002663, 10.3999949, 1, 0, 0, 0, 1, 0, 0, 0, 1));
						
					elseif mission.ProgressionPoint == 3 then
						stanModule.Interactable.Parent = script;
						stanModule.Actions:Teleport(CFrame.new(235.310089, 9.83002663, 10.3999949, 1, 0, 0, 0, 1, 0, 0, 0, 1));
						wait(2);
						if stanModule == nil then return end;
						stanModule.Movement:SetWalkSpeed("default", 7);
						stanModule.Movement:Move(Vector3.new(230.71, 9.83, 10.74)):Wait(5);
						stanModule.Movement:Face(Vector3.new(230.65, 12.165, 14.3));
						wait(0.5);
						if stanModule == nil then return end;
						stanModule.Actions:EnterDoor("safehouse4Exit2");
						wait(2);
						if stanModule == nil then return end;
						stanModule.Movement:Move(Vector3.new(271.33, 25.69, -20.69)):Wait(5);
						stanModule.Movement:Face(Vector3.new(276.16, 28.8, -40.043));
						stanModule.Wield.Equip("czevo3");
						stanModule.Chat(stanModule.Owner, "Oh boy.. we better just save ammo and run past them.");
						wait(5);
						if stanModule == nil then return end;
						stanModule.Movement:SetWalkSpeed("default", 25);
						stanModule.Movement:Move(Vector3.new(268.98, 52.65, -259.39)):Wait(20);
						
						stanModule.Actions:EnterDoor("mallProtect2");
						stanModule.Movement:Move(Vector3.new(273.25, 55.57, -282.3)):Wait(5);
						wait(1)
						if stanModule == nil then return end;
						stanModule.Actions:FaceOwner();
						stanModule.Chat(stanModule.Owner, "Ah.. Wrighton Dale Mall.. ");
						
					elseif mission.ProgressionPoint >= 4 and mission.ProgressionPoint <= 9 then
						if stanModule == nil then return end;
						stanModule:TeleportHide();
					end
				elseif mission.Type == 3 then -- OnComplete
					stanModule:TeleportHide();
				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)
		
		return CutsceneSequence;
	elseif modBranchConfigs.IsWorld("TheMall") then
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
			
			local patrickPrefab = workspace.Entity:FindFirstChild("Patrick");
			local patrickModule = patrickPrefab and modNpcs.getByModel(patrickPrefab);
			
			local mallStanSpawn = CFrame.new(755.640137, 59.1950226, -805.369812, -1, 0, 0, 0, 1, 0, 0, 0, -1);
			local stanModule = modNpcs.getByOwner(player, "Stan");
			
			local function OnChanged(firstRun)
				if mission.Type == 1 then -- OnActive
					if firstRun and mission.ProgressionPoint >= 4 and stanModule == nil then
						local npc = modNpcs.spawn("Stan", mallStanSpawn, function(npc, npcModule)
							npcModule.Owner = player;
							stanModule = npcModule;
						end);
						modReplicationManager.ReplicateOut(player, npc);
					end
					
					if mission.ProgressionPoint == 4 then
						stanModule.Wield.Equip("czevo3");
						stanModule.Actions:Teleport(mallStanSpawn);
						
					elseif mission.ProgressionPoint == 5 then
						stanModule.Interactable.Parent = script;
						stanModule.Actions:Teleport(mallStanSpawn);
						
						if stanModule.Wield.ToolModule == nil then
							stanModule.Wield.Equip("czevo3");
						end
						
						wait(2);
						stanModule.Movement:SetWalkSpeed("default", 25);
						
						local waypoint = Vector3.new(714.962, 95.72, -721.133);
						
						waypoint = Vector3.new(731.861, 131.438, -728.346);
						stanModule.Movement:Move(waypoint):Wait(60);
						if stanModule.Actions:DistanceFrom(waypoint) > 20 then
							stanModule.Actions:Teleport(CFrame.new(waypoint));
						end
						
						stanModule.Movement:SetWalkSpeed("default", 10);
						waypoint = Vector3.new(793.235, 162.864, -726.123);
						stanModule.Movement:Move(waypoint):Wait(10);
						stanModule.Movement:Face(Vector3.new(797.496, 160.864, -730.922));
						
						if stanModule.Actions:DistanceFrom(waypoint) > 20 then
							stanModule.Movement:EndMovement();
							stanModule.Actions:Teleport(CFrame.new(waypoint));
						end
						
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint <= 5 then
								mission.ProgressionPoint = 6;
							end;
						end)
						
					elseif mission.ProgressionPoint == 6 then
						stanModule.Interactable.Parent = script;
						stanModule.Actions:Teleport(CFrame.new(793.235, 160.864, -726.123));
						stanModule.Movement:Face(Vector3.new(797.496, 160.864, -730.922));
						stanModule.Actions:WaitForOwner(20);
						if stanModule == nil then return end;
						
						stanModule.Wield.Unequip();
						
						patrickModule.Chat(player, "HALT! STOP RIGHT THERE OR I SHOOT!");
						wait(1);
						stanModule.Chat(stanModule.Owner, "WAIT wait wait!!! We are here to talk!");
						wait(2);
						patrickModule.Chat(player, "What do you want?!");
						wait(2);
						stanModule.Chat(stanModule.Owner, "We want to speak to your leader.");
						wait(2);
						patrickModule.Chat(player, "Not gonna happen. Leave now!");
						wait(2);
						stanModule.Actions:FaceOwner();
						
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint <= 6 then
								mission.ProgressionPoint = 7;
							end;
						end)
						
					elseif mission.ProgressionPoint == 7 then
						stanModule.Interactable.Parent = script;
						stanModule.Actions:Teleport(CFrame.new(793.235, 162.864, -726.123));
						stanModule.Actions:WaitForOwner(20);
						stanModule.Actions:FaceOwner();
						
					elseif mission.ProgressionPoint == 8 then
						stanModule.Interactable.Parent = script;
						stanModule.Actions:Teleport(CFrame.new(793.235, 162.864, -726.123));
						stanModule.Actions:WaitForOwner(20);
						stanModule.Actions:FaceOwner();
						
					elseif mission.ProgressionPoint == 9 then
						stanModule.Interactable.Parent = stanModule.Prefab;
						
					elseif mission.ProgressionPoint == 10 then
						stanModule.Interactable.Parent = script;
						
						if stanModule.Wield.ToolModule == nil then
							stanModule.Wield.Equip("czevo3");
						end
						stanModule.Movement:SetWalkSpeed("default", 25);
						stanModule.Movement:Move(Vector3.new(735.55, 97.3, -711.272)):Wait(10);
						
						modMission:CompleteMission(player, MISSION_ID);
					end
				elseif mission.Type == 3 then -- OnComplete
					if stanModule then
						stanModule.Interactable.Parent = stanModule.Prefab;
					end
				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)
		
		return CutsceneSequence;
	end

	return;
end;