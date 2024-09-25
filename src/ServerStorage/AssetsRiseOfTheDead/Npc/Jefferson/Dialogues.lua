local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="*Ughhh*";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {

};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		local mission10 = modMission:GetMission(player, 10);
		if mission10 then return end;

		dialog:InitDialog{
			Reply="GET BACK! Stay away from me, I am infected.";
			Face="Frustrated";
		}

		dialog:AddDialog({
			CheckMission=10;
			Say="Please let me help you.";
			Reply="I can't be saved, I'm infected. Don't waste your resources on me.";
			Face="Frustrated"; 
			FailResponses = {
				{Reply="I don't think you can help me.."};
			};
		}, function(dialog)
			dialog:AddDialog({
				Say="It's okay, I want to help you.";
				Face="Serious"; 
				Reply="*sigh* If you insist, please get me some antibiotics for this wound from Sunday's convenient store.";
			}, function(dialog)
				modMission:StartMission(player, 10);
			end);
		end);
		
	end 
end

return Dialogues;