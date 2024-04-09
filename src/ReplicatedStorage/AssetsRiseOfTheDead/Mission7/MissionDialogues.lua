local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Robert={};
};

local missionId = 7;
--==

-- !outline: Robert Dialogues
Dialogues.Robert.Dialogues = function()
	return {
		{Tag="thePrisoner_areYouAlright"; Dialogue="Hey, are you alright?"; 
			Face="Smile"; Reply="Yeah, thanks again dude."};
		{Tag="thePrisoner_howLong"; Dialogue="How long have you been in there?";
			Face="Grumpy"; Reply="Couple days dude, I survived off the food in the store. I got trapped in there when I was scavenging some supplies then the power went out and the gates locked me in."};
		{Tag="thePrisoner_otherSafehouse"; Dialogue="Oh...";
			Face="Worried"; Reply="I really want to get back to my safehouse, but there's something dangerous in the way..."};
		{Tag="thePrisoner_dangerous"; Dialogue="What is it?";
			Face="Scared"; Reply="When I tried to get the gates open, I saw a really strong zombie with prison jumpsuit on, it killed a dude and his dead body is still there!"};
		{Tag="thePrisoner_stillThere"; CheckMission=missionId; Dialogue="I can help you get back to your safehouse.";
			Face="Confident"; Reply="Okay, I'll show you the way.";
			FailResponses = {
				{Reply="We're not ready. Come back later.."};
			};
		};

	};
end

if RunService:IsServer() then
	-- !outline: Robert Handler
	Dialogues.Robert.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 2 then -- Available;
			dialog:AddChoice("thePrisoner_areYouAlright", function(dialog)
				dialog:AddChoice("thePrisoner_howLong", function(dialog)
					dialog:AddChoice("thePrisoner_otherSafehouse", function(dialog)
						dialog:AddChoice("thePrisoner_dangerous", function(dialog)
							dialog:AddChoice("thePrisoner_stillThere", function(dialog)
								modMission:StartMission(player, missionId);
							end)
						end)
					end)
				end)
			end);
			
			
		elseif mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 1 then
				dialog:SetInitiate("Follow me...");
				
			elseif mission.ProgressionPoint == 2 then
				dialog:SetInitiate("Lets go in and put it out of it's misery!");
				
			end
			
		elseif mission.Type == 4 then -- Failed
			
		end
	end

end


return Dialogues;
