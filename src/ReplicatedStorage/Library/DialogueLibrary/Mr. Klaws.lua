local NpcDialogues = {};

NpcDialogues.Initial = {
	"Ho ho he~";
	"Merry Christmas fellow person..";
	"Eyy, it's a holiday.";
	"Feeling the Christmas spirit?";
	"Got any coal? I'll trade ya for it.";
};

NpcDialogues.Dialogues = {
	--Christmas Rampage
	{MissionId=25; Tag="xmasramp_yes"; Dialogue="Umm, yes.";
		Reply="Well, I need you to kill some zombies which are wearing santa hats."};
	{MissionId=25; Tag="xmasramp_start"; CheckMission=25; Dialogue="Oh, that sounds easy. I'll do it.";
		Reply="Good luck out there!"};
	{MissionId=25; Tag="xmasramp_done"; Dialogue="Wow, you got it done.";
		Reply="Yeah, am I on the nice list now?"};
	{MissionId=25; Tag="xmasramp_almost"; Dialogue="Oh ho ho, I won't reveal that.";
		Reply="Oh."};
	
	--Warming Up
	{MissionId=46; Tag="warmup_init"; Dialogue="Sure, how do I do that?";
		Reply="You'll need coal. The zombies has been pretty naughty so they might drop some coal when you kill them."};
	{MissionId=46; Tag="warmup_start"; CheckMission=46; Dialogue="I'm on it.";
		Reply="Chip chop!"};
	{MissionId=46; Tag="warmup_done"; Dialogue="I've started the fireplace.";
		Reply="Goodjob, it will keep these surivors warm and cozy."};
	
	--Christmas Rampage
	{MissionId=57; Tag="klawsWorkshop_init"; CheckMission=57; Dialogue="Sure, but where is your workshop?";
		Reply="Here's a map, good luck!"};
	{MissionId=57; Tag="klawsWorkshop_done"; Dialogue="I found it, here you go..";
		Reply="Hah thanks! I am moving your name to the good list."};
	
	--Genral
	{Tag="general_spirit"; Dialogue="Merry Christmas!";
		Reply="Merry Christmas to you too!"};
	
	{Tag="general_trade"; Dialogue="Do you want some coal?";
		Reply="Yes! Give it to me, and I will give you something in return."};

	{Tag="xmas2019"; Dialogue="I got 400 coal.";
		Reply="Ho ho, that's great, here I'll trade you a present for the 400 coal."};
	{Tag="xmas2020"; Dialogue="I got 200 coal.";
		Reply="Ho ho, that's great, here I'll trade you a present for the 200 coal."};
	{Tag="xmas2021"; Dialogue="I got 100 coal.";
		Reply="Ho ho, that's great, here I'll trade you a present for the 100 coal."};
	
	
	{Tag="general_giftSanta"; Dialogue="*Gift Mr. Klaws a Present*";
		Reply="Why thank you! I see you are in the Christmas Spirit, but that's a present from me to you.\n\n*Gift present back to you*"};
	
	
};

return NpcDialogues;