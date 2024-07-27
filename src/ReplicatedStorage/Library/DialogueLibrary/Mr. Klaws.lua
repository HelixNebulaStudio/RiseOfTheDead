local NpcDialogues = {};

NpcDialogues.Initial = {
	"Ho ho he~";
	"Merry Christmas fellow person..";
	"Eyy, it's a holiday.";
	"Feeling the Christmas spirit?";
	"Got any coal? I'll trade ya for it.";
};

NpcDialogues.Dialogues = {
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