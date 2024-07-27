local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Wilson={};
};

local missionId = 19;
--==

-- MARK: Wilson Dialogues
Dialogues.Wilson.Dialogues = function()
	return {
		{Tag="medbre_init";
			Face="Worried"; Reply="Stan saved my life, I was trapped and he heard me cried for help. I miss him so much..";};

		{CheckMission=missionId; Tag="medbre_start"; Dialogue="Hey, it's okay. I have some news about Stan.";
			Face="Worried"; Reply="News.. about Stan?";
			FailResponses = {
				{Reply="You're too new here, come back once you're more familiar with the place."};
			};
		};
		{Tag="medbre_start2"; Dialogue="Yes, so apparently Stan is still alive.";
			Face="Disbelief"; Reply="..."};


		{Tag="tickhunting_sure"; Dialogue="Sure."; 
			Face="Ugh"; Reply="This annonying type of zombies keeps ticking, they run at you and tries to blow you up. I need you to get rid of them."};
		{CheckMission=missionId; Tag="tickhunting_yeah"; Dialogue="I'm on it."; 
			Face="Smirk"; Reply="Off you go solider, get back here as soon as you are done."};
		{Tag="tickhunting_stillWorking"; Dialogue="Hard at work sir.."; 
			Face="Ugh"; Reply="Alright, keep going."};
		{Tag="tickhunting_return"; Dialogue="I got rid of as much as I could."; 
			Face="Joyful"; Reply="You did great solider."};
		
	};
end

if RunService:IsServer() then
	-- MARK: Wilson Handler
	Dialogues.Wilson.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			dialog:SetInitiate("Progress status?");
			if stage == 1 then
				dialog:AddChoice("tickhunting_stillWorking");
			elseif stage == 2 then
				dialog:AddChoice("tickhunting_return", function(dialog)
					modMission:CompleteMission(player, missionId);
				end)
			end
			
		elseif mission.Type == 2 then -- Available
			dialog:SetInitiate("You up for another task, solider?");
			dialog:AddChoice("tickhunting_sure", function(dialog)
				dialog:AddChoice("tickhunting_yeah", function(dialog)
					modMission:StartMission(player, missionId);
				end)
			end)
			
		end
	end
end


return Dialogues;