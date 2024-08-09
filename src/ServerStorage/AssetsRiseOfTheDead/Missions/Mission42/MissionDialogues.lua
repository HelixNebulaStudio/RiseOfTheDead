local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Victor={};
};

local missionId = 42;
--==

-- MARK: Victor Dialogues
Dialogues.Victor.DialogueStrings = {
	["vt3_check"]={
		CheckMission=missionId;
		Face="Happy";
		Say="Sure?"; 
		Reply="Cool, just let me know when you're ready to travel.";
	};

	["vt3_vttravel"]={
		Face="Confident";
		Say="I'm ready to go to the tombs."; 
		Reply="Alright, let's go.";
	};

	["vt3_follow"]={
		Face="Skeptical";
		Say="Sure?"; 
		Reply="Cool, just let me know when you're ready to travel.";
	};
	
	["vt3_bargain"]={
		Face="Grumpy";
		Say="No! You tried to kill me and now you are going to rot here."; 
		Reply="Uggh. Fine. I'm sorry, if you get me out of here, you will never see me again.";
	};

	["vt3_depress"]={
		Face="Worried";
		Say="I won't be making any deals with you.."; 
		Reply="Well then, this is it huh.. ";
	};
	
	["vt3_save"]={
		Face="Tired";
		Say="*Save Victor*"; 
		Reply="...";
	};

	["vt3_dontsave"]={
		Face="Tired";
		Say="*Kill Victor*"; 
		Reply="...";
	};
};


if RunService:IsServer() then
	-- MARK: Victor Handler
	Dialogues.Victor.DialogueHandler = function(player, dialog, data, mission)
		local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available	
			local gaveMask = data:Get("gaveMask") == true;
			dialog:SetInitiate("Hey dude, I checked out the tombs after you cleared it. I need some help again in the tombs.", gaveMask and "Happy" or "Skeptical");
			
			dialog:AddChoice("vt3_check", function(dialog)
				modMission:StartMission(player, missionId);
			end)
			
		elseif mission.Type == 1 then -- Active;
			if modBranchConfigs.IsWorld("TheWarehouse") then
				if mission.ProgressionPoint == 1 then
					dialog:AddChoice("vt3_vttravel", function()
						local npcModel = dialog.Prefab;
						local lowerTorso = npcModel.LowerTorso;
						if lowerTorso:FindFirstChild("Interactable") then
							dialog:InteractRequest(lowerTorso.Interactable, lowerTorso, "interact");
						end

					end);
				end
			elseif modBranchConfigs.IsWorld("VindictiveTreasure") then
				modMission:Progress(player, missionId, function(mission)
					if mission.ProgressionPoint <= 2 then
						mission.ProgressionPoint = 2;
					end;
				end)
				if mission.ProgressionPoint == 2 then
					dialog:SetInitiate("Alright, I know there's another secret passage somewhere..", "Skeptical");
					dialog:SetExpireTime(workspace:GetServerTimeNow()+6);
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint <= 2 then
							mission.ProgressionPoint = 3;
						end;
					end)
					
				elseif mission.ProgressionPoint == 7 then
					dialog:SetInitiate("How did you.. Help me get out of this quick!!", "Frustrated");
					dialog:AddChoice("vt3_bargain", function(dialog)
						dialog:AddChoice("vt3_depress", function(dialog)
							dialog:AddChoice("vt3_save", function(dialog)
								modMission:Progress(player, missionId, function(mission)
									if mission.ProgressionPoint <= 8 then
										mission.SaveData.SaveVictor = 1;
										mission.ProgressionPoint = 8;
									end;
								end)
							end)
							dialog:AddChoice("vt3_dontsave", function(dialog)
								modMission:Progress(player, missionId, function(mission)
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
				modMission:StartMission(player, missionId);
			end)
			
		end
	end
end


return Dialogues;