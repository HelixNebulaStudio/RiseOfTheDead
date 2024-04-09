local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Jane={};
	Lennon={};
	Carlson={};
};

local missionId = 24;
--==

-- !outline: Jane Dialogues
Dialogues.Jane.Dialogues = function()
	return {		
		{Tag="mia_yes"; CheckMission=missionId; Dialogue="Yeah, there were 2 survivors outside the other end of the sewers."; 
			Face="Surprise"; Reply="Oh, under the Wrighton Dale Bridge?";
			FailResponses = {
				{Reply="Wait, I'm a bit busy.."};
			};	
		};
		{Tag="mia_bridge"; Dialogue="Yeah, they said they were attacked by the bandits.. I thought Robert was coming back to tell you this. Did he come back?"; 
			Face="Surprise"; Reply="No.. He hasn't been back for a while now, where did he say he was going?"};
		{Tag="mia_warn"; Dialogue="Wait what!?.. He said he's coming back to warn you guys about the bandits."; 
			Face="Scared"; Reply="Oh nooo, we need to find him."};

		{Tag="mia_no"; Dialogue="Still no signs of him, but I think the bandits got him.."; 
			Face="Scared"; Reply="*Gasp* This is bad.. You need to help us get to the bottom of this.."};
		{Tag="mia_zombie"; Dialogue="There was a bandit, he was turning into a zombie. He said that something got him, but he wasn't bitten or anything.. He just turned.."; 
			Face="Suspicious"; Reply="I'm no expert at this but many of the zombies I saw weren't bitten too!"};
	};
end

-- !outline: Lennon Dialogues
Dialogues.Lennon.Dialogues = function()
	return {		
		{Tag="mia_clue"; Dialogue="Hey, umm, have you seen a guy with a red beanie?"; 
			Face="Bored"; Reply="Yeah, he came by and told me that be careful of bandits, and I told him, they should be careful of me!"};
		{Tag="mia_thanks"; Dialogue="Oh, umm.. okay, Thanks."; 
			Face="Joyful"; Reply="Yeah, I'm welcome. Huhuh."};
	};
end

-- !outline: Carlson Dialogues
Dialogues.Carlson.Dialogues = function()
	return {		
		{Tag="mia_seen"; Dialogue="Hey, has Robert come by recently??"; 
			Face="Suspicious"; Reply="No, but there were a lot of noise of bandits running by towards north. Did something happen to Robert?"};
		{Tag="mia_thanks"; Dialogue="I think he's been kidnapped by the bandits.."; 
			Face="Scared"; Reply="Oh Jesus! I remember hearing screaming too, that could had been him! You should head into the caves to look for him."};

	};
end

if RunService:IsServer() then
	-- !outline: Jane Handler
	Dialogues.Jane.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available;
			dialog:SetInitiate("So did you find them? The survivors in the sewers?", "Joyful");
			dialog:AddChoice("mia_yes", function(dialog)
				dialog:AddChoice("mia_bridge", function(dialog)
					dialog:AddChoice("mia_warn", function(dialog)
						modMission:StartMission(player, missionId);
					end)
				end)
			end)
			
			
		elseif mission.Type == 1 then -- Active
			dialog:SetInitiate("Have you found him yet?", "Worried");

			if mission.Type == 1 then
				if mission.ProgressionPoint >= 5 then
					if mission.ProgressionPoint >= 5 then
						dialog:AddChoice("mia_no", function(dialog)
							dialog:AddChoice("mia_zombie", function(dialog)
								modMission:CompleteMission(player, missionId);
							end)
						end)
					end
				end
			end
			
		end
	end

	-- !outline: Lennon Handler
	Dialogues.Lennon.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
		
		if mission.ProgressionPoint <= 1 then
			dialog:SetInitiate("Hmmmmmmm, huh? Oh it's you!", "Happy");
			dialog:AddChoice("mia_clue", function(dialog)
				dialog:AddChoice("mia_thanks", function(dialog)
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint <= 1 then
							mission.ProgressionPoint = 2;
						end;
					end)
				end)
			end)
		end
		
	end

	-- !outline: Carlson Handler
	Dialogues.Carlson.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
		
		if mission.ProgressionPoint == 3 then
			dialog:SetInitiate("Yo $PlayerName, what do you need?", "Confident");
			dialog:AddChoice("mia_seen", function(dialog)
				dialog:AddChoice("mia_thanks", function(dialog)
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint == 3 then
							mission.ProgressionPoint = 4;
						end;
					end)
				end)
			end)
		end
		
	end
	
end


return Dialogues;
