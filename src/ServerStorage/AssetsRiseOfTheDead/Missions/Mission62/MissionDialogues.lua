local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

--=
local Dialogues = {
	Patrick={};
	Eugene={};
	Revas={};
	Stan={};
};

local missionId = 62;
--==

-- MARK: Patrick Dialogues
Dialogues.Patrick.Dialogues = function()
	return {
		{Tag="theRecruit_settleR"; Face="Confident"; 
			Dialogue="How are you settling in?";
			Reply="It's great, the place is really cozy."};
		{Tag="theRecruit_settle2R"; Face="Confident"; 
			Dialogue="Hear anything about the Bandits or the Rats?";
			Reply="Yes, in fact, I got intel that Revas wants to talk to you after you helped pull the lever."};
		{Tag="theRecruit_revas1"; Face="Surprise"; 
			Dialogue="Should I talk to Revas?";
			Reply="I guess if you want to figure out what he wants, since he shot me last time, I'm no longer interested in joining them."};
	};
end

-- MARK: Eugene Dialogues
Dialogues.Eugene.Dialogues = function()
	return {
		{Tag="theRecruit_help"; Face="Skeptical";
			Dialogue="Umm, sorry. What do you need again?";
			Reply="What?! How incompetent are you, I said I need 2 Nekron Particulate Caches."};

		{Tag="theRecruit_nekronParticulateCache"; Face="Skeptical";
			Dialogue="Here's the 2 Nekron Particulate Cache you requested.";
			Reply="Good, good. Just put it down and get out of my sight."};
	};
end

-- MARK: Revas Dialogues
Dialogues.Revas.Dialogues = function()
	return {
		{Tag="theRecruit_revasInit"; Face="Confident"; 
			Reply="Ah, just who I was looking for..";};

		{Tag="theRecruit_revas1"; Face="Confident";
			Dialogue="What on earth was that?! You shot patrick!";
			Reply="Indeed, how is he right now? He honored our argreement."};
		{Tag="theRecruit_revas2"; Face="Confident";
			Dialogue="He did not agree to being shot. He's no longer interested in your offer.";
			Reply="That's ashame despite agreeing to do whatever it takes.\n\nAnyways, I have not had the chance to show my gratitude for helping us."};
		{Tag="theRecruit_revas3"; Face="Confident";
			Dialogue="By pulling the lever?";
			Reply="Yes, thanks to you, we captured the infector that the Bandits brought in. Come with me when you are ready.."};
		{Tag="theRecruit_revasTravel"; Face="Confident";
			Dialogue="I'm ready to go.";
			Reply="Fantastic, follow me this way, through the intricate rat underground tunnels."};

		{Tag="theRecruit_secE"; Face="Confident";
			Dialogue="So this is Sector E..";
			Reply="Indeed, it has been repurposed. Since much of the systems are still functional and Eugene was the head of this sector.\n\nNow, follow me.."};

		{Tag="theRecruit_retrieve1"; Face="Confident";
			Dialogue="Alright, what do you need?";
			Reply="There's only one physical copy of a certain research paper that Eugene needs. He'll also need some Nekron particulate cache. Let's first head to Sector F.."};

		{Tag="theRecruit_cantFind"; Face="Suspicious";
			Dialogue="I can't seem to find it..";
			Reply="It should be in one of the labs, check the top of the counters.."};
		{Tag="theRecruit_found"; Face="Confident";
			Dialogue="Here's the papers.";
			Reply="Excellent, as for the Nekron particulate cache, I trust that you can manage that yourself. Good luck."};

	};
end

-- MARK: Stan Dialogues
Dialogues.Stan.Dialogues = function()
	return {
		{Tag="ratRecruit_chamber1"; Face="Tired";
			Dialogue="Stan?! Can you hear me..?";
			Reply="Yes.. What's happening?.."};
		{Tag="ratRecruit_chamber2"; Face="Tired";
			Dialogue="You are a infector..";
			Reply="Yeah, I can feel it fighting inside of me.. Please.. Help me."};
		{Tag="ratRecruit_chamber3"; Face="Tired";
			Dialogue="But the parasite inside you.. What can I do?";
			Reply="I will control it. Please, they are going to kill me, or at least help me turn down the heat.."};
		
		{Tag="ratRecruit_chamber4"; Face="Serious";
			Dialogue="Those people are Rats' people, they might be able to help you..";
			Reply="No, don't trust them. They will use you, they just want whatever's inside of me and kill me when they're done.."};
		{Tag="ratRecruit_chamber5"; Face="Skeptical";
			Dialogue="I'm not sure what I can do..";
			Reply="Alright, listen. You've come this far, just work with them for a while, buy me some time so I can figure out how you can get me out of here.."};
		{Tag="ratRecruit_chamber6"; Face="Skeptical";
			Dialogue="Sure, I'll do that..";
			Reply="Okay, I hear them coming back, quick, act natural!"};
	};
end

