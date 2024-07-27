local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Lennon={};
};

local missionId = 23;
--==

-- MARK: Lennon Dialogues
Dialogues.Lennon.Dialogues = function()
	return {
		{CheckMission=missionId; Tag="snipernest_help"; Dialogue="Ummm ok?";
			Face="Smirk"; Reply="Good good, are you good at killing zombies?"};
		{Tag="snipernest_many"; Dialogue="YES! I'm the greatest zombie killer here.";
			Face="Surprise"; Reply="WOW! There's are few zombies I want you to kill."};
		{Tag="snipernest_yes"; Dialogue="Maybe.. What do you think?";
			Face="Joyful"; Reply="Errrr, you seem like you are really good at it. I believe you can do it, there's a few zombies I want you to kill."};
		{Tag="snipernest_no"; Dialogue="Nah, it's hard to kill them.";
			Face="Disbelief"; Reply="Ohh darn, come back when you are better please."};
		
		{Tag="snipernest_done"; Dialogue="Yeah, I helped you kill some zombies.";
			Face="Oops"; Reply="Oh! Umm, thank you?"};
		{Tag="fail_invFull"; Dialogue="Yeah, I helped you kill some zombies.";
			Face="Suspicious"; Reply="Your inventory is quite full, comeback when you have some space available."};
	};
end

if RunService:IsServer() then
	-- MARK: Lennon Handler
	Dialogues.Lennon.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			dialog:SetInitiate("Errr, were you suppose to be doing something for me? I forgot..");
			local mission = modMission:Progress(player, missionId);
			if mission.Type == 1 then
				if mission.ProgressionPoint == 2 then
					if modMission:CanCompleteMission(player, missionId) then
						dialog:AddChoice("snipernest_done", function(dialog)
							modMission:CompleteMission(player, missionId);
						end);
					else
						dialog:AddChoice("fail_invFull");
					end
				end
			end
			
		elseif mission.Type == 2 then -- Available
			dialog:SetInitiate("Kiddddo, ehhh can you help me out?", "Confident");
			dialog:AddChoice("snipernest_help", function(dialog)
				dialog:AddChoice("snipernest_many", function(dialog)
					modMission:StartMission(player, missionId);
				end)
				dialog:AddChoice("snipernest_yes", function(dialog)
					modMission:StartMission(player, missionId);
				end)
				dialog:AddChoice("snipernest_no");
			end)
			
		end
	end
end


return Dialogues;