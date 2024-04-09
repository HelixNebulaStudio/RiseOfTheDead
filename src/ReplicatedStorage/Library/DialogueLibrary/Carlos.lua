local NpcDialogues = {};

NpcDialogues.Initial = {
	"Want to hear me play the flute?";
	"I really like to play the flute, want to hear?";
	"I can play the flute if you want.";
	"The noise from that vent up there is really distracting...";
};

NpcDialogues.Dialogues = {
	{Tag="heal_request"; Dialogue="Can you heal me please?"; Reply="Let me heal you with the sound of music!"};
	
	-- Sound of Music
	{MissionId=47; Tag="soundOfMusic_get"; Dialogue="Hey, where can I get a flute like yours?";
		Reply="Oh, I'm glad you asked. I want to spread hope with music, I'd gladly give you one of my extra new flute if you can learn to play it."};
	{MissionId=47; Tag="soundOfMusic_sure"; CheckMission=47; Dialogue="Sure, can you teach me?";
		Reply="Of course, give me a second to find it."};
	{MissionId=47; Tag="soundOfMusic_full"; Dialogue="*Waits patiently for the flute*";
		Reply="Your inventory is full."};
	{MissionId=47; Tag="soundOfMusic_take"; Dialogue="*Waits patiently for the flute*";
		Reply="Here you go, try to play these notes to me."};
	{MissionId=47; Tag="soundOfMusic_done"; Dialogue="That was great! Please share your musical knowledge with others too!";
		Reply="Thanks, that was fun."};
	
	
	{MissionId=47; Tag="soundOfMusic_how"; Dialogue="How do I do this again?";
		Reply="Okay, you need to equip the flute, then use it to play these notes. C, C, G, F, D#, D, D, D, F, D#, D, C, C, D#, D, D#, D, D#."};
};

return NpcDialogues;