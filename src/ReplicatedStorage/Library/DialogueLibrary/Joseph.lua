local NpcDialogues = {};

NpcDialogues.Initial = {
	"These crops can keep us going for years.";
	"Jesus.. I almost forgot to water the crops..";
	"One step closer to becoming self sustainable..";
};

NpcDialogues.Dialogues = {
	{Tag="heal_request"; Dialogue="Can you heal me please?"; Reply="Cmon' closer and I'll patch you up."};
	
	-- Lend a hand
	{MissionId=35; Tag="pledginCloth_start"; CheckMission=35; Dialogue="Sure, how much cloth do you need?"; 
		Reply="I'm making lots of portable sleeping bags, I'll need as much cloth you can provide."};
	
	-- Joseph's lettuce
	{MissionId=37; Tag="josephsLettuce_start"; CheckMission=37; Face="Joyful"; Dialogue="Sure, how do I help make the watering can?"; 
		Reply="Here's a blueprint, after you're done please also water the plants for me."};
	{MissionId=37; Tag="josephsLettuce_end"; Face="Happy"; Dialogue="Yep, I watered them."; 
		Reply="Good job, get some rest. You earned it."};
	
	--The Investigation
	{MissionId=52; Tag="investigation_zombieface"; Face="Surprise"; Dialogue="Robert has been acting strange and I feel like it's bad. He had this zombie look the last time I saw him, but when I went up close to him, he was fine."; 
		Reply="Zombie look? Who else saw it? Could it be just you?"};
	{MissionId=52; Tag="investigation_fast"; Face="Skeptical"; Dialogue="Not sure, that's why I have some questions. How long has Robert been here? He went missing for a couple days and next thing I know, he's here.."; 
		Reply="He's been here for a couple days. He saved one of our members, Nate, from a dire situation when he was caught under some debris after an explosion while scavenging for supplies.. He somehow lifted the heavy debris and got Nate out of there.."};
	{MissionId=52; Tag="investigation_zark"; Face="Question"; Dialogue="I see. I had an encounter with the Bandit leader, Zark. He mentioned something about Infectors.. Do you know anything about them?"; 
		Reply="Hmmm, I've only heard of them, but I know that they are physically stronger and can disguise as a normal person. There are rumors about infectors lurking around in the train stations.."};
	{MissionId=52; Tag="investigation_keepEye"; CheckMission=52; Face="Question"; Dialogue="Hmmm, I'm going to talk to the others to get more information.";
		Reply="Alright, I'll try to keep an eye on Robert while you do that."};
	
	
	{MissionId=52; Tag="investigation_patchJoseph"; Face="Frustrated"; Dialogue="*Wrap strap around arm to stop bleeding*";
		Reply="Ugh... Alright, this will stop the bleeding.."};
	{MissionId=52; Tag="investigation_complete"; Face="Serious"; Dialogue="Are you sure? You should just rest here..";
		Reply="... I rather not. Our people needs us, the community needs us."};
	{MissionId=52; Tag="investigation_complete2"; Face="Serious"; Dialogue="Alright..";
		Reply="Don't worry kid, you did well.. We will be fine, we will continue once I'm well rested."};
	
	{Tag="lostArm_muchBetter"; Face="Confident"; Dialogue="How are you feeling?";
		Reply="Much better now.. Definitely going to miss my left arm.. Going to need a hand later though, hahah.."};
	
	-- End Of The Line
	{Tag="eotl_init"; Face="Happy"; 
		Reply="Welcome back, $PlayerName.";};
	{MissionId=56; Tag="eotl_howsarm"; Face="Skeptical"; Dialogue="How's your arm, Joseph?"; 
		Reply="Thank god it was just my arm, it could have been worse."};
	{MissionId=56; Tag="eotl_patchup"; CheckMission=56; Face="Skeptical"; Dialogue="Good to hear it, what should I do about Robert and the hole he escaped through?"; 
		Reply="Nate patched up the hole a bit, I don't recommend going after him alone.. But it's up to you, I know you can take care of yourself."};
	
	--== Joseph's Crossbow
	{Tag="josephcrossbow_init"; Face="Suspicious"; 
		Reply="If you ever come across a crossbow, please show it to me.";};
	{MissionId=64; Tag="josephcrossbow_try"; Face="Skeptical"; Dialogue="Is this crossbow what you are talking about?"; 
		Reply="Ahh yes.. I had a build for the crossbow, I've written my build somewhere near my workbench a long time ago and forgotten it, try to figure out how it's built."};
	{MissionId=64; Tag="josephcrossbow_failBuild"; Face="Skeptical"; Dialogue="Is this how you built your crossbow?"; 
		Reply="Hmm, not quite, something's off. Look around my workbench to see if you can find any clues.."};
	{MissionId=64; Tag="josephcrossbow_corectBuild"; Face="Skeptical"; Dialogue="Is this how you built your crossbow?"; 
		Reply="Well well well, it is perfeect. Here, use this to give it a final touch."};

};



return NpcDialogues;