local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Face="Smirk";
		Reply="Hmm?";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["aggresiveInit"]={
		Face="Angry";
		Reply="Halt! Turn back now!";
	};
	
	["guide_factions"]={
		Face="Happy";
		Say="You said something about starting our own faction?";
		Reply="Yeah! I'll help with distributing the information to keep the members up to date.. But I'll need 5000 gold before we begin..";
		ReturnToInit=true;
	};
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
		local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
		local modEvents = require(game.ServerScriptService.ServerLibrary.Events);

		if #modMission:GetNpcMissions(player, script.Name) > 0 then return end;

		if not modMission:IsComplete(player, 30) then
			dialog:SetInitiateTag("aggresiveInit");
			return;
		end
		
		if not modMission:IsComplete(player, 58) then return end;
			
		local profile = shared.modProfile:Get(player);
		local factionTag = tostring(profile.Faction.Tag);
		local safehomeData = profile.Safehome;
	
	
		local npcNames = {};
		for name, npcData in pairs(safehomeData.Npc) do
			if name == "Patrick" then continue end;
			if npcData and npcData.Active then
				table.insert(npcNames, name);
			end
		end
		if #npcNames > 0 then
			local targetNpcName = table.remove(npcNames, math.random(1, #npcNames));
	
			local rngDialogues = {
				" seems to be visiting the freezer a bit much lately..";
				" has been doing a good job keep zombies off our lawn..";
				" forgot to take out the trash last night..";
				" clogged the toilet again..";
				" accidentally attracted a horde towards us, lucky we fended them off..";
			}
			
			if #npcNames > 1 then
				table.insert(rngDialogues, " and ".. npcNames[math.random(1, #npcNames)] .. " might be up to something..");
				table.insert(rngDialogues, " and ".. npcNames[math.random(1, #npcNames)] .. " found a vechicle while scavenging and spent a bunch of resources trying to get it fixed up, but to no avail..");
				table.insert(rngDialogues, " and ".. npcNames[math.random(1, #npcNames)] .. " are playing that Fall of the Living card game too much..");
			end
	
			local newDialog = {
				Face="Smirk";
				Say="Anything interesting happened?";
				Reply="Hmmm, ".. targetNpcName .. rngDialogues[math.random(1, #rngDialogues)];
			};
	
			if #rngDialogues > 0 then
				dialog:SetInitiate(newDialog.Reply, newDialog.Face);
			end
			
		else
			dialog:SetInitiate("Welcome back!");
			
		end
		
		if factionTag == nil then
			dialog:AddChoice("guide_factions");
		end
		
	
		local wantedPoster = modEvents:GetEvent(player, "wantedPoster");
		if wantedPoster then
			local dialogPacket = {
				Face="Happy";
				Say="Who's wanted posters are we putting up?";
			}
			
			local modNpcProfileLibrary = require(game.ReplicatedStorage.BaseLibrary.NpcProfileLibrary);
			local npcLib = modNpcProfileLibrary:Find(wantedPoster.Name);
			local nameRich = '<font face="ArialBold" color="#'.. modNpcProfileLibrary.ClassColors[npcLib.Class]:ToHex() ..'">'.. wantedPoster.Name ..'</font>';
			
			dialogPacket.Reply = "I've been putting up ".. nameRich .."'s wanted posters.";
			dialog:AddDialog(dialogPacket, function(dialog)
				
			end);
		end
	
		local list = modStorage.ListItemIdFromStorages("wantedposter", player);
	
		if #list > 0 and shared.modSafehomeService and shared.modSafehomeService.FactionTag == nil then
	
			local dialogPacket = {
				Face="Happy";
				Say="I have wanted posters I want you to put up..";
				Reply="Sure, which one?";
			}
			
			dialog:AddDialog(dialogPacket, function(dialog)
				
				local availablePosters = {};
				
				for a=1, #list do
					local storageItem = list[a].Item;
					
					local wantedNpc = storageItem.Values and storageItem.Values.WantedNpc;
					if wantedNpc then
						local modNpcProfileLibrary = require(game.ReplicatedStorage.BaseLibrary.NpcProfileLibrary);
						local npcLib = modNpcProfileLibrary:Find(wantedNpc);
						local nameRich = '<font face="ArialBold" color="#'.. modNpcProfileLibrary.ClassColors[npcLib.Class]:ToHex() ..'">'.. wantedNpc ..'</font>';
						list[a].NameRich = nameRich;
						availablePosters[wantedNpc] = list[a];
					end
				end
	
				for npcName, info in pairs(availablePosters) do
					if table.find(npcNames, npcName) then continue end;
	
					local dialogPacket = {
						Face="Happy";
						Say= "Give ".. info.NameRich .."'s Wanted Poster";
						Reply="I'll get right to it and put up these ".. info.NameRich .."'s Wanted Poster";
					}
					
					dialog:AddDialog(dialogPacket, function(dialog)
						modEvents:NewEvent(player, {Id="wantedPoster"; Name=npcName;});
						info.Storage:Remove(info.Item.ID);
						shared.Notify(player, "A ".. npcName .." wanted poster has been given to Patrick.", "Inform");
	
					end)
				end
			end);
		end
	end
	
end

return Dialogues;