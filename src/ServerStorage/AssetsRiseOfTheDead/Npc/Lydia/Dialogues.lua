local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Speak.";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	--== Lvl0
	["shelter_new"]={
		Face="Smirk"; 
		Reply="Yes... yes.. I can work with this..";
	};
	
	--== Lvl1 
	["shelter_lvl1_init"]={
		Face="Skeptical"; 
		Reply="As promised, I will tell you your fortune. However, I will need to channel my energy..";
	};
	
	["shelter_lvl1_choice1"]={
		Face="Suspicious"; 
		Say="Do you need any help?";
		Reply="Hmmm, help would be good. Bring me a can of bloxy cola..";
	};
	["shelter_lvl1_a"]={
		Face="Joyful"; 
		Say="Here you go. *give bloxy cola*.";
		Reply="Good, this will have to be boiled..";
	};
	["shelter_lvl1_b"]={
		Face="Ugh"; 
		Say="Let me go get a can of bloxy cola.";
		Reply="Very well..";
	};
	
	
	--== Lvl2
	["shelter_lvl2_init"]={
		Face="Yeesh"; 
		Reply="*boiling bloxy cola*";
	};
	["shelter_lvl2_choice1"]={
		Face="Serious"; 
		Say="How's it going?";
		Reply="This is a delicate process.. Now.. shoo.";
	};
	
	
	--== Lvl3
	["shelter_lvl3_init"]={
		Face="Welp"; 
		Reply="Hmmm, something's missing..";
	};
	
	["shelter_lvl3_choice1"]={
		Face="Surprise"; 
		Say="What do you need?";
		Reply="I think I'll need another ingredient.. A purple lemon..";
	};
	["shelter_lvl3_choice1_a"]={
		Face="Welp"; 
		Say="Here you go. *give purple lemon*.";
		Reply="Good, good..";
	};
	["shelter_lvl3_choice1_b"]={
		Face="Question"; 
		Say="Where do I find purple lemons?";
		Reply="Hmm, all over Wrighton Dale.. They fermented lemons in a special liquid..";
	};
	
	["shelter_lvl3_choice2"]={
		Face="Serious"; 
		Say="Hey, soo are you a witch or something?";
		Reply="I am a fortune teller, I can foresee glimpse of the future and patterns in your past..";
	};
	
	
	--== Lvl4
	["shelter_lvl4_init"]={
		Face="Skeptical"; 
		Reply="$PlayerName, I do not sense your past.. As if it has been erased from your memory.. Quite peculiar..";
	};
	["shelter_lvl4_choice1"]={
		Face="Suspicious"; 
		Say="Yeah.. I woke up from a crash trying to get away from here. Lost my memories of anything before that..";
		Reply="Hmmmm, fasinating..";
	};
	
	["shelter_lvl4_choice2"]={
		Face="Serious"; 
		Say="How did you become a fortune teller?";
		Reply="Ever since the apocalypse began, my foresight guided me.. Though it may be vague, I believe it holds true in the end.";
	};
	
	--== Shop
	["shelter_fortunetell"]={
		Face="Confident"; 
		AskMe=true;
		Reply="Ask me anything and I will tell you your fortune..";
	};
	
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local survivorDialogueHandler = require(script.Parent.Parent.Survivor);
		survivorDialogueHandler(player, dialog, data);
	end

	Dialogues.PromptHandler = function(player, dialog, data, userPrompt)
		local npcName = dialog.Name;
		local profile = shared.modProfile:Get(player);
		local safehomeData = profile.Safehome;
		
		local npcData = safehomeData:GetNpc(npcName);
		if npcData == nil then return end

		local npcLevel = npcData.Level or 0;
		if npcLevel < 5 then 
			dialog:SetInitiate("Your question will be answered when I have my magic crystal set up.");
			return 
		end;

		local questionKeywords = {"what"; "when"; "will"; "is"; "are"; "who"; "where"; "should"};
				
		local isQuestion = false;
		for a=1, #questionKeywords do
			if userPrompt:lower():match(questionKeywords[a]) then
				isQuestion = true;
				break;
			end
		end

		if isQuestion then
			local randomResponse = {
				"It is certain.";
				"It is decidedly so.";
				"Without a doubt.";
				"Yes, definitely.";
				"You may rely on it.";
				"As I see it, yes.";
				"Most likely.";
				"Outlook good.";
			}
			dialog:SetInitiate(randomResponse[math.random(1, #randomResponse)]);
		end
	end

end

return Dialogues;