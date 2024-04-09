local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local NpcDialogues = {};

NpcDialogues.Initial = {
	"I wanted freedom, but this isn't what I was expecting..";
	"I'm prison mike!";
	"Freeedom!";
};

NpcDialogues.Dialogues = {
	{Tag="travel_prison";
		Dialogue="Could you take me to the Wrighton Dale Prison?";
		Reply="I guess..";
		ReplyFunction=function(dialogPacket)
			local npcModel = dialogPacket.Prefab;
			if npcModel:FindFirstChild("prisonInteractable") then
				local localPlayer = game.Players.LocalPlayer;
				local modData = require(localPlayer:WaitForChild("DataModule"));

				modData.InteractRequest(npcModel.prisonInteractable, npcModel.PrimaryPart);
			end
		end};
	
	{MissionId=45; Tag="mlc_init"; Dialogue="What's wrong? What did you left?"; 
		Reply="My lucky coin, I left it when I got out of prison."};
	{MissionId=45; Tag="mlc_start"; CheckMission=45; Dialogue="I could help you look for it if you lead me there."; 
		Reply="Oh, that would be great. Whenever you are ready."};
	{MissionId=45; Tag="mlc_found"; Dialogue="Is this the coin you were looking for?"; 
		Reply="YES! Oh, thanks so much."};
	
	
	{Tag="general_inprison"; Dialogue="Why were you in prison?"; 
		Reply="I was on a job.. A heist all planned out, a three man job.. But I was backstabbed.. They threw me under the bus and they escaped. This was years ago."}; --end
	{Tag="general_how"; Dialogue="How did you escape?"; 
		Reply="A cellmate of mine heard that one of the prisoner volunteered into a special program.. He was transported to some lab one day, and been gone the whole day. Few days after that, he's been acting strange.\n\nThat night, we all heard a huge roar, the guards unlocked his cell to try to get him out back to the lab."};
	{Tag="general_how2"; Dialogue="And then what happened?"; 
		Reply="THAT PRISONER SENT THE GUARD FLYING!! He then forced some of the prison gates open and the control room caught on fire. Next thing I know, all the cells are unlocked and I got out of there as fast as I could."};
};

return NpcDialogues;