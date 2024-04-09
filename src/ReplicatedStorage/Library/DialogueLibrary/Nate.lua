local NpcDialogues = {};

NpcDialogues.Initial = {
	"Hmmm.";
	"You good?";
	"Ummm. What?";
};

NpcDialogues.Dialogues = {
	--The Investigation
	{MissionId=52; Tag="investigation_robert"; Face="Serious"; Dialogue="Hey, have you noticed anything suspicious with Robert? Joseph and I suspect that he might be an infector..";
		Reply="Now that you mention it, after the explosion from my scavenge, I was trapped and my vision was blurry. I didn't believe it at the time, but he had this zombie look on his face."};
	{MissionId=52; Tag="investigation_face"; Face="Angry"; Dialogue="So I wasn't the only one who saw it.. We need to do something..";
		Reply="We made a cell in the basement of one of the buildings in case of event like these. I'll set it up, I need you to lure him there."};
	{MissionId=52; Tag="investigation_wakeUp"; Face="Skeptical"; Dialogue="Nate, wake up. Wake up!";
		Reply="Ahhh. My heaad.. It hurts.."};
	{MissionId=52; Tag="investigation_wHappen"; Face="Skeptical"; Dialogue="Robert knocked you out, then the bandits came. They took Robert's severed hand and left.";
		Reply="OH MY GOD, Joseph! Bring him to the hospital now!"};
	
};

return NpcDialogues;