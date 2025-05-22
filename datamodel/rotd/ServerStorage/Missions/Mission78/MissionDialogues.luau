local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Lydia={};
};

local MISSION_ID = 78;
--==

-- MARK: Lydia Dialogues
Dialogues.Lydia.DialogueStrings = {
	["killhue_init"]={
		Face="Happy"; 
		Reply="Hi $PlayerName!";
	};

	["killhue_start"]={
		CheckMission=MISSION_ID; 
		Say="Hey Lydia, how are you doing?";
		Face="Worried"; 
		Reply="I'm alright.. But since you're here, I have a request.";
		FailResponses = {
			{Reply="Hmm, actually nevermind.."};
		};
	};
	["killhue_start2"]={
		Say="Oh, what are you requesting?";
		Face="Worried"; 
		Reply="I've been wanting to kill zombies, but I've never used a gun before.";
	};
	["killhue_start3"]={
		Say="I could teach you how to use a gun.";
		Face="Happy"; 
		Reply="Yay! Oh, but I don't actually have a gun.";
	};
	["killhue_start4"]={
		Say="Don't worry, I will get you a gun.";
		Face="Happy"; 
		Reply="Oooo. Sure, I'll wait here.";
	};

	["killhue_giveGun"]={
		Say="Hey, I got a gun for you.";
		Face="Happy"; 
		Reply="Yay!";
	};

	["killhue_finInit"]={
		Face="Joyful"; 
		Reply="That was really fun, thanks for letting me learn and shoot some zombies!";
	};
	["killhue_fin1"]={
		Say="You did pretty good! Now you can defend yourself with the gun.";
		Face="Suspicious"; 
		Reply="Mhm! Hmmmm, something still bothers me. It's not too important but..";
	};
	["killhue_fin2"]={
		Say="..? What's bothering you?";
		Face="Oops"; 
		Reply="The colors of the gun.. Hahah! I like to decorate the things I have..";
	};
	["killhue_fin3"]={
		Say="Ohh";
		Face="Oops"; 
		Reply="You know what, since you taught me how to shoot, how about I scavenge some new colors for your weapons?";
	};
	["killhue_fin4"]={
		Say="Sure, I guess..";
		Face="Happy"; 
		Reply="Yay! I'll see what I can find.";
	};
};

if RunService:IsServer() then
	-- MARK: Lydia Handler
	Dialogues.Lydia.DialogueHandler = function(player, dialog, data, mission)
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		local modNpcs = shared.modNpcs;

		local lydiaModule = modNpcs.getByModel(dialog.Prefab)
		if lydiaModule == nil or lydiaModule.Owner ~= player then
			shared.Notify(player, "[The Killer Hues] You are not in your safehome for this mission.", "Inform"); 
			return;
		end;

		if mission.Type == 2 then -- Available
			dialog:SetInitiateTag("killhue_init");
			dialog:AddChoice("killhue_start", function(dialog)
				dialog:AddChoice("killhue_start2", function(dialog)
					dialog:AddChoice("killhue_start3", function(dialog)
						dialog:AddChoice("killhue_start4", function(dialog)
							modMission:StartMission(player, MISSION_ID);
						end);
					end);
				end);
			end);

		elseif mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 1 then
				dialog:AddDialog({
					Face="Happy";
					Say="Hey, I got a gun for you.";
					Reply="Yay!";
					ToggleWindow="NpcWindow";
				}, function(dialog)
					if lydiaModule then
						lydiaModule.Chat(lydiaModule.Owner, "I hope the gun is pretty. :3");
					end
				end, "Lydia");
				
			elseif mission.ProgressionPoint == 6 then
				dialog:SetInitiateTag("killhue_finInit");
				dialog:AddChoice("killhue_fin1", function(dialog)
					dialog:AddChoice("killhue_fin2", function(dialog)
						dialog:AddChoice("killhue_fin3", function(dialog)
							dialog:AddChoice("killhue_fin4", function(dialog)
								modMission:CompleteMission(player, MISSION_ID);
								shared.Notify(player, "Lydia can now scavenge custom colors to unlock for customizing your weapons.", "Inform");

								local lydiaStorage = shared.modStorage.Get("LydiaStorage", player);
								if lydiaStorage then
									lydiaStorage.Locked = false;
								end
							end)
						end)
					end)
				end)

			end
			
		end
	end
end


return Dialogues;