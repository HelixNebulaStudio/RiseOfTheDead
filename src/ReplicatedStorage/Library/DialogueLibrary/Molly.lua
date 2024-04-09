local NpcDialogues = {};

NpcDialogues.Initial = {
	"This is sooo not cool.";
	"You got to be kidding me, where's the government?!";
	"Ugh, I just want to go home, this better be over soon.";
};

NpcDialogues.Dialogues = {
	{Tag="heal_request"; Dialogue="Can you heal me please?"; Reply="Sure~ Like I got anything better to do in this situation..."};
	
	-- Escort
	{MissionId=34; Tag="escort_init"; Dialogue="Sure, how can I help?"; 
		Reply="So.. This person wants to get somewhere, could you escort the person there?"};
	{MissionId=34; Tag="escort_alright"; Dialogue="Sure, hope it's not far.."; 
		Reply="Mhm.. Alright, get going.."};
		
	{MissionId=34; Tag="escort_heal"; Dialogue="Could you heal the person?"; 
		Reply="Ugh, how hard is it just to escort someone to some place. Here, healed."};
	
	{MissionId=34; Tag="escort_retry"; Dialogue="Sorry, I should be more focused. Can we try again?"; 
		Reply="Alright, be careful this time!"};
	
	{MissionId=34; Tag="escort_complete"; Dialogue="It's done, we've safely arrived to the destination."; 
		Reply="Hmmm.. Good job I guess, come back next time for another one."};
	
	-- The Investigation
	{MissionId=52; Tag="investigation_convince"; Face="Question"; Dialogue="Can you help my friend?! An infector ripped out his arm!!";
		Reply="Afraid not sir.. Why can't just help everyone that comes in here.."};
	{MissionId=52; Tag="investigation_convince2"; Face="Welp"; Dialogue="What?! Why not?!";
		Reply="Look, you guys aren't the first to come here for help. Many came here for help and still didn't make it, we don't have a choice. Supplies are limited."};
	{MissionId=52; Tag="investigation_convince3"; Face="Suspicious"; Dialogue="What resources do you need? Maybe I can get you some..";
		Reply="I'll need advance med kits. You better make it quick if you want to help your friend here cause I'm not starting until I get the resource I need.."};
	{MissionId=52; Tag="investigation_medkit"; Face="Surprise"; Dialogue="*Give Advance Medkit*";
		Reply="I'm surprise you actually got it. Alright, I'll patch him up."};
	
	{MissionId=52; Tag="investigation_needAdvmedkit"; Face="Welp"; Dialogue="I don't have an advance medkit.";
		Reply="Then you should look for some.."};

	
};

return NpcDialogues;