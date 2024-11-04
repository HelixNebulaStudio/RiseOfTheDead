local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local missionId = 85;

local dialogsList = {
	--{Say="Hello, how're you feeling?"; Reply="Not too bad, hope the weather's good today.";};

	{
		Init="Killing the zombies are such a waste of energy..";
		Say="At least we're slowly wiping them out right?"; 
		Reply="Not really, they just keep regenerating!";
	};

	{
		Init="Oh hey, what are you doing here?";
		Say="Check on how you're holding up."; 
		Reply="Not bad, could be better.";
	};

	{
		Init="If Wrighton Dale's all barricaded up, how are the Rats getting they're products to sell?";
		Say="That is a mystery indeed.."; 
		Reply="Hmmm.. Maybe they are Rats because they got some kind of pipe or tunnel to crawl around it.";
	};

	{
		Init="Anyone signing up to be a Bandit is stupid.";
		Say="I heard they don't even get enough food for themselves."; 
		Reply="Them being backed by the military are a total lie.";
	};

	{NpcName="Michael";
		Init="Would be nice if someone could take my place..";
		Say="How long have you been keeping watch?"; 
		Reply="Way too long, but I guess keeping them safe keeps me going..";
	};

	{NpcName="Russell";
		Init="Why do people keep trying to talk to me?!";
		Say="Sorry, I didn't mean to disturb you."; 
		Reply="Leave! I'm going back to sleep now.";
	};

	{NpcName="Stephanie";
		Say="Discover anything new?"; 
		Reply="I think I'm really close to discovering a weapon of mass destruction..";
	};

	-- 24
	{MissionId=24; ExcludeNpc={"Carlson"; "Erik"};
		Say="A group of survivors lives right next to a giant worm nest.."; 
		Reply="Ah yes, the underbridge community.";};

	{MissionId=24; NpcName="Carlson";
		Say="I'm surprised that worm out there hasn't attacked us yet."; 
		Reply="Maybe they are just territorial..";};

	-- 30
	{MissionId=30; 
		Say="Bribing Bandits are pretty easy. Just give them Cannded Beans."; 
		Reply="That is literally why I carry canned beans around.";};

	-- 33
	{MissionId=33; 
		Init="Heard the Bandit boss captured an infector..";
		Say="I was there, I'm not sure if they know what they are dealing with.."; 
		Reply="Well, hope it doesn't go well for them.";};

	-- 38
	{MissionId=38; 
		Init="Okay, why did I only just learnt about infectors?";
		Say="Maybe they blend in too well.."; 
		Reply="I'm going to be so paranoid.";};

	-- 49
	{MissionId=49; ExcludeNpc={"Mason"};
		Say="At least GPS still works.."; 
		Reply="We're trapped here, I don't think the GPS is going to be that useful.";};
		
	{MissionId=49; NpcName="Mason";
		Init="Getting the hang of the GPS yet?";
		Say="Yeah, it's pretty useful actually."; 
		Reply="Good, better not loose it.";};

	-- 51
	{MissionId=51; 
		Init="What are the military even doing..";
		Say="They seem to just be assessing the situation, I'm not sure why can't they just send rescue along."; 
		Reply="I heard they barricaded us all within Wrighton Dale, no one's leaving this place.";};

	-- 52
	{MissionId=52; 
		Say="So apparently infectors are people who's been hijacked by the parasite.. "; 
		Reply="Yeah, I heard patient zero was an infector too, it was too late when people found out.";};

	-- 53
	{MissionId=53; 
		Say="I had to drag a zombie around for some military inspector."; 
		Reply="Sounds like the zombie had a fun time.";};

	-- 54
	{MissionId=54; 
		Say="My safehome is welcoming new survivors right now."; 
		Reply="Glad to hear that, but I think I'm good here for now.";};

	-- 56
	{MissionId=56; 
		Say="So I had to run through the sewers, dodge a air strike and take down an infector.."; 
		Reply="Sounds like you had fun..";};

	-- 58
	{MissionId=58; 
		Init="I heard there was a shoot out between the Rats and the Bandits out in the harbor.";
		Say="Yeah, I was there. It was an intense situation because a trade went wrong."; 
		Reply="Seriously? Wow, these power hungry tyrants.";};

	-- 62
	{MissionId=62; 
		Init="Becareful when you work with the Rats..";
		Say="They got my friend, I have no choice."; 
		Reply="Just beware, they are a bunch of silver tongued rats.";};

	-- 63
	{MissionId=63; 
		Init="Hey, I heard you've been working with the Bandits..";
		Say="Trust me when I say, it's to help you guys.."; 
		Reply="Alright.. You haven't done anything to betray us yet but we'll be on alert.";};

	-- 77
	{MissionId=77; 
		Say="I still can't believe it, but I was just eaten by a gigantic worm beneath the ocean.."; 
		Reply="I can't neither, how are you still alive?!";};

	-- 75
	{MissionId=75; 
		Init="Will we ever get a cure..";
		Say="Actually, I've been helping a few medics and scientist to research infector blood, hopefully we'll find something more that just a power up potion..";
		Reply="That's a relief to hear that there's some progress.";};
	{MissionId=75; 
		Say="Do you know anything about blood research? We might be making progress on a potential cure and we need more people..";
		Reply="No, I can't say I know much.";};

	-- 77
	{MissionId=77; 
		Say="I still can't believe it, but I was just eaten by a gigantic worm beneath the ocean.."; 
		Reply="I can't neither, how are you still alive?!";};
	{MissionId=77; 
		Say="So the mysterious engineer is actually real and he lives in the ocean.."; 
		Reply="Definitely sounds real..";};

	-- 78
	{MissionId=78; 
		Say="I taught a survivor how to use a gun and the suddenly a horde attacked our safehome."; 
		Reply="Well, at least now you got another person to defend the place now.";};
	{MissionId=78; 
		Say="I taught a survivor how to use a gun, in return she's teaching me how to paint my guns."; 
		Reply="Win-win!";};

	-- 79
	{MissionId=79; 
		Say="My arms are so tired killing zombies with a throwing weapon.."; 
		Reply="Maybe get something lighter.";};
	{MissionId=79; 
		Say="I'm getting really good at throwing weapons.."; 
		Reply="Cool, maybe you could teach me some day.";};

	-- 81
	{MissionId=81; 
		Say="I played Fall of the Living with some Rats.."; 
		Reply="You should'nt have.. I bet they cheated.";};

	{MissionId=81; 
		Say="Want to play some Fall of the Living?"; 
		Reply="Maybe next time..";};
	
};

