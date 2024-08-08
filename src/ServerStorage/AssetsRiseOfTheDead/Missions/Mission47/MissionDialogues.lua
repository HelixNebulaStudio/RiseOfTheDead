local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Carlos={};
};

local missionId = 47;
--==

-- MARK: Carlos Dialogues
Dialogues.Carlos.DialogueStrings = {
	["soundOfMusic_get"]={
		Say="Hey, where can I get a flute like yours?";
		Reply="Oh, I'm glad you asked. I want to spread hope with music, I'd gladly give you one of my extra new flute if you can learn to play it.";
	};
	["soundOfMusic_sure"]={
		CheckMission=missionId;
		Say="Sure, can you teach me?";
		Reply="Of course, give me a second to find it.";
	};
	["soundOfMusic_full"]={
		Say="*Waits patiently for the flute*";
		Reply="Your inventory is full.";
	};
	["soundOfMusic_take"]={
		Say="*Waits patiently for the flute*";
		Reply="Here you go, try to play these notes to me.";
	};
	["soundOfMusic_done"]={
		Say="Thanks, that was fun.";
		Reply="There are other instruments too if you ever come across them.";
	};
	
	["soundOfMusic_how"]={
		Say="How do I do this again?";
		Reply="Okay, you need to equip the flute, then use it to play these notes. C, C, G, F, D#, D, D, D, F, D#, D, C, C, D#, D, D#, D, D#.";
	};
};

if RunService:IsServer() then
	-- MARK: Carlos Handler
	Dialogues.Carlos.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			if stage == 1 then

				local profile = shared.modProfile:Get(player);
				local activeInventory = profile.ActiveInventory;

				local hasSpace = activeInventory:SpaceCheck{{ItemId="flute"}};
				if not hasSpace then
					dialog:AddChoice("soundOfMusic_full");

				else
					dialog:AddChoice("soundOfMusic_take", function(dialog)
						if mission.ProgressionPoint == 1 then mission.ProgressionPoint = 2; end;
						activeInventory:Add("flute");
						shared.Notify(player, "You recieved a Flute.", "Reward");
					end)

				end
				
				modMission:Progress(player, 14, function(mission)
					if mission.ProgressionPoint < 3 then
						mission.ProgressionPoint = 3;
					end;
				end)
				
			elseif stage == 3 then
				dialog:SetInitiate("That was great! Please share your musical knowledge with others too!");
				dialog:AddChoice("soundOfMusic_done", function(dialog)
					modMission:CompleteMission(player, missionId);
				end)
				
			end
			dialog:AddChoice("soundOfMusic_how");
			
		elseif mission.Type == 2 then -- Available;
			dialog:AddChoice("soundOfMusic_get", function(dialog)
				dialog:AddChoice("soundOfMusic_sure", function(dialog)
					modMission:StartMission(player, missionId);
				end)
			end)
			
		end
	end
end


return Dialogues;