local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local NpcDialogues = {};

NpcDialogues.Initial = {
};

NpcDialogues.Dialogues = {
	-- Bandits Recruitment
	{MissionId=63; Tag="banditRecruit_banditCampGate"; Face="Serious"; 
		Reply="Halt right here! What do you want?";};
	
	{MissionId=63; Tag="banditRecruit_recruit1"; Face="Serious";
		Dialogue="I heard you guys are recruiting?";
		Reply="Yes, and if you dare to join, you are going to have to prove your loyalty.."};
	{MissionId=63; Tag="banditRecruit_recruit2"; Face="Skeptical";
		Dialogue="How do I prove my loyalty?";
		Reply="If you're sure about proving your loyalty, I will take you to our recruitment leader.."};
	{MissionId=63; Tag="banditRecruit_recruit3"; Face="Serious";
		Dialogue="I want to prove my loyalty.";
		Reply="Alright, follow me.."};

};

return NpcDialogues;