if RunService:IsServer() then
	local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	local modDialogueService = require(game.ReplicatedStorage.Library.DialogueService);
	
	local loadedDialogues = {};

	function MissionLogic.Init(_, mission)

		local function OnChanged(firstRun)
			if mission.Type == 1 then -- OnActive
				local npcName = mission.SaveData.NpcName;
				if npcName == nil then return end;
				if loadedDialogues[npcName] then return end;

				local dialogueHandlerFunc = function(player, dialog, data)
					local rng = Random.new(tonumber(os.date("%H")) :: number);
					local missionProfile = modMission.GetMissions(player.Name);

					local completeMissions = {};

					for a=#missionProfile, 1, -1 do
						local mission = missionProfile[a];
						if mission.Type ~= 3 then continue end;
						table.insert(completeMissions, mission);

						if #completeMissions >= 30 then break; end;
					end

					local pickableDialogs = {};
					for a=1, #completeMissions do
						local missionLib = completeMissions[a].Library;
						if not (missionLib.MissionType == 1 or missionLib.MissionType == 2 or missionLib.MissionType == 5) then continue end;

						local missionId = missionLib.MissionId;

						for b=1, #dialogsList do
							if dialogsList[b].MissionId ~= missionId then
								continue;
							end
							if dialogsList[b].NpcName and dialogsList[b].NpcName ~= npcName then
								continue;
							end

							table.insert(pickableDialogs, dialogsList[b]);
						end
					end

					for b=1, #dialogsList do
						if dialogsList[b].MissionId then continue end;
						if dialogsList[b].NpcName and dialogsList[b].NpcName ~= npcName then continue end

						table.insert(pickableDialogs, dialogsList[b]);
					end

					for b=#pickableDialogs, 1, -1 do
						if pickableDialogs[b].ExcludeNpc and table.find(pickableDialogs[b].ExcludeNpc, npcName) then
							table.remove(pickableDialogs, b);
						end
					end

					local pickDialog = pickableDialogs[rng:NextInteger(1, #pickableDialogs)];

					local mission = modMission:GetMission(player, missionId);
					if mission == nil or mission.Type == 3 then return end;

					if pickDialog.Init then
						dialog:SetInitiate(pickDialog.Init);
					end
					dialog:AddDialog({
						Say=pickDialog.Say;
						Reply=pickDialog.Reply;
		
					}, function(dialog)
						modMission:CompleteMission(player, missionId);
					end);
				end
		
				modDialogueService:AddHandler(npcName, dialogueHandlerFunc);
				loadedDialogues[npcName] = dialogueHandlerFunc;

			elseif mission.Type == 3 then -- OnComplete
			
			end
		end
		
		mission.Changed:Connect(OnChanged);
		OnChanged(true);
	end

	game.Players.PlayerRemoving:Connect(function()
		local existNpcNames = {};
		for player, _ in pairs(game.Players:GetPlayers()) do
			local mission = modMission:GetMission(player, missionId);
			if mission and mission.Type ~= 3 then
				existNpcNames[mission.SaveData.NpcName] = true;
			end
		end

		for npcName, diagFunc in pairs(loadedDialogues) do
			if existNpcNames[npcName] then continue end;
			
			modDialogueService:ClearHandler(npcName, diagFunc);
		end
	end)
end

return MissionLogic;