local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Hey hey";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	--== Lvl0
	["shelter_new"]={
		Face="Confident"; 
		Reply="Is this place a palace or what.";
	};
	
	--== Lvl1 
	["shelter_lvl1_init"]={
		Face="Skeptical"; 
		Reply="First thing's first, I'll need some materials to set up shop..";
	};
	
	["shelter_lvl1_choice1"]={
		Face="Suspicious"; 
		Say="What do you need for the shop?";
		Reply="Get me 200 metal scraps, that should do for now."
	};
	["shelter_lvl1_a"]={
		Face="Joyful"; 
		Say="Here you go. *give metal scraps*.";
		Reply="Thanks, I'll get to work.."
	};
	["shelter_lvl1_b"]={
		Face="Welp"; 
		Say="I'll go get some metal scraps.";
		Reply="Alright."
	};
	
	
	--== Lvl2
	["shelter_lvl2_init"]={
		Face="Yeesh"; 
		Reply="*building* ...";
	};
	["shelter_lvl2_choice1"]={
		Face="Oops"; 
		Say="How's it going?";
		Reply="Er.. So far so good..";
	};
	
	
	--== Lvl3
	["shelter_lvl3_init"]={
		Face="Oops"; 
		Reply="$PlayerName, looks like I need some more stuff.";
	};
	["shelter_lvl3_choice1"]={
		Face="Surprise"; 
		Say="What do you need?";
		Reply="Hmmm, I'll need 60 wooden parts.";
	};
	["shelter_lvl3_choice1_a"]={
		Face="Welp"; 
		Say="Here you go. *give wood*.";
		Reply="Great, thanks!";
	};
	["shelter_lvl3_choice2"]={
		Face="Happy"; 
		Say="Hey, soo why do you work for R.A.T.?";
		Reply="I was a colleague of the leader of R.A.T. before everything gone down the drain. He recruited us as soon as the apocalypse started annnd I was like 'Apes together strong.' so I joined.";
	};
	
	
	--== Lvl4
	["shelter_lvl4_init"]={
		Face="Happy"; 
		Reply="$PlayerName, it's done.. One last thing, where can I get some food around here. I'm starving from building..";
	};
	["shelter_lvl4_choice1"]={
		Face="Smirk"; 
		Say="There's a freezer where we keep our food. One person can take one per day.";
		Reply="Oh, good. It's actual food right? Not the dried insects some have to resort to eating..";
	};
	
	["shelter_lvl4_choice2"]={
		Face="Serious"; 
		Say="What were you before the apocalypse?";
		Reply="Err, I worked for a hedge fund company..";
	};
	
	--== Shop
	["shelter_shop"]={
		Face="Smirk"; 
		Say="What do you have for sale?";
		Reply="I got everything here in my trench coat.. Just kidding, I'll have to contact R.A.T.";
	};
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local survivorDialogueHandler = require(script.Parent.Parent.Survivor);
		survivorDialogueHandler(player, dialog, data);
	end 
end

return Dialogues;