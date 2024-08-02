local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Survival of the fittest.. I think I'm pretty fit for this economy..";
	};
	["init2"]={
		Reply="Arrr, like clockworks..";
	};
	["init3"]={
		Reply="Supply and demand, that's me in the flesh.";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["trader_new"]={
		Face="Confident"; 
		Reply="Hey, you. I have an offer that is hard to refuse..";
	};
	["trader_tradeDisabled"]={
		Face="Serious"; 
		Say="Let's trade"; 
		Reply="Shop's closed today, come back next time.";
	};
	
	-- The Wandering Trader
	["wanderingtrader_init"]={
		MissionId=58; 
		Face="Skeptical"; 
		Reply="Arr, you don't happen to have any extra canned sardines do ya?";
		};
	
	["wanderingtrader_accept"]={
		MissionId=58; 
		CheckMission=58; 
		Face="Suspicious";
		Say="Oh sure, here's a can.";
		Reply="Yes! My craving is vanquished."
	};
	["wanderingtrader_decline"]={MissionId=58; 
		Face="Ugh"; 
		Say="I don't think I have any canned sardines on me at the moment..";
		Reply="Hmm, very well.."
	};
	
	
	--== Lvl0
	["trader_lvl0_init"]={
		Face="Skeptical"; 
		Reply="Arr, you don't happen to have any extra canned sardines do ya?";
		};
	
	["trader_lvl0_accept"]={
		Face="Suspicious"; 
		Say="Oh sure, here's a can.";
		Reply="Yes! My craving is vanquished."
	};
	["trader_lvl0_decline"]={
		Face="Ugh"; 
		Say="I don't think I have any canned sardines on me at the moment..";
		Reply="Hmm, very well..";
	};
	
	--== Lvl1
	["trader_lvl1_init"]={
		Face="Happy"; 
		Reply="Thanks again for the can of sardines. Is there anything you need, maybe I can return the favor.";
	};
	
	["trader_lvl1_choice1"]={
		Face="Suspicious"; 
		Say="I'm not sure, what do you have?";
		Reply="Arr, have a look at my backpack.";
	};
	
	["trader_lvl1_a"]={
		Face="Suspicious"; 
		Say="*Pick Suspicious Key*";
		Reply="Arr, yes. I found this while scavenging, I can't actually give this to you for free. Hahah.";
	};
	["trader_lvl1_b"]={
		Face="Suspicious"; 
		Say="*Pick Gold*";
		Reply="Oh, ummm. That's mine, no touchy.";
	};
	["trader_lvl1_c"]={
		Face="Suspicious"; 
		Say="*Pick Explosives*";
		Reply="Oh yes, please take that off me. I shouldn't be carrying that around..";
	};
	
	
	--== Lvl2
	["trader_lvl2_init"]={
		Face="Happy"; 
		Reply="Speaking of which, do you carry any gold around?";
	};
	
	["trader_lvl2_a"]={
		Face="Smirk"; 
		Say="Nope, I don't have any gold.";
		Reply="Arrr, it's alright lad. Maybe I could give you gold for something in exchange later..";
	};
	["trader_lvl2_b"]={
		Face="Joyful"; 
		Say="Yes, I have gold.";
		Reply="Great! I might have something you want to exchange for.";
	};
	
	
	--== Lvl3
	["trader_buy"]={
		Face="Smirk"; 
		Say="What can I buy from you today?";
		Reply="Take a look.";
	};
	["trader_sell"]={
		Face="Skeptical"; 
		Say="What can I sell to you?";
		Reply="I am willing to exchange some gold for..";
	};
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local wanderingTraderDialogueHandler = require(script.Parent.Parent.WanderingTrader);
		wanderingTraderDialogueHandler(player, dialog, data);
		
	end 
end

return Dialogues;