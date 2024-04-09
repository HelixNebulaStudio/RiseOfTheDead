local NpcDialogues = {};
--==

NpcDialogues.Initial = {
	"Hmmmmmm.";
	"What chu want?";
	"What chu looking at?";
};

NpcDialogues.Dialogues = {
	-- VindictiveTreasure1
	{MissionId=40; Tag="vt1_init"; Face="Skeptical"; Dialogue="Ummm, what is it?"; 
		Reply="There is a pathway under the park's statue, a pathway to some kind of tombs."};
	{MissionId=40; Tag="vt1_beast"; Face="Confident"; Dialogue="What's in the tombs?"; 
		Reply="I am not sure. There are rumors about some kind of treasure but the beast is in the way. Could you clear the path to the tombs?"};
	{MissionId=40; Tag="vt1_sure"; CheckMission=40; Face="Happy"; Dialogue="Sure."; 
		Reply="Thats rad dude, let me know if you find anything."};
	
	{Tag="vt1_tombs"; Face="Suspicious"; Dialogue="I'll be heading down to the tombs again."; 
		Reply="Alright."};
	
	{MissionId=40; Tag="vt1_find"; Face="Happy"; Dialogue="The tombs was overran with zombies. I found this mask in the tombs though."; 
		Reply="Wow, I'm impressed. Thanks for the mask, I will be inspecting it."};
	{MissionId=40; Tag="vt1_notfind"; Face="Suspicious"; Dialogue="The tombs was overran with zombies, and I didn't find anything special there."; 
		Reply="Hmmm, thats odd.. Anyways thanks for clearing the path there."};
	
	
	
	{MissionId=41; Tag="vt2_cultist"; Face="Suspicious"; Dialogue="A group of cultists are hunting me, and one of them dropped this note."; 
		Reply="Oh yeah, I forgot to tell you, the tombs were apart of their lair. "};
	{MissionId=41; Tag="vt2_cultist2"; Face="Grumpy"; Dialogue="Why do they call you The Venator?"; 
		Reply="Dude, that doesn't matter. What matters is getting rid of the cultist. What else does the note say?"};
	{MissionId=41; Tag="vt2_cultist3"; Face="Suspicious"; Dialogue="Umm, \"retrieve the mask immediately before they unleash hellfire upon everyone\".. What do they mean by that?"; 
		Reply="Err, umm, yeah.. *Looks away* I don't know either.. Like I said, what matters is getting rid of these cultists."};
	
	{MissionId=41; Tag="vt2_outfit"; Face="Skeptical"; Dialogue="What should I do?"; 
		Reply="Disguise yourself with. They don't know each other so that'll make them question whether you are one of them."};
	
	
	
	{MissionId=42; Tag="vt3_check"; CheckMission=42; Face="Happy"; Dialogue="Sure?"; 
		Reply="Cool, just let me know when you're ready to travel."};
	{MissionId=42; Tag="vt3_vttravel"; Face="Confident"; Dialogue="I'm ready to go to the tombs."; 
		Reply="Alright, let's go.";
		ReplyFunction=function(dialogPacket)
			local npcModel = dialogPacket.Prefab;
			local LowerTorso = npcModel.LowerTorso;
			if LowerTorso:FindFirstChild("Interactable") then
				local localPlayer = game.Players.LocalPlayer;
				local modData = require(localPlayer:WaitForChild("DataModule"));

				modData.InteractRequest(LowerTorso.Interactable, LowerTorso);
			end
		end
	};
	{MissionId=42; Tag="vt3_follow"; Face="Skeptical"; Dialogue="Sure?"; 
		Reply="Cool, just let me know when you're ready to travel."};
	
	{MissionId=42; Tag="vt3_bargain"; Face="Grumpy"; Dialogue="No! You tried to kill me and now you are going to rot here."; 
		Reply="Uggh. Fine. I'm sorry, if you get me out of here, you will never see me again."};
	{MissionId=42; Tag="vt3_depress"; Face="Worried"; Dialogue="I won't be making any deals with you.."; 
		Reply="Well then, this is it huh.. "};
	
	{MissionId=42; Tag="vt3_save"; Face="Tired"; Dialogue="*Save Victor*"; 
		Reply="..."};
	{MissionId=42; Tag="vt3_dontsave"; Face="Tired"; Dialogue="*Kill Victor*"; 
		Reply="..."};
	
};

return NpcDialogues;