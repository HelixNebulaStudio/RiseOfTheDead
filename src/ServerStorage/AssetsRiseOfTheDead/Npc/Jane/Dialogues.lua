local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="I want to see my friends again..";
	};
	["init2"]={
		Reply="We can't survive like this for long..";
	};
	["init3"]={
		Reply="Where are the national guards?!";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["thanks_noproblem"]={
		Say="You're welcome, I'm just trying to save as much people as possible.";
		Reply="Is it true that there's another safehouse with other survivors?";
	};
	["thanks_othersafehouse"]={
		Say="Yes, there are other survivors in the warehouse opposite of the Bloxmart entrance.";
		Reply="Oh, it's great to hear that we aren't the only survivors.";
	};
	["thanks_dontmindstaying"]={
		Say="Is it okay if I stay here for a while?";
		Reply="Sure, make yourself at home.";
	};

};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		if data:Get("FirstMet") == nil then
			dialog:SetInitiate("Thank you so much for rescuing Robert. We couldn't afford to lose another survivor..");
			dialog:AddChoice("thanks_noproblem", function(dialog)
				dialog:AddChoice("thanks_othersafehouse", function(dialog)
					dialog:AddChoice("thanks_dontmindstaying", function(dialog)
						data:Set("FirstMet", true);
					end)
				end)
			end);
		end
	end 
end

return Dialogues;