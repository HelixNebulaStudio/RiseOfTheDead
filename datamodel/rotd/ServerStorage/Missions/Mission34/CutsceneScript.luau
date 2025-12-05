local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

--== Server Variables;
local MISSION_ID = 34;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	
end

--== Script;
return function(CutsceneSequence)
	if modBranchConfigs.IsWorld("MainMenu") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
		
		if modMission:IsComplete(player, MISSION_ID) then return end;
	
		for a=1, 5 do
			if player.Character ~= nil then break; end;
			wait(1)
		end
		if player.Character == nil then return end;
		
		local strangerNpcClass: NpcClass? = shared.modNpcs.getPlayerNpc(player, "Stranger", function(npcClass: NpcClass)
			return npcClass.Properties.MissionId == MISSION_ID;
		end);

		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 1 then
					
				elseif mission.ProgressionPoint == 2 then
					if strangerNpcClass == nil then
						local playerCframe = player.Character:GetPrimaryPartCFrame();

						strangerNpcClass = shared.modNpcs.spawn2{
							Name = "Stranger";
							CFrame = playerCframe;
							Player = player;
							BindSetup = function(npcClass: NpcClass)
								npcClass.Properties.MissionId = MISSION_ID;
								npcClass.Properties.Seed = (mission.SaveData.Seed or 1);
							end;
						};
						if strangerNpcClass then
							strangerNpcClass:GetComponent("FollowPlayer")(nil, function() 
								return mission.ProgressionPoint == 2;
							end);
							strangerNpcClass.Character:SetAttribute("Player", player.Name);
						end
					end
					
				elseif mission.ProgressionPoint == 3 then
					if strangerNpcClass and strangerNpcClass.Character then
						strangerNpcClass.Properties.Immortal = 1;
						wait(1);
						strangerNpcClass.Character:Destroy();
						strangerNpcClass = nil;
					end
				end
				
			elseif mission.Type == 3 then -- OnComplete
				mission.Changed:Disconnect(OnChanged);
				if strangerNpcClass and strangerNpcClass.Character then
					strangerNpcClass.Character:Destroy();
					strangerNpcClass = nil;
				end
				
			elseif mission.Type == 4 then -- OnFail
				if strangerNpcClass and strangerNpcClass.Character then
					strangerNpcClass.Character:Destroy();
					strangerNpcClass = nil;
				end
				
			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
			
	end)
	
	return CutsceneSequence;
end;