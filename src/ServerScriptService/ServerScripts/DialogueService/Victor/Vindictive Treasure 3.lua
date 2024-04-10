local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modGameModeManager = require(game.ServerScriptService.ServerLibrary.GameModeManager);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

--==
return function(player, dialog, data, mission)
	if mission.Type == 2 then -- Available	
		local gaveMask = data:Get("gaveMask") == true;
		dialog:SetInitiate("Hey dude, I checked out the tombs after you cleared it. I need some help again in the tombs.", gaveMask and "Happy" or "Skeptical");
		
		dialog:AddChoice("vt3_check", function(dialog)
			modMission:StartMission(player, 42);
		end)
		
	elseif mission.Type == 1 then -- Active;
		if modBranchConfigs.IsWorld("TheWarehouse") then
			if mission.ProgressionPoint == 1 then
				dialog:AddChoice("vt3_vttravel");
			end
		elseif modBranchConfigs.IsWorld("VindictiveTreasure") then
			modMission:Progress(player, 42, function(mission)
				if mission.ProgressionPoint <= 2 then
					mission.ProgressionPoint = 2;
				end;
			end)
			if mission.ProgressionPoint == 2 then
				dialog:SetInitiate("Alright, I know there's another secret passage somewhere..", "Skeptical");
				modMission:Progress(player, 42, function(mission)
					if mission.ProgressionPoint <= 2 then
						mission.ProgressionPoint = 3;
					end;
				end)
				
			elseif mission.ProgressionPoint == 7 then
				dialog:SetInitiate("How did you.. Help me get out of this quick!!", "Frustrated");
				dialog:AddChoice("vt3_bargain", function(dialog)
					dialog:AddChoice("vt3_depress", function(dialog)
						dialog:AddChoice("vt3_save", function(dialog)
							modMission:Progress(player, 42, function(mission)
								if mission.ProgressionPoint <= 8 then
									mission.SaveData.SaveVictor = 1;
									mission.ProgressionPoint = 8;
								end;
							end)
						end)
						dialog:AddChoice("vt3_dontsave", function(dialog)
							modMission:Progress(player, 42, function(mission)
								if mission.ProgressionPoint <= 8 then
									mission.SaveData.SaveVictor = 2;
									mission.ProgressionPoint = 8;
								end;
							end)
						end)
					end)
				end)
				
			end
		end
		
	elseif mission.Type == 4 then -- Failed
		dialog:SetInitiate("Where did you go?!", "Angry");
		dialog:AddChoice("vt3_vttravel", function(dialog)
			modMission:StartMission(player, 42);
		end)
		
	end
end