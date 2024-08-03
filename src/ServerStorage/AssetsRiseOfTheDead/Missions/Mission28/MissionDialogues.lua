local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Carlson={};
};

local missionId = 28;
--==

-- !outline: Carlson Dialogues
Dialogues.Carlson.DialogueStrings = {
	--== Safety Safehouse
	["safetysafehouse_goodGotTime"]={
		CheckMission=missionId;
		Say="Yeah, I got time."; 
		Reply="Good, I think we should fortify the front with some metal walls.";
	};
	["safetysafehouse_badGotTime"]={
		CheckMission=missionId;
		Say="Yeah, I got time."; 
		Reply="Good, since the bandits took our metal, we'll need metal to build some metal walls in the front.";
	};
	
	-- ss bad dialog
	["safetysafehouse_badMetal"]={
		Say="How much metal will we need?"; 
		Reply="About 500 metal scrap should be enough, if the bandits had not taken my 1000 metal scraps, we wouldn't have to find metal ourselves.";
	};
	["safetysafehouse_truth"]={
		Say="Carlson, I'm so sorry. I actually kept the metal for myself that I took from your crate."; 
		Reply="Oh... How could you.. Are you still going to help us?";
	};
	["safetysafehouse_yes"]={
		Say="Yes, I will do anything to redeem from what I did."; 
		Reply="Okay.. you'll have to get the metal to build the walls.";
	};
	
	-- ss good dialog
	["safetysafehouse_goodMetal"]={
		Say="How much metal will we need?"; 
		Reply="About 500 metal scrap should be enough, we'll use my metal scraps.";
	};
	["safetysafehouse_start"]={
		Dialogue="Okay, I'll get started."; 
		Reply="Alright.";
	};
	["safetysafehouse_complete"]={
		Say="I've added walls to the front of the safehouse, is that enough?"; 
		Reply="Yes, that'll do for now. Thanks for your help. Here's the spare scraps as a gratitude for helping us with this.";
	};
	["safetysafehouse_askForMetal"]={
		Say="Hey, do you have any spare metal scraps?"; 
		Reply="Yeah, I do, here have some.";
	};
};

if RunService:IsServer() then
	-- !outline: Carlson Handler
	Dialogues.Carlson.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		local profile = shared.modProfile:Get(player);
		local playerSave = profile:GetActiveSave();
		local inventory = playerSave.Inventory;
		
		if mission.Type == 1 then -- Active
			dialog:SetInitiate("How's it going so far?", "Confident");
			
			if mission.ObjectivesCompleted["addDoorway"]
			and mission.ObjectivesCompleted["addWall1"]
			and mission.ObjectivesCompleted["addWall2"]
			and mission.ObjectivesCompleted["addWall3"]
			and mission.ObjectivesCompleted["addWall4"] then
				dialog:AddChoice("safetysafehouse_complete", function(dialog)
					modMission:CompleteMission(player, missionId);
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
					modMission:StartMission(player, missionId);
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
end


return Dialogues;