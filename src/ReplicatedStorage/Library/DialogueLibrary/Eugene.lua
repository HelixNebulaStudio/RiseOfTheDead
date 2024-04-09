local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local NpcDialogues = {};

NpcDialogues.Initial = {
};

NpcDialogues.Dialogues = {
	-- Rats Recruitment
	{MissionId=62; Tag="theRecruit_help"; Face="Skeptical";
		Dialogue="Umm, sorry. What do you need again?";
		Reply="What?! How incompetent are you, I said I need 2 Nekron Particulate Caches."};
	
	{MissionId=62; Tag="theRecruit_nekronParticulateCache"; Face="Skeptical";
		Dialogue="Here's the 2 Nekron Particulate Cache you requested.";
		Reply="Good, good. Just put it down and get out of my sight."};
	
};

return NpcDialogues;