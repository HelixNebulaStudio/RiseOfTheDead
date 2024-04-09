local NpcDialogues = {};

NpcDialogues.Initial = {};

NpcDialogues.Dialogues = {
	{Tag="sunkenShip_stumbled"; Face="Question";
		Dialogue="Oh I'm sorry.. I was told to search for something in the seabed but I stumbled on to this place..";
		Reply="Wait wait wait, how did you get pass that gigantic worm outside?"};
	{Tag="sunkenShip_itleft"; Face="Surprise";
		Dialogue="I shot at it a couple of times and it left..";
		Reply="Oh no... It will be back after a while, and it might destroy everything.."};
	{Tag="sunkenShip_getout"; Face="Skeptical";
		Dialogue="We should get out of here then..";
		Reply="This is my home, I'm not leaving this place for the surface above that is overruned by zombies and bandits."};
	{Tag="sunkenShip_death"; Face="Skeptical";
		Dialogue="But what about the Elder Vexeron?";
		Reply="Hmmm, I think I can put the worm back to sleep. It wasn't suppose to wake up that easily, I don't think shooting it a couple times was the real reason it woke up."};
	{Tag="sunkenShip_why"; Face="Welp";
		Dialogue="How are you going to put it back to sleep?";
		Reply="I need your help. A few months ago, an explosion from the North shook the ship and parts of it collapsed and flooded some sections."};
	{Tag="sunkenShip_whattodo"; Face="Welp";
		Dialogue="So what do you need me to do?";
		Reply="I need you to salvage as many tubes of Nekron Particulates as you can. I'll reward you handsomely for them."};
	
	
	{Tag="sunkenShip_give"; Face="Bored";
		Dialogue="I managed to salvage some tubes.. *give 4 tubes*";
		Reply="Alright, thanks. Here's something for the trouble."};
	{Tag="sunkenShip_need"; Face="Bored";
		Dialogue="What am I looking for?";
		Reply="Look for tubes of nekron particulates, I'll give you something for every 4 tubes you find."};
	
};

return NpcDialogues;