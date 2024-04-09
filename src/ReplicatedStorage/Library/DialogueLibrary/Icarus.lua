local NpcDialogues = {};

NpcDialogues.Initial = {
	"Survival of the fittest.. I think I'm pretty fit for this economy..";
	"Arrr, like clockworks..";
	"Supply and demand, that's me in the flesh.";
};

NpcDialogues.Dialogues = {
	{Tag="trader_new"; Face="Confident"; Reply="Hey, you. I have an offer that is hard to refuse..";};
	{Tag="trader_tradeDisabled"; Face="Serious"; Dialogue="Let's trade"; Reply="Shop's closed today, come back next time.";};
	
	-- The Wandering Trader
	{MissionId=58; Tag="wanderingtrader_init"; Face="Skeptical"; Reply="Arr, you don't happen to have any extra canned sardines do ya?";};
	
	{MissionId=58; Tag="wanderingtrader_accept"; CheckMission=58; Face="Suspicious"; Dialogue="Oh sure, here's a can.";
		Reply="Yes! My craving is vanquished."};
	{MissionId=58; Tag="wanderingtrader_decline"; Face="Ugh"; Dialogue="I don't think I have any canned sardines on me at the moment..";
		Reply="Hmm, very well.."};
	
	
	--== Lvl0
	{Tag="trader_lvl0_init"; Face="Skeptical"; 
		Reply="Arr, you don't happen to have any extra canned sardines do ya?";};
	
	{Tag="trader_lvl0_accept"; Face="Suspicious"; Dialogue="Oh sure, here's a can.";
		Reply="Yes! My craving is vanquished."};
	{Tag="trader_lvl0_decline"; Face="Ugh"; Dialogue="I don't think I have any canned sardines on me at the moment..";
		Reply="Hmm, very well.."};
	
	--== Lvl1
	{Tag="trader_lvl1_init"; Face="Happy"; 
		Reply="Thanks again for the can of sardines. Is there anything you need, maybe I can return the favor.";};
	
	{Tag="trader_lvl1_choice1"; Face="Suspicious"; Dialogue="I'm not sure, what do you have?";
		Reply="Arr, have a look at my backpack."};
	
	{Tag="trader_lvl1_a"; Face="Suspicious"; Dialogue="*Pick Suspicious Key*";
		Reply="Arr, yes. I found this while scavenging, I can't actually give this to you for free. Hahah."};
	{Tag="trader_lvl1_b"; Face="Suspicious"; Dialogue="*Pick Gold*";
		Reply="Oh, ummm. That's mine, no touchy."};
	{Tag="trader_lvl1_c"; Face="Suspicious"; Dialogue="*Pick Explosives*";
		Reply="Oh yes, please take that off me. I shouldn't be carrying that around.."};
	
	
	--== Lvl2
	{Tag="trader_lvl2_init"; Face="Happy"; 
		Reply="Speaking of which, do you carry any gold around?";};
	
	{Tag="trader_lvl2_a"; Face="Smirk"; Dialogue="Nope, I don't have any gold.";
		Reply="Arrr, it's alright lad. Maybe I could give you gold for something in exchange later.."};
	{Tag="trader_lvl2_b"; Face="Joyful"; Dialogue="Yes, I have gold.";
		Reply="Great! I might have something you want to exchange for."};
	
	
	--== Lvl3
	{Tag="trader_buy"; Face="Smirk"; Dialogue="What can I buy from you today?";
		Reply="Take a look."};
	{Tag="trader_sell"; Face="Skeptical"; Dialogue="What can I sell to you?";
		Reply="I am willing to exchange some gold for.."};
	
};

return NpcDialogues;