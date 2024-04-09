local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);

local random = Random.new();
--== Server Variables;
if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modEvents = require(game.ServerScriptService.ServerLibrary.Events);
	modItemDrops = require(game.ServerScriptService.ServerLibrary.ItemDrops);
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheWarehouse") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player = players[1];
		local mission = modMission:GetMission(player, 15);
		if mission == nil then return end;
		
		if not modMission:IsComplete(player, 15) then
			local function OnChanged()
				if mission.Type == 1 then -- Active
					if modEvents:GetEvent(player, "mission15Battery") == nil then
						modItemDrops.Spawn({Name="Battery"; Type=modItemDrops.Types.Battery; Quantity=1}, CFrame.new(-9.9, 72.5, -41.9), player, false);
					end
					if modEvents:GetEvent(player, "mission15Wires") == nil then
						modItemDrops.Spawn({Name="Wires"; Type=modItemDrops.Types.Wires; Quantity=1}, CFrame.new(42.8, 63.3, 191.9), player, false);
					end
					mission.Changed:Disconnect(OnChanged);
				end
			end
			mission.Changed:Connect(OnChanged);
			OnChanged();
		end
	end)
	
	return CutsceneSequence;
end;