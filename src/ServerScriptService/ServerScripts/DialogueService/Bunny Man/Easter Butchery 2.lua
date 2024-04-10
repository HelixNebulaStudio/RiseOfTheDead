local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		if not modBranchConfigs.IsWorld("EasterButchery") then
			dialog:AddChoice("eb2_letsgo", function(dialog)
				data:Set("World", modBranchConfigs.WorldName);
				modMission:Progress(player, 50, function(mission)
					if mission.ProgressionPoint == 1 then
						mission.ProgressionPoint = 2;
					end;
				end)

				local profile = modProfile:Get(player);
				local activeSave = profile:GetActiveSave();
				if profile and activeSave then
					activeSave.Spawn = "EasterButchery2";
				end
				modServerManager:Travel(player, "EasterButchery");
			end)
		else
			if mission.ProgressionPoint == 1 then
				modMission:Progress(player, 50, function(mission)
					if mission.ProgressionPoint == 1 then
						mission.ProgressionPoint = 2;
					end;
				end)
				local profile = modProfile:Get(player);
				local activeSave = profile:GetActiveSave();
				if profile and activeSave then
					activeSave.Spawn = "EasterButchery2";
				end
				
				local spawnPart = workspace:FindFirstChild("EasterButchery2");
				if spawnPart then
					shared.modAntiCheatService:Teleport(player, spawnPart.CFrame * CFrame.new(0, 2, 0));
				end
				
			elseif mission.ProgressionPoint == 2 then
				dialog:SetInitiate("Cultists are always watching.. Their meet signal is boric acid fire, it creates a green flame. Follow my lead.");
				
				dialog:AddChoice("eb2_lead", function(dialog)
					
					modMission:Progress(player, 50, function(mission)
						if mission.ProgressionPoint == 2 then
							mission.ProgressionPoint = 3;
						end;
					end)
				end)
				
			elseif mission.ProgressionPoint == 8 then
				dialog:SetInitiate("You did well, looks like I know how to make the cultists crumple.");
				dialog:AddChoice("eb2_end1", function(dialog)
					dialog:AddChoice("eb2_end2", function(dialog)
						modMission:CompleteMission(player, 50);

						local profile = modProfile:Get(player);
						profile.ItemUnlockables:Set("bunnymanhead", "bunnymanheadbenefactor", true);
						profile.ItemUnlockables:Alert("bunnymanhead", "bunnymanheadbenefactor");
						
						profile:Sync("ItemUnlockables/bunnymanhead/"..profile.ItemUnlockables["bunnymanhead"]);
					end)
				end)
				
			else
				dialog:SetInitiate("Hmmm?");

			end
		end
		
	elseif mission.Type == 2 then -- Available
		dialog:SetInitiate("You are me, Bunny Man. I have another task for you.");
		dialog:AddChoice("eb2_greet", function(dialog)
			dialog:AddChoice("eb2_greet2", function(dialog)
				dialog:AddChoice("eb2_greet3", function(dialog)
					dialog:AddChoice("eb2_greet4", function(dialog)
						dialog:AddChoice("eb2_start", function(dialog)
							modMission:StartMission(player, 50);
						end)
					end)
				end)
			end)
		end)
		
	elseif mission.Type == 3 then -- Complete
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
		
	end
end
