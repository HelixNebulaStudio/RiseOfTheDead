local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);

--==
return function(player, dialog, data, mission)
	if mission.Type == 2 then -- Available

	elseif mission.Type == 1 then -- Active
		local stage = mission.ProgressionPoint;
		if stage == 12 then
			dialog:SetInitiate("...");
			local dallasModule = modNpc.GetPlayerNpc(player, "Dallas");
			if dallasModule.Humanoid.PlatformStand then
				dialog:AddChoice("investigation_wakeUp", function(dialog)
					if dallasModule then
						dallasModule.Humanoid.PlatformStand = false;
						dallasModule.StopAnimation("Unconscious");
						dallasModule.Humanoid:ChangeState(Enum.HumanoidStateType.None);
					end
				end)
			end
			
		end
		
	end
end
