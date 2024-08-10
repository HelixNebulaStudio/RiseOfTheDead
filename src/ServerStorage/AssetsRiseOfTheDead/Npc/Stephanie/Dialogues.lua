local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: PromptProfile
Dialogues.PromptProfile = {
	World=[[
	I'm held up in a safehouse called "The Warehouse".
	It's a old carshop warehouse with red brick walls.
	It is completely fenced off from the outside and is pretty safe inside.
	]];
	Role=[[
	I am a Survivor.
	I am a 27 year old caucasian woman who was a martial arts teacher.
	I am a bit of a tinker, and mash components together in my free time.
	I am also a scavenger.
	I generally try to improve my weapons by adding interesting mods to it.
	I am playful but in a appropriate way.
	]];
	Appear=[[
	I have dark brown hair and slightly tanned skin.
	I wear a black bottom with a short-sleeved black jacket, along with some gloves
	I have a Dual P250 as my weapon, my left P250 is called Icey and right P250 is called Feisty.
	]];
	Relations=[[
	I created the Incendiary Rounds mod blueprint for $PlayerName, with it built and attached to their weapon, they can ignite their enemies with the mod.
	I created another elemental mod called Electric Charge for $PlayerName which when attached to a weapon allows their weapon to shock and damage near by enemies.
	Mason is a great leader of this group, if it wasn't for him, I would have still be looking for shelter.
	I used to sell chopped up planks from my martial arts class to Mason.
	Nick is great, he is really socially aware for his age.
	I don't know Dr. Deniski that well but he was helpful when I needed bandages.
	Russell used to be my building's janitor and cleans up my martial art's class room once we're done, he is a wholesome guy.
	I am not a big fan of Jesse, he seems so rude.
	]];
};

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Hmmmm..? What do you want?";
	};
	["init2"]={
		Reply="Need something or what?";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
		local remoteSetHeadIcon = remotes:WaitForChild("SetHeadIcon");

		local npcName = dialog.Name;

		remoteSetHeadIcon:FireClient(player, 0, npcName, "Guide");
	
		local mission3 = modMission:GetMission(player, 3);
		if mission3 == nil then
			dialog:AddChoice("pre_findBook");
		end
		
		local mission9 = modMission:GetMission(player, 9);
		if mission3 and mission3.Type == 3 and (mission9 == nil or mission9.Type ~= 3) then
			dialog:AddChoice("findBook_whatsInTheBook");
		end
	end 
end

return Dialogues;