local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

--== Variables;
local MISSION_ID = 17;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheWarehouse") and not modBranchConfigs.IsWorld("BioXResearch") then return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
			
		local jesseNpcClass: NpcClass? = shared.modNpcs.getByModel(workspace.Entity:WaitForChild("Jesse"));
		if jesseNpcClass == nil then return end;

		local cutscenePlayersComp = jesseNpcClass:GetComponent("CutscenePlayers");
		if not modMission:IsComplete(player, MISSION_ID) then

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					cutscenePlayersComp:AddPlayer(player, MISSION_ID);

				elseif mission.Type == 1 then -- OnActive
					cutscenePlayersComp:AddPlayer(player, MISSION_ID);

				elseif mission.Type == 3 then -- OnComplete
					cutscenePlayersComp:RemovePlayer(player, MISSION_ID);
					mission.OnChanged:Disconnect(OnChanged);
					
				elseif mission.Type == 4 then -- OnFail
					cutscenePlayersComp:RemovePlayer(player, MISSION_ID);

				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);

		end
	end)
	
	return CutsceneSequence;
end;