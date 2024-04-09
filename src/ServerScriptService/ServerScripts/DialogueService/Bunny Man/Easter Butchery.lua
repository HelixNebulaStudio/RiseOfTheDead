local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

--==
return function(player, dialog, data, mission)
	local mission50 = modMission:GetMission(player, 50);
	local function addLoreOptions(dialog)
		if mission50 and mission50.Type ~= 3 then return end;
		
		dialog:AddChoice("reborn_lore1", function(dialog)
			addLoreOptions(dialog);
		end);
		dialog:AddChoice("reborn_lore2", function(dialog)
			addLoreOptions(dialog);
		end);
		dialog:AddChoice("reborn_lore3", function(dialog)
			addLoreOptions(dialog);
		end);
		dialog:AddChoice("reborn_lore4", function(dialog)
			addLoreOptions(dialog);
		end);
		dialog:AddChoice("reborn_home", function(dialog)
			local worldName = data:Get("World") or "TheResidentials";
			modServerManager:Travel(player, worldName);
		end)
	end
	
	if mission.Type == 1 then -- Active
		if not modBranchConfigs.IsWorld("EasterButchery") then
			dialog:AddChoice("reborn_travel", function(dialog)
				data:Set("World", modBranchConfigs.WorldName);
				modMission:Progress(player, 32, function(mission)
					if mission.ProgressionPoint == 1 then
						mission.ProgressionPoint = 2;
					end;
				end)
				modServerManager:Travel(player, "EasterButchery");
			end)
		else
			if mission.ProgressionPoint == 3 then
				dialog:SetInitiate("You have been reborn. You are now a Bunny Man. You are me.");
				
				dialog:AddChoice("reborn_complete", function(dialog)
					modMission:CompleteMission(player, 32);
					addLoreOptions(dialog);
				end)
				
			end
		end
		
	elseif mission.Type == 2 then -- Available
		dialog:SetInitiate("Err.. You. Yes, you.");
		dialog:AddChoice("reborn_init", function(dialog)
			dialog:AddChoice("reborn_what", function(dialog)
				dialog:AddChoice("reborn_alright", function(dialog)
					modMission:StartMission(player, 32);
				end)
			end)
		end)
		
	elseif mission.Type == 3 then -- Complete
		if mission50 == nil or mission50.Type ~= 1 then
			if not modBranchConfigs.IsWorld("EasterButchery") then
				dialog:AddChoice("reborn_travel", function(dialog)
					data:Set("World", modBranchConfigs.WorldName);
					modServerManager:Travel(player, "EasterButchery");
				end)
				
			else
				dialog:AddChoice("reborn_home", function(dialog)
					local worldName = data:Get("World") or "TheResidentials";
					modServerManager:Travel(player, worldName);
				end)
			
			end
		end;
		addLoreOptions(dialog);
		
	end
end