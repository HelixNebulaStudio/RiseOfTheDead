local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);

--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		dialog:SetInitiate("How's it going so far?", "Confident");
		
		local mission = modMission:Progress(player, 28);
		if mission.ObjectivesCompleted["addDoorway"]
		and mission.ObjectivesCompleted["addWall1"]
		and mission.ObjectivesCompleted["addWall2"]
		and mission.ObjectivesCompleted["addWall3"]
		and mission.ObjectivesCompleted["addWall4"] then
			dialog:AddChoice("safetysafehouse_complete", function(dialog)
				modMission:CompleteMission(player, 28);
				if data:Get("thebackup_gaveMetal") then
					data:Set("thebackup_claimedMetal", false);
				end
			end)
		end
		
	elseif mission.Type == 2 then -- Available
		local gaveMetal = data:Get("thebackup_gaveMetal");
		dialog:SetInitiate("$PlayerName, do you have time to help with fortifying the safehouse?");
		local karma = 0;
		
		local function start(dialog)
			dialog:AddChoice("safetysafehouse_start", function(dialog)
				modMission:StartMission(player, 28);
				data:Set("Karma", (data:Get("Karma") or 0) + karma);
			end)
		end
		
		if gaveMetal then
			karma = karma +1;
			dialog:AddChoice("safetysafehouse_goodGotTime", function(dialog)
				dialog:AddChoice("safetysafehouse_goodMetal", start)
			end)
		else
			karma = karma -1;
			
			dialog:AddChoice("safetysafehouse_badGotTime", function(dialog)
				local function truth(dialog)
					dialog:AddChoice("safetysafehouse_truth", function(dialog)
						karma = karma +1;
						dialog:AddChoice("safetysafehouse_yes", start)
					end)
				end
				dialog:AddChoice("safetysafehouse_badMetal", function(dialog)
					start(dialog);
					truth(dialog);
				end)
				truth(dialog);
			end)
		end
	
	elseif mission.Type == 3 then -- Complete
		if data:Get("thebackup_claimedMetal") == false then
			local profile = modProfile:Get(player);
			local playerSave = profile:GetActiveSave();
			local inventory = playerSave.Inventory;
			local hasSpace = inventory:SpaceCheck{
				{ItemId="metal"; Data={Quantity=500}; };
			};
			
			if hasSpace then
				dialog:AddChoice("safetysafehouse_askForMetal", function()
					if not dialog.InRange() then return end;
					inventory:Add("metal", {Quantity=500;});
					shared.Notify(player, "You recieved 500 Metal Scraps from Carlson.", "Reward");
					data:Set("thebackup_claimedMetal", true);
				end)
			end
		end	
		
	end
end
