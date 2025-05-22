local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="What's up?";
	};
	["init2"]={
		Reply="Look who we have here..";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	--== Lvl0
	["shelter_new"]={
		Face="Confident"; 
		Reply="Now.. Where's the toilet?";
	};
	
	--== Lvl1 
	["shelter_lvl1_init"]={
		Face="Skeptical"; 
		Reply="Alright, first, I'll need some materials.";
	};
	
	["shelter_lvl1_choice1"]={
		Face="Suspicious"; 
		Say="Okay, what do you need?";
		Reply="Get me 3 gears, that should do for now.";
	};
	["shelter_lvl1_a"]={
		Face="Joyful"; 
		Say="Here you go. *give gears*.";
		Reply="Nice.. I hope I'm not grinding your gears. Hahah";
	};
	["shelter_lvl1_b"]={
		Face="Welp"; 
		Say="I'll go get some gears.";
		Reply="Chop chop.";
	};
	
	
	--== Lvl2
	["shelter_lvl2_init"]={
		Face="Yeesh"; 
		Reply="*tinkering* ...";
	};
	["shelter_lvl2_choice1"]={
		Face="Question"; 
		Say="How's it going?";
		Reply="Very scrappy..";
	};
	
	
	--== Lvl3
	["shelter_lvl3_init"]={
		Face="Welp"; 
		Reply="$PlayerName, I'm just missing a few stuff.";
	};
	["shelter_lvl3_choice1"]={
		Face="Surprise"; 
		Say="What do you need?";
		Reply="Hmmm, I'll need about 4 Steel Fragments.";
	};
	["shelter_lvl3_choice1_a"]={
		Face="Welp"; 
		Say="Here you go. *give steel*.";
		Reply="Ah, the finest steel!";
	};
	["shelter_lvl3_choice2"]={
		Face="Happy"; 
		Say="Hey, soo what do you do again?";
		Reply="If you give me enough junk, I can give you something useful. Just make sure the item is recyclable.";
	};
	
	
	--== Lvl4
	["shelter_lvl4_init"]={
		Face="Happy"; 
		Reply="$PlayerName, thanks for letting me settle here. *stomach growls*";
	};
	["shelter_lvl4_choice1"]={
		Face="Smirk"; 
		Say="I heard that, there's a freezer where we keep our food. One person can take one per day.";
		Reply="Oh yeah, thanks!";
	};
	
	["shelter_lvl4_choice2"]={
		Face="Serious"; 
		Say="How did you survive the apocalypse?";
		Reply="Just me being a handy man got me quite far.";
	};
	
	--== Recycle
	["shelter_recycle"]={
		Face="Smirk"; 
		Say="I want to recycle some stuff.";
		Reply="Let's see what you got.";
	};
	
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local survivorDialogueHandler = shared.require(script.Parent.Parent.Survivor);
		survivorDialogueHandler(player, dialog, data);
	end 
end

return Dialogues;