local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local NpcDialogues = {};

NpcDialogues.Initial = {
};

NpcDialogues.Dialogues = {
	-- Rats Recruitment
	{MissionId=62; Tag="theRecruit_revasInit"; Face="Confident"; 
		Reply="Ah, just who I was looking for..";};
	
	{MissionId=62; Tag="theRecruit_revas1"; Face="Confident";
		Dialogue="What on earth was that?! You shot patrick!";
		Reply="Indeed, how is he right now? He honored our argreement."};
	{MissionId=62; Tag="theRecruit_revas2"; Face="Confident";
		Dialogue="He did not agree to being shot. He's no longer interested in your offer.";
		Reply="That's ashame despite agreeing to do whatever it takes.\n\nAnyways, I have not had the chance to show my gratitude for helping us."};
	{MissionId=62; Tag="theRecruit_revas3"; Face="Confident";
		Dialogue="By pulling the lever?";
		Reply="Yes, thanks to you, we captured the infector that the Bandits brought in. Come with me when you are ready.."};
	{MissionId=62; Tag="theRecruit_revasTravel"; Face="Confident";
		Dialogue="I'm ready to go.";
		Reply="Fantastic, follow me this way, through the intricate rat underground tunnels."};
	
	{MissionId=62; Tag="theRecruit_secE"; Face="Confident";
		Dialogue="So this is Sector E..";
		Reply="Indeed, it has been repurposed. Since much of the systems are still functional and Eugene was the head of this sector.\n\nNow, follow me.."};

	{MissionId=62; Tag="theRecruit_retrieve1"; Face="Confident";
		Dialogue="Alright, what do you need?";
		Reply="There's only one physical copy of a certain research paper that Eugene needs. He'll also need some Nekron particulate cache. Let's first head to Sector F.."};
	
	{MissionId=62; Tag="theRecruit_cantFind"; Face="Suspicious";
		Dialogue="I can't seem to find it..";
		Reply="It should be in one of the labs, check the top of the counters.."};
	{MissionId=62; Tag="theRecruit_found"; Face="Confident";
		Dialogue="Here's the papers.";
		Reply="Excellent, as for the Nekron particulate cache, I trust that you can manage that yourself. Good luck."};
	
	
	
};

return NpcDialogues;