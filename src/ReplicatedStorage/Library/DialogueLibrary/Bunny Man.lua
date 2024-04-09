local NpcDialogues = {};

NpcDialogues.Initial = {
	"Ugggh..";
	"Neeed moore eeeggs..";
};

NpcDialogues.Dialogues = {
	-- Crowd Control
	{MissionId=31; Tag="egghunt_init"; CheckMission=31;
		Dialogue="Who are you?!";
		Reply="I'm the Bunny Man, what do you want..?"};
	{MissionId=31; Tag="egghunt_find";
		Dialogue="What are you doing here?"; 
		Reply="I'm searching for eggs. You know what. Help me find the Easter Eggs.."};
	{MissionId=31; Tag="egghunt_end";
		Dialogue="Here I found some.."; 
		Reply="Good.. good..."};
	{MissionId=31; Tag="egghunt_where";
		Dialogue="Where do I find the Easter Eggs?"; 
		Reply="Hmmm, never thought about that.. Just look around.."};
	{MissionId=31; Tag="egghunt_invfull";
		Dialogue="Here I found some.."; 
		Reply="Your inventory is full."};

	{MissionId=32; Tag="reborn_init"; CheckMission=32;
		Dialogue="Yeah, what do you need me for?"; 
		Reply="You helped me, I will help you back, you need to be reborn. Complete my challenge and you will be reborn.."};
	{MissionId=32; Tag="reborn_what";
		Dialogue="What challenge?"; 
		Reply="Err.. I will bring you there. Let me know if you are ready for the challenge."};
	{MissionId=32; Tag="reborn_alright";
		Dialogue="Umm, alright."; 
		Reply="Err.. Good, good.."};
	
	{MissionId=32; Tag="reborn_travel";
		Dialogue="Bring me to the butchery."; 
		Reply="Follow me.."};
		
	{MissionId=32; Tag="reborn_complete";
		Dialogue="Ummm.."; 
		Reply="Now I can tell you anything you want to know.."};
		 
		
	{MissionId=32; Tag="reborn_home";
		Dialogue="Okay, can you bring me home now?"; 
		Reply="Err.. alright."};
	
	{MissionId=50; Tag="eb2_greet"; CheckMission=50;
		Dialogue="What task do you have for me?"; 
		Reply="The people who caused this apocalypse, is no single person. The groups that are responsible.. are powerful people. But not powerful enough to contain what they have created."};
	{MissionId=50; Tag="eb2_greet2";
		Dialogue="Hmm"; 
		Reply="Scattered to pieces by their own creation, they now struggle.. fight.. and hunt to survive. They almost killed me, left me to die out in the woods."};
	{MissionId=50; Tag="eb2_greet3";
		Dialogue="I see"; 
		Reply="They should have made sure they finished what they started, because I will get back at them."};
	{MissionId=50; Tag="eb2_greet4";
		Dialogue="..."; 
		Reply="As we have been reborn, we have nothing to fear. We shall make contact with the cultist. They have something I need."};
	{MissionId=50; Tag="eb2_start";
		Dialogue="Alright"; 
		Reply="We will commence when you are ready."};
	
	{MissionId=50; Tag="eb2_letsgo";
		Dialogue="I am ready, let's go."; 
		Reply="Follow me.."};
	{MissionId=50; Tag="eb2_lead";
		Dialogue="Okay."; 
		Reply="Come."};
	{MissionId=50; Tag="eb2_end1";
		Dialogue="I see, who is omega?"; 
		Reply="The one who exiled me."};
	{MissionId=50; Tag="eb2_end2";
		Dialogue="What do we do now?"; 
		Reply="We are done for today, that earlier is going to raise some alarms. We will need to lay low, we will continue this next time."};
	

	{Tag="reborn_lore1";
		Dialogue="What's with all the Bunny Masks?"; 
		Reply="I was lost, lost in the woods. A bunny accompanied me in my solitude. A loud explosion guided me back to civilization. In the end bunny gave it's life for me to survive."};
	{Tag="reborn_lore2";
		Dialogue="What is this place?"; 
		Reply="This is my home now, with a bunch of zombies accompanying me, I feel.. safe."};
	{Tag="reborn_lore3";
		Dialogue="Why are you searching for those eggs?"; 
		Reply="It guides me, something inside.. which I need."};
	{Tag="reborn_lore4";
		Dialogue="Why do the zombies ignore me when I wear this bunny mask?"; 
		Reply="They are confused, lack of other senses.. Their controller could be weakened during the time.."};
};

return NpcDialogues;