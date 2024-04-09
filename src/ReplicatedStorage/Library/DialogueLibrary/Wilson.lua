local NpcDialogues = {};

NpcDialogues.Initial = {
	"Derrick, any signs of him? Over...";
	"Derrick, do you copy? Over...";
};

NpcDialogues.Dialogues = {
	-- Crowd Control
	{MissionId=13; Tag="crowdcontrol_what"; Dialogue="What do you need help with?"; Reply="I have intel that the population of the zombies is growing rapidly.. I've heard you are very capable of taking out large amount of zombies."};
	{MissionId=13; Tag="crowdcontrol_yeah"; CheckMission=13; Dialogue="Yeah, I can."; Reply="Great! This will really help me out in finding my partner. Kill about a hundred zombies will do."};
	{MissionId=13; Tag="crowdcontrol_stillWorking"; Dialogue="Still working on it.."; Reply="Alright, keep at it."};
	{MissionId=13; Tag="crowdcontrol_return"; Dialogue="I think I killed about a hundred zombies..."; Reply="That'll be good for now, thanks for your help."};
	
	-- tickhunting
	{MissionId=19; Tag="tickhunting_sure"; Dialogue="Sure."; Reply="This annonying type of zombies keeps ticking, they run at you and tries to blow you up. I need you to get rid of them."};
	{MissionId=19; Tag="tickhunting_yeah"; CheckMission=19; Dialogue="I'm on it."; Reply="Off you go solider, get back here as soon as you are done."};
	{MissionId=19; Tag="tickhunting_stillWorking"; Dialogue="Hard at work sir.."; Reply="Alright, keep going."};
	{MissionId=19; Tag="tickhunting_return"; Dialogue="I got rid of as much as I could."; Reply="You did great solider."};
	
	-- Quarantine Assessment
	{MissionId=51; Tag="qa1_hq"; Face="Confident"; Dialogue="Sure, what's happening?"; 
		Reply="I have recieved a radio broadcast that the military is going to dispatch in a small team of inspectors into our quarantine zone for an assessment.."};
	{MissionId=51; Tag="qa1_no"; Face="Grumpy"; Dialogue="Wow, are we going to be saved?!"; 
		Reply="Unlikely. Under protocals, survivors are the least of their worries in our current situation.."};
	{MissionId=51; Tag="qa1_sample"; Face="Suspicious"; Dialogue="Oh no, then what are they going?"; 
		Reply="They are probably here to inspect the severity of the situation and perhaps retrieve some zombie samples for research."};
	{MissionId=51; Tag="qa1_contact"; Face="Serious"; Dialogue="I see."; 
		Reply="We need to make contact. If we can prove ourselves useful, they will protect us. We can give them information in exchange for their help."};
	{MissionId=51; Tag="qa1_radio"; CheckMission=51; Face="Confident"; Dialogue="Okay, I'm on it."; 
		Reply="We need a stronger radio to try to broadcast our message to them.. Look for any military grade radio to try to make contact and tell them Wilson from squad B is still alive."};
	
	{MissionId=51; Tag="qa1_notyet"; Face="Serious"; Dialogue="Not yet."; 
		Reply="Hurry, I don't know when they will be dispatched into our quarantine zone.."};

	{MissionId=51; Tag="qa1_done"; Face="Confident"; Dialogue="Yep, I've made contact from the Radio Station."; 
		Reply="Ok good, what did they say?"};
	{MissionId=51; Tag="qa1_done2"; Face="Surprise"; Dialogue="They say they will be dispatching the inspection team here."; 
		Reply="Here? Hmmm, that's strange. That's unlike protocol for them to directly come to us. This might not be what we think it is.."};
	{MissionId=51; Tag="qa1_done3"; Face="Surprise"; Dialogue="Oh, what do you mean?"; 
		Reply="Nevermind, I am just going to be optimistic for now and hope they get here quick."};
	
};

return NpcDialogues;