if RunService:IsServer() then
	local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
	local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

	-- MARK: Patrick Handler
	Dialogues.Patrick.DialogueHandler = function(player, dialog, data, mission)
		if mission.Type == 2 then -- Available
			if mission.ProgressionPoint == 1 then
				dialog:SetInitiateTag("safehomeInit");
				dialog:AddChoice("theRecruit_settleR", function(dialog)
					dialog:AddChoice("theRecruit_settle2R", function(dialog)
						dialog:AddChoice("theRecruit_revas1", function(dialog)
							modMission:StartMission(player, missionId);
						end)
					end)
				end);
			end
		end

	end

	-- MARK: Eugene Handler
	if modBranchConfigs.IsWorld("SectorE") then
		Dialogues.Eugene.DialogueHandler = function(player, dialog, data, mission)
			if mission.Type == 1 then -- Active
				local stage = mission.ProgressionPoint;
				if stage == 15 then
					dialog:SetInitiate("Well?..");
	
					local profile = shared.modProfile:Get(player);
					local playerSave = profile:GetActiveSave();
					local inventory = playerSave.Inventory;
					local total, itemList = inventory:ListQuantity("nekronparticulatecache", 2);
	
					if total >= 2 then
						dialog:AddChoice("theRecruit_nekronParticulateCache", function(dialog)
							for a=1, #itemList do
								inventory:Remove(itemList[a].ID, itemList[a].Quantity);
								shared.Notify(player, "2 Nekron Particulate Cache removed from your Inventory.", "Negative");
							end
							
							modMission:CompleteMission(player, missionId);
						end)
						
					else
						dialog:AddChoice("theRecruit_help");
						
					end
					
				end
			end
		end
	end
	
	-- MARK: Revas Handler
	if modBranchConfigs.IsWorld("TheHarbor") then
		local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);

		Dialogues.Revas.DialogueHandler = function(player, dialog, data, mission)
			if mission.Type == 1 then -- Active
				local stage = mission.ProgressionPoint;
				if stage == 1 then
					dialog:SetInitiateTag("theRecruit_revasInit");
					dialog:AddChoice("theRecruit_revas1", function(dialog)
						dialog:AddChoice("theRecruit_revas2", function(dialog)
							dialog:AddChoice("theRecruit_revas3", function(dialog)
								modMission:Progress(player, missionId, function(mission)
									if mission.ProgressionPoint < 2 then
										mission.ProgressionPoint = 2;
									end;
								end)
							end)
						end)
					end);

				elseif stage == 2 then
					dialog:SetInitiate("Are you ready?");
					dialog:AddChoice("theRecruit_revasTravel", function(dialog)
						--modServerManager:Travel(player, "SectorE");
						modServerManager:TeleportToPrivateServer("SectorE", modServerManager:CreatePrivateServer("SectorE"), {player});
					end)

				end
			end
		end
	elseif modBranchConfigs.IsWorld("SectorE") then
		Dialogues.Revas.DialogueHandler = function(player, dialog, data, mission)
			if mission.Type == 1 then -- Active
				local stage = mission.ProgressionPoint;
				if stage == 3 then
					dialog:SetInitiate("Here we are.");
					dialog:AddChoice("theRecruit_secE", function(dialog)
						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint <= 4 then
								mission.ProgressionPoint = 4;
							end
						end)
					end)
					
				elseif stage == 11 then
					dialog:SetInitiate("Eugene requires some items. Maybe you can be of service.");

					dialog:AddChoice("theRecruit_retrieve1", function(dialog)
						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint <= 11 then
								mission.ProgressionPoint = 12;
							end
						end)
					end)
					
				end
			end
		end
	elseif modBranchConfigs.IsWorld("SectorF") then
		Dialogues.Revas.DialogueHandler = function(player, dialog, data, mission)
			if mission.Type == 1 then -- Active
				local stage = mission.ProgressionPoint;
				if stage == 13 then
					dialog:SetInitiate("Have you found it?");
					dialog:AddChoice("theRecruit_cantFind");
					
				elseif stage == 14 then
					dialog:SetInitiate("Have you found it?");

					local profile = shared.modProfile:Get(player);
					local playerSave = profile:GetActiveSave();
					local inventory = playerSave.Inventory;
					local total, itemList = inventory:ListQuantity("researchpapers", 1);
					
					if total >= 1 then
						dialog:AddChoice("theRecruit_found", function(dialog)
							for a=1, #itemList do
								inventory:Remove(itemList[a].ID, itemList[a].Quantity);
								shared.Notify(player, "Research papers removed from your Inventory.", "Negative");
							end

							modMission:Progress(player, missionId, function(mission)
								mission.ProgressionPoint = 15;
							end)
						end)
						
					else
						dialog:AddChoice("theRecruit_cantFind");
						
					end
					
				end
			end
		end
	end

	-- MARK: Stan Handler
	if modBranchConfigs.IsWorld("SectorE") then
		Dialogues.Stan.DialogueHandler = function(player, dialog, data, mission)
			if mission.Type == 1 then -- Active
				local stage = mission.ProgressionPoint;
				if stage == 6 then
					
				elseif stage == 7 then
					dialog:SetInitiate("It.. burns..\n\nIt's you.. $PlayerName..");

					dialog:AddChoice("ratRecruit_chamber1", function(dialog)
						dialog:AddChoice("ratRecruit_chamber2", function(dialog)
							dialog:AddChoice("ratRecruit_chamber3", function(dialog)
								modMission:Progress(player, missionId, function(mission)
									mission.ProgressionPoint = 8;
								end)

							end)
						end)
					end)

				elseif stage == 8 then
					dialog:SetInitiate("Use the terminal, look around if you don't know how, I think Eugene wrote down some notes.");

				elseif stage == 9 then
					dialog:SetInitiate("Thanks, $PlayerName..");
					dialog:AddChoice("ratRecruit_chamber4", function(dialog)
						dialog:AddChoice("ratRecruit_chamber5", function(dialog)
							dialog:AddChoice("ratRecruit_chamber6", function(dialog)
								modMission:Progress(player, missionId, function(mission)
									mission.ProgressionPoint = 10;
								end)
								
							end)
						end)
						
					end)
					
				end
			end
		
		end
	end
end


return Dialogues;