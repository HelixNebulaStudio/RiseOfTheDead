local NpcDialogues = {};

NpcDialogues.Initial = {
	"I have never felt so alive...";
	"Ah, music to my ears..";
};

NpcDialogues.Dialogues = {
	-- HorrorShow
	{MissionId=43; Tag="missingbody_init"; CheckMission=43;
		Dialogue="Hey.. You look really pale. Are you alright?";
		Reply="You.. Help me.. I am finding something.. Head in, you will find it.."};
	
	{MissionId=43; Tag="missingbody_voodoo";
		Dialogue="What happened to the place!? Something's wrong with the place and I didn't find anything.."; 
		Reply="Oh no, it was there.. Here take this.."};

	{MissionId=43; Tag="missingbody_takevoodoo";
		Dialogue="*Take Voodoo Doll*"; 
		Reply="This doll will guide you to where you need to go.."};
	
	{MissionId=43; Tag="missingbody_invfull";
		Dialogue="*Take Voodoo Doll*"; 
		Reply="Your inventory is full."};
};

return NpcDialogues;