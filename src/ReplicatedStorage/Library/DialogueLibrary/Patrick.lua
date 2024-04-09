local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local NpcDialogues = {};

NpcDialogues.Initial = {
	"Hmm?";
};

NpcDialogues.Dialogues = {
	{Tag="aggresiveInit"; Face="Angry"; 
		Reply="Halt! Turn back now!";};
	
	{MissionId=30; Tag="pokeTheBear_start"; Face="Angry";
		Dialogue="I really need to speak to your leader, you kidnapped our people!";
		Reply="I don't care, you weaklings will probably die out sooner on your own!"};
	
	{MissionId=30; Tag="pokeTheBear_A1"; Face="Bored";
		Dialogue="You kidnapped our friend and I will fight to rescue him!";
		Reply="You're up against an army of people buddy, your death would be fast and swift."};
	
	{MissionId=30; Tag="pokeTheBear_A2"; Face="Sad";
		Dialogue="How could you do this?! Where's your humanity?";
		Reply="Look, the world has gone down the toilet, everybody's just doing whatever to survive."};
	
	{MissionId=30; Tag="pokeTheBear_A3"; Face="Frustrated";
		Dialogue="We're also doing whatever to survive, but you don't see us kidnapping anyone!";
		Reply="Hey, I don't tell you how to survive, so don't tell me how to survive."};
	
	{MissionId=30; Tag="pokeTheBear_P1"; Face="Skeptical";
		Dialogue="But why did you kidnap our friend?";
		Reply="Look, I don't know what and why our leader kidnapped who. They put food on the table and that's all it matters to me."};
	
	{MissionId=30; Tag="pokeTheBear_P2"; Face="Grumpy";
		Dialogue="You don't need to do this to get food..";
		Reply="Hey, I don't tell you how to find your food, so don't tell me how I should find mine."};
		
	{MissionId=30; Tag="pokeTheBear_bribe"; Face="Skeptical";
		Dialogue="Look, what can I do to talk to your leader?";
		Reply="Hmmm.. You know what, get me some food and I will secretly let you in.."};
	
	
	
	{MissionId=30; Tag="pokeTheBear_beans1"; Face="Joyful";
		Dialogue="*Give 1 can of Canned Beans*";
		Reply="Alright, this is the good stuff.. Come back later, I can't let you in right now. I'll let you know when I can."};
		
	{MissionId=30; Tag="pokeTheBear_beans2"; Face="Joyful";
		Dialogue="*Give 2 can of Canned Beans*";
		Reply="Great. This is the good stuff.. Come back later, I can't let you in right now. I'll let you know when I can."};
		
	{MissionId=30; Tag="pokeTheBear_beans3"; Face="Joyful";
		Dialogue="*Give 3 can of Canned Beans*";
		Reply="Amazing! This is the good stuff.. Come back later, I can't let you in right now. I'll let you know when I can."};
		
	{Tag="banditOutpost";
		Dialogue="Could you take me to the Bandit Outpost?";
		Reply="Sure..";
		ReplyFunction=function(dialogPacket)
			local npcModel = dialogPacket.Prefab;
			if npcModel:FindFirstChild("banditOutpostInteractable") then
				local localPlayer = game.Players.LocalPlayer;
				local modData = require(localPlayer:WaitForChild("DataModule"));

				modData.InteractRequest(npcModel.banditOutpostInteractable, npcModel.PrimaryPart);
			end
		end};

	{Tag="banditmapGift"; Face="Happy";
		Dialogue="Hey, how's the wound?";
		Reply="It's getting better.. Oh and I want to give you this.."};

	{Tag="guide_factions"; Dialogue="You said something about starting our own faction?"; Face="Happy";
		Reply="Yeah! I'll help with distributing the information to keep the members up to date.. But I'll need 5000 gold before we begin.."}; --end

	{Tag="safehomeInit"; Face="Confident"; 
		Reply="Welcome back.";};


	--Rats Recruitment
	{MissionId=62; Tag="theRecruit_settleR"; Face="Confident"; 
		Dialogue="How are you settling in?";
		Reply="It's great, the place is really cozy."};
	{MissionId=62; Tag="theRecruit_settle2R"; Face="Confident"; 
		Dialogue="Hear anything about the Bandits or the Rats?";
		Reply="Yes, in fact, I got intel that Revas wants to talk to you after you helped pull the lever."};
	{MissionId=62; Tag="theRecruit_revas1"; Face="Surprise"; 
		Dialogue="Should I talk to Revas?";
		Reply="I guess if you want to figure out what he wants, since he shot me last time, I'm no longer interested in joining them."};


	--Bandits Recruitment
	{MissionId=63; Tag="theRecruit_settleB"; Face="Confident"; 
		Dialogue="How are you settling in?";
		Reply="It's great, the place is really cozy."};
	{MissionId=63; Tag="theRecruit_settle2B"; Face="Confident"; 
		Dialogue="Hear anything about the Bandits or the Rats?";
		Reply="Yes actually, I heard the Bandits are recruiting, and they are looking specifically for you because they somehow found out you helped them."};
	{MissionId=63; Tag="theRecruit_zark1"; Face="Surprise"; 
		Dialogue="Should I talk to Zark?";
		Reply="That would be quite risky, but if you want to take the Bandits down, you might have to take them down from within."};

	
	--Deadly Zeniths Strike
	{MissionId=73; Tag="dps_init"; Face="Frustrated"; 
		Reply="Hurry, I think it's around here somewhere. Get your weapons ready..";};
	{MissionId=73; Tag="dps_start"; Face="Skeptical"; 
		Dialogue="What is here?";
		Reply="A zenith boss is here, be careful."};
	{MissionId=73; Tag="dps_retry"; Face="Frustrated"; 
		Reply="It's still around, let's try this again.";};
	{MissionId=73; Tag="dps_restart"; Face="Skeptical"; 
		Dialogue="Let's do this again..";
		Reply="That's the spirit, take it down."};
	{MissionId=73; Tag="dps_cheer"; Face="Frustrated"; 
		Reply="Watch your backs!";};
	{MissionId=73; Tag="dps_goToHq"; Face="Happy"; 
		Dialogue="I got a mission from my faction, can you bring me to HQ?";
		Reply="Sure, let's go.."};
};

--[[
	A: Aggressive
	P: Passive
--]]


return NpcDialogues;