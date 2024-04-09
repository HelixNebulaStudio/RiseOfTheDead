local NpcDialogues = {};

NpcDialogues.Initial = {
	"Yo, need any help?";
	"Whachu doing?";
	"We really need to take back what's ours!";
};

NpcDialogues.Dialogues = {
	{Tag="general_fast"; Dialogue="You run really fast."; Reply="Thanks, survival of the fittest right!"};
	
	-- Poke The Bear;
	{MissionId=30; Tag="pokeTheBear_who"; CheckMission=30; Face="Suspicious";
		Dialogue="Woah, careful with that thing, I'm just another scavenger. My name's $PlayerName."; 
		Reply="*Exhales with relief* Hm, okay. Sooo, whatchu want?"};
	{MissionId=30; Tag="pokeTheBear_help"; Face="Suspicious";
		Dialogue="I need help, I think the bandits kidnapped a friend of mine.";
		Reply="Those bandits.. They attacked my safehouse too. You know what, I'll help you if you help us."};
	{MissionId=30; Tag="pokeTheBear_sure"; Face="Happy";
		Dialogue="Alright, what do you need help with?";
		Reply="We'll pay those bandits a visit."};
		
	{MissionId=30; Tag="pokeTheBear_mall"; Face="Confident";
		Dialogue="I'm ready.";
		Reply="Alright, let's go."};
	
	{MissionId=30; Tag="pokeTheBear_mallInfo"; Face="Grumpy";
		Dialogue="Oh, where's the Bandit Camp?";
		Reply="It's on the top floor, let's go."};
	
	{MissionId=30; Tag="pokeTheBear_wait"; Face="Suspicious";
		Dialogue="He will figure out a way to let us in.. But we'll have to wait.";
		Reply="Fine.. I'll head back, you take care."};
		
	
	--Rats Recruitment;
	{MissionId=62; Tag="ratRecruit_chamber1"; Face="Tired";
		Dialogue="Stan?! Can you hear me..?";
		Reply="Yes.. What's happening?.."};
	{MissionId=62; Tag="ratRecruit_chamber2"; Face="Tired";
		Dialogue="You are a infector..";
		Reply="Yeah, I can feel it fighting inside of me.. Please.. Help me."};
	{MissionId=62; Tag="ratRecruit_chamber3"; Face="Tired";
		Dialogue="But the parasite inside you.. What can I do?";
		Reply="I will control it. Please, they are going to kill me, or at least help me turn down the heat.."};
	
	{MissionId=62; Tag="ratRecruit_chamber4"; Face="Serious";
		Dialogue="Those people are Rats' people, they might be able to help you..";
		Reply="No, don't trust them. They will use you, they just want whatever's inside of me and kill me when they're done.."};
	{MissionId=62; Tag="ratRecruit_chamber5"; Face="Skeptical";
		Dialogue="I'm not sure what I can do..";
		Reply="Alright, listen. You've come this far, just work with them for a while, buy me some time so I can figure out how you can get me out of here.."};
	{MissionId=62; Tag="ratRecruit_chamber6"; Face="Skeptical";
		Dialogue="Sure, I'll do that..";
		Reply="Okay, I hear them coming back, quick, act natural!"};
	
};

return NpcDialogues;