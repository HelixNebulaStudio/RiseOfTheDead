local NpcDialogues = {};

NpcDialogues.Initial = {
	"Hey, you're looking well, need help?";
	"Hmm, Yes? Do you need some help?";
	"What a ###### mess... OH hey, what do you need help with?"; --end
	"How may I help you hmm?";
};

NpcDialogues.Dialogues = {	
	-- General
	{Tag="general_what"; Dialogue="What should I do now?"; 
		Reply="Look around and see if anyone needs help."}; --end
	{Tag="general_where"; Dialogue="Where should I go now?"; 
		Reply="I heard there's other safehouses, maybe if you could find them, we could set up a network somehow..."};
	{Tag="general_how"; Dialogue="How's the car?"; 
		Reply="I'm still trying to fix it, but I'm afraid we're missing some components."};
	
	-- Guide
	{Tag="guide_refillAmmo"; Dialogue="How do I buy ammo for my weapons?"; Face="Joyful";
		Reply="Go to the shop and pick your weapon that you want refilled."}; --end
	{Tag="guide_getWeapon"; Dialogue="How do I get new weapons?"; Face="Happy";
		Reply="The shop sells blueprints for building weapons."}; --end
	{Tag="guide_levelUp"; Dialogue="How do I level up?"; Face="Joyful";
		Reply="Kill zombies to level up your weapons and you will level up your mastery level."}; --end
	{Tag="guide_getPerks"; Dialogue="How do I get perks?"; Face="Happy";
		Reply="Complete missions, farm zombies or level up weapons. Every 5 level ups, rewards you 10 perks."}; --end
	{Tag="guide_invSpace"; Dialogue="How to get more space in my inventory?"; Face="Welp";
		Reply="You can't, however every safehouse has a storage and you can store your excess items there."};
	{Tag="guide_makeMoney"; Dialogue="How to earn money?"; Face="Happy";
		Reply="You can get some pocket change by killing zombies. But if you want to earn more, you should sell commodity items. Commodity items are usually crafted from a blueprint obtain from bosses."};
	{Tag="guide_getMaterials"; Dialogue="Where do I find materials I need for building?"; Face="Skeptical";
		Reply="You can use the \"/item [itemName]\" command to know where to obtain an item from. For example, try typing this in chat /item Boombox"};
	
	
	-- Guide Safehome
	{Tag="guide_safehomeNpcs"; Dialogue="Where do I look for survivors?"; Face="Confident";
	Reply="Some might stumble upon this place, or I could look for some. But first, this place needs to be sustainable.."};
	{Tag="guide_safehomeSustain"; Dialogue="How do I make this place sustainable?"; Face="Confident";
	Reply="Make sure you got food, there should be a freezer somewhere, keep some food there.. As long as you have enough food to feed everyone everyday, you should be good. (1 food per survivor daily)"};
	
};

return NpcDialogues;