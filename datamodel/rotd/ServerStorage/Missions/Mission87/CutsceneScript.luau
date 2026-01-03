local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local MISSION_ID = 87;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	--if not modBranchConfigs.IsWorld("TheWarehouse") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
			
		local playerClass: PlayerClass = shared.modPlayers.get(player);

		local josephModel;
		if josephModel == nil and shared.WorldCore.JosephClass then
			josephModel = shared.WorldCore.JosephClass.Character;
		end
		local josephClass = modNpcs.getPlayerNpc(player, "Joseph");
		if josephClass == nil then
			if josephModel then
				modReplicationManager.UnreplicateFrom(player, josephModel);
			end

			local spawnCf = playerClass:GetCFrame();
			if josephModel then
				spawnCf = josephModel:GetPivot();
			end
			josephClass = shared.modNpcs.spawn2{
				Name = "Joseph";
				Player = player;
				CFrame = spawnCf;
			};
			if modBranchConfigs.IsWorld("TheResidentials") then
				modReplicationManager.ReplicateOut(player, josephClass.Character);
			end
			task.delay(1, function()
				local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
				local remoteSetHeadIcon = remotes:WaitForChild("SetHeadIcon");
				remoteSetHeadIcon:FireAllClients(0, "Joseph", "Heal");
			end)
		end
		
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 1 then

				elseif mission.ProgressionPoint == 2 then
					local followPlayerComp = josephClass:GetComponent("FollowPlayer");
					followPlayerComp(nil, function()
						return mission.Type == 1 and mission.ProgressionPoint == 2;
					end)

				end
			elseif mission.Type == 3 then -- OnComplete


			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;