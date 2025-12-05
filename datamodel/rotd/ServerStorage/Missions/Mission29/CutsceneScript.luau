local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local MISSION_ID = 29;

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
			
		if not modMission:IsComplete(player, MISSION_ID) then
			local hilbertNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Hilbert");
			if hilbertNpcClass == nil then
				hilbertNpcClass = modNpcs.spawn2{
					Name = "Hilbert";
					Player = player;
					ReplicateOut = true;
					BindSetup = function(npcClass: NpcClass)
						npcClass.RootPart.Anchored = true;
					end;
				};
				
			end

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- Available

				elseif mission.Type == 1 then -- Active
					if mission.ProgressionPoint == 1 then

					elseif mission.ProgressionPoint == 2 then

					end
				elseif mission.Type == 3 then
					mission.OnChanged:Disconnect(OnChanged);
					hilbertNpcClass.Character:Destroy();
				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end
	end)
	
	return CutsceneSequence;
end;