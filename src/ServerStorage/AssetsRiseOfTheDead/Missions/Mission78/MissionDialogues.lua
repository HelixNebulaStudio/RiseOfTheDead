local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

--=
local Dialogues = {
	Lydia={};
};

local missionId = 78;
--==

-- MARK: Lydia Dialogues
Dialogues.Lydia.Dialogues = function()
	return {
		{Tag="killhue_init";
			Face="Happy"; Reply="Hi $PlayerName!";};

		{CheckMission=missionId; Tag="killhue_start"; Dialogue="Hey Lydia, how are you doing?";
			Face="Worried"; Reply="I'm alright.. But since you're here, I have a request.";
			FailResponses = {
				{Reply="Hmm, actually nevermind.."};
			};
		};
		{Tag="killhue_start2"; Dialogue="Oh, what are you requesting?";
			Face="Worried"; Reply="I've been wanting to kill zombies, but I've never used a gun before."};
		{Tag="killhue_start3"; Dialogue="I could teach you how to use a gun.";
			Face="Happy"; Reply="Yay! Oh, but I don't actually have a gun."};
		{Tag="killhue_start4"; Dialogue="Don't worry, I will get you a gun.";
			Face="Happy"; Reply="Oooo. Sure, I'll wait here."};

		{Tag="killhue_giveGun"; Dialogue="Hey, I got a gun for you.";
			Face="Happy"; Reply="Yay!"};

		{Tag="killhue_finInit";
			Face="Joyful"; Reply="That was really fun, thanks for letting me learn and shoot some zombies!";};
		{Tag="killhue_fin1"; Dialogue="You did pretty good! Now you can defend yourself with the gun.";
			Face="Suspicious"; Reply="Mhm! Hmmmm, something still bothers me. It's not too important but.."};
		{Tag="killhue_fin2"; Dialogue="..? What's bothering you?";
			Face="Oops"; Reply="The colors of the gun.. Hahah! I like to decorate the things I have.."};
		{Tag="killhue_fin3"; Dialogue="Ohh";
			Face="Oops"; Reply="You know what, since you taught me how to shoot, how about I scavenge some new colors for your weapons?"};
		{Tag="killhue_fin4"; Dialogue="Sure, I guess..";
			Face="Happy"; Reply="Yay! I'll see what I can find."};
	};
end

if RunService:IsServer() then
	-- MARK: Lydia Handler
	Dialogues.Lydia.DialogueHandler = function(player, dialog, data, mission)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
		local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);

		local lydiaModule = modNpc.GetNpcModule(dialog.Prefab)
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
							modMission:StartMission(player, missionId);
						end);
					end);
				end);
			end);

		elseif mission.Type == 1 then -- Active
			if mission.ProgressionPoint == 1 then
				dialog:AddDialog({
					Face="Happy";
					Dialogue="Hey, I got a gun for you.";
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
								modMission:CompleteMission(player, missionId);